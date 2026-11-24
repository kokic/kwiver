class ConnectPreview {
    constructor(ui) {
        this.ui = ui;
        this.preview_reconnect = null;
    }

    committed_endpoint_of(edge, end, runtime_by_id = null) {
        if (!edge?.is_edge?.() || (end !== "source" && end !== "target")) {
            return null;
        }
        return this.ui?.kwiver_runtime_edge_endpoint_cell?.(edge, end, runtime_by_id) ?? null;
    }

    committed_level_of(cell, runtime_by_id = null) {
        if (!cell?.is_vertex?.() && !cell?.is_edge?.()) {
            return null;
        }
        const runtime_level = this.ui?.kwiver_runtime_cell_level?.(cell, runtime_by_id);
        return Number.isInteger(runtime_level) ? runtime_level : null;
    }

    committed_edge_options(edge, runtime_by_id = null) {
        if (!edge?.is_edge?.()) {
            return null;
        }
        return this.ui?.kwiver_runtime_edge_options?.(edge, runtime_by_id) ?? null;
    }

    preview_record_of(cell) {
        return this.preview_reconnect?.records_by_cell?.get(cell) ?? null;
    }

    source_of(edge, runtime_by_id = null) {
        const preview_source = this.preview_record_of(edge)?.source;
        if (preview_source !== null && preview_source !== undefined) {
            return preview_source;
        }
        const source = this.committed_endpoint_of(edge, "source", runtime_by_id);
        if (source === null && edge?.is_edge?.()) {
            throw new Error("[kwiver-only] ui.connect_preview.source: runtime endpoint snapshot invalid");
        }
        return source;
    }

    target_of(edge, runtime_by_id = null) {
        const preview_target = this.preview_record_of(edge)?.target;
        if (preview_target !== null && preview_target !== undefined) {
            return preview_target;
        }
        const target = this.committed_endpoint_of(edge, "target", runtime_by_id);
        if (target === null && edge?.is_edge?.()) {
            throw new Error("[kwiver-only] ui.connect_preview.target: runtime endpoint snapshot invalid");
        }
        return target;
    }

    level_of(cell, runtime_by_id = null) {
        const preview_level = this.preview_record_of(cell)?.level;
        if (Number.isInteger(preview_level)) {
            return preview_level;
        }
        const committed_level = this.committed_level_of(cell, runtime_by_id);
        if (Number.isInteger(committed_level)) {
            return committed_level;
        }
        throw new Error("[kwiver-only] ui.connect_preview.level: runtime cell snapshot invalid");
    }

    options_of(edge, runtime_by_id = null) {
        const preview_options = this.preview_record_of(edge)?.options;
        if (preview_options !== null && preview_options !== undefined) {
            return preview_options;
        }
        const committed_options = this.committed_edge_options(edge, runtime_by_id);
        if (committed_options === null) {
            throw new Error("[kwiver-only] ui.connect_preview.options: runtime edge snapshot invalid");
        }
        return committed_options;
    }

    transitive_dependencies(cells, exclude_roots = false) {
        const preview = this.preview_reconnect;
        if (preview !== null && Array.isArray(cells) && cells.length === 1 && cells[0] === preview.edge) {
            const ordered_edges = exclude_roots
                ? preview.ordered_edges.filter((cell) => cell !== preview.edge)
                : preview.ordered_edges;
            return new Set(ordered_edges);
        }
        return this.ui.kwiver_require_runtime_transitive_dependency_cells(
            cells,
            exclude_roots,
            "ui.connect_preview.transitive_dependencies",
        );
    }

    with_temporary_reconnect(edge, source, target, callback) {
        if (!edge?.is_edge?.() || source === null || target === null) {
            return callback();
        }
        const previous_preview = this.preview_reconnect;
        const preview = this.ui?.kwiver_preview_reconnect_plan?.(
            edge,
            source,
            target,
            "ui.connect_preview.preview_plan",
        );
        if (preview === null || preview === undefined) {
            throw new Error("[kwiver-only] ui.connect_preview.preview_plan: reconnect preview unavailable");
        }
        this.preview_reconnect = preview;
        try {
            return callback();
        } finally {
            this.preview_reconnect = previous_preview;
        }
    }
}

export { ConnectPreview };
