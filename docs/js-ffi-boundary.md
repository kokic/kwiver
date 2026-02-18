# JS FFI Boundary (Task 4)

This module freezes a first-pass browser integration surface around `Quiver`.

- Adapter implementation: `engine/quiver_ui_ffi.mbt`
- JS exported entrypoints: `engine/moon.pkg` -> `options.link.js.exports`

## State Model

- `QuiverUiAdapter` owns one mutable in-memory `Quiver`.
- JS/UI code keeps one adapter instance per editor tab/document.

## Import Calls

- `ffi_adapter_import_base64(adapter, payload) -> String`
- `ffi_adapter_import_share_url(adapter, input, default_renderer?) -> QuiverUiImportResult`
- `ffi_adapter_import_share_text(adapter, input, default_renderer?) -> QuiverUiImportResult`
- `ffi_adapter_import_text_auto(adapter, input, default_renderer?) -> QuiverUiImportResult`
- `ffi_adapter_import_tikz_cd(adapter, input, default_renderer?) -> QuiverUiImportResult`
- `ffi_adapter_import_fletcher(adapter, input, default_renderer?) -> QuiverUiImportResult`
- `ffi_adapter_import_html_embed(adapter, input, default_renderer?) -> QuiverUiImportResult`
- `ffi_adapter_paste_base64_selection(adapter, payload, origin_x, origin_y, start_id?) -> QuiverUiSelectionImportResult`

## Update Calls

- `ffi_adapter_add_vertex(adapter, label, x, y, label_colour?) -> Int`
- `ffi_adapter_add_edge(adapter, source_id, target_id, label?, options?, label_colour?) -> Int`
- `ffi_adapter_set_cell_label(adapter, cell_id, label) -> Bool`
- `ffi_adapter_set_cell_label_colour(adapter, cell_id, label_colour) -> Bool`
- `ffi_adapter_move_vertex(adapter, vertex_id, x, y) -> Bool`
- `ffi_adapter_set_edge_options(adapter, edge_id, options) -> Bool`
- `ffi_adapter_reconnect_edge(adapter, edge_id, source_id, target_id) -> Bool`
- `ffi_adapter_apply_mutation_batch(adapter, batch) -> QuiverUiMutationBatchResult`
- `ffi_adapter_apply_mutation_batch_json(adapter, batch_json) -> String`
- `ffi_adapter_remove(adapter, cell_id, when) -> Array[Int]`
- `ffi_adapter_flush(adapter, when)`
- `ffi_adapter_reset(adapter)`

## Render/Read Calls

- `ffi_adapter_all_cells(adapter) -> Array[CellData]`
- `ffi_adapter_all_cell_ids(adapter) -> Array[Int]`
- `ffi_adapter_snapshot(adapter) -> QuiverUiSnapshot`
- `ffi_adapter_snapshot_json(adapter) -> String`
- `ffi_adapter_dependencies_of(adapter, cell_id) -> Array[Int]`
- `ffi_adapter_reverse_dependencies_of(adapter, cell_id) -> Array[Int]`
- `ffi_adapter_transitive_dependencies(adapter, roots, exclude_roots?) -> Array[Int]`
- `ffi_adapter_transitive_reverse_dependencies(adapter, roots) -> Array[Int]`
- `ffi_adapter_connected_components(adapter, roots) -> Array[Int]`

## Export Calls

- `ffi_adapter_export_base64(adapter) -> String`
- `ffi_adapter_export_base64_selection(adapter, selected_ids, include_dependencies?) -> String`
- `ffi_adapter_export_tikz_cd(adapter, settings?, options?, definitions?) -> TikzCdExportResult`
- `ffi_adapter_export_fletcher(adapter, settings?, options?) -> String`
- `ffi_adapter_export_html_embed(adapter, settings, options?) -> String`

## Metadata Contracts

- `QuiverUiImportResult` returns `{ payload, macro_url, renderer, embed }`.
- `QuiverUiSelectionImportResult` returns `{ payload, imported_ids, id_remap }`.
- `QuiverUiMutationBatchResult` returns per-operation success arrays plus canonical `payload`.
- `ffi_adapter_apply_mutation_batch_json` accepts the same batch shape as `QuiverUiMutationBatch` in JSON and returns JSON-serialized `QuiverUiMutationBatchResult`.
- `QuiverUiSnapshot` returns canonical `payload`, ordered `cell_ids`, flattened `vertices`, flattened `edges` (with stringified option enums), and per-cell dependency adjacency.
- `ffi_adapter_snapshot_json` serializes the same snapshot shape into plain JSON for JS consumers that avoid MoonBit runtime data shapes.
- `id_remap` is sorted by `old_id` to keep deterministic JS-side patch application.
- Batch apply order is fixed: `labels -> label_colours -> vertex_positions -> edge_options -> edge_connections`.
