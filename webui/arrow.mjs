import { Arc, Bezier, CurvePoint, EPSILON } from "./curve.mjs";
import { DOM } from "./dom.mjs";
import { Dimensions, Enum, Point, rad_to_deg } from "./ds.mjs";
import {
    kwiver_bridge_arrow_find_endpoints_local,
    kwiver_bridge_arrow_label_position_local,
    kwiver_bridge_arrow_render_plan_local,
} from "./kwiver_bridge.mjs";

function heads_to_csv(heads) {
    return Array.isArray(heads) && heads.length > 0 ? heads.join(",") : "";
}

function shape_geometry_args(shape) {
    const is_endpoint = shape instanceof Shape.Endpoint
        || (shape.size !== undefined && shape.size.is_zero());
    return [
        is_endpoint,
        shape.origin.x,
        shape.origin.y,
        is_endpoint ? 0 : shape.size.width,
        is_endpoint ? 0 : shape.size.height,
        is_endpoint ? 0 : shape.radius,
    ];
}

function arrow_body_style_token(body_style) {
    switch (body_style) {
        case CONSTANTS.ARROW_BODY_STYLE.NONE: return "none";
        case CONSTANTS.ARROW_BODY_STYLE.LINE: return "line";
        case CONSTANTS.ARROW_BODY_STYLE.SQUIGGLY: return "squiggly";
        case CONSTANTS.ARROW_BODY_STYLE.ADJUNCTION: return "adjunction";
        case CONSTANTS.ARROW_BODY_STYLE.PROARROW: return "proarrow";
        case CONSTANTS.ARROW_BODY_STYLE.DOUBLE_PROARROW: return "double proarrow";
        case CONSTANTS.ARROW_BODY_STYLE.BULLET_SOLID: return "bullet solid";
        case CONSTANTS.ARROW_BODY_STYLE.BULLET_HOLLOW: return "bullet hollow";
    }
    return "line";
}

function arrow_dash_style_token(dash_style) {
    switch (dash_style) {
        case CONSTANTS.ARROW_DASH_STYLE.DASHED: return "dashed";
        case CONSTANTS.ARROW_DASH_STYLE.DOTTED: return "dotted";
    }
    return "solid";
}

export class QuiverSVG {
    constructor() {
        // Create a top-level SVG. This will include all the edges and labels as children.
        // Note that we need to explicitly set the namespace attribute so that the SVG can be
        // treated as a standalone file, when we want to export it.
        this.element = new DOM.SVGElement("svg", { xmlns: DOM.SVGElement.NAMESPACE });
    }
}

// Note that we sometimes use fractional pixel values to align drawings optimally with the pixel
// grid.
export const CONSTANTS = {
    /// The space (in pixels) between each line in an n-cell. This space is the distance from the
    /// "outside" of each line: if the lines are thicker, the whitespace between them will be
    /// unaltered, so they will be pushed farther apart.
    LINE_SPACING: 4.5,
    /// The width of each line (in pixels).
    STROKE_WIDTH: 1.5,
    /// The extra padding (in pixels) of the background around an edge.
    BACKGROUND_PADDING: 16,
    /// The opacity (0 to 1) of the background.
    BACKGROUND_OPACITY: 0.2,
    /// How much padding (in pixels) to give to masks to ensure they crop sufficiently.
    MASK_PADDING: 4,
    /// How much spacing (in pixels) to leave between arrowheads of the same type.
    HEAD_SPACING: 2,
    /// How much padding (in pixels) of straight line to provide around the head/tail of a squiggly
    /// line.
    SQUIGGLY_PADDING: 4,
    /// The height (in pixels) of a single triangle of the squiggly arrow body style.
    SQUIGGLY_TRIANGLE_HEIGHT: 2,
    /// The length of the line segments in an adjunction symbol (⊣).
    ADJUNCTION_LINE_LENGTH: 16,
    /// The length of the line segments in a corner (i.e. a pullback or pushout).
    CORNER_LINE_LENGTH: 12,
    /// The radius of the handle for dragging an edge.
    HANDLE_RADIUS: 14,
    /// Constants handling the behaviour of loops.
    ARC: {
        // If `OUTER_DIS` <= `chord_length`, then the path will be a straight line.
        OUTER_DIS: 96,
        // If `INNER_DIS` <= `chord_length` <= `OUTER_DIS`, then the path will be an inner arc, with
        // diameter `INNER_DIS`.
        INNER_DIS: 64,
    },
    /// The possible path shapes to use for an edge.
    ARROW_SHAPE: new Enum(
        "ARROW_SHAPE",
        // Bézier curve (default for edges).
        "BEZIER",
        // Arc (used for loops).
        "ARC",
    ),
    /// The possible styles for an edge.
    ARROW_BODY_STYLE: new Enum(
        "ARROW_BODY_STYLE",
        // No edge ( ).
        "NONE",
        // A line (—). This is the default.
        "LINE",
        // A squiggly line, made up of alternating triangles (⟿).
        "SQUIGGLY",
        // The adjunction symbol: ⊣.
        "ADJUNCTION",
        // A line with a bar through it (-+-).
        "PROARROW",
        // A line with two bars through it (-++-).
        "DOUBLE_PROARROW",
        // A solid bullet.
        "BULLET_SOLID",
        // A hollow bullet.
        "BULLET_HOLLOW",
    ),
    /// The standard dash styles for an edge.
    ARROW_DASH_STYLE: new Enum(
        "ARROW_DASH_STYLE",
        // A solid line, with no breaks (—). This is the default.
        "SOLID",
        // A dashed line (⤏).
        "DASHED",
        // A dotted line (⤑).
        "DOTTED",
    ),
    /// The different kinds of (preset) arrow heads. Technically, we are able to draw more
    /// sophisticated combinations, but these are the ones that have been tested and will be
    /// used by quiver directly.
    ARROW_HEAD_STYLE: {
        /// No arrow head (-).
        NONE: [],
        /// The usual arrow head style (→).
        NORMAL: ["epi"],
        /// A double arrow head (↠).
        EPI: ["epi", "epi"],
        /// A reversed arrow head (⤚).
        MONO: ["mono"],
        /// A perpendicular line (↦).
        MAPS_TO: ["maps to"],
        /// A harpoon: just the upper part of the arrow head (⇀).
        HARPOON_TOP: ["harpoon-top"],
        /// A harpoon: just the lower part of the arrow head (⇁).
        HARPOON_BOTTOM: ["harpoon-bottom"],
        /// A hook (↪).
        HOOK_TOP: ["hook-top"],
        /// A hook (↩).
        HOOK_BOTTOM: ["hook-bottom"],
        /// The corner of a square, used for pullbacks and pushouts.
        CORNER: ["corner"],
        /// The corner of a square, used for an alternate style for pullbacks and pushouts.
        CORNER_INVERSE: ["corner-inverse"],
    },
    /// The various label alignment options.
    LABEL_ALIGNMENT: new Enum(
        "LABEL_ALIGNMENT",
        // In the centre of an edge, cutting out the edge underneath it.
        "CENTRE",
        // In the centre of an edge, overlapping the edge underneath it.
        "OVER",
        // To the left of the edge, viewed as if the arrow is facing up.
        "LEFT",
        // To the right of the edge, viewed as if the arrow is facing up.
        "RIGHT",
    ),
};

export class ArrowStyle {
    constructor() {
        // The "n" in "n-cell". Must be a positive integer.
        this.level = 1;
        // The position of the label (from 0 to 1) along the arrow.
        this.label_position = 0.5;
        // The height of the curve (in pixels). May be positive or negative. This is used for both
        // Bézier curves and arcs. However, `curve` is assumed to be nonzero for arcs.
        this.curve = 0;
        // The angle of the curve (relevant only for arcs).
        this.angle = 0;
        // The offset of the curve (in pixels). May be positive or negative.
        this.shift = 0;
        // How much to offset the head and tail of the edge from their endpoints.
        this.shorten = { tail: 0, head: 0 };
        // The shape of the arrow.
        this.shape = CONSTANTS.ARROW_SHAPE.BEZIER;
        // The various styles for the head, body, and tail.
        this.body_style = CONSTANTS.ARROW_BODY_STYLE.LINE;
        this.dash_style = CONSTANTS.ARROW_DASH_STYLE.SOLID;
        this.heads = CONSTANTS.ARROW_HEAD_STYLE.NORMAL;
        this.tails = CONSTANTS.ARROW_HEAD_STYLE.NONE;
        // The colour of the arrow.
        this.colour = "black";
    }
}

export class Label {
    constructor() {
        this.size = Dimensions.zero();
        this.alignment = CONSTANTS.LABEL_ALIGNMENT.CENTRE;
        this.element = null;
    }
}

export class Shape {
    /// Return a point representing the origin of the shape.
    point() {
        return new Shape.Endpoint(this.origin);
    }
}

Shape.RoundedRect = class extends Shape {
    constructor(origin, size, radius) {
        super();
        this.origin = origin;
        this.size = size;
        this.radius = radius;
    }
}

// The endpoint of a Bézier curve. This is used when we want to draw a Bézier curve in
// its entirety.
Shape.Endpoint = class extends Shape {
    constructor(origin) {
        super();
        this.origin = origin;
    }
}

export class Arrow {
    constructor(source, target, style = new ArrowStyle(), label = null) {
        this.source = source;
        this.target = target;
        this.style = style;
        this.label = label;
        this.kwiver_geometry_options = null;

        // We need to have unique `id`s for each arrow, to assign masks and clipping paths.
        this.id = Arrow.NEXT_ID++;
        this.element = new DOM.Div({ class: "arrow" });
        // The background to the edge, with which the user may interact.
        this.background = new DOM.SVGElement("svg").add_to(this.element);
        // The SVG containing the edge itself, including the arrow head and tail.
        this.svg = new DOM.SVGElement("svg").add_to(this.element);
        // The mask to be used for any edges having this edge as a source or target.
        this.mask = new DOM.SVGElement("svg");
    }

    /// Returns the source and target origins, adjusting for zero-length edges.
    origin() {
        const vector = this.target.origin.sub(this.source.origin);
        if (this.style.shape === CONSTANTS.ARROW_SHAPE.BEZIER || vector.length() > 0) {
            return { source: this.source.origin, target: this.target.origin };
        } else {
            // If the length of the chord is 0, we still want to draw the arc. However, since the
            // arc is no longer uniquely determined, we must decide upon the orientation of the arc.
            // Technically, since the source/target shapes depend on the source/target origins, this
            // will cause the location of the endpoints to be slightly incorrect. However, since we
            // only adjust by a very small amount (enough to ensure the SVG arc renders), this
            // should be essentially imperceptible.
            const min_chord = 0.01;
            const angle = vector.angle() + this.style.angle;
            const nudge = Point.lendir(min_chord / 2, angle);
            return { source: this.source.origin.sub(nudge), target: this.target.origin.add(nudge) };
        }
    }

    kwiver_geometry_options_or_throw() {
        if (this.kwiver_geometry_options === null) {
            throw new Error("Arrow geometry options are unavailable.");
        }
        return this.kwiver_geometry_options;
    }

    /// Returns the vector from source to target.
    vector() {
        const origin = this.origin();
        return origin.target.sub(origin.source);
    }

    /// Returns the angle of the vector from source to target.
    angle() {
        return this.vector().angle();
    }

    /// Returns the length of the vector from source to target.
    length() {
        return this.vector().length();
    }

    /// Returns the underlying curve associated to the arrow.
    curve(origin = this.origin().source, angle = this.angle()) {
        const length = this.length();
        switch (this.style.shape) {
            case CONSTANTS.ARROW_SHAPE.BEZIER:
                return new Bezier(origin, length, this.style.curve, angle);
            case CONSTANTS.ARROW_SHAPE.ARC:
                if (this.source === this.target) {
                    return new Arc(origin, length, true, this.style.curve, angle);
                }
                return this.arc_for_chord(origin, length, this.style.curve, angle);
        }
    }

    /// Returns the points along the Bézier curve associated to the arrow that intersect with the
    /// source and target.
    /// Returns either an array `[start, end]` or throws an error if the curve is invalid and has no
    /// nontrivial endpoints.
    find_endpoints() {
        const origin = this.origin();
        const geometry_options = this.kwiver_geometry_options_or_throw();
        const source_geometry = shape_geometry_args(this.source);
        const target_geometry = shape_geometry_args(this.target);
        const bridged = kwiver_bridge_arrow_find_endpoints_local(
            origin.source.x,
            origin.source.y,
            origin.target.x,
            origin.target.y,
            ...source_geometry,
            ...target_geometry,
            geometry_options.shape === "arc",
            geometry_options.curve,
            geometry_options.radius,
            geometry_options.angle,
            geometry_options.offset,
        );
        if (bridged?.ok !== true) {
            throw new Error("Arrow endpoints are unavailable.");
        }
        return [
            new CurvePoint(
                new Point(bridged.start.x, bridged.start.y),
                bridged.start.t,
                bridged.start.angle,
            ),
            new CurvePoint(
                new Point(bridged.end.x, bridged.end.y),
                bridged.end.t,
                bridged.end.angle,
            ),
        ];
    }

    /// Return an existing element, or create a new one if it does not exist.
    /// This is more efficient, and also preserves event listeners on the existing elements.
    /// The `selector` may be of the form `element#optional-id.class1.class2...`.
    requisition_element(
        parent,
        selector,
        attributes = {},
        style = {},
        namespace = DOM.SVGElement.NAMESPACE,
    ) {
        const elements = parent.query_selector_all(selector);
        switch (elements.length) {
            case 0:
                // Strip CSS selectors before parsing name, ID, and classes.
                const [prefix, ...classes] = selector.replace(/^.+>\s+/, "").split(".");
                const [name, id = null] = prefix.split("#");
                const extra_attrs = {};
                if (id !== null) {
                    extra_attrs.id = id;
                }
                if (classes.length > 0) {
                    extra_attrs.class = classes.join(" ");
                }
                return new DOM.Element(
                    name,
                    Object.assign(extra_attrs, attributes),
                    style,
                    namespace,
                ).add_to(parent);
            case 1:
                // Overwrite existing attributes and styling.
                elements[0].set_attributes(attributes);
                elements[0].set_style(style);
                return elements[0];
            default:
                console.error("Found multiple candidates for requisitioning.");
                break;
        }
    }

    /// Remove an existing element, or do nothing if it does not exist.
    release_element(parent, selector) {
        const elements = parent.query_selector_all(selector);
        switch (elements.length) {
            case 0:
                // It's already released, so we can ignore.
                break;
            case 1:
                elements[0].remove();
                break;
            default:
                console.error("Found multiple candidates for releasing.");
                break;
        }
    }

    /// Redraw the arrow, its mask, and its background. We should minimise calls to `redraw`: it
    /// should only be called if something has actually changed: for instance, its position or
    /// properties.
    redraw() {
        const stroke_width = this.style.level * CONSTANTS.STROKE_WIDTH
            + (this.style.level - 1) * CONSTANTS.LINE_SPACING;
        const edge_width = this.style.body_style === CONSTANTS.ARROW_BODY_STYLE.SQUIGGLY ?
            this.style.level * CONSTANTS.SQUIGGLY_TRIANGLE_HEIGHT * 2
                + CONSTANTS.STROKE_WIDTH
                + (this.style.level - 1) * CONSTANTS.LINE_SPACING
            : stroke_width;
        const head_width =
            (CONSTANTS.LINE_SPACING + CONSTANTS.STROKE_WIDTH) + (this.style.level - 1) * 2;
        const head_height = edge_width + (CONSTANTS.LINE_SPACING + CONSTANTS.STROKE_WIDTH) * 2;
        this.element.class_list.remove("invalid");
        this.svg.class_list.remove("invalid");

        const geometry_options = this.kwiver_geometry_options_or_throw();
        const origin = this.origin();
        const source_geometry = shape_geometry_args(this.source);
        const target_geometry = shape_geometry_args(this.target);
        const render_plan = kwiver_bridge_arrow_render_plan_local(
            origin.source.x,
            origin.source.y,
            origin.target.x,
            origin.target.y,
            ...source_geometry,
            ...target_geometry,
            geometry_options.shape === "arc",
            this.source === this.target,
            geometry_options.curve,
            geometry_options.radius,
            geometry_options.angle,
            geometry_options.offset,
            this.style.curve,
            this.style.angle,
            this.style.level,
            stroke_width,
            edge_width,
            head_width,
            head_height,
            this.style.shift,
            this.style.shorten.tail,
            this.style.shorten.head,
            arrow_body_style_token(this.style.body_style),
            arrow_dash_style_token(this.style.dash_style),
            heads_to_csv(this.style.tails),
            heads_to_csv(this.style.heads),
        );
        if (render_plan === null || !render_plan.ok) {
            this.element.class_list.add("invalid");
            return;
        }

        const angle = render_plan.angle;
        const shift = new Point(render_plan.shift.x, render_plan.shift.y);
        const offset = new Point(render_plan.offset.x, render_plan.offset.y);
        const start = new Point(render_plan.start.x, render_plan.start.y);
        const end = new Point(render_plan.end.x, render_plan.end.y);
        const apply_path_plan = (element, plan) => {
            element.set_attributes({ d: plan.d });
            if (plan.dash_array !== null) {
                element.set_attributes({ "stroke-dasharray": plan.dash_array });
            } else {
                element.remove_attributes("stroke-dasharray");
            }
        };

        for (const svg of [this.background, this.svg]) {
            svg.set_attributes({
                width: render_plan.svg_width,
                height: render_plan.svg_height,
            });
            svg.set_style({
                width: `${render_plan.svg_width}px`,
                height: `${render_plan.svg_height}px`,
                "transform-origin": offset.px(false),
                transform: `
                    translate(${shift.px()})
                    translate(${origin.source.sub(offset).px()})
                    rotate(${angle}rad)
                `,
            });
        }

        this.background.set_style({
            opacity: CONSTANTS.BACKGROUND_OPACITY,
        });

        const background_path = this.requisition_element(this.background, "path.arrow-background", {
            fill: "none",
            stroke: "black",
            "stroke-width": edge_width + CONSTANTS.BACKGROUND_PADDING * 2,
        });
        apply_path_plan(background_path, render_plan.background);

        const round_bg_end = (endpoint, is_start) => {
            if (endpoint !== null) {
                const point = offset.add(endpoint);
                const name = is_start ? "source" : "target";
                this.requisition_element(this.background, `circle.${name}.arrow-background`, {
                    cx: point.x,
                    cy: point.y,
                    r: edge_width / 2 + CONSTANTS.BACKGROUND_PADDING,
                    fill: "black",
                });
                const handle_origin = Point.diag(CONSTANTS.HANDLE_RADIUS).sub(endpoint);
                this.requisition_element(this.element, `div.arrow-endpoint.${name}`, {}, {
                    width: `${CONSTANTS.HANDLE_RADIUS * 2}px`,
                    height: `${CONSTANTS.HANDLE_RADIUS * 2}px`,
                    left: `${endpoint.x}px`,
                    top: `${endpoint.y}px`,
                    "border-radius": `${CONSTANTS.HANDLE_RADIUS}px`,
                    "transform-origin": `${handle_origin.x}px ${handle_origin.y}px`,
                    transform: `
                        translate(${shift.x}px, ${shift.y}px)
                        translate(calc(${origin.source.x}px - 50%),
                            calc(${origin.source.y}px - 50%))
                        rotate(${angle}rad)
                    `,
                }, null);
            }
        }
        round_bg_end(start, true);
        round_bg_end(end, false);

        const defs
            = this.requisition_element(this.svg, "svg:not(.typst-doc) > defs.clipping-masks");
        const clipping_mask = this.requisition_element(
            defs,
            `mask#arrow${this.id}-clipping-mask`,
            { maskUnits: "userSpaceOnUse" },
        );
        // We use a separate clipping mask for the label. This is because we want
        // to clip the head, tail and proarrow bar by the label mask, but *not* by
        // the endpoint masks, which otherwise cut into the head and tail. Thus, the
        // mask for the label is duplicated: once in `clipping_mask` and once in
        // `label_clipping_mask`.
        const label_clipping_mask = this.requisition_element(
            defs,
            `mask#arrow${this.id}-label-clipping-mask`,
            { maskUnits: "userSpaceOnUse" },
        );
        for (const mask of [clipping_mask, label_clipping_mask]) {
            mask.clear();
            this.requisition_element(mask, "rect.base", {
                width: render_plan.svg_width,
                height: render_plan.svg_height,
                fill: "white",
            });
        }

        const edge = this.requisition_element(this.svg, "path.arrow-edge", {
            mask: `url(#arrow${this.id}-clipping-mask)`,
            fill: "none",
            stroke: this.style.colour,
            "stroke-width": stroke_width,
        });
        apply_path_plan(edge, render_plan.edge);

        const draw_heads = (is_start, is_mask) => {
            const render_plan_part = is_start
                ? (is_mask ? render_plan.tail_mask : render_plan.tail)
                : (is_mask ? render_plan.head_mask : render_plan.head);
            if (render_plan_part.has_path) {
                const element = !is_mask ? this.svg : clipping_mask;
                new DOM.SVGElement("path", {
                    class: "arrow-head",
                    d: render_plan_part.d,
                    mask: !is_mask ? `url(#arrow${this.id}-label-clipping-mask)` : null,
                    fill: is_mask ? "black" : "none",
                    stroke: !is_mask ? this.style.colour : "none",
                    "stroke-width": CONSTANTS.STROKE_WIDTH,
                    "stroke-linecap": "round",
                }).add_to(element);
            }
            return render_plan_part.total_width;
        };

        this.svg.query_selector_all(".arrow-head").forEach((element) => element.remove());
        draw_heads(true, false);
        draw_heads(false, false);

        this.release_element(this.svg, "path.arrow-decoration");
        this.release_element(this.svg, "circle.arrow-decoration");
        this.release_element(clipping_mask, "circle.arrow-decoration");
        switch (render_plan.decoration.kind) {
            case "path":
                this.requisition_element(this.svg, "path.arrow-decoration", {
                    d: render_plan.decoration.path_d,
                    mask: `url(#arrow${this.id}-label-clipping-mask)`,
                    fill: "none",
                    stroke: this.style.colour,
                    "stroke-width": CONSTANTS.STROKE_WIDTH,
                    "stroke-linecap": "round",
                });
                break;
            case "solid-circle":
                if (render_plan.decoration.circle !== null) {
                    this.requisition_element(this.svg, "circle.arrow-decoration", {
                        cx: render_plan.decoration.circle.cx,
                        cy: render_plan.decoration.circle.cy,
                        r: render_plan.decoration.circle.r,
                        mask: `url(#arrow${this.id}-label-clipping-mask)`,
                        fill: this.style.colour,
                        stroke: "none",
                    });
                }
                break;
            case "hollow-circle":
                if (render_plan.decoration.circle !== null) {
                    this.requisition_element(this.svg, "circle.arrow-decoration", {
                        cx: render_plan.decoration.circle.cx,
                        cy: render_plan.decoration.circle.cy,
                        r: render_plan.decoration.circle.r,
                        mask: `url(#arrow${this.id}-label-clipping-mask)`,
                        fill: "none",
                        stroke: this.style.colour,
                        "stroke-width": CONSTANTS.STROKE_WIDTH,
                    });
                }
                break;
        }

        if (!render_plan.edge_valid) {
            this.svg.class_list.add("invalid");
            return;
        }

        for (let i = this.style.level - 1, cut = true; i > 0; --i, cut = !cut) {
            new DOM.SVGElement("path", {
                d: render_plan.edge.d,
                fill: "none",
                stroke: cut ? "black" : "white",
                "stroke-width": `${
                    (i - (cut ? 1 : 0)) * CONSTANTS.STROKE_WIDTH
                        + (i - (cut ? 0 : 1)) * CONSTANTS.LINE_SPACING
                }`,
            }).add_to(clipping_mask);
        }

        const clipping_path = new DOM.SVGElement("path", {
            d: render_plan.clipping_path.d,
            fill: "none",
            stroke: "black",
            "stroke-width": edge_width + CONSTANTS.BACKGROUND_PADDING * 2,
        });
        if (render_plan.clipping_path.dash_array !== null) {
            clipping_path.set_attributes({ "stroke-dasharray": render_plan.clipping_path.dash_array });
        }
        clipping_path.add_to(clipping_mask);
        draw_heads(true, true);
        draw_heads(false, true);

        if (render_plan.decoration.mask_circle !== null) {
            this.requisition_element(clipping_mask, "circle.arrow-decoration", {
                cx: render_plan.decoration.mask_circle.cx,
                cy: render_plan.decoration.mask_circle.cy,
                r: render_plan.decoration.mask_circle.r,
                fill: "black",
            });
        }

        const constants = { offset, edge_width, angle };
        if (this.label !== null) {
            if (this.label.alignment === CONSTANTS.LABEL_ALIGNMENT.CENTRE) {
                this.redraw_label(constants, "rect").add_to(clipping_mask);
                this.redraw_label(constants, "rect").add_to(label_clipping_mask);
            }
            const label_content = this.svg.query_selector(".arrow-label div");
            this.release_element(this.svg, "foreignObject.arrow-label");
            const label = this.redraw_label(constants, "foreignObject");
            label.set_attributes({ class: "arrow-label" });
            this.label.element = (label_content || new DOM.Div({
                xmlns: "http://www.w3.org/1999/xhtml",
                class: "label",
            })).add_to(label);
            this.svg.add(label);
        }
    }

    /// Returns the arc associated to a chord length.
    arc_for_chord(origin, chord, loop_radius, angle) {
        // If `outer_dis` <= `chord`, then the path will be a straight line.
        const outer_dis = CONSTANTS.ARC.OUTER_DIS;
        // If `inner_dis` <= `chord` <= `outer_dis`, then the path will be an inner arc, with
        // diameter `inner_dis`.
        const inner_dis = CONSTANTS.ARC.INNER_DIS;
        // If 0 <= `chord` <= `inner_dis`, then the path will be an outer arc, with radius
        // interpolating from `semicircle_radius` to `loop_radius` (when `chord` is 0).

        // Derived constants.
        const semicircle_radius = inner_dis / 2;
        const boundary_dis = outer_dis - inner_dis;
        // The height of the inner arc.
        const sagitta = chord >= outer_dis ? EPSILON
            : (semicircle_radius * ((outer_dis - chord) / boundary_dis));
        // The radius needed for the arc to have height `sagitta`.
        const r_for_sagitta = sagitta / 2 + (chord ** 2) / (8 * sagitta);
        // The radius of the arc.
        const r = chord <= inner_dis ? (semicircle_radius +
                (inner_dis - chord) / inner_dis * (loop_radius - semicircle_radius))
                : r_for_sagitta;
        return new Arc(origin, chord, chord <= inner_dis, r, angle);
    }

    /// Redraw the label attached to the edge. Returns the mask associated to the label.
    redraw_label(constants, tag_name) {
        const { offset, angle } = constants;

        const origin = this.determine_label_position(constants).add(offset).sub(new Point(
            this.label.size.width / 2,
            this.label.size.height / 2,
        ));

        // Draw the mask.
        return new DOM.SVGElement(tag_name, {
            width: this.label.size.width,
            height: this.label.size.height,
            fill: "black",
            x: 0,
            y: 0,
            transform: `translate(${origin.x} ${origin.y}) ${
                // The label should be horizontal for most alignments, but in the direction of the
                // arrow for `OVER`.
                this.label.alignment === CONSTANTS.LABEL_ALIGNMENT.OVER ? "" :
                    `rotate(${-rad_to_deg(angle)} ${
                        this.label.size.width / 2} ${this.label.size.height / 2})`
            }`,
        });
    }

    /// Find the correct position of the label. If the label is centred, this is easy. However, if
    /// it is offset to either side, we want to find the minimum offset from the centre of the edge
    /// such that the label no longer overlaps the edge.
    determine_label_position(constants) {
        const { edge_width } = constants;
        const geometry_options = this.kwiver_geometry_options_or_throw();
        const origin = this.origin();
        const source_geometry = shape_geometry_args(this.source);
        const target_geometry = shape_geometry_args(this.target);
        const bridged = kwiver_bridge_arrow_label_position_local(
            origin.source.x,
            origin.source.y,
            origin.target.x,
            origin.target.y,
            ...source_geometry,
            ...target_geometry,
            geometry_options.shape === "arc",
            geometry_options.curve,
            geometry_options.radius,
            geometry_options.angle,
            geometry_options.offset,
            geometry_options.label_alignment,
            geometry_options.label_position,
            this.label.size.width,
            this.label.size.height,
            edge_width,
        );
        if (bridged === null) {
            throw new Error("Arrow label position is unavailable.");
        }
        return new Point(bridged.x, bridged.y);
    }
}

Arrow.NEXT_ID = 0;
