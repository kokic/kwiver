import { delay } from "./dom.mjs";
import { Point } from "./ds.mjs";
import { Parser } from "./parser.mjs";
import {
    kwiver_bridge_all_cells,
    kwiver_bridge_export,
    kwiver_bridge_import_tikz_result,
} from "./kwiver_bridge.mjs";

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
            case "html": {
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
            }
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

/// Shared export helpers that still matter for runtime-backed product paths.
export class QuiverExport {
    /// A method to export a quiver as a string.
    export() {}
}

QuiverExport.CONSTANTS = {
    // The parser still reuses these heuristics when recovering curve heights from tikz-cd.
    TIKZ_HORIZONTAL_MULTIPLIER: 1 / 4,
    TIKZ_VERTICAL_MULTIPLIER: 1 / 6,
};

/// Shared import lifecycle helpers.
export class QuiverImportExport extends QuiverExport {
    /// A method to import a quiver as a string. `import(export(quiver))` should be the
    /// identity function. Currently `import` takes a `UI` into which to import directly.
    import() {}

    static begin_import(ui) {
        // We don't want to relayout every time we add a new cell: instead, we should perform
        // layout once, once all of the cells have been created.
        ui.buffer_updates = true;
    }

    static end_import(ui, imported_cells, centre_view = true) {
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
