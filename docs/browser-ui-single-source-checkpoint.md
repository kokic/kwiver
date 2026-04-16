# Browser UI Single-Source Checkpoint

Updated: 2026-04-16

## Objective

Record the exact browser-UI migration state so the next session can continue directly without rediscovering architecture, partial refactors, or dead paths.

## Current Code Facts

- Product browser UI entrypoint remains `kwiver/browser_ui_upstream/ui.mjs`.
- Product import/export shell remains `kwiver/browser_ui_upstream/quiver.mjs`.
- Product bridge remains `kwiver/browser_ui_upstream/kwiver_bridge.mjs`.
- `kwiver_bridge_import_tikz_payload(...)` has been removed. Structured tikz import now goes only through `kwiver_bridge_import_tikz_result(...)`.
- `QuiverImportExport.base64.import(...)` has been removed from `browser_ui_upstream/quiver.mjs`.
- `Quiver::import_base64_v0(...)` no longer accepts the removed internal `EncodedQuiver` tuple shape; it imports the canonical JSON payload shape only.
- There is no remaining `ui.quiver` / `this.quiver` runtime-path usage in `browser_ui_upstream/ui.mjs` or `browser_ui_upstream/quiver.mjs`.
- Browser-side state in `ui.mjs` is now split into:
  - `bridge_quiver`: runtime-backed import/export shell
  - `ViewRegistry`: active DOM-backed cells and level buckets
  - `ConnectPreview`: connect/reconnect drag-time temporary dependency index

## What Has Already Been Migrated

### 1. Old JS graph container removed from product runtime paths

- `ui.mjs` now constructs:
  - `this.bridge_quiver = new Quiver()`
  - `this.view_registry = new ViewRegistry()`
  - `this.connect_preview = new ConnectPreview()`
- `browser_ui_upstream/quiver.mjs` no longer acts as the product UI's second graph owner. It is now a bridge/import-export shell.

### 2. Connect/reconnect temporary logic isolated

- `ConnectPreview` is the only local object allowed to maintain drag-time dependency/index state.
- `ConnectPreview` currently owns:
  - `dependencies_of(...)`
  - `transitive_dependencies(...)`
  - `set_endpoints(...)`
  - `update_edge_levels(...)`
  - `with_temporary_reconnect(...)`
  - `reconnect(...)`
- `valid_connection(...)` no longer mutates temporary `level` state directly in outer UI code. It now routes temporary reconnect simulation through `connect_preview.with_temporary_reconnect(...)`.
- `Edge.reconnect(...)` no longer directly mutates temporary `source/target/level` state in outer code. It now routes endpoint replacement and affected-level recomputation through `connect_preview`.

### 3. Runtime -> JS edge-option decoding now has one entrypoint

- Added `UI.kwiver_edge_options_from_runtime(runtime_options)`.
- Added `UI.kwiver_js_colours_equal(left, right)` for JS-to-JS colour comparison after decoding runtime options.
- `UI.kwiver_runtime_edge_matches(...)` now uses decoded runtime options instead of ad hoc field-by-field reads from raw runtime payload.

### 4. Runtime snapshot application is now centralized

- Added:
  - `UI.kwiver_apply_runtime_cell_level(...)`
  - `UI.kwiver_apply_runtime_label_colour(...)`
  - `UI.kwiver_apply_runtime_cell_snapshot(...)`
  - `UI.kwiver_apply_runtime_edge_snapshot(...)`
- `UI.kwiver_apply_runtime_cell_snapshot(...)` now owns committed vertex-field application for:
  - `level`
  - `label`
  - `label_colour`
  - `position`
- `UI.kwiver_apply_runtime_edge_snapshot(...)` now owns committed edge-field application for:
  - `level`
  - `label`
  - `label_colour`
  - `source`
  - `target`
  - `options`
- Direct non-history mutation success paths that rehydrate existing JS objects now route through the same helpers:
  - `kwiver_apply_connect_action(...)`
  - renderer bullet-label rewrite path in the renderer `<select>` change handler

### 5. History rehydration now routes through snapshot helpers

- `History.effect(...)` now validates runtime snapshots and applies them through the centralized helpers for:
  - `move`
  - `label`
  - `label_colour`
  - `label_alignment`
  - `label_position`
  - `offset`
  - `curve`
  - `radius`
  - `angle`
  - `length`
  - `level`
  - `style`
  - `colour`
  - `edge_alignment`
- Edge transform history paths (`reverse`, `flip`, `flip labels`) now validate against runtime and reapply committed edge snapshots through the same helper path.
- The history render-dependency pass now reapplies runtime edge snapshots before rerendering dependency closures, so render-time edge state is not left on partially transformed JS fields.

### 6. Panel style controls no longer stage committed style edits in live edge objects

- Tail/body/head style buttons now compute `from`/`to` style snapshots directly and commit them through `History.add(...)`.
- Edge-type buttons (`arrow`, `adjunction`, `corner`, `corner-inverse`) now compute target committed styles directly instead of mutating selected edges first and then sampling those JS objects to build history.
- The old panel-local `record_edge_style_change(...)` / `effect_edge_style_change(...)` staging path has been removed.
- Panel style buttons now also anchor their committed `from` baselines to runtime edge snapshots instead of reading `edge.options.style` as local truth.

### 7. Pointer-drag move commit now replays through runtime

- Pointer move still previews by moving local vertex views during drag.
- But on pointer release, the committed `move` history event is now invoked through runtime replay instead of being recorded as already-applied local state.
- This narrows the remaining move-related duplication to drag-time preview only.

### 8. Panel edge-option controls now take committed baselines from runtime

- Command/panel controls for:
  - `label_alignment`
  - `label_position`
  - `offset`
  - `curve`
  - `radius`
  - `angle`
  - `length`
  - `level`
  - endpoint-alignment toggles
  now derive their current committed baseline from runtime edge snapshots before constructing history actions.
- This removes another class of "JS view object as committed option owner" behavior from panel-driven editing.

### 9. Label / colour edit baselines now come from runtime

- Label input edits now compare against runtime cell labels and store runtime-backed `from` values before constructing `history.label` actions.
- Colour picker edits now derive:
  - label-colour `from` values from runtime cell snapshots
  - edge-colour `from` values from runtime edge snapshots
  - label/edge sync checkbox state from runtime colour equality
- Renderer bullet-label rewrite now also uses runtime label baselines before dispatching label updates.

### 10. Internal kwiver-compat cleanup for browser/runtime product paths is complete

- The dead bridge wrapper `kwiver_bridge_import_tikz_payload(...)` has been removed.
- Runtime/browser tests now use the structured bridge result `{ ok, payload, error }` directly.
- `kwiver_bridge_import_tikz_result(...)` fail-fast behavior is now treated as:
  - `ok === false`
  - `payload` is still the canonical payload for the unchanged runtime state
  - `error` carries parser/runtime diagnostics
- The dead browser-side constructor importer `QuiverImportExport.base64.import(...)` has been removed.
- The removed internal `EncodedQuiver` tuple branch is no longer accepted by `Quiver::import_base64_v0(...)`.
- Remaining `base64` compatibility in engine tests now refers only to upstream/original `quiver` payload conventions, not to prior `kwiver` internal formats.

## What Is Still Not Done

### 1. JS view objects still own committed semantic fields

- `Cell` / `Vertex` / `Edge` objects still carry committed fields such as:
  - `level`
  - `label`
  - `label_colour`
  - `source`
  - `target`
  - `options`
- This means JS is not yet a pure runtime projection.

### 2. Pre-commit UI code still mutates committed-looking fields locally

- Most of the obvious preview-time committed-field writes have now been removed.
- `pointer-drag` move preview no longer writes live `vertex.position`; temporary drag positions now live in `UIMode.PointerMove.preview_positions`.
- Temporary reconnect validation no longer rewrites live `edge.source`, `edge.target`, or `cell.level`.
- Active reconnect drag rendering now reads preview-owned endpoint/level/shape state via `ConnectPreview`, instead of assuming live `edge.source`, `edge.target`, `cell.level`, or `edge.options.shape` were temporarily rewritten.
- Remaining preview-state work is now mostly audit/cleanup rather than another large ownership cutover.

### 3. Runtime-backed fresh-cell hydration now materializes directly from runtime snapshots

- Direct UI create paths now add through runtime first and decode runtime snapshots before constructing `Vertex` / `Edge`.
- Runtime-backed paste, query bootstrap, and tikz import now materialize JS cells through `kwiver_import_runtime_cells(...)` directly from runtime cell snapshots.
- Product paths no longer depend on `QuiverImportExport.base64.import(...)` plus a later post-bind rehydrate step to recover canonical committed state.
- The old browser-side constructor-based `base64` importer has been removed from `browser_ui_upstream/quiver.mjs`; runtime payload import is now the only product path.

### 4. Browser helper-module replacement is explicitly deferred

- Replacing browser helper modules such as `browser_ui_upstream/ds.mjs` or `browser_ui_upstream/curve.mjs` with MoonBit-backed exports is not part of the current migration slice.
- If that work is resumed later, the preferred direction is to rewrite JS callsites to consume MoonBit-style data/function APIs directly.
- Do not spend current migration time exporting JS-class-compatible OOP wrappers from MoonBit just to preserve old helper-module shapes.
- Current priority remains product bug fixing plus deleting duplicated committed graph semantics from JS runtime paths.

## Exact Next Tasks

Before any helper-library/API work:

- Keep prioritizing browser bug fixes and single-source graph-semantics migration.
- Treat `ds.mjs` / `curve.mjs` replacement as deferred follow-up work, not a blocker for the current phase.
- When that deferred work starts, prefer changing JS callsites to accept MoonBit-style non-OOP APIs instead of adding MoonBit-side class/prototype compatibility shims.

### Priority 1

- Audit the remaining product shell in `browser_ui_upstream/quiver.mjs` and `browser_ui_upstream/kwiver_bridge.mjs` for any local reconstruction of committed state that is no longer needed after runtime-backed hydration.
- Start from:
  - `QuiverImportExport.tikz_cd.import(...)`
  - `QuiverImportExport.export(...)`
  - bridge import/export helpers that still normalize metadata or payloads for UI consumption
- For each candidate path, classify it as exactly one of:
  - required external/upstream compatibility surface
  - runtime projection/helper glue that still belongs in JS
  - dead product-path shell that can be deleted
- Do not add a new JS-side importer/rebuilder while simplifying these paths. If a path still needs cell materialization, route it through runtime snapshots and `kwiver_import_runtime_cells(...)`.
- Validation after each slice:
  - `node --check kwiver/browser_ui_upstream/quiver.mjs`
  - `node kwiver/browser_ui_upstream/tests/kwiver_bridge_smoke.test.mjs`
  - `node kwiver/browser_ui_upstream/tests/runtime_smoke_non_mock.test.mjs`

### Priority 2

- Audit remaining committed-looking JS field reads in `browser_ui_upstream/ui.mjs` and separate harmless projection reads from hidden semantic ownership.
- Start with `rg` over:
  - `cell.level`
  - `cell.label`
  - `cell.label_colour`
  - `edge.source`
  - `edge.target`
  - `edge.options`
- First-pass hotspots to inspect:
  - `panel.update(...)`
  - colour aggregation / palette helpers
  - selection-derived UI summaries
  - renderer-adjacent label/style helpers
- Rule for cleanup:
  - display-only reads are acceptable if they are obviously projection-only
  - any read that chooses a mutation baseline, history `from`, selection semantic, dependency semantic, or persistence/export semantic must come from runtime snapshot helpers instead
- Preferred implementation pattern:
  - add a focused runtime getter/helper if repeated
  - switch the callsite to runtime-backed baseline
  - delete the old local semantic fallback instead of keeping both

### Priority 3

- Keep preview-only regressions on a short leash while Priority 1 and Priority 2 continue.
- Highest-value targeted manual checks after any reconnect/import/export change:
  - reconnect normal edge -> edge reference closure remains visually stable
  - reconnect loop -> non-loop -> loop does not lose shape/level/rerender order
  - paste/import/share bootstrap still preserves loop geometry and explicit `level`
  - tikz import fail-fast still leaves runtime state unchanged and diagnostics usable
- Rebuild release artifact before browser testing if behavior looks stale:
  - `moon build --release`

## Archived Progress Snapshot (2026-04-16)

- Browser UI committed-state replay is now centralized on runtime snapshot helpers rather than ad hoc local field mutation.
- Connect/reconnect drag preview and pointer-drag move preview both use preview-owned state instead of rewriting committed-looking live fields during interaction.
- Fresh-cell creation, paste, query bootstrap, and tikz import now materialize cells from runtime snapshots rather than from payload-shaped local constructors.
- Loop creation and `base64` persistence regressions were fixed in runtime:
  - new self-loop edges now canonicalize to `shape_arc()` in runtime add-edge flow
  - persisted `shape=arc` and explicit `options.level` now survive save/refresh
- tikz export/import round-trip was repaired by:
  - passing `share_base_url` through the bridge
  - preserving loop geometry in share/base64 payload encoding
- Internal `kwiver` compatibility cleanup completed in this snapshot:
  - removed dead bridge tikz wrapper
  - removed dead browser-side base64 importer
  - removed internal `EncodedQuiver` import branch
- Current remaining work is no longer a broad architecture rewrite. It is a narrower audit of:
  - remaining shell code in `quiver.mjs` / `kwiver_bridge.mjs`
  - remaining hidden semantic reads in `ui.mjs`
  - targeted preview/import/export regressions found by browser testing

## Resume Checklist

1. Read:
   - `roadmap.md`
   - `kwiver/docs/browser-ui-single-source-checkpoint.md`
2. Run:
   - `node --check kwiver/browser_ui_upstream/ui.mjs`
   - `node --check kwiver/browser_ui_upstream/quiver.mjs`
   - `node kwiver/browser_ui_upstream/tests/kwiver_bridge_smoke.test.mjs`
   - `node kwiver/browser_ui_upstream/tests/runtime_smoke_non_mock.test.mjs`
   - `node kwiver/browser_ui_upstream/tests/parser_corpus_runtime_non_mock.test.mjs`
3. If browser behavior looks stale:
   - `moon build --release`
4. Resume from `Priority 1` above; do not reopen helper-module replacement or new compatibility-shim work first.

## Invariants To Preserve

- Do not reintroduce `ui.quiver` or `this.quiver` into product runtime paths.
- Do not add new sync shims or new dual-write ownership just to keep JS state "looking right".
- `ConnectPreview` must remain pre-commit drag logic only. It must not grow into a second committed graph model.
- Runtime -> JS edge option decoding must go through `UI.kwiver_edge_options_from_runtime(...)`.
- Do not export new MoonBit class-compatibility facades for `ds.mjs` / `curve.mjs` during the single-source graph migration phase just to keep old JS callsites unchanged.
- Keep using upstream behavior as the compatibility reference. Do not invent new browser-side semantics that upstream does not need.

## Recent Cleanup

- Removed dead local committed-state mutators `Edge.flip(...)` / `Edge.reverse(...)` from `ui.mjs`.
- Edge transform behavior now exists only in runtime/history replay plus transient render helpers, not as a second direct local mutation API on `Edge`.
- Panel edge-option/style controls now read committed baselines from runtime snapshots rather than from live `edge.options` fields.
- Label / colour edit paths now read committed baselines from runtime snapshots rather than from live `cell.label`, `cell.label_colour`, or `edge.options.colour` fields.
- `ConnectPreview.with_temporary_reconnect(...)` now keeps temporary reconnect endpoints/levels in preview-owned getters instead of rewriting live `edge.source`, `edge.target`, or `cell.level` during validation.
- `UIMode.PointerMove` now keeps drag-preview positions in `preview_positions`; pointer-drag preview no longer writes live `vertex.position` before runtime-confirmed move replay.
- `kwiver_create_vertex(...)` / `kwiver_create_edge(...)` now decode runtime snapshots after add and construct JS cells from runtime values rather than from local pre-runtime inputs.
- Runtime-backed paste/query bootstrap/tikz import now materialize JS cells directly from runtime snapshots via `kwiver_import_runtime_cells(...)`, instead of creating payload-shaped cells and repairing them afterwards.
- Active reconnect drag rendering now uses preview-owned endpoint/level/shape state during render, so dependent-edge preview no longer relies on live committed-looking endpoint/level mutation.

## Useful Entry Points

- `kwiver/browser_ui_upstream/ui.mjs`
  - `class ViewRegistry`
  - `class ConnectPreview`
  - `UI.kwiver_edge_options_from_runtime(...)`
  - `UI.kwiver_runtime_edge_matches(...)`
  - `History.effect(...)`
  - `Edge.reconnect(...)`
  - `UIMode.Connect.valid_connection(...)`
- `kwiver/browser_ui_upstream/quiver.mjs`
  - bridge-backed import/export shell

## Suggested Start Commands

Run from repo root:

```sh
node --check kwiver/browser_ui_upstream/ui.mjs
node kwiver/browser_ui_upstream/tests/kwiver_bridge_smoke.test.mjs
node kwiver/browser_ui_upstream/tests/runtime_smoke_non_mock.test.mjs
```

If browser runtime behavior looks stale in manual testing:

```sh
moon build --release
```
