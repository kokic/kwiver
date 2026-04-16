import { delay } from "./dom.mjs";
import { Colour, Encodable, Point, Position, mod } from "./ds.mjs";
import { CONSTANTS } from "./arrow.mjs";
import { Parser } from "./parser.mjs";
import { Edge, Vertex } from "./ui.mjs";
import { kwiver_bridge_all_cells, kwiver_bridge_export, kwiver_bridge_import_tikz_result } from "./kwiver_bridge.mjs";

function tikzImportKindTitle(kind) {
    switch (kind) {
        case "syntax":
            return "tikz-cd syntax error";
        case "option":
            return "unsupported tikz-cd option";
        case "reference":
            return "invalid tikz-cd reference";
        case "base64":
            return "invalid share/base64 input";
        case "tikz":
            return "tikz-cd import error";
        default:
            return "tikz-cd import error";
    }
}

function tikzImportRangeFromLineColumn(text, line, column) {
    if (!Number.isInteger(line) || !Number.isInteger(column) || line < 1 || column < 1) {
        return null;
    }
    if (typeof text !== "string") {
        return null;
    }

    let currentLine = 1;
    let index = 0;
    while (index < text.length && currentLine < line) {
        if (text[index] === "\n") {
            currentLine += 1;
        }
        index += 1;
    }
    if (currentLine !== line) {
        return null;
    }

    const lineStart = index;
    while (index < text.length && text[index] !== "\n") {
        index += 1;
    }
    const lineEnd = index;
    const zeroBasedColumn = column - 1;
    const caret = Math.max(lineStart, Math.min(lineStart + zeroBasedColumn, lineEnd));
    return new Parser.Range(caret, 0);
}

function graphAllCells(graph) {
    if (!graph || typeof graph.all_cells !== "function") {
        throw new Error("graph provider missing all_cells()");
    }
    return graph.all_cells();
}

function graphIsEmpty(graph) {
    return graphAllCells(graph).length === 0;
}

function graphVertices(graph) {
    return graphAllCells(graph).filter((cell) => cell.is_vertex());
}

function graphEdgesByLevel(graph) {
    const levels = [];
    for (const cell of graphAllCells(graph)) {
        if (!cell.is_edge()) {
            continue;
        }
        while (levels.length <= cell.level) {
            levels.push([]);
        }
        levels[cell.level].push(cell);
    }
    return levels;
}

function graphDependenciesOf(graph, cell) {
    if (graph && typeof graph.dependencies_of === "function") {
        return graph.dependencies_of(cell);
    }

    const dependencies = new Map();
    for (const candidate of graphAllCells(graph)) {
        if (!candidate.is_edge()) {
            continue;
        }
        if (candidate.source === cell) {
            dependencies.set(candidate, "source");
        }
        if (candidate.target === cell) {
            dependencies.set(candidate, "target");
        }
    }
    return dependencies;
}

/// Bridge-facing import/export shell.
export class Quiver {
    constructor() {}

    /// Return a `{ data, metadata }` object containing the graph in a specific format.
    /// Currently, the supported formats are:
    /// - "tikz-cd"
    /// - "fletcher"
    /// - "base64"
    /// - "html"
    /// `settings` describes persistent user settings (like whether to centre the diagram);
    /// `options` describes non-persistent user settings and diagram attributes (like the macro
    /// URL, and the dimensions of the diagram);
    /// `definitions` contains key-value pairs for macros and colours.
    export(format, settings, options, definitions) {
        switch (format) {
            case "tikz-cd":
            case "fletcher":
            case "base64":
            case "html":
                const bridged = kwiver_bridge_export(
                    format,
                    settings,
                    options,
                    definitions,
                );
                if (bridged !== null) {
                    return bridged;
                }

                throw new Error(`kwiver MoonBit bridge unavailable for export format \`${format}\``);
            default:
                throw new Error(`unknown export format \`${format}\``);
        }
    }
    /// Return a `{ data, metadata }` object.
    /// Currently, the supported formats are:
    /// - "tikz-cd"
    /// `settings` describes persistent user settings (like whether to centre the diagram);
    import(ui, format, data, settings) {
        switch (format) {
            case "tikz-cd": {
                const bridged = kwiver_bridge_import_tikz_result(data, settings);
                if (bridged === null) {
                    throw new Error("kwiver MoonBit bridge unavailable for tikz-cd import");
                }

                if (bridged.ok === true) {
                    const runtime_cells = kwiver_bridge_all_cells();
                    ui.kwiver_import_runtime_cells(
                        runtime_cells,
                        "quiver.import.tikz-cd",
                    );
                    return { diagnostics: [] };
                }

                const errorKind = bridged.error && typeof bridged.error.kind === "string"
                    ? bridged.error.kind
                    : "";
                const line = bridged.error ? Number(bridged.error.line) : 0;
                const column = bridged.error ? Number(bridged.error.column) : 0;
                const hasLine = Number.isInteger(line) && line > 0;
                const hasColumn = Number.isInteger(column) && column > 0;
                const range = tikzImportRangeFromLineColumn(data, line, column);

                const detail = bridged.error && typeof bridged.error.message === "string"
                    ? bridged.error.message
                    : "tikz-cd import failed";
                let message = `${tikzImportKindTitle(errorKind)}: ${detail}`;
                if (hasLine || hasColumn) {
                    message += ` (line ${hasLine ? line : 0}, column ${hasColumn ? column : 0})`;
                }

                const diagnostic = new Parser.Error(message, range);
                diagnostic.kwiver_kind = errorKind !== "" ? errorKind : "tikz";
                diagnostic.kwiver_source = "bridge_import";
                diagnostic.kwiver_line = hasLine ? line : null;
                diagnostic.kwiver_column = hasColumn ? column : null;
                return { diagnostics: [diagnostic] };
            }
            default:
                throw new Error(`unknown export format \`${format}\``);
        }
    }
}

/// Various methods of exporting a quiver.
export class QuiverExport {
    /// A method to export a quiver as a string.
    export() {}
}

/// Various methods of exporting and importing a quiver.
export class QuiverImportExport extends QuiverExport {
    /// A method to import a quiver as a string. `import(export(quiver))` should be the
    /// identity function. Currently `import` takes a `UI` into which to import directly.
    import() {}

    begin_import(ui) {
        // We don't want to relayout every time we add a new cell: instead, we should perform
        // layout once, once all of the cells have been created.
        ui.buffer_updates = true;
    }

    end_import(ui, imported_cells, centre_view = true) {
        if (centre_view) {
            // Centre the view on the quiver.
            ui.centre_view();
            // Also centre the focus point, so that it's centre of screen.
            // We subtract 0.5 from the position so that when the view is centred perfectly between
            // two cells, we prefer the top/leftmost cell.
            ui.focus_point.class_list.remove("smooth");
            ui.reposition_focus_point(ui.position_from_offset(ui.view.sub(Point.diag(0.5))));
            ui.focus_point.class_list.add("focused");
            delay(() => ui.focus_point.class_list.add("smooth"));
        }

        // When cells are created, they are usually queued. We don't want any cells that have been
        // imported to be queued.
        for (const cell of imported_cells) {
            cell.element.query_selector("kbd.queue").class_list.remove("queue");
        }

        // Update all the affected columns and rows.
        delay(() => ui.update_col_row_size(
            ...ui.view_all_cells()
                .filter((cell) => cell.is_vertex()).map((vertex) => vertex.position)
        ));

        // Stop buffering updates, so that individual changes to cells will resize the grid.
        ui.buffer_updates = false;

        // If the quiver is now nonempty, some toolbar actions will be available.
        ui.toolbar.update(ui);
        ui.update_focus_tooltip();
    }
}

QuiverExport.CONSTANTS = {
    // For curves and shortening, we need to try to convert proportional measurements
    // into absolute distances (in `pt`) for TikZ. There are several subtleties, one of
    // which is that the grid cell size in tikz-cd has a greater width than height, so
    // when we scale things, we need to scale differently in the horizontal and vertical
    // directions. For now, we simply multiply by constants that, heuristically, give
    // reasonable results for various diagrams I tested. It would be nice to eventually
    // correct this by using proportional lengths, but that requires a custom TikZ style
    // I do not currently possess the skills to create.
    TIKZ_HORIZONTAL_MULTIPLIER: 1/4,
    TIKZ_VERTICAL_MULTIPLIER: 1/6,
};

QuiverExport.fletcher = new class extends QuiverExport {
    export(quiver, settings, options, definitions) {
        let output = "";

        const wrap_boilerplate = (output) => {
            const center = settings.get("export.centre_diagram");
            return `// ${
                QuiverImportExport.base64.export(quiver, settings, options, definitions).data
            }\n#${center ? "align(center, " : ""}diagram({\n${output}})${center ? ")" : ""}`;
        };

        // Early exit for empty quivers.
        if (graphIsEmpty(quiver)) {
            return {
                data: wrap_boilerplate(output),
                metadata: { fletcher_incompatibilities: new Set() },
            };
        }

        const fletcher_incompatibilities = new Set();

        // Returns the coördinates of a cell, in the form `(x, y)`.
        const cell_coords = (cell) => `(${cell.position.x}, ${cell.position.y})`;
        // Wrap a label in a content block. If the label text is empty, return an empty string.
        const format_label = (label) => label === "" ? "" : `[$${label}$]`;
        // Concatenate the arguments into a string that can directly be appended to a function call,
        // ignoring empty strings. If there is no effective argument, returns the empty string.
        const arg_list_to_string = (list) => {
            const result = list.filter((arg) => arg !== "").join(", ");
            return result.length > 0 ? `, ${result}` : "";
        };

        // Get a Typst description of the colour from a colour object.
        // Uses Typst's `color.hsl()` function.
        const colour_to_typst_hsl = (colour) => {
            let [h, s, l, _] = colour.hsla();
            return `color.hsl(${h}deg, ${Math.round(s * 2.55)}, ${Math.round(l * 2.55)})`;
        };

        // Output the vertices.
        const vertices_in_order = graphVertices(quiver);
        const edges_by_level = graphEdgesByLevel(quiver);

        for (const vertex of vertices_in_order) {
            let label_colour = "";
            if (vertex.label !== "" && vertex.label_colour.is_not_black()) {
                label_colour = `text(${colour_to_typst_hsl(vertex.label_colour)})`;
            }
            output += `\tnode(${cell_coords(vertex)}${
                arg_list_to_string([label_colour + format_label(vertex.label)])
            })\n`;
        }

        // Output the edges, i.e. 1-cells and above.
        for (let level = 1; level < edges_by_level.length; ++level) {
            // Double arrows and higher are not yet supported in fletcher.
            if (level > 1) {
                fletcher_incompatibilities.add("arrows between arrows");
                break;
            }

            for (const edge of edges_by_level[level] || []) {
                // This will be the list of arguments passed to the `edge()` function after the
                // source and target coördinates.
                const args = [format_label(edge.label)];

                if (edge.label !== "") {
                    // We must explicitly declare that labels are on the left by default because the
                    // default behavior for fletcher (auto) is inconsistent with quiver's rendering
                    // otherwise.
                    let side;
                    switch (edge.options.label_alignment) {
                        case "left":
                            side = "left";
                            break;
                        case "centre":
                            side = "center";
                            break;
                        case "over":
                            side = "center";
                            args.push("label-fill: false");
                            args.push("label-angle: right");
                            break;
                        case "right":
                            side = "right";
                            break;
                    }
                    args.push(`label-side: ${side}`);

                    if (edge.options.label_position !== 50) {
                        args.push(`label-pos: ${edge.options.label_position / 100}`);
                    }
                }

                // Shortened edges are not yet supported in fletcher.
                if (edge.options.shorten.source !== 0 || edge.options.shorten.target !== 0) {
                    fletcher_incompatibilities.add("shortened arrows");
                }

                // Apply the edge offset.
                if (edge.options.offset !== 0) {
                    if (edge.source !== edge.target && edge.options.curve === 0) {
                        args.push(`shift: ${-edge.options.offset / 20}`);
                    } else {
                        fletcher_incompatibilities.add("offset curves and loops");
                    }
                }

                // We will build the description of the arrow style, which will determine the tail,
                // body, and head style of the arrow.
                let arrow_marks = "";
                // Additional arguments to the `edge()` function when the style isn't implemented as
                // an arrow mark. We store this list separately because these styles must appear
                // after the arrow marks.
                const arrow_args = [];
                switch (edge.options.style.name){
                    case "arrow":
                        // Fletcher specifies arrow styles in the form tail-body-head.

                        // Arrow tail
                        switch(edge.options.style.tail.name){
                            case "maps to":
                                arrow_marks += "|";
                                break;
                            case "mono":
                                arrow_marks += ">";
                                break;
                            case "hook":
                                arrow_marks += "hook";
                                arrow_marks += edge.options.style.tail.side === "top" ? "" : "'";
                                break;
                            case "arrowhead":
                                arrow_marks += "<";
                                break;
                        }
                        // Arrow body
                        switch (edge.options.style.body.name){
                            case "cell":
                                let level = edge.options.level;
                                // Level 4 arrows have no shorthand, so we use the
                                // level 1 arrow that we manually extrude.
                                if (level > 3) {
                                    level = 1;
                                    arrow_args.push(`extrude: (-6,-2,2,6)`);
                                    // Scale the arrowhead accordingly.
                                    arrow_args.push(`mark-scale: 2`);
                                }
                                arrow_marks
                                    += level === 1 ? "-" : "=".repeat(edge.options.level - 1);
                                break;
                            case "dashed":
                                arrow_marks += "--";
                                break;
                            case "dotted":
                                arrow_marks += "..";
                                break;
                            case "squiggly":
                                arrow_marks += "~";
                                break;
                            case "barred":
                                arrow_marks += "-|-";
                                break;
                            case "double barred":
                                arrow_marks += "-||-";
                                break;
                            case "bullet solid":
                                arrow_marks += "-@-";
                                break;
                            case "bullet hollow":
                                arrow_marks += "-O-";
                                break;
                            case "none":
                                arrow_marks += " ";
                                break;
                            default:
                                arrow_marks += "-";
                        }
                        // Arrow head
                        switch(edge.options.style.head.name) {
                            case "none":
                                break;
                            case "arrowhead":
                                arrow_marks += ">";
                                break;
                            case "epi":
                                arrow_marks += ">>";
                                break;
                            case "harpoon":
                                arrow_marks += "harpoon";
                                arrow_marks += edge.options.style.head.side === "top" ? "" : "'";
                                break;
                        }
                        break;

                    case "adjunction":
                        fletcher_incompatibilities.add("adjunctions");
                        break;

                    default:
                        // In the future, adjunctions and corners can probably be implemented with
                        // custom marks along with "none" body type.
                        fletcher_incompatibilities.add("pullbacks and pushouts");
                        break;
                }

                // We only explicitly specify the arrow style when it's not the default.
                if (arrow_marks !== "-") {
                    args.push(`"${arrow_marks}"`);
                    arrow_args.forEach((style) => args.push(style));
                }

                // Colour the label if it is not black.
                if (edge.label !== "" && edge.label_colour.is_not_black()) {
                    args[0] = `text(${colour_to_typst_hsl(edge.label_colour)})${args[0]}`;
                }
                // Colour the arrow if is not black.
                if (edge.options.colour.is_not_black()) {
                    args.push(`stroke: ${colour_to_typst_hsl(edge.options.colour)}`);
                }

                // Handle loops. We translate the radius setting into a bend angle, mapping radii
                // 1 – 5 to the range 130deg – 150deg.
                if (edge.source === edge.target) {
                    args.push(`bend: ${Math.sign(edge.options.radius) *
                            ((Math.abs(edge.options.radius) - 1) * (150 - 130) / 4 + 130)}deg`);
                    args.push(`loop-angle: ${90 - edge.options.angle}deg`);
                }
                // If the edge is curved (but not a loop), add a bend.
                else if (edge.options.curve !== 0) {
                    args.push(`bend: ${-edge.options.curve * 90 / 5}deg`);
                }

                output += `\tedge(${cell_coords(edge.source)}, ${cell_coords(edge.target)}${
                    arg_list_to_string(args)
                })\n`;
            }
        }

        return {
            data: wrap_boilerplate(output),
            metadata: { fletcher_incompatibilities },
        };
    }
}

QuiverImportExport.tikz_cd = new class extends QuiverImportExport {
    export(quiver, settings, options, definitions) {
        let output = "";

        // Wrap tikz-cd code with `\begin{tikzcd} ... \end{tikzcd}`.
        const wrap_boilerplate = (output) => {
            const diagram_options = [];
            // Ampersand replacement.
            if (settings.get("export.ampersand_replacement")) {
                diagram_options.push("ampersand replacement=\\&");
            }
            // Cramped.
            if (settings.get("export.cramped")) {
                diagram_options.push("cramped");
            }
            // Column and row separation.
            const sep = {
                column: `${options.sep.column.toFixed(2)}em`,
                row: `${options.sep.row.toFixed(2)}em`,
            };
            const seps = {
                "0.45em": "tiny",
                "0.90em": "small",
                "1.35em": "scriptsize",
                "1.80em": "normal",
                "2.70em": "large",
                "3.60em": "huge",
            };
            for (const axis of ["column", "row"]) {
                if (seps.hasOwnProperty(sep[axis])) {
                    sep[axis] = seps[sep[axis]];
                }
            }
            if (sep.column === sep.row && sep.column !== "normal") {
                diagram_options.push(`sep=${sep.column}`);
            } else {
                for (const axis of ["column", "row"]) {
                    if (sep[axis] !== "normal") {
                        diagram_options.push(`${axis} sep=${sep[axis]}`);
                    }
                }
            }
            // `tikzcd` environment.
            let tikzcd = `\\begin{tikzcd}${
                diagram_options.length > 0 ? `[${diagram_options.join(",")}]` : ""
            }\n${
                output.length > 0 ? `${
                    output.split("\n").map(line => `\t${line}`).join("\n")
                }\n` : ""
            }\\end{tikzcd}`;
            if (settings.get("export.centre_diagram") && !settings.get("export.standalone")) {
                tikzcd = `\\[${tikzcd}\\]`;
            }
            if (settings.get("export.standalone")) {
                tikzcd = `\\documentclass[tikz]{standalone}\n\\usepackage{quiver}\n\\begin{document}\n${tikzcd}\n\\end{document}`;
            }
            // URL.
            return `% ${
                QuiverImportExport.base64.export(quiver, settings, options, definitions).data
            }\n${tikzcd}`;
        };

        // Early exit for empty quivers.
        if (graphIsEmpty(quiver)) {
            return {
                data: wrap_boilerplate(output),
                metadata: { tikz_incompatibilities: new Set(), dependencies: new Map() },
            };
        }

        // Which symbol to use as a column separator. Usually ampersand (`&`), but sometimes it is
        // necessary to escape the ampersand when using TikZ diagrams in a nested context.
        const ampersand = settings.get("export.ampersand_replacement") ? "\\&" : "&";

        // If a label is particularly simple (containing no special symbols), we do not need to
        // surround it in curly brackets. This is preferable, because simpler output is more
        // readable. In general, we need to use curly brackets to avoid LaTeX errors. For instance,
        // `[a]` is invalid: we must use `{[a]}` instead.
        const simple_label = /^\\?[a-zA-Z0-9]+$/;

        // Adapt a label to be appropriate for TikZ output, by surrounding it in curly brackets when
        // necessary, and using `\array` for newlines.
        const format_label = (label) => {
            if (label.includes("\\\\")) {
                // The label may contain a newline. In this case, we place the label inside a table,
                // which is permitted to contain newlines.
                return `\\begin{array}{c} ${label} \\end{array}`;
            }
            if (!simple_label.test(label)) {
                return `{${label}}`;
            }
            return label;
        };

        // We handle the export in two stages: vertices and edges. These are fundamentally handled
        // differently in tikz-cd, so it makes sense to separate them in this way. We have a bit of
        // flexibility in the format in which we output (e.g. edges relative to nodes, or with
        // absolute positions).
        // We choose to lay out the tikz-cd code as follows:
        //    (vertices)
        //    X & X & X \\
        //    X & X & X \\
        //    X & X & X
        //    (1-cells)
        //    (2-cells)
        //    ...

        // Output the vertices.
        // Note that currently vertices may not share the same position,
        // as in that case they will be overwritten.
        const vertices_in_order = graphVertices(quiver);
        const edges_by_level = graphEdgesByLevel(quiver);

        let offset = new Position(Infinity, Infinity);
        // Construct a grid for the vertices.
        const rows = new Map();
        for (const vertex of vertices_in_order) {
            if (!rows.has(vertex.position.y)) {
                rows.set(vertex.position.y, new Map());
            }
            rows.get(vertex.position.y).set(vertex.position.x, vertex);
            offset = offset.min(vertex.position);
        }
        // Iterate through the rows and columns in order, outputting the tikz-cd code.
        const prev = new Position(offset.x, offset.y);
        for (const [y, row] of Array.from(rows).sort(([y1,], [y2,]) => y1 - y2)) {
            if (y - prev.y > 0) {
                output += ` ${"\\\\\n".repeat(y - prev.y)}`;
            }
            // This variable is really unnecessary, but it allows us to remove
            // a leading space on a line, which makes things prettier.
            let first_in_row = true;
            for (const [x, vertex] of Array.from(row).sort(([x1,], [x2,]) => x1 - x2)) {
                if (x - prev.x > 0) {
                    output += `${!first_in_row ? " " : ""}${ampersand.repeat(x - prev.x)} `;
                }
                if (vertex.label !== "" && vertex.label_colour.is_not_black()) {
                    output += `\\textcolor${
                        vertex.label_colour.latex(definitions.colours, true)}{${format_label(
                            vertex.label
                        )}}`;
                } else {
                    output += format_label(vertex.label);
                }
                prev.x = x;
                first_in_row = false;
            }
            prev.x = offset.x;
            prev.y = y;
        }

        // Referencing cells is slightly complicated by the fact that we can't give vertices
        // names in tikz-cd, so we have to refer to them by position instead. That means 1-cells
        // have to be handled differently to k-cells for k > 1.
        // A map of unique identifiers for cells.
        const names = new Map();
        let index = 0;
        const cell_reference = (cell, phantom) => {
            if (cell.is_vertex()) {
                // Note that tikz-cd 1-indexes its cells.
                return `${cell.position.y - offset.y + 1}-${cell.position.x - offset.x + 1}`;
            } else {
                return `${names.get(cell)}${phantom ? "p" : ""}`;
            }
        };

        // quiver can draw more complex arrows than tikz-cd, and in some cases we are currently
        // unable to export faithfully to tikz-cd. In this case, we issue a warning to alert the
        // user that their diagram is not expected to match the quiver representation.
        const tikz_incompatibilities = new Set();
        // In some cases, we can resolve this issue by relying on another package. However, these
        // packages may not yet be standard in LaTeX installations, so we warn the issue that they
        // are required.
        const dependencies = new Map();
        const add_dependency = (dependency, reason) => {
            if (!dependencies.has(dependency)) {
                dependencies.set(dependency, new Set());
            }
            dependencies.get(dependency).add(reason);
        };

        // Output the edges, i.e. 1-cells and above.
        for (let level = 1; level < edges_by_level.length; ++level) {
            if ((edges_by_level[level] || []).length > 0) {
                output += "\n";
            }

            // Sort the edges so that we iterate through based on source (top-to-bottom,
            // left-to-right), and then target.
            const edges = [...(edges_by_level[level] || [])];
            const compare_cell_position = (a, b) => {
                if (a.position.y < b.position.y) {
                    return -1;
                }
                if (a.position.y > b.position.y) {
                    return 1;
                }
                if (a.position.x < b.position.x) {
                    return -1;
                }
                if (a.position.x > b.position.x) {
                    return 1;
                }
                return 0;
            }
            edges.sort((a, b) => {
                const find_vertex = (cell, choose) => {
                    if (cell.is_edge()) {
                        return find_vertex(choose(cell), choose);
                    }
                    return cell;
                };
                return compare_cell_position(
                    find_vertex(a, (cell) => cell.source),
                    find_vertex(b, (cell) => cell.source),
                ) || compare_cell_position(
                    find_vertex(a, (cell) => cell.target),
                    find_vertex(b, (cell) => cell.target),
                );
            });

            for (const edge of edges) {
                // The parameters pertinent to the entire arrow. TikZ is quite flexible in
                // where it allows various parameters to appear. E.g. `text` can appear in the
                // general parameter list, or as a parameter specific to a label. For specific
                // parameters, we always attach it to the label to which it is relevant. This helps
                // us avoid accidentally affecting the properties of other labels.
                const parameters = {};
                // The parameters that are inherited by phantom edges (i.e. those relating to
                // positioning, but not styling).
                const phantom_parameters = {};
                // The primary label (i.e. the one the user edits directly).
                const label = { content: edge.label };
                // A label used for the edge style, e.g. a bar, corner, or adjunction symbol.
                let decoration = {};
                // All the labels for this edge, including the primary label, a placeholder label if
                // any edges are attached to this one, and labels for non-arrow edge styles, or the
                // bar on a barred arrow.
                const labels = [label];
                // We can skip applying various properties if the edge is invisible.
                const edge_is_empty = edge.options.style.name === "arrow"
                    && edge.options.style.head.name === "none"
                    && edge.options.style.body.name === "none"
                    && edge.options.style.tail.name === "none";

                const current_index = index;
                // We only need to give edges names if they're depended on by another edge. Note
                // that we provide a name even for edges that only have non-edge-aligned edges. This
                // is not useful for the TikZ output, but is useful if the TikZ code is later parsed
                // by quiver, as it allows quiver to match phantom edges to the real edges.
                if (graphDependenciesOf(quiver, edge).size > 0) {
                    names.set(edge, current_index);
                    // We create a placeholder label that is used as a source/target for other
                    // edges. It's more convenient to create a placeholder label so that we have
                    // fine-grained control of positioning independent of the actual label
                    // position.
                    labels.unshift({
                        name: current_index,
                        // The placeholder labels should have zero size. The following
                        // properties heuristically gave the best results for this purpose.
                        anchor: "center",
                        "inner sep": 0,
                    });
                    index++;
                }

                switch (edge.options.label_alignment) {
                    case "centre":
                        // Centring is done by using the `description` style.
                        label.description = "";
                        break;
                    case "over":
                        // Centring without clearing is done by using the `marking` style.
                        label.marking = "";
                        // If the `allow upside down` option is not specified, TikZ will flip labels
                        // when the rotation is too high.
                        label["allow upside down"] = "";
                        break;
                    case "right":
                        // By default, the label is drawn on the left side of the edge; `swap`
                        // flips the side.
                        label.swap = "";
                        break;
                }

                if (edge.options.label_position !== 50) {
                    label.pos = edge.options.label_position / 100;
                }

                if (edge.options.offset !== 0) {
                    const side = edge.options.offset > 0 ? "right" : "left";
                    const abs_offset = Math.abs(edge.options.offset);
                    parameters[`shift ${side}`] = abs_offset !== 1 ? abs_offset : "";
                    phantom_parameters[`shift ${side}`] = parameters[`shift ${side}`];
                }

                // This is the simplest case, because we can set a single attribute for both the
                // label and edge colours (which also affects the other labels, e.g. those for
                // pullbacks and adjunctions).
                if (edge.options.colour.eq(edge.label_colour) && edge.label_colour.is_not_black()) {
                    parameters.color = edge.label_colour.latex(definitions.colours);
                } else {
                    // The edge colour. An arrow is drawn only for the `arrow` style, so we don't
                    // need to emit `draw` in another case.
                    if (
                        !edge_is_empty && edge.options.colour.is_not_black()
                        && edge.options.style.name === "arrow"
                    ) {
                        parameters.draw = edge.options.colour.latex(definitions.colours);
                    }
                    // The label colour.
                    if (edge.label_colour.is_not_black()) {
                        label.text = edge.label_colour.latex(definitions.colours);
                    }
                    // The colour for non-`arrow` edges, which is drawn using a label.
                    if (edge.options.style.name !== "arrow" && edge.options.colour.is_not_black()) {
                        decoration.text = edge.options.colour.latex(definitions.colours);
                    }
                }

                // This is the calculation for the radius of an ellipse, combining the two
                // multipliers based on the angle of the edge.
                const multiplier = QuiverExport.CONSTANTS.TIKZ_HORIZONTAL_MULTIPLIER
                    * QuiverExport.CONSTANTS.TIKZ_VERTICAL_MULTIPLIER
                    / ((QuiverExport.CONSTANTS.TIKZ_HORIZONTAL_MULTIPLIER ** 2
                            * Math.sin(edge.angle()) ** 2
                    + QuiverExport.CONSTANTS.TIKZ_VERTICAL_MULTIPLIER ** 2
                        * Math.cos(edge.angle()) ** 2) ** 0.5);

                if (edge.options.curve !== 0) {
                    parameters.curve = `{height=${
                        // Using a fixed multiplier for curves of any angle tends to work better
                        // in the examples I tested.
                        edge.options.curve * CONSTANTS.CURVE_HEIGHT
                            * QuiverExport.CONSTANTS.TIKZ_HORIZONTAL_MULTIPLIER
                    }pt}`;
                    phantom_parameters.curve = parameters.curve;
                }

                // Shortened edges. This may only be set for the `arrow` style.
                if (!edge_is_empty
                    && (edge.options.shorten.source !== 0 || edge.options.shorten.target !== 0)) {
                    parameters['between'] = `{${
                        edge.options.shorten.source / 100
                    }}{${
                        (100 - edge.options.shorten.target) / 100
                    }}`;
                    add_dependency("quiver", "shortened arrows");
                }

                // Edge styles.
                switch (edge.options.style.name) {
                    case "arrow":
                        // We special-case arrows with no head, body, nor tail. This is because the
                        // `no body` style has some graphical issues in some versions of TikZ, so
                        // we prefer to avoid this style if possible.
                        if (edge_is_empty) {
                            parameters.draw = "none";
                            break;
                        }

                        // tikz-cd only has supported for 1-cells and 2-cells...
                        if (edge.options.level === 2) {
                            if (edge.options.style.head.name === "none") {
                                // We special-case the combination of double arrows with no head,
                                // because tikz-cd has a dedicated style, which means more concise
                                // output.
                                parameters.equals = "";
                            } else {
                                parameters.Rightarrow = "";
                            }
                        } else if (edge.options.level > 2) {
                            // So for n-cells for n > 2, we make use of tikz-nfold.
                            parameters.Rightarrow = "";
                            parameters["scaling nfold"] = edge.options.level;
                            add_dependency("tikz-nfold", "triple arrows or higher");
                        }

                        const midpoint = (edge.options.shorten.source
                            + (100 - edge.options.shorten.target)) / (2 * 100);

                        // Body styles.
                        switch (edge.options.style.body.name) {
                            case "cell":
                                // This is the default in tikz-cd.
                                break;

                            case "dashed":
                                parameters.dashed = "";
                                break;

                            case "dotted":
                                parameters.dotted = "";
                                break;

                            case "squiggly":
                                parameters.squiggly = "";
                                break;

                            case "bullet hollow":
                                labels.push(decoration);
                                decoration.content = "\\bullet";
                                decoration.marking = "";
                                if (midpoint !== 0.5) {
                                    decoration.pos = midpoint;
                                }
                                decoration.text
                                    = "\\pgfkeysvalueof{/tikz/commutative diagrams/background color}";
                                decoration = {};
                                // Fall through.

                            case "barred":
                            case "double barred":
                            case "bullet solid":
                                labels.push(decoration);
                                decoration.content = {
                                    "barred": "\\shortmid",
                                    "double barred": "\\shortmid\\shortmid",
                                    "bullet solid": "\\bullet",
                                    "bullet hollow": "\\circ",
                                }[edge.options.style.body.name];
                                decoration.marking = "";
                                if (midpoint !== 0.5) {
                                    decoration.pos = midpoint;
                                }
                                if (edge.options.colour.is_not_black()) {
                                    decoration.text
                                        = edge.options.colour.latex(definitions.colours);
                                }
                                if (["left", "right"].includes(edge.options.label_alignment)) {
                                    label["inner sep"] = ".8ex";
                                }
                                if (edge.options.level > 1 && [
                                    "bullet hollow", "bullet solid"
                                ].includes(edge.options.style.body.name)) {
                                    tikz_incompatibilities
                                        .add("double arrows or higher with decorations");
                                }
                                break;

                            case "none":
                                parameters["no body"] = "";
                                break;
                        }

                        // Tail styles.
                        switch (edge.options.style.tail.name) {
                            case "maps to":
                                parameters["maps to"] = "";
                                break;

                            case "mono":
                                switch (edge.options.level) {
                                    case 1:
                                        parameters.tail = "";
                                        break;
                                    case 2:
                                        parameters["2tail"] = "";
                                        break;
                                    default:
                                        // We've already reported an issue with triple arrows and
                                        // higher in tikz-cd, so we don't emit another one. Triple
                                        // cells are currently exported as normal arrows, so we add
                                        // the correct tail for 1-cells.
                                        parameters.tail = "";
                                        break;
                                }
                                break;

                            case "hook":
                                parameters[`hook${
                                    edge.options.style.tail.side === "top" ? "" : "'"
                                }`] = "";
                                if (edge.options.level > 1) {
                                    tikz_incompatibilities.add(
                                        "double arrows or higher with hook tails"
                                    );
                                }
                                break;

                            case "arrowhead":
                                switch (edge.options.level) {
                                    case 1:
                                        parameters["tail reversed"] = "";
                                        break;
                                    case 2:
                                        parameters["2tail reversed"] = "";
                                        break;
                                    default:
                                        // We've already reported an issue with triple arrows and
                                        // higher in tikz-cd, so we don't emit another one. Triple
                                        // cells are currently exported as normal arrows, so we add
                                        // the correct tail for 1-cells.
                                        parameters["tail reversed"] = "";
                                        break;
                                }
                                break;

                            case "none":
                                // This is the default in tikz-cd.
                                break;
                        }

                        // Head styles.
                        switch (edge.options.style.head.name) {
                            case "none":
                                // Only add the `no head` option if we haven't already handled this
                                // when setting the body style earlier.
                                if (!parameters.hasOwnProperty("equals")) {
                                    parameters["no head"] = "";
                                }
                                break;

                            case "epi":
                                parameters["two heads"] = "";
                                if (edge.options.level > 1) {
                                    tikz_incompatibilities.add(
                                        "double arrows or higher with multiple heads"
                                    );
                                }
                                break;

                            case "harpoon":
                                parameters[`harpoon${
                                    edge.options.style.head.side === "top" ? "" : "'"
                                }`] = "";
                                if (edge.options.level > 1) {
                                    tikz_incompatibilities.add(
                                        "double arrows or higher with harpoon heads"
                                    );
                                }
                                break;
                        }

                        break;

                    case "adjunction":
                    case "corner":
                    case "corner-inverse":
                        labels.push(decoration);

                        parameters.draw = "none";
                        decoration.anchor = "center";

                        let angle;

                        switch (edge.options.style.name) {
                            case "adjunction":
                                decoration.content = "\\dashv";
                                // Adjunction symbols should point in the direction of the arrow.
                                angle = -Math.round(edge.angle() * 180 / Math.PI);
                                break;
                            case "corner":
                            case "corner-inverse":
                                decoration.content = edge.options.style.name.endsWith("-inverse") ?
                                    "\\ulcorner" : "\\lrcorner";
                                decoration.pos = "0.125";
                                // Round the angle to the nearest 45º, so that the corner always
                                // appears aligned with horizontal, vertical or diagonal lines.
                                angle = 45 - 45 * Math.round(4 * edge.angle() / Math.PI);
                                break;
                        }

                        if (angle !== 0) {
                            decoration.rotate = angle;
                        }

                        break;
                }

                parameters.from = cell_reference(edge.source, !edge.options.edge_alignment.source);
                parameters.to = cell_reference(edge.target, !edge.options.edge_alignment.target);

                // Loops.
                if (edge.target === edge.source) {
                    parameters.loop = "";
                    const clockwise = edge.options.radius >= 0 ? 1 : -1;
                    const loop_angle = (180 - 90 * clockwise - edge.options.angle);
                    const angle_spread = 30 + 5 * (Math.abs(edge.options.radius) - 1) / 2;
                    parameters.in = mod(loop_angle - angle_spread * clockwise, 360);
                    parameters.out = mod(loop_angle + angle_spread * clockwise, 360);
                    parameters.distance = `${5 + 5 * (Math.abs(edge.options.radius) - 1) / 2}mm`;
                }

                const object_to_list = (object) => {
                    return Object.entries(object).map(([key, value]) => {
                        return value !== "" ? `${key}=${value}` : key;
                    });
                };

                output += `\\arrow[${
                    // Ignore any labels that are empty (and aren't playing an important role as a
                    // placeholder).
                    labels.filter((label) => label.hasOwnProperty("name") || label.content !== "")
                        .map((label) => {
                            const content = label.content || "";
                            delete label.content;
                            const swap = label.hasOwnProperty("swap");
                            delete label.swap;
                            const parameters = object_to_list(label);
                            return `"${content !== "" ?
                                format_label(content) : ""}"${swap ? "'" : ""}${
                                parameters.length > 0 ? `{${parameters.join(", ")}}` : ""
                            }`;
                        })
                        .concat(object_to_list(parameters))
                        .join(", ")
                }]\n`;

                // Check whether any edges depend on this one, but are not edge aligned. In this
                // case, we have to create a phantom edge that does not depend on the labels of the
                // source and target.
                if (graphDependenciesOf(quiver, edge).size > 0) {
                    for (const [dependency, end] of graphDependenciesOf(quiver, edge)) {
                        if (!dependency.options.edge_alignment[end]) {
                            output += `\\arrow[""{name=${
                                current_index
                            }p, anchor=center, inner sep=0}, phantom, from=${
                                parameters.from
                            }, to=${
                                parameters.to
                            }, start anchor=center, end anchor=center${
                                Object.keys(phantom_parameters).length > 0 ?
                                    `, ${object_to_list(phantom_parameters).join(", ")}`
                                : ""
                            }]\n`;
                        }
                    }
                }
            }
            // Remove any trailing whitespace.
            output = output.trim();
        }

        return {
            data: wrap_boilerplate(output),
            metadata: { tikz_incompatibilities, dependencies },
        };
    }

    import(ui, data) {
        this.begin_import(ui);

        const parser = new Parser(ui, data);
        parser.parse_diagram();

        this.end_import(ui, ui.view_all_cells());

        return { diagnostics: parser.diagnostics };
    }
};

QuiverImportExport.base64 = new class extends QuiverImportExport {
    // The format we use for encoding quivers in base64 (primarily for link-sharing) is
    // the following. This has been chosen based on minimality (for shorter representations),
    // rather than readability.
    //
    // Note that an empty quiver has no representation.
    //
    // `[version: integer, |vertices|: integer, ...vertices, ...edges]`
    //
    // Parameters:
    // - `version` is currently only permitted to be 0. The format has been designed to be
    //   forwards-compatible with changes, so it is intended that this version will not
    //   change.
    // - `|vertices|` is the length of the array `vertices`.
    // - `vertices` is an array of vertices of the form:
    //      `[x: integer, y: integer, label: string, label_colour: [h, s, l, a]]`
    //      + `label` is optional (if not present, it will default to `""`), though it must be
    //         present if any later option is.
    //      + `label_colour` is optional (if not present, it will default to `[0, 0, 0, 1]`).
    //          + `h` is an integer from `0` to `360`
    //          + `s` is an integer from `0` to `100`
    //          + `l` is an integer from `0` to `100`
    //          + `a` is a floating-point number from `0` to `1`
    // - `edges` is an array of edges of the form:
    //      `[source: index, target: index, label: string, alignment, options, label_colour]`
    //      + (label) `alignment` is an enum comprising the following options:
    //          * `0`: left
    //          * `1`: centre
    //          * `2`: right
    //          * `3`: over
    //        It has been distinguished from the other options as one that is frequently
    //        changed from the default, to avoid the overhead of encoding an options
    //        object.
    //      + `options` is an object containing the delta of the options from the defaults.
    //         This is the only parameter that is not encoded simply as an array, as the
    //         most likely parameter to be changed in the future.
    //      + `label_colour` is stored in the same manner as for vertices.
    //
    // Notes:
    // - An `index` is an integer indexing into the array `[...vertices, ...edges]`.
    // - Arrays may be truncated if the values of the elements are the default values.

    export(quiver, settings, options) {
        // Remove the query string and fragment identifier from the current URL and use that as a
        // base.
        const URL_prefix = window.location.href.replace(/\?.*$/, "").replace(/#.*$/, "");

        if (graphIsEmpty(quiver)) {
            // No need to have an encoding of an empty quiver; we'll just use the URL directly.
            return {
                data: URL_prefix,
                metadata: {},
            };
        }

        // Encode the macro URL if it's not null.
        const macro_data = options.macro_url !== null
            ? `&macro_url=${encodeURIComponent(options.macro_url)}` : "";

        const renderer = settings.get("quiver.renderer");
        return {
            // We exclude the default renderer from the URL to decrease length as much as possible.
            data: `${URL_prefix}#${renderer === CONSTANTS.DEFAULT_RENDERER ? ""
                    : `r=${renderer}&`}q=${
                this.export_selection(quiver, new Set(graphAllCells(quiver)))
            }${macro_data}`,
            metadata: {},
        };
    }

    // Export just the specified selection of cells. This is used when we copy a selection. It is
    // not assumed that the selection is closed under dependencies: e.g. it is possible to export an
    // edge without exporting the corresponding vertices.
    export_selection(quiver, selection) {
        let vertices = 0;
        const cells = [];
        const indices = new Map();

        let offset = new Position(Infinity, Infinity);
        // We want to ensure that the top-left cell is in position (0, 0), so we need
        // to work out where the top-left cell actually is, to compute an offset.
        const vertices_in_order = graphVertices(quiver);
        const edges_by_level = graphEdgesByLevel(quiver);

        for (const vertex of vertices_in_order) {
            if (selection.has(vertex)) {
                offset = offset.min(vertex.position);
                ++vertices;
            }
        }
        for (const vertex of vertices_in_order) {
            if (!selection.has(vertex)) {
                continue;
            }
            const { label, label_colour } = vertex;
            indices.set(vertex, cells.length);
            const position = vertex.position.sub(offset).toArray();
            const cell = [...position];
            // In the name of efficiency, we omit any parameter that is not necessary, and for which
            // no later parameter is necessary.
            if (label !== "") {
                cell.push(label);
            }
            if (label !== "" && label_colour.is_not_black()) {
                // Even if the colour is not black, it's irrelevant if there is no label.
                cell.push(label_colour.hsla());
            }
            cells.push(cell);
        }

        for (let level = 1; level < edges_by_level.length; ++level) {
            for (const edge of edges_by_level[level] || []) {
                if (!selection.has(edge)) {
                    continue;
                }
                const { label, label_colour, options: { label_alignment, ...options } } = edge;
                const [source, target] = [indices.get(edge.source), indices.get(edge.target)];
                indices.set(edge, cells.length);
                const cell = [source, target];
                // We want to omit parameters that are unnecessary (i.e. have the default
                // values). However, because we store parameters in an array, the only way
                // we can distinguish missing values is by the length. Therefore, we can
                // only truncate the array (not omit elements partway through the array).
                // This means we may need to include unnecessary information if there is a
                // non-default parameter after a default one. The parameters most likely to
                // be default are placed further back in the array to reduce the frequency
                // of this situation.
                const end = [];

                // Even if the colour is not black, it's irrelevant if there is no label.
                if (label !== "" && label_colour.is_not_black()) {
                    end.push(label_colour.hsla());
                }

                // We compute a delta of the edge options compared
                // to the default, so we encode a minimum of data.
                const default_options = Edge.default_options({ level });

                // Recursively compute a delta between an `object` and `base`.
                const probe = (object, base) => {
                    const delta = {};
                    for (const [key, value] of Object.entries(object)) {
                        const default_value = base[key];
                        if (default_value instanceof Encodable && value instanceof Encodable) {
                            if (!default_value.eq(value)) {
                                delta[key] = value;
                            }
                        } else if (typeof default_value === "object" && typeof value === "object") {
                            const subdelta = probe(value, default_value);
                            if (Object.keys(subdelta).length > 0) {
                                delta[key] = subdelta;
                            }
                        } else if (default_value !== value) {
                            delta[key] = value;
                        }
                    }
                    return delta;
                };

                const delta = probe(options, default_options);

                // Some parameters are redundant and are used only for convenience, so we strip them
                // out.
                delete delta["shape"];
                switch (edge.options.shape) {
                    case "bezier":
                        delete delta["radius"];
                        delete delta["angle"];
                        break;
                    case "arc":
                        delete delta["curve"];
                        break;
                }

                if (end.length > 0 || Object.keys(delta).length > 0) {
                    end.push(delta);
                }

                const push_if_necessary = (parameter, default_value, condition = true) => {
                    if (end.length > 0 || (parameter !== default_value && condition)) {
                        end.push(parameter);
                    }
                };

                const variant = { left: 0, centre: 1, right: 2, over: 3 }[label_alignment];
                // It's only necessary to encode the label alignment if the label is not blank.
                push_if_necessary(variant, 0, label !== "");
                push_if_necessary(label, "");

                cell.push(...end.reverse());
                cells.push(cell);
            }
        }

        // The version of the base64 output format exported by this version of quiver.
        const VERSION = 0;
        const output = [VERSION, vertices, ...cells];
        const encoder = new TextEncoder();
        return btoa(String.fromCharCode(...encoder.encode(JSON.stringify(output))));
    }

};

QuiverExport.html = new class extends QuiverExport {
    export (quiver, settings, options, definitions) {
        const url = QuiverImportExport.base64.export(quiver, settings, options, definitions).data;
        let [width, height] = settings.get("export.embed.fixed_size") ? [
            settings.get("export.embed.width"),
            settings.get("export.embed.height"),
        ] : [
            options.dimensions.width + 2 * CONSTANTS.EMBED_PADDING,
            options.dimensions.height + 2 * CONSTANTS.EMBED_PADDING,
        ];
        return {
            data: `<!-- ${url} -->
<iframe class="quiver-embed" \
src="${url}${!graphIsEmpty(quiver) ? "&" : "#"}embed" \
width="${width}" \
height="${height}" \
style="border-radius: 8px; border: none;">\
</iframe>`,
            metadata: {},
        };
    }
};
