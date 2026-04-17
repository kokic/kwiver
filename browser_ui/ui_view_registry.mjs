class ViewRegistry {
    constructor() {
        this.cells = [];
        this.levels_by_cell = new Map();
    }

    ensure_level(level) {
        while (this.cells.length <= level) {
            this.cells.push(new Set());
        }
        return this.cells[level];
    }

    level_of(cell) {
        const level = Number(this.levels_by_cell.get(cell));
        return Number.isInteger(level) ? level : null;
    }

    projection_level_of(cell) {
        const level = Number(cell?.kwiver_projection_level?.());
        return Number.isInteger(level) ? level : null;
    }

    add(cell, level = null) {
        const resolved_level = Number.isInteger(level) ? level : this.projection_level_of(cell);
        if (!Number.isInteger(resolved_level)) {
            return;
        }
        this.ensure_level(resolved_level).add(cell);
        this.levels_by_cell.set(cell, resolved_level);
    }

    contains_cell(cell) {
        const level = this.level_of(cell);
        return level !== null && this.cells[level]?.has(cell) === true;
    }

    all_cells() {
        const cells = [];
        for (const level of this.cells) {
            if (!(level instanceof Set)) {
                continue;
            }
            for (const cell of level) {
                cells.push(cell);
            }
        }
        return cells;
    }

    remove(cell) {
        const level = this.level_of(cell);
        if (level === null) {
            return;
        }
        this.cells[level]?.delete(cell);
        this.levels_by_cell.delete(cell);
    }

    update_level(cell, level) {
        if (!Number.isInteger(level)) {
            return;
        }
        this.ensure_level(level);
        const current_level = this.level_of(cell);
        if (current_level !== null) {
            this.cells[current_level]?.delete(cell);
        }
        this.levels_by_cell.set(cell, level);
        this.cells[level].add(cell);
    }
}

export { ViewRegistry };
