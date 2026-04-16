# Browser UI Single-Source Checkpoint

Updated: 2026-04-16

## Objective

Record the exact browser-UI migration state so the next session can continue directly without rediscovering architecture, partial refactors, or dead paths.

## Current Code Facts

- Product browser UI entrypoint remains `kwiver/browser_ui_upstream/ui.mjs`.
- Product import/export shell remains `kwiver/browser_ui_upstream/quiver.mjs`.
- Product bridge remains `kwiver/browser_ui_upstream/kwiver_bridge.mjs`.
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

### 7. Pointer-drag move commit now replays through runtime

- Pointer move still previews by moving local vertex views during drag.
- But on pointer release, the committed `move` history event is now invoked through runtime replay instead of being recorded as already-applied local state.
- This narrows the remaining move-related duplication to drag-time preview only.

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

- Many interaction paths still write directly to JS view objects before runtime-confirmed history replay, especially:
  - edge transform helpers such as `Edge.flip(...)` / `Edge.reverse(...)`
  - command-mode edit actions that derive new values from JS object fields
  - pointer-drag move preview before committed move history is recorded
- Those writes are now reconciled from runtime after commit, but JS still behaves as a temporary owner of committed semantics during the interaction.

### 3. Fresh-cell construction still materializes committed state in JS constructors/importers

- `Vertex` / `Edge` constructors and base64 import/bootstrap paths still instantiate JS cells with committed semantic fields already populated.
- That keeps product behavior correct, but the browser view layer is still not a pure projection from runtime snapshots.

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

Audit and classify remaining direct JS writes to committed fields in `ui.mjs`.

Start with:

- command-mode edit actions
- `Edge.flip(...)`
- `Edge.reverse(...)`
- any remaining preview paths that leak committed-looking writes beyond transient interaction state

For each path, decide whether the write is:

- preview-only transient state that may remain local, or
- committed state that should move behind runtime-first mutation + snapshot reapply

### Priority 2

Convert one committed edit vertical slice to runtime-first ownership instead of JS-first local mutation.

Best next candidates:

- command-mode connect/transform/edit flows
- edge transform helpers used outside history replay

The target is:

- dispatch through runtime/history
- reapply selected cells from runtime snapshots
- stop treating mutated JS fields as the pre-commit source of truth

### Priority 3

Revisit fresh-cell hydration paths (`create`, `paste`, bootstrap/import) and decide whether they should normalize through runtime snapshot helpers or remain constructor-based until a later projection-only refactor.

## Invariants To Preserve

- Do not reintroduce `ui.quiver` or `this.quiver` into product runtime paths.
- Do not add new sync shims or new dual-write ownership just to keep JS state "looking right".
- `ConnectPreview` must remain pre-commit drag logic only. It must not grow into a second committed graph model.
- Runtime -> JS edge option decoding must go through `UI.kwiver_edge_options_from_runtime(...)`.
- Do not export new MoonBit class-compatibility facades for `ds.mjs` / `curve.mjs` during the single-source graph migration phase just to keep old JS callsites unchanged.
- Keep using upstream behavior as the compatibility reference. Do not invent new browser-side semantics that upstream does not need.

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
