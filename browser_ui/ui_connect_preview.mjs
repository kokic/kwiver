class ConnectPreview {
    constructor(ui) {
        this.ui = ui;
        this.edges_by_endpoint = new Map();
        this.preview_reconnect = null;
    }

    runtime_cells_by_id() {
        return this.ui?.kwiver_runtime_cells_by_id?.() ?? null;
    }

    committed_endpoint_of(edge, end, runtime_by_id = null) {
        if (!edge?.is_edge?.() || (end !== "source" && end !== "target")) {
            return null;
        }
        return this.ui?.kwiver_runtime_edge_endpoint_cell?.(edge, end, runtime_by_id) ?? null;
    }

    committed_level_of(cell, runtime_by_id = null) {
        if (cell?.is_vertex?.() || cell?.is_edge?.()) {
            const runtime_level = this.ui?.kwiver_runtime_cell_level?.(cell, runtime_by_id);
            return Number.isInteger(runtime_level) ? runtime_level : null;
        }
        const level = Number(cell?.kwiver_projection_level?.());
        return Number.isInteger(level) ? level : null;
    }

    committed_edge_options(edge, runtime_by_id = null) {
        if (!edge?.is_edge?.()) {
            return null;
        }
        return this.ui?.kwiver_runtime_edge_options?.(edge, runtime_by_id) ?? null;
    }

    committed_edge_is_loop(edge, runtime_by_id = null) {
        if (!edge?.is_edge?.()) {
            return false;
        }
        const runtime_is_loop = this.ui?.kwiver_runtime_edge_is_loop?.(edge, runtime_by_id);
        return typeof runtime_is_loop === "boolean" ? runtime_is_loop : null;
    }

    register_edge_at_endpoints(
        edge,
        source = edge?.kwiver_projection_source?.(),
        target = edge?.kwiver_projection_target?.(),
    ) {
        if (!edge?.is_edge?.() || !source || !target) {
            return;
        }
        this.endpoint_edges(source).add(edge);
        this.endpoint_edges(target).add(edge);
    }

    unregister_edge_at_endpoints(
        edge,
        source = edge?.kwiver_projection_source?.(),
        target = edge?.kwiver_projection_target?.(),
    ) {
        if (!edge?.is_edge?.()) {
            return;
        }
        for (const endpoint of [source, target]) {
            const edges = this.edges_by_endpoint.get(endpoint);
            if (!(edges instanceof Set)) {
                continue;
            }
            edges.delete(edge);
            if (edges.size === 0) {
                this.edges_by_endpoint.delete(endpoint);
            }
        }
    }

    apply_committed_endpoints(edge, source, target, registered = true) {
        if (registered) {
            this.unregister_edge_at_endpoints(
                edge,
                edge?.kwiver_projection_source?.(),
                edge?.kwiver_projection_target?.(),
            );
        }
        edge.kwiver_set_projection_endpoints(source, target);
        if (registered) {
            this.register_edge_at_endpoints(edge, source, target);
        }
    }

    preview_reconnect_of(edge) {
        return this.preview_reconnect?.edge === edge ? this.preview_reconnect : null;
    }

    source_of(edge, runtime_by_id = null) {
        const preview_source = this.preview_reconnect_of(edge)?.source;
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
        const preview_target = this.preview_reconnect_of(edge)?.target;
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
        const preview_level = this.preview_reconnect?.levels.get(cell);
        if (Number.isInteger(preview_level)) {
            return preview_level;
        }
        const committed_level = this.committed_level_of(cell, runtime_by_id);
        if (Number.isInteger(committed_level)) {
            return committed_level;
        }
        throw new Error("[kwiver-only] ui.connect_preview.level: runtime cell snapshot invalid");
    }

    shape_of(edge, runtime_by_id = null) {
        const preview = this.preview_reconnect_of(edge);
        const committed_options = this.committed_edge_options(edge, runtime_by_id);
        if (committed_options === null) {
            throw new Error("[kwiver-only] ui.connect_preview.shape: runtime edge snapshot invalid");
        }
        if (preview === null || preview === undefined) {
            return committed_options.shape;
        }

        const committed_loop = this.committed_edge_is_loop(edge, runtime_by_id);
        if (typeof committed_loop !== "boolean") {
            throw new Error("[kwiver-only] ui.connect_preview.shape: runtime edge snapshot invalid");
        }
        const preview_loop = preview.source === preview.target;
        return committed_loop && preview_loop ? "arc" : "bezier";
    }

    options_of(edge, runtime_by_id = null) {
        const preview = this.preview_reconnect_of(edge);
        const committed_options = this.committed_edge_options(edge, runtime_by_id);
        if (committed_options === null) {
            throw new Error("[kwiver-only] ui.connect_preview.options: runtime edge snapshot invalid");
        }
        if (preview === null || preview === undefined) {
            return committed_options;
        }

        return {
            ...committed_options,
            level: this.level_of(edge, runtime_by_id),
            shape: this.shape_of(edge, runtime_by_id),
        };
    }

    endpoint_edges(cell) {
        if (!this.edges_by_endpoint.has(cell)) {
            this.edges_by_endpoint.set(cell, new Set());
        }
        return this.edges_by_endpoint.get(cell);
    }

    register_cell(cell) {
        if (!cell?.is_edge?.()) {
            return;
        }
        this.register_edge_at_endpoints(
            cell,
            cell?.kwiver_projection_source?.(),
            cell?.kwiver_projection_target?.(),
        );
    }

    unregister_cell(cell) {
        this.unregister_edge_at_endpoints(
            cell,
            cell?.kwiver_projection_source?.(),
            cell?.kwiver_projection_target?.(),
        );
    }

    dependencies_of(cell, runtime_by_id = null) {
        const dependencies = new Map();
        for (const candidate of this.edges_by_endpoint.get(cell) || []) {
            if (this.source_of(candidate, runtime_by_id) === cell) {
                dependencies.set(candidate, "source");
            }
            if (this.target_of(candidate, runtime_by_id) === cell) {
                dependencies.set(candidate, "target");
            }
        }
        const preview_edge = this.preview_reconnect?.edge;
        if (preview_edge !== null && preview_edge !== undefined) {
            if (this.source_of(preview_edge, runtime_by_id) === cell) {
                dependencies.set(preview_edge, "source");
            }
            if (this.target_of(preview_edge, runtime_by_id) === cell) {
                dependencies.set(preview_edge, "target");
            }
        }
        return dependencies;
    }

    transitive_dependencies(cells, exclude_roots = false, runtime_by_id = null) {
        let closure = new Set(cells);
        for (const cell of closure) {
            this.dependencies_of(cell, runtime_by_id).forEach((_, dependency) => closure.add(dependency));
        }
        if (exclude_roots) {
            for (const cell of cells) {
                closure.delete(cell);
            }
        }
        closure = Array.from(closure);
        closure.sort((a, b) => this.level_of(a, runtime_by_id) - this.level_of(b, runtime_by_id));
        return new Set(closure);
    }

    update_edge_levels(edge, apply_level = null, levels = new Map(), runtime_by_id = null) {
        for (const cell of this.transitive_dependencies([edge], false, runtime_by_id)) {
            if (!cell.is_edge()) {
                continue;
            }
            const level = Math.max(
                this.level_of(this.source_of(cell, runtime_by_id), runtime_by_id),
                this.level_of(this.target_of(cell, runtime_by_id), runtime_by_id),
            ) + 1;
            levels.set(cell, level);
            if (apply_level !== null) {
                apply_level(cell, level);
            }
        }
        return levels;
    }

    with_temporary_reconnect(edge, source, target, callback) {
        const previous_preview = this.preview_reconnect;
        const runtime_by_id = this.runtime_cells_by_id();
        this.preview_reconnect = {
            edge,
            source,
            target,
            levels: new Map(),
        };
        this.update_edge_levels(edge, null, this.preview_reconnect.levels, runtime_by_id);

        try {
            return callback();
        } finally {
            this.preview_reconnect = previous_preview;
        }
    }
}

export { ConnectPreview };
