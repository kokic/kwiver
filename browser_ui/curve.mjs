import { Point } from "./ds.mjs";
import {
    kwiver_bridge_arc_intersections_with_rounded_rectangle,
    kwiver_bridge_arc_angle_in_arc,
    kwiver_bridge_arc_arc_length,
    kwiver_bridge_arc_height,
    kwiver_bridge_arc_point,
    kwiver_bridge_arc_t_after_length,
    kwiver_bridge_arc_tangent,
    kwiver_bridge_arc_width,
    kwiver_bridge_bezier_arc_length,
    kwiver_bridge_bezier_height,
    kwiver_bridge_bezier_intersections_with_rounded_rectangle,
    kwiver_bridge_bezier_point,
    kwiver_bridge_bezier_t_after_length,
    kwiver_bridge_bezier_tangent,
    kwiver_bridge_bezier_width,
} from "./kwiver_bridge.mjs";

/// A very small value we use to determine fuzzy equality of points.
export const EPSILON = 10 ** -6;

function bridge_error(name) {
    return new Error(`${name} requires the MoonBit geometry bridge.`);
}

function bridge_point(name, raw) {
    if (!raw || typeof raw !== "object") {
        throw bridge_error(name);
    }
    const x = Number(raw.x);
    const y = Number(raw.y);
    if (!Number.isFinite(x) || !Number.isFinite(y)) {
        throw bridge_error(name);
    }
    return new Point(x, y);
}

function bridge_number(name, raw) {
    if (typeof raw !== "number" || !Number.isFinite(raw)) {
        throw bridge_error(name);
    }
    return raw;
}

function bridge_boolean(name, raw) {
    if (typeof raw !== "boolean") {
        throw bridge_error(name);
    }
    return raw;
}

function bridge_curve_points(name, raw) {
    if (!Array.isArray(raw)) {
        throw bridge_error(name);
    }
    const points = [];
    for (const item of raw) {
        if (!item || typeof item !== "object") {
            throw bridge_error(name);
        }
        const x = Number(item.x);
        const y = Number(item.y);
        const t = Number(item.t);
        const angle = Number(item.angle);
        if (
            !Number.isFinite(x)
            || !Number.isFinite(y)
            || !Number.isFinite(t)
            || !Number.isFinite(angle)
        ) {
            throw bridge_error(name);
        }
        points.push(new CurvePoint(new Point(x, y), t, angle));
    }
    return points;
}

export class Curve {}

/// A flat symmetric quadratic Bezier curve.
export class Bezier extends Curve {
    constructor(origin, w, h, angle) {
        super();
        this.origin = origin;
        this.w = w;
        this.h = h;
        this.angle = angle;
    }

    /// Returns the (x, y)-point at t = `t`.
    point(t) {
        return bridge_point(
            "Bezier.point",
            kwiver_bridge_bezier_point(
                this.origin.x,
                this.origin.y,
                this.w,
                this.h,
                this.angle,
                t,
            ),
        );
    }

    /// Returns the angle of the tangent to the curve at t = `t`.
    tangent(t) {
        return bridge_number(
            "Bezier.tangent",
            kwiver_bridge_bezier_tangent(
                this.origin.x,
                this.origin.y,
                this.w,
                this.h,
                this.angle,
                t,
            ),
        );
    }

    /// Returns the arc length of the Bezier curve from t = 0 to t = `t`.
    arc_length(t) {
        return bridge_number(
            "Bezier.arc_length",
            kwiver_bridge_bezier_arc_length(
                this.origin.x,
                this.origin.y,
                this.w,
                this.h,
                this.angle,
                t,
            ),
        );
    }

    /// Returns a function giving the parameter t of the point a given length along the arc of the
    /// Bezier curve.
    t_after_length(clamp = false) {
        return (length) => {
            if (length === 0) {
                return 0;
            }
            if (length < 0) {
                if (clamp) {
                    return 0;
                }
                throw new Error("Length was less than 0.");
            }
            const total = this.arc_length(1);
            if (length > total) {
                if (clamp) {
                    return 1;
                }
                throw new Error("Length was greater than the arc length.");
            }
            return bridge_number(
                "Bezier.t_after_length",
                kwiver_bridge_bezier_t_after_length(
                    this.origin.x,
                    this.origin.y,
                    this.w,
                    this.h,
                    this.angle,
                    length,
                ),
            );
        };
    }

    get height() {
        return bridge_number(
            "Bezier.height",
            kwiver_bridge_bezier_height(
                this.origin.x,
                this.origin.y,
                this.w,
                this.h,
                this.angle,
            ),
        );
    }

    get width() {
        return bridge_number(
            "Bezier.width",
            kwiver_bridge_bezier_width(
                this.origin.x,
                this.origin.y,
                this.w,
                this.h,
                this.angle,
            ),
        );
    }

    intersections_with_rounded_rectangle(rect, permit_containment) {
        return bridge_curve_points(
            "Bezier.intersections_with_rounded_rectangle",
            kwiver_bridge_bezier_intersections_with_rounded_rectangle(
                this.origin.x,
                this.origin.y,
                this.w,
                this.h,
                this.angle,
                rect.centre.x,
                rect.centre.y,
                rect.size.width,
                rect.size.height,
                rect.r,
                permit_containment,
            ),
        );
    }

    /// Render the Bezier curve to an SVG path.
    render(path) {
        return path.curve_by(new Point(this.w / 2, this.h), new Point(this.w, 0));
    }
}

/// A point on a quadratic Bezier curve or arc, which also records the parameter `t` and the tangent
/// `angle` of the curve at the point.
export class CurvePoint extends Point {
    constructor(point, t, angle) {
        super(point.x, point.y);
        this.t = t;
        this.angle = angle;
    }
}

/// A very simple class for computing the value of a cubic Bezier at a point, used for replicating
/// CSS transition timing functions in JavaScript.
export class CubicBezier {
    constructor(p0, p1, p2, p3) {
        this.p0 = p0;
        this.p1 = p1;
        this.p2 = p2;
        this.p3 = p3;
    }

    point(t) {
        const p = this.p0.mul((1 - t) ** 3)
            .add(this.p1.mul(3 * (1 - t) ** 2 * t))
            .add(this.p2.mul(3 * (1 - t) * t ** 2))
            .add(this.p3.mul(t ** 3));
        return new CurvePoint(p, t, null);
    }
}

/// A circular arc.
export class Arc extends Curve {
    constructor(origin, chord, major, radius, angle) {
        super();
        this.origin = origin;
        this.chord = chord;
        this.major = major;
        this.radius = radius;
        this.angle = angle;
        this.sagitta = this.radius
            - Math.sign(this.radius) * (this.radius ** 2 - this.chord ** 2 / 4) ** 0.5;
    }

    /// Returns the (x, y)-point at t = `t`.
    point(t) {
        return bridge_point(
            "Arc.point",
            kwiver_bridge_arc_point(
                this.origin.x,
                this.origin.y,
                this.chord,
                this.major,
                this.radius,
                this.angle,
                t,
            ),
        );
    }

    /// Returns the angle of the tangent to the curve at t = `t`.
    tangent(t) {
        return bridge_number(
            "Arc.tangent",
            kwiver_bridge_arc_tangent(
                this.origin.x,
                this.origin.y,
                this.chord,
                this.major,
                this.radius,
                this.angle,
                t,
            ),
        );
    }

    /// Returns the arc length of the arc from t = 0 to t = `t`.
    arc_length(t) {
        return bridge_number(
            "Arc.arc_length",
            kwiver_bridge_arc_arc_length(
                this.origin.x,
                this.origin.y,
                this.chord,
                this.major,
                this.radius,
                this.angle,
                t,
            ),
        );
    }

    /// Returns a function giving the parameter t of the point a given length along the arc.
    t_after_length(clamp = false) {
        return (length) => {
            if (length < 0) {
                if (clamp) {
                    return 0;
                }
                throw new Error("Length was less than 0.");
            }
            const total = this.arc_length(1);
            if (length > total) {
                if (clamp) {
                    return 1;
                }
                throw new Error("Length was greater than the arc length.");
            }
            return bridge_number(
                "Arc.t_after_length",
                kwiver_bridge_arc_t_after_length(
                    this.origin.x,
                    this.origin.y,
                    this.chord,
                    this.major,
                    this.radius,
                    this.angle,
                    length,
                ),
            );
        };
    }

    /// Returns the height of the curve.
    get height() {
        return bridge_number(
            "Arc.height",
            kwiver_bridge_arc_height(
                this.origin.x,
                this.origin.y,
                this.chord,
                this.major,
                this.radius,
                this.angle,
            ),
        );
    }

    /// Returns the width of the curve.
    get width() {
        return bridge_number(
            "Arc.width",
            kwiver_bridge_arc_width(
                this.origin.x,
                this.origin.y,
                this.chord,
                this.major,
                this.radius,
                this.angle,
            ),
        );
    }

    /// Returns whether or not the given angle is contained within the arc.
    angle_in_arc(angle) {
        return bridge_boolean(
            "Arc.angle_in_arc",
            kwiver_bridge_arc_angle_in_arc(
                this.origin.x,
                this.origin.y,
                this.chord,
                this.major,
                this.radius,
                this.angle,
                angle,
            ),
        );
    }

    intersections_with_rounded_rectangle(rect, permit_containment) {
        return bridge_curve_points(
            "Arc.intersections_with_rounded_rectangle",
            kwiver_bridge_arc_intersections_with_rounded_rectangle(
                this.origin.x,
                this.origin.y,
                this.chord,
                this.major,
                this.radius,
                this.angle,
                rect.centre.x,
                rect.centre.y,
                rect.size.width,
                rect.size.height,
                rect.r,
                permit_containment,
            ),
        );
    }

    /// Render the arc to an SVG path.
    render(path) {
        if (!this.major && Math.abs(this.sagitta) <= 1.0) {
            return path.line_by(new Point(this.chord, 0));
        }
        return path.arc_by(
            Point.diag(Math.abs(this.radius)),
            0,
            this.major,
            this.radius >= 0,
            new Point(this.chord, 0),
        );
    }
}
