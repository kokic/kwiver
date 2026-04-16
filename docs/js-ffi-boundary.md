# JS FFI Boundary

This document tracks the current browser/runtime integration surface around `Quiver`.

Status note: the current implementation is transitional. The browser product no longer uses a top-level JS `ui.quiver` graph container in product runtime paths, but JS view objects still retain some graph semantics beside MoonBit runtime state. The highest-priority migration task remains making runtime the sole owner of committed diagram structure/history semantics.

- Adapter implementation: `engine/quiver_ui_ffi.mbt`
- JS exported entrypoints: `engine/moon.pkg` -> `options.link.js.exports`

## State Model

- `QuiverUiAdapter` owns one mutable in-memory `Quiver`.
- JS/UI code keeps one adapter instance per editor tab/document.
- Current reality: `browser_ui_upstream/ui.mjs` now splits browser-side state into:
  - `bridge_quiver`: runtime-backed import/export shell
  - `ViewRegistry`: active DOM-backed cells and level buckets
  - `ConnectPreview`: connect/reconnect drag-time temporary dependency index
- Remaining JS semantic ownership is now concentrated in view objects plus runtime snapshot rehydration paths (`History.effect`, mutation success handlers), not in a second top-level graph container.
- Target end-state: JS keeps only DOM/render/transient interaction state, while runtime owns graph topology, dependency relationships, selection semantics, and history semantics.
- Deferred API direction: if browser helper functionality such as `ds.mjs` / `curve.mjs` moves across the FFI later, JS should adapt to MoonBit-style data/function APIs instead of requiring MoonBit to export JS-compatible OOP/class facades.
- This helper-API refactor is not a current blocker. The present priority remains fixing browser regressions and deleting duplicated committed graph semantics from JS runtime paths.

Current browser-UI handoff/checkpoint: `docs/browser-ui-single-source-checkpoint.md`

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
- tikz-cd import is fail-fast: unknown arrow/label options, invalid colour expressions, unresolved endpoint references, and invalid loop/source-target combinations return `ok=false` instead of permissive fallback.
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

`browser_adapter/moon.pkg` is now intentionally minimal. JS exports only:

- `ffi_browser_runtime_new`
- `ffi_browser_runtime_dispatch_json_safe`

All runtime actions remain available through dispatch (`{ action, input? }`) and keep the same envelope contract:
`{ ok, action, result, payload, selection, error }`.

## Browser Demo Package (Runtime Layer)

`browser_demo/` is now a thin session wrapper dedicated to the product bridge.
`browser_demo/moon.pkg` exports only:

- `ffi_browser_demo_command_protocol`
- `ffi_browser_demo_session_new`
- `ffi_browser_demo_session_dispatch_command_json`

`dispatch_command_json` / `ffi_browser_demo_session_dispatch_command_json` provide the command-envelope wrapper used by JS shells:

- input: runtime dispatch envelope plus optional `origin` and `command_id`.
- output: `{ sequence, ok, action, protocol, origin, command_id, result, error, changed, undo_checkpoint, redo_checkpoint, before, after }`.
- `before` / `after` always include `{ payload, selection, cell_ids }`, and checkpoints are only non-null when `changed=true`.

## Browser UI Action->Command Mapping

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
- tikz text import: `kwiver_bridge_import_tikz_result` (structured `{ ok, payload, error }`)
- render/export text: `kwiver_bridge_export("tikz-cd"|"fletcher"|"html")` -> `render_tikz_json` / `render_fletcher` / `render_html_embed`
- base64 share export: `kwiver_bridge_export("base64")` -> `export_payload`
- graph snapshot/query sync: `kwiver_bridge_all_cells` / `kwiver_bridge_all_cell_ids` / `kwiver_bridge_connected_components` / `kwiver_bridge_dependencies` / `kwiver_bridge_transitive_dependencies` / `kwiver_bridge_transitive_reverse_dependencies` / `kwiver_bridge_reverse_dependencies` -> `all_cells_json` / `all_cell_ids_json` / `connected_components_json` / `dependencies_of_json` / `transitive_dependencies_json` / `transitive_reverse_dependencies_json` / `reverse_dependencies_of_json`
- lifecycle reset: `kwiver_bridge_reset` -> `reset`

Current invariants and migration rules:

- UI code must not call `ffi_browser_demo_session_dispatch_command_json` directly.
- every outbound envelope includes `{ protocol, command_id, origin }`.
- every accepted response must include matching `protocol`; missing/mismatch is rejected.
- bridge unavailability is fail-fast at startup, with candidate/load-error details in dev error text.
- tikz import fail-fast errors are surfaced to `quiver.mjs` as parser diagnostics (`message + optional line/column`) instead of a generic "bridge unavailable" error; parser/runtime fail-fast paths now include non-zero line/column for environment/body validation and unresolved-reference cases, so UI import panes receive a concrete `Parser.Range` caret for fragment highlighting; bridge diagnostics render kind labels (for example `Syntax` / `Option` / `Reference`) plus location badges (`Lx:Cy`) in the diagnostics list, and clicking or keyboard-activating a diagnostic entry moves the caret to its range (with Up/Down navigation across entries); highlighted source fragments are also clickable and jump back to the mapped diagnostic; with focus in the import textarea, `F8` / `Shift+F8` navigates next/previous diagnostic.
- The repository does not yet satisfy a single-source graph model. Some interaction paths still read/write JS view-side graph fields after runtime commits.
- No new graph semantics should be added to the JS local model. Migration work should delete JS graph ownership rather than add more synchronization shims.
- Do not expand the current FFI surface with MoonBit-side class/prototype compatibility wrappers for `ds.mjs` / `curve.mjs` just to preserve legacy JS helper callsites. If/when helper functionality moves, prefer changing JS callsites to the MoonBit API shape.
- Runtime -> JS edge option decoding must go through `UI.kwiver_edge_options_from_runtime(...)`; do not add new ad hoc `runtime_edge?.options?.field` parsing in history/mutation code.
- `ConnectPreview` is only for pre-commit connect/reconnect dragging. Do not expand it into a second committed graph model.
- Target end-state: JS view objects are runtime-backed projections, not an independent source of truth.

## Browser Bridge Smoke Checks (JS side)

`browser_ui_upstream/tests/kwiver_bridge_smoke.test.mjs` provides a lightweight JS smoke runner for bridge invariants:

- bridge unavailable path when autoload is disabled
- command response rejection when `protocol` is missing or mismatched
- outbound command envelope always carries `protocol` and `command_id`
- startup fail-fast error formatting includes `candidate` and first load error
- startup fail-fast formatting fallback uses `candidate=none` and `error=n/a`
- query wrappers dispatch runtime graph actions (`all_cell_ids_json` / `connected_components_json` / `dependencies_of_json` / `transitive_dependencies_json` / `transitive_reverse_dependencies_json` / `reverse_dependencies_of_json`)
- bridge-backed mutation/clipboard wrappers dispatch command envelopes (`selection/create/move/remove/edge/paste`)
- render wrappers dispatch runtime render actions (`render_tikz_json` / `render_fletcher` / `render_html_embed`)
- base64 share export pulls canonical payload from runtime `export_payload`
- reset action dispatches runtime `reset`
- reconnect, set-label, and patch-edge-options interactions dispatch runtime mutation commands

`browser_ui_upstream/tests/runtime_smoke_non_mock.test.mjs` adds a lightweight runtime-backed smoke path (no mock API):

- bridge autoload resolves a real built `browser_demo.js` artifact
- mutation/export/import roundtrip works through the runtime command entrypoint
- handwritten `tikz-cd` import path works through runtime dispatch
- invalid handwritten `tikz-cd` import fails fast and preserves runtime state
- graph query wrappers (`dependencies_of_json` / `connected_components_json` / `transitive_dependencies_json`) return runtime-backed arrays
- selection export/paste paths roundtrip through runtime command dispatch with deterministic ID remap start (`start_id`)

`browser_ui_upstream/tests/parser_corpus_runtime_non_mock.test.mjs` validates selected `parser.tex` fixtures through runtime import entrypoints:

- supported fixtures import successfully and produce non-empty payload/state
- fail-fast fixtures return `null` and preserve empty runtime state

Run:

```sh
node scripts/local_regression.mjs --smoke-only
```

A deferred manual browser checklist is tracked in `docs/browser-ui-manual-checklist.md`.
Run it after the single-source graph migration stabilizes.

## Browser UI Upstream (Product Shell)

The product UI surface is `browser_ui_upstream/`.

- entrypoint: `browser_ui_upstream/index.html`
- runtime bridge: `browser_ui_upstream/kwiver_bridge.mjs`
- interaction surface: `browser_ui_upstream/ui.mjs`
- import/export routing: `browser_ui_upstream/quiver.mjs`

It imports `../_build/js/debug/build/browser_demo/browser_demo.js` (or release build) and routes interactions through the command envelope.
