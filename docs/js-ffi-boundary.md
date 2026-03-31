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
- `ffi_adapter_import_share_url_json(adapter, input, default_renderer?) -> String`
- `ffi_adapter_import_share_text(adapter, input, default_renderer?) -> QuiverUiImportResult`
- `ffi_adapter_import_share_text_json(adapter, input, default_renderer?) -> String`
- `ffi_adapter_import_text_auto(adapter, input, default_renderer?) -> QuiverUiImportResult`
- `ffi_adapter_import_text_auto_json(adapter, input, default_renderer?) -> String`
- `ffi_adapter_import_tikz_cd(adapter, input, default_renderer?) -> QuiverUiImportResult`
- `ffi_adapter_import_tikz_cd_json(adapter, input, default_renderer?) -> String`
- `ffi_adapter_import_fletcher(adapter, input, default_renderer?) -> QuiverUiImportResult`
- `ffi_adapter_import_fletcher_json(adapter, input, default_renderer?) -> String`
- `ffi_adapter_import_html_embed(adapter, input, default_renderer?) -> QuiverUiImportResult`
- `ffi_adapter_import_html_embed_json(adapter, input, default_renderer?) -> String`
- `ffi_adapter_paste_base64_selection(adapter, payload, origin_x, origin_y, start_id?) -> QuiverUiSelectionImportResult`
- `ffi_adapter_paste_base64_selection_json(adapter, payload, origin_x, origin_y, start_id?) -> String`

## Update Calls

- `ffi_adapter_add_vertex(adapter, label, x, y, label_colour?) -> Int`
- `ffi_adapter_add_vertex_json(adapter, input_json) -> String`
- `ffi_adapter_add_edge(adapter, source_id, target_id, label?, options?, label_colour?) -> Int`
- `ffi_adapter_add_edge_json(adapter, input_json) -> String`
- `ffi_adapter_set_cell_label(adapter, cell_id, label) -> Bool`
- `ffi_adapter_set_cell_label_json(adapter, input_json) -> String`
- `ffi_adapter_set_cell_label_colour(adapter, cell_id, label_colour) -> Bool`
- `ffi_adapter_set_cell_label_colour_json(adapter, input_json) -> String`
- `ffi_adapter_move_vertex(adapter, vertex_id, x, y) -> Bool`
- `ffi_adapter_move_vertex_json(adapter, input_json) -> String`
- `ffi_adapter_set_edge_options(adapter, edge_id, options) -> Bool`
- `ffi_adapter_set_edge_options_json(adapter, input_json) -> String`
- `ffi_adapter_set_edge_label_alignment(adapter, edge_id, label_alignment) -> Bool`
- `ffi_adapter_set_edge_label_alignment_json(adapter, input_json) -> String`
- `ffi_adapter_set_edge_label_position(adapter, edge_id, label_position) -> Bool`
- `ffi_adapter_set_edge_label_position_json(adapter, input_json) -> String`
- `ffi_adapter_set_edge_offset(adapter, edge_id, offset) -> Bool`
- `ffi_adapter_set_edge_offset_json(adapter, input_json) -> String`
- `ffi_adapter_set_edge_curve(adapter, edge_id, curve) -> Bool`
- `ffi_adapter_set_edge_curve_json(adapter, input_json) -> String`
- `ffi_adapter_set_edge_shorten(adapter, edge_id, shorten_source, shorten_target) -> Bool`
- `ffi_adapter_set_edge_shorten_json(adapter, input_json) -> String`
- `ffi_adapter_reconnect_edge(adapter, edge_id, source_id, target_id) -> Bool`
- `ffi_adapter_reconnect_edge_json(adapter, input_json) -> String`
- `ffi_adapter_apply_mutation_batch(adapter, batch) -> QuiverUiMutationBatchResult`
- `ffi_adapter_apply_mutation_batch_json(adapter, batch_json) -> String`
- `ffi_adapter_remove(adapter, cell_id, when) -> Array[Int]`
- `ffi_adapter_remove_json(adapter, input_json) -> String`
- `ffi_adapter_flush(adapter, when)`
- `ffi_adapter_flush_json(adapter, input_json) -> String`
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
- `ffi_adapter_export_tikz_cd_json(adapter, settings?, options?, definitions?) -> String`
- `ffi_adapter_export_fletcher(adapter, settings?, options?) -> String`
- `ffi_adapter_export_html_embed(adapter, settings, options?) -> String`

## Metadata Contracts

- `QuiverUiImportResult` returns `{ ok, payload, macro_url, renderer, embed, error }`.
- `QuiverUiImportResult.error` is `null` on success, or `{ kind, message, line, column }` on typed import failure (currently used by strict tikz-cd import).
- `QuiverUiSelectionImportResult` returns `{ payload, imported_ids, id_remap }`.
- `*_json` import/paste wrappers serialize the same result contracts to plain JSON (`null` for absent optional fields).
- `add/remove/flush` JSON wrappers return payload-carrying JSON results for JS state sync (`add*`: `{id,payload}`, `remove`: `{removed_ids,payload}`, `flush`: `{payload}`).
- single mutation JSON wrappers (`set_label`, `set_label_colour`, `move_vertex`, `set_edge_options`, `patch_edge_options`, `set_edge_label_alignment`, `set_edge_label_position`, `set_edge_offset`, `set_edge_curve`, `set_edge_shorten`, `reconnect_edge`) return `{ ok, payload }`.
- `QuiverUiMutationBatchResult` returns per-operation success arrays plus canonical `payload`.
- `ffi_adapter_apply_mutation_batch_json` accepts the same batch shape as `QuiverUiMutationBatch` in JSON and returns JSON-serialized `QuiverUiMutationBatchResult`.
- `ffi_adapter_export_tikz_cd_json` serializes `{ data, metadata }` where `metadata.dependencies` stays in set-like object form (`package -> { reason: true }`).
- `QuiverUiSnapshot` returns canonical `payload`, ordered `cell_ids`, flattened `vertices`, flattened `edges` (with stringified option enums), and per-cell dependency adjacency.
- `ffi_adapter_snapshot_json` serializes the same snapshot shape into plain JSON for JS consumers that avoid MoonBit runtime data shapes.
- `id_remap` is sorted by `old_id` to keep deterministic JS-side patch application.
- Batch apply order is fixed: `labels -> label_colours -> vertex_positions -> edge_options -> edge_connections`.

## Browser Runtime JS Exports

`browser_adapter/moon.pkg` now exports a thin runtime entrypoint layer for JS:

- lifecycle/selection: `ffi_browser_runtime_new`, `ffi_browser_runtime_reset`, `ffi_browser_runtime_set_selection`, `ffi_browser_runtime_selection`
- graph queries: `ffi_browser_runtime_all_cell_ids`, `ffi_browser_runtime_all_cells`, `ffi_browser_runtime_all_cells_json`, `ffi_browser_runtime_all_cell_ids_json`, `ffi_browser_runtime_dependencies_of`, `ffi_browser_runtime_dependencies_of_json`, `ffi_browser_runtime_reverse_dependencies_of`, `ffi_browser_runtime_reverse_dependencies_of_json`, `ffi_browser_runtime_transitive_dependencies`, `ffi_browser_runtime_transitive_dependencies_json`, `ffi_browser_runtime_transitive_reverse_dependencies`, `ffi_browser_runtime_transitive_reverse_dependencies_json`, `ffi_browser_runtime_connected_components`, `ffi_browser_runtime_connected_components_json`
- add/remove/flush: `ffi_browser_runtime_add_vertex_json`, `ffi_browser_runtime_add_edge_json`, `ffi_browser_runtime_remove_json`, `ffi_browser_runtime_flush_json`
- single mutation json wrappers: `ffi_browser_runtime_set_label_json`, `ffi_browser_runtime_set_label_colour_json`, `ffi_browser_runtime_move_vertex_json`, `ffi_browser_runtime_set_edge_options_json`, `ffi_browser_runtime_patch_edge_options_json`, `ffi_browser_runtime_set_edge_label_alignment_json`, `ffi_browser_runtime_set_edge_label_position_json`, `ffi_browser_runtime_set_edge_offset_json`, `ffi_browser_runtime_set_edge_curve_json`, `ffi_browser_runtime_set_edge_shorten_json`, `ffi_browser_runtime_reconnect_edge_json`
- batch update: `ffi_browser_runtime_apply_mutation_batch_json`
- action dispatch: `ffi_browser_runtime_dispatch_json_safe`, `ffi_browser_runtime_dispatch_many_json_safe`, and compatibility aliases `ffi_browser_runtime_dispatch_json`, `ffi_browser_runtime_dispatch_many_json`
- import wrappers: `ffi_browser_runtime_import_payload`, `ffi_browser_runtime_import_text_auto_json`, `ffi_browser_runtime_import_share_url_json`, `ffi_browser_runtime_import_share_text_json`, `ffi_browser_runtime_import_tikz_cd_json`, `ffi_browser_runtime_import_fletcher_json`, `ffi_browser_runtime_import_html_embed_json`
- export/render: `ffi_browser_runtime_export_payload`, `ffi_browser_runtime_export_selection`, `ffi_browser_runtime_render_tikz`, `ffi_browser_runtime_render_tikz_json`, `ffi_browser_runtime_render_fletcher`, `ffi_browser_runtime_render_html_embed`
- snapshot/paste: `ffi_browser_runtime_snapshot_json`, `ffi_browser_runtime_paste_selection_json`

`ffi_browser_runtime_dispatch_json_safe` accepts `{ action|type, input?, default_renderer?, include_dependencies? }` and returns `{ ok, action, result, payload, selection, error }`.
It supports mutation/import/export actions plus graph-query actions (`dependencies_of_json`, `reverse_dependencies_of_json`, `transitive_dependencies_json`, `transitive_reverse_dependencies_json`, `connected_components_json`) and lifecycle/render actions:
- Includes partial edge patch mutation action `patch_edge_options_json` for sparse options updates.
- `reset`
- `import_payload` (`input` can be raw payload string, payload object, or payload json scalar)
- `render_tikz_json` (`input.settings` + `input.options` + `input.definitions.colours`, with shorthand fallback to flat keys)
- `render_fletcher` (`input.settings` + `input.options`)
- `render_html_embed` (`input.settings` + `input.options`, fixed/dynamic size inferred from `fixed_size` or width/height presence)
- `render_tikz` (string output)
- `export_selection` with `include_dependencies` accepted in either top-level envelope or `input`
- For `import_*_json` actions, if nested import result has `ok=false`, dispatch promotes it to top-level `{ ok:false, error:<message> }` while preserving current payload/selection.
The FFI wrapper is safe for JS callers: malformed envelope JSON and decode failures are converted into `{ ok: false, ... }` error payloads instead of raising.

`ffi_browser_runtime_dispatch_many_json_safe` accepts either:
- `Array[DispatchEnvelope]`
- `{ actions: Array[DispatchEnvelope], stop_on_error?: Bool }`
and returns `{ ok, processed, results, payload, selection, error }`, where each `results[i]` is the same contract as `dispatch_json`.
For malformed batch JSON, the wrapper returns `{ ok: false, processed: 0, results: [], ... }` with a non-null `error`.

`ffi_browser_runtime_dispatch_json` and `ffi_browser_runtime_dispatch_many_json` are preserved as aliases to the corresponding `*_safe` entrypoints for JS compatibility.

This keeps browser code on plain JSON contracts while reusing `BrowserRuntime` state-management semantics.

## Browser Demo Package (Task 6 runtime layer)

A thin integration package now exists at `browser_demo/` to exercise a UI-loop style flow on top of `ffi_browser_runtime_dispatch_json` and `ffi_browser_runtime_dispatch_many_json`.

- `BrowserDemoSession` wraps a runtime instance and caches `{ payload, selection }` from dispatch envelopes.
- `BrowserDemoSession::state_json()` provides a small JS-friendly state snapshot (`payload`, `selection`, `cell_ids`).
- `BrowserDemoSession` also exposes typed helper methods above dispatch envelopes:
  - `add_vertex`
  - `add_edge`
  - `set_label`
  - `set_label_colour`
  - `set_label_colour_hsla`
  - `set_edge_options_json`
  - `set_edge_label_alignment`
  - `set_edge_label_position`
  - `set_edge_offset`
  - `set_edge_curve`
  - `set_edge_shorten`
  - `reconnect_edge`
  - `move_vertex`
  - `patch_edge_options_json`
  - `apply_mutation_batch`
  - `apply_mutation_batch_json`
  - `remove`
  - `flush`
  - `dependencies_of`
  - `reverse_dependencies_of`
  - `transitive_dependencies`
  - `transitive_reverse_dependencies`
  - `connected_components`
  - `apply_selection`
  - `export_selection`
  - `paste_selection`
  - `paste_selection_result`
  - `import_payload`
  - `import_text_auto`
  - `import_text_auto_result`
  - `import_share_url`
  - `import_share_url_result`
  - `import_tikz_cd`
  - `import_tikz_cd_result`
  - `import_fletcher`
  - `import_fletcher_result`
  - `import_html_embed`
  - `import_html_embed_result`
  - `import_share_text`
  - `import_share_text_result`
  - `reset`
  - `dispatch_json_safe`
  - `dispatch_many_json_safe`
  - `dispatch_command_json`
  - `all_cells`
  - `all_cells_json`
  - `all_cell_ids`
  - `render_tikz`
  - `render_tikz_result`
  - `render_tikz_result_with_config`
  - `render_tikz_result_with_input`
  - `render_tikz_json`
  - `render_tikz_result_json`
  - `render_fletcher`
  - `render_fletcher_with_config`
  - `render_fletcher_with_input`
  - `render_html_embed`
  - `render_html_embed_with_config`
  - `render_html_embed_with_input`
  - `snapshot_json`
  - `snapshot`
- JS exports in `browser_demo/moon.pkg`:
  - `ffi_browser_demo_session_new`
  - `ffi_browser_demo_session_dispatch_json`
  - `ffi_browser_demo_session_dispatch_json_safe`
  - `ffi_browser_demo_session_dispatch_many_json`
  - `ffi_browser_demo_session_dispatch_many_json_safe`
  - `ffi_browser_demo_session_dispatch_command_json`
  - `ffi_browser_demo_session_add_vertex`
  - `ffi_browser_demo_session_add_edge`
  - `ffi_browser_demo_session_set_label`
  - `ffi_browser_demo_session_set_label_colour_hsla`
  - `ffi_browser_demo_session_set_edge_options_json`
  - `ffi_browser_demo_session_set_edge_label_alignment`
  - `ffi_browser_demo_session_set_edge_label_position`
  - `ffi_browser_demo_session_set_edge_offset`
  - `ffi_browser_demo_session_set_edge_curve`
  - `ffi_browser_demo_session_set_edge_shorten`
  - `ffi_browser_demo_session_reconnect_edge`
  - `ffi_browser_demo_session_move_vertex`
  - `ffi_browser_demo_session_patch_edge_options_json`
  - `ffi_browser_demo_session_remove`
  - `ffi_browser_demo_session_flush`
  - `ffi_browser_demo_session_apply_mutation_batch_demo_json`
  - `ffi_browser_demo_session_apply_mutation_batch_json`
  - `ffi_browser_demo_session_dependencies_of`
  - `ffi_browser_demo_session_reverse_dependencies_of`
  - `ffi_browser_demo_session_transitive_dependencies`
  - `ffi_browser_demo_session_transitive_reverse_dependencies`
  - `ffi_browser_demo_session_connected_components`
  - `ffi_browser_demo_session_set_selection`
  - `ffi_browser_demo_session_export_selection`
  - `ffi_browser_demo_session_paste_selection`
  - `ffi_browser_demo_session_paste_selection_result_json`
  - `ffi_browser_demo_session_import_payload`
  - `ffi_browser_demo_session_reset`
  - `ffi_browser_demo_session_all_cells`
  - `ffi_browser_demo_session_all_cells_json`
  - `ffi_browser_demo_session_all_cell_ids`
  - `ffi_browser_demo_session_import_text_auto`
  - `ffi_browser_demo_session_import_text_auto_result_json`
  - `ffi_browser_demo_session_import_share_url`
  - `ffi_browser_demo_session_import_share_url_result_json`
  - `ffi_browser_demo_session_import_tikz_cd`
  - `ffi_browser_demo_session_import_tikz_cd_result_json`
  - `ffi_browser_demo_session_import_fletcher`
  - `ffi_browser_demo_session_import_fletcher_result_json`
  - `ffi_browser_demo_session_import_html_embed`
  - `ffi_browser_demo_session_import_html_embed_result_json`
  - `ffi_browser_demo_session_import_share_text`
  - `ffi_browser_demo_session_import_share_text_result_json`
  - `ffi_browser_demo_session_render_tikz`
  - `ffi_browser_demo_session_render_tikz_json`
  - `ffi_browser_demo_session_render_tikz_result_json`
  - `ffi_browser_demo_session_render_tikz_result_with_input_json`
  - `ffi_browser_demo_session_render_fletcher`
  - `ffi_browser_demo_session_render_fletcher_with_input`
  - `ffi_browser_demo_session_render_html_embed`
  - `ffi_browser_demo_session_render_html_embed_with_input`
  - `ffi_browser_demo_session_snapshot_json`
  - `ffi_browser_demo_session_state_json`
  - `ffi_browser_demo_roundtrip_demo_json`

This package is intentionally minimal and acts as an end-to-end reference for wiring add/remove/import/export roundtrips via JSON action envelopes.
`import_text_auto` now recognizes both `\begin{tikzcd}...\end{tikzcd}` and `\begin{tikzcd*}...\end{tikzcd*}` handwritten inputs.
`BrowserDemoImportResult` JSON now includes `{ ok, payload, macro_url, renderer, embed, error }`, where `error` is a top-level runtime error string when import dispatch fails.
Task 8 Step 5 adds `dispatch_command_json` / `ffi_browser_demo_session_dispatch_command_json` as a stable command-envelope wrapper for JS shells:

- input: runtime dispatch envelope plus optional `origin` and `command_id`.
- output: `{ sequence, ok, action, origin, command_id, result, error, changed, undo_checkpoint, redo_checkpoint, before, after }`.
- `before` / `after` always include `{ payload, selection, cell_ids }`, and checkpoints are only non-null when `changed=true`.

## Browser UI Action->Command Mapping (runtime-first)

`browser_ui_upstream/ui.mjs` must route interaction entrypoints through `browser_ui_upstream/kwiver_bridge.mjs`.
The bridge is the only JS owner of command-envelope dispatch.

- create vertex: `kwiver_bridge_add_vertex_json` -> `add_vertex_json`
- create edge: `kwiver_bridge_add_edge_json` -> `add_edge_json`
- move vertex: `kwiver_bridge_move_vertex_json` -> `move_vertex_json`
- set label: `kwiver_bridge_set_label_json` -> `set_label_json`
- set label colour: `kwiver_bridge_set_label_colour_json` -> `set_label_colour_json`
- reconnect edge: `kwiver_bridge_reconnect_edge_json` -> `reconnect_edge_json`
- remove: `kwiver_bridge_remove_json` -> `remove_json`
- edge option updates: `kwiver_bridge_set_edge_offset_json` / `kwiver_bridge_set_edge_curve_json` / `kwiver_bridge_set_edge_label_alignment_json` / `kwiver_bridge_set_edge_label_position_json` / `kwiver_bridge_patch_edge_options_json`
- edge transforms: `kwiver_bridge_reverse_edge_json` / `kwiver_bridge_flip_edge_json` / `kwiver_bridge_flip_edge_labels_json`
- selection sync and clipboard payload: `kwiver_bridge_set_selection` / `kwiver_bridge_export_selection` / `kwiver_bridge_paste_selection_json`
- payload import: `kwiver_bridge_import_payload_json` -> `import_payload`
- render/export text: `kwiver_bridge_export("tikz-cd"|"fletcher"|"html")` -> `render_tikz_json` / `render_fletcher` / `render_html_embed`
- base64 share export: `kwiver_bridge_export("base64")` -> `export_payload`
- graph snapshot/query sync: `kwiver_bridge_all_cells` / `kwiver_bridge_all_cell_ids` / `kwiver_bridge_connected_components` / `kwiver_bridge_dependencies` / `kwiver_bridge_transitive_dependencies` / `kwiver_bridge_transitive_reverse_dependencies` / `kwiver_bridge_reverse_dependencies` -> `all_cells_json` / `all_cell_ids_json` / `connected_components_json` / `dependencies_of_json` / `transitive_dependencies_json` / `transitive_reverse_dependencies_json` / `reverse_dependencies_of_json`
- lifecycle reset: `kwiver_bridge_reset` -> `reset`

Runtime-first invariants:

- UI code must not call `ffi_browser_demo_session_dispatch_command_json` directly.
- every outbound envelope includes `{ protocol, command_id, origin }`.
- every accepted response must include matching `protocol`; missing/mismatch is rejected.
- dependency query paths used by interactions are runtime-only and fail-fast (`dependencies_of_json` / `transitive_dependencies_json` / `reverse_dependencies_of_json`); no local graph-query fallback.
- bridge unavailability is fail-fast at startup, with candidate/load-error details in dev error text.
- JS model updates are derived from runtime payload/snapshot results, not treated as independent source of truth.

## Browser Bridge Smoke Checks (JS side)

`browser_ui_upstream/tests/kwiver_bridge_smoke.test.mjs` provides a lightweight JS smoke runner for bridge invariants:

- bridge unavailable path when autoload is disabled
- command response rejection when `protocol` is missing or mismatched
- outbound command envelope always carries `protocol` and `command_id`
- startup fail-fast error formatting includes `candidate` and first load error
- startup fail-fast formatting fallback uses `candidate=none` and `error=n/a`
- query wrappers dispatch runtime graph actions (`all_cell_ids_json` / `connected_components_json` / `dependencies_of_json` / `transitive_dependencies_json` / `transitive_reverse_dependencies_json` / `reverse_dependencies_of_json`)
- runtime-first interaction wrappers dispatch command envelopes (`selection/create/move/remove/edge/paste`)
- render wrappers dispatch runtime render actions (`render_tikz_json` / `render_fletcher` / `render_html_embed`)
- base64 share export pulls canonical payload from runtime `export_payload`
- reset action dispatches runtime `reset`
- reconnect, set-label, and patch-edge-options interactions dispatch runtime mutation commands

Run:

```sh
node browser_ui_upstream/tests/kwiver_bridge_smoke.test.mjs
```

## Runnable Browser UI Demo (Task 6 deliverable)

A runnable static UI demo is provided in `browser_ui_demo/`:

- `browser_ui_demo/index.html`
- `browser_ui_demo/app.js`
- `browser_ui_demo/styles.css`

It imports `../_build/js/debug/build/browser_demo/browser_demo.js` directly in the browser and exercises the real loop:

- add/remove/connect
- selection export/paste
- import payload / import text auto
- render outputs (`tikz-cd`, `fletcher`, `html embed`)
- dependency closures and connected component query

Task 8 Step 1 extends this demo with a formal editor-shell layout and a unified JS command pipeline (`dispatchCommand`) so UI actions and JSON inspector actions share one command route.
Task 8 Step 2 adds gesture wiring on top of the same pipeline: canvas click add, node drag move, shift-drag connect, keyboard delete, and undo/redo skeleton.
Task 8 Step 3 further aligns interaction semantics with q.uiver: box selection, multi-vertex drag, refined curved connect preview with endpoint clipping, edge hit selection, and inline label quick edit.
Task 8 Step 4 adds editor keyboard/clipboard shortcuts on the same command pipeline (`Ctrl/Cmd+A/C/X/V`) with system clipboard integration and local fallback payload buffer.
Task 8 Step 5 adds a stable command-envelope + checkpoint contract in `browser_demo` for production JS shells to route commands and own undo/redo with deterministic payload checkpoints.
