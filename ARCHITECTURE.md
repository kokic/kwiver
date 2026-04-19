# Project Architecture Design Document

## 1. Purpose

`kwiver` is a MoonBit-based reimplementation of the Quiver commutative diagram editor. The project is organized around a canonical graph/model core in MoonBit, a browser-facing runtime/session layer, and a browser UI shell that is currently being migrated away from duplicated graph ownership.

This document describes the architecture as implemented in the repository today, not an idealized target state.

## 2. Repository Architecture at a Glance

```text
+---------------------------+
| browser_ui/               |
| Upstream-style UI shell   |
| DOM, rendering, input     |
+-------------+-------------+
              |
              | JS bridge wrappers
              v
+---------------------------+
| runtime/                  |
| BrowserRuntime            |
| command protocol/session  |
| geometry FFI exports      |
+-------------+-------------+
              |
              | calls adapter + geometry
              v
+-------------+-------------+------------------+
| engine/                   | geometry/        |
| canonical diagram model   | pure arrow math  |
| import/export             | layout/render    |
| snapshot/query adapters   | plans            |
+---------------------------+------------------+
```

### Main packages

| Package | Role |
| --- | --- |
| `engine/` | Canonical domain model, graph semantics, import/export, UI adapter APIs |
| `geometry/` | Pure geometric computation for curves, clipping, label placement, and SVG render plans |
| `runtime/` | Browser-oriented facade over `engine` and `geometry`; command dispatch, session envelopes, JSON contracts |
| `browser_ui/` | Product UI shell, runtime bridge, DOM rendering, interaction handling, smoke tests |
| `scripts/` | Local regression orchestration and parser corpus synchronization |
| `docs/` | Developer guides, maintenance procedures, and browser/runtime boundary notes |

The root package is intentionally minimal; implementation lives in subpackages.

## 3. Architectural Intent

The current design follows four primary ideas:

1. **Canonical committed state lives in MoonBit.** The authoritative diagram model is the `Quiver` graph in `engine/`.
2. **The browser talks to MoonBit through explicit contracts.** The preferred browser-facing API is the runtime command/session layer in `runtime/`, not ad hoc direct access to core model internals.
3. **Geometry is isolated from product workflow code.** Arrow path generation, clipping, label placement, and local render planning are kept in `geometry/` and exposed as pure helpers.
4. **The browser UI is transitional.** `browser_ui/` still carries view-side graph semantics in some paths, but the stated migration direction is to keep only rendering and transient interaction state in JS.

## 4. Package Responsibilities

### 4.1 `engine/`: Domain Core and Compatibility Layer

`engine/` is the architectural center of the system.

Its responsibilities are:

- defining the diagram data model
- maintaining graph topology and dependency relationships
- applying mutations such as add, reconnect, relabel, remove, and option changes
- importing and exporting supported formats
- exposing UI-oriented snapshots and query results
- providing a JS/MoonBit FFI-friendly adapter surface

Key files:

- `engine/quiver_model.mbt`: core `Quiver` graph and dependency management
- `engine/cell.mbt`: `Cell`, `Vertex`, `Edge`, `CellData`
- `engine/edge_options.mbt`: edge geometry/style configuration
- `engine/quiver_base64.mbt`: canonical payload/share URL encoding and decoding
- `engine/quiver_export_tikz.mbt`: `tikz-cd` export
- `engine/quiver_export_tikz_parser.mbt`: strict `tikz-cd` import/parser
- `engine/quiver_preview.mbt`: reconnect preview and edge option suggestion logic
- `engine/quiver_ui_ffi.mbt`: adapter, snapshots, JSON results, JS export boundary
- `engine/quiver_ui_selection_summary.mbt`, `engine/quiver_ui_selection_state.mbt`: UI-specific derived query state

### 4.2 `geometry/`: Pure Arrow Geometry

`geometry/` depends on `engine/` types but is conceptually independent of editor workflow.

Its responsibilities are:

- curve modelling for Bezier and arc arrows
- endpoint clipping against shapes
- label position calculation
- SVG path and decoration planning for arrow rendering

Key files:

- `geometry/arrow_curve_model.mbt`: curve abstraction and sampling
- `geometry/arrow_layout.mbt`: clipped endpoints and label positioning
- `geometry/arrow_render_plan.mbt`: complete local render plan for arrows
- `geometry/engine_aliases.mbt`: type aliases back to `engine` primitives

This separation is important: the browser and runtime can reuse the same geometry rules without embedding them into UI logic.

### 4.3 `runtime/`: Browser Service Facade

`runtime/` turns `engine` and `geometry` into a browser-consumable service boundary.

Its responsibilities are:

- wrapping the adapter in a browser runtime object
- tracking browser-oriented selection state
- dispatching string-based JSON actions
- normalizing import/export options and result shapes
- exposing a versioned command-envelope protocol
- exporting geometry helpers for the browser renderer

Key files:

- `runtime/runtime.mbt`: `BrowserRuntime`, action dispatch, JSON-safe command handling
- `runtime/session.mbt`: `BrowserDemoSession`, protocol validation, before/after state envelopes
- `runtime/curve_ffi.mbt`: Bezier/arc geometry exports
- `runtime/arrow_geometry_ffi.mbt`: arrow endpoint, label, and render-plan exports

### 4.4 `browser_ui/`: Product Shell and Bridge

`browser_ui/` is the browser product layer. It is not the source of truth for committed diagram structure, but it still contains temporary view-side semantics while the migration is incomplete.

Its responsibilities are:

- mounting the editor and owning DOM/render state
- loading the built runtime artifact
- mapping UI interactions to runtime commands
- hydrating view objects from runtime snapshots/results
- providing smoke tests for runtime integration

Key files:

- `browser_ui/ui.mjs`: primary interaction surface
- `browser_ui/kwiver_bridge.mjs`: runtime autoload, typed wrappers, command dispatch
- `browser_ui/bridge_startup.mjs`: fail-fast bridge startup diagnostics
- `browser_ui/quiver.mjs`: import/export routing in the product shell
- `browser_ui/tests/*.test.mjs`: bridge and runtime smoke tests

## 5. Core Domain Model

### 5.1 Graph Representation

The canonical model is `Quiver` in `engine/quiver_model.mbt`.

It stores:

- `cells_by_level`: ordered buckets of cell IDs by level
- `cells`: all `CellData` records by ID
- `dependencies`: forward dependency edges
- `reverse_dependencies`: reverse adjacency for traversal and deletion impact
- `deleted`: tombstones with timestamps for deferred deletion

This is not just a drawing container. It is a dependency graph with structural semantics.

### 5.2 Cell Types

The basic model types are:

- `Vertex`: grid-positioned node with label and label colour
- `Edge`: connection between source and target cell IDs plus `EdgeOptions`
- `CellData`: tagged union of `Vertex` or `Edge`

`Cell.level` is structural, while `Edge.options.level` can carry format-level overrides. The code intentionally preserves this distinction during some import/export compatibility paths.

### 5.3 Edge Configuration

`EdgeOptions` is the main styling and geometry contract for edges. It combines:

- label alignment and position
- parallel offset
- Bezier curve amount or arc radius/angle
- shortening
- logical level
- shape kind (`Bezier` or `Arc`)
- colour
- endpoint alignment rules
- style tokens for tail/body/head

This makes `EdgeOptions` the shared contract between:

- domain editing
- import/export compatibility
- preview planning
- geometry layout
- runtime/browser JSON serialization

### 5.4 Dependency Semantics

Edges can depend on vertices or other edges. The model therefore supports:

- direct dependencies
- reverse dependencies
- transitive dependency closure
- transitive reverse dependency closure
- connected-component expansion

Deletion is two-phase:

1. `remove(cell_id, when)` marks the cell and its dependent closure as deleted.
2. `flush(when)` physically removes tombstoned entries and rewrites adjacency.

This design supports delayed cleanup and UI workflows that need a removal timestamp barrier.

## 6. Important Subsystems

### 6.1 Import and Export

The engine supports multiple serialization/interchange paths:

- base64 payload/state export and import
- share URL and share text parsing
- `tikz-cd` export
- strict `tikz-cd` import
- Fletcher export/import
- HTML embed export/import
- selection export/paste

Notable characteristics:

- Base64 payload is the canonical compact serialization used for sync and checkpoints.
- `tikz-cd` import is fail-fast rather than permissive for malformed options and unresolved references.
- Export paths also return metadata, such as TikZ incompatibilities and package dependencies.

### 6.2 UI Adapter Layer

`QuiverUiAdapter` in `engine/quiver_ui_ffi.mbt` is the compatibility boundary between the raw graph model and UI consumers.

It provides:

- mutation wrappers
- snapshot generation
- dependency queries
- selection-oriented exports
- import result normalization
- JSON-shaped wrappers for JS consumers

Important adapter DTOs include:

- `QuiverUiImportResult`
- `QuiverUiSelectionImportResult`
- `QuiverUiSnapshot`
- `QuiverUiMutationBatchResult`

### 6.3 Selection-Derived State

The engine computes UI-facing derived state rather than forcing the browser to recalculate everything.

Two key outputs are:

- `QuiverUiSelectionSummary`: connected components and dependency closures for a selection
- `QuiverUiSelectionPanelState` / `QuiverUiSelectionToolbarState`: aggregated panel/toolbar state, unanimous values, capability flags, and edge-specific controls

This reduces duplicated reasoning in the browser layer and helps move committed semantics into MoonBit.

### 6.4 Preview and Suggestion Logic

`engine/quiver_preview.mbt` provides higher-level graph reasoning for interactive editing:

- reconnect preview plans that propagate structural level changes through dependent edges
- automatic edge option suggestions for parallel edges and loops

This is notable because it keeps editing heuristics close to the canonical graph rather than in browser-only code.

### 6.5 Geometry and Render Planning

`geometry/` takes the domain model and converts it into renderable geometry.

The main progression is:

1. `ArrowCurveModel`: represent the mathematical curve
2. `ArrowLayout`: clip the curve to source/target shapes and compute label placement
3. `arrow_render_plan_local`: emit an SVG-oriented render plan with body, heads, masks, clipping path, and decorations

This render-plan approach is stronger than ad hoc string building in the UI because it keeps geometry deterministic and testable.

## 7. Runtime Protocol and Browser Integration

### 7.1 Browser Runtime

`BrowserRuntime` in `runtime/runtime.mbt` owns:

- one `QuiverUiAdapter`
- browser-side selected IDs

It exposes command-style APIs such as:

- mutations: add, move, patch, reconnect, remove, flush
- reads: snapshot, dependency queries, selection summaries
- exports: payload, tikz, fletcher, html
- imports: payload, share text/URL, `tikz-cd`, fletcher, html

`dispatch_json` routes string action names to those methods and returns normalized JSON results.

### 7.2 Session Envelope

`BrowserDemoSession` in `runtime/session.mbt` is the protocol wrapper used by the browser bridge.

The command protocol is versioned as:

```text
kwiver.command.v1
```

For each command, the session layer:

- validates protocol/version
- records `origin` and `command_id`
- dispatches into `BrowserRuntime`
- captures `before` and `after` payload/selection/cell IDs
- computes `changed`
- emits `undo_checkpoint` and `redo_checkpoint` payloads when state changed

This makes the session layer a browser integration contract, not just a thin method call.

### 7.3 Browser Bridge

`browser_ui/kwiver_bridge.mjs` is the only intended JS owner of command-envelope dispatch.

It:

- autoloads `browser_ui/_build/js/release/build/runtime/runtime.js`
- verifies required runtime exports
- keeps a single runtime session handle
- normalizes outgoing commands
- validates command protocol on responses
- exposes typed browser-friendly wrappers for UI code

The bridge also exposes pure geometry helpers that call runtime-exported FFI functions.

## 8. End-to-End Data Flows

### 8.1 Editing Flow

```text
UI event
-> browser_ui/ui.mjs
-> browser_ui/kwiver_bridge.mjs
-> runtime BrowserDemoSession command envelope
-> runtime BrowserRuntime::dispatch_json
-> engine QuiverUiAdapter
-> engine Quiver
-> response envelope with before/after/checkpoints
-> browser UI rehydrates affected view state
```

### 8.2 Import Flow

```text
Text/share payload input
-> runtime import action
-> engine parser/decoder
-> canonical Quiver state
-> payload + snapshot/selection results
-> browser view hydration
```

### 8.3 Export Flow

```text
Browser export request
-> runtime render/export action
-> engine export subsystem
-> formatted output (base64 / tikz-cd / fletcher / html)
```

### 8.4 Geometry Flow

```text
Browser needs local arrow geometry
-> bridge pure helper
-> runtime geometry FFI
-> geometry package
-> SVG-ready render plan / points / intersections
```

## 9. Testing and Verification Strategy

The repository uses both MoonBit tests and JS smoke tests.

### MoonBit side

- `engine/*_test.mbt`
- `geometry/*_test.mbt`
- `runtime/*_test.mbt`

These cover domain logic, geometry, and runtime dispatch behavior.

### Browser/runtime integration side

- `browser_ui/tests/kwiver_bridge_smoke.test.mjs`
- `browser_ui/tests/runtime_smoke_non_mock.test.mjs`
- `browser_ui/tests/parser_corpus_runtime_non_mock.test.mjs`
- `browser_ui/tests/toolbar_update_fail_fast.test.mjs`

### Regression entrypoint

`scripts/local_regression.mjs` orchestrates:

- parser corpus manifest sync
- release build into `browser_ui/_build`
- MoonBit tests
- JS smoke tests

This is the closest thing to the repository-wide architecture verification pipeline.

## 10. Current Strengths

- Clear separation between domain model, geometry, runtime service, and product shell
- Canonical serialization (`base64`) reused for sync, checkpoints, and import/export
- Geometry is pure and reusable instead of being embedded in browser rendering logic
- Runtime/session protocol provides a stable integration boundary for JS
- Engine-derived selection state reduces duplicated browser logic

## 11. Current Constraints and Risks

### 11.1 Transitional Browser Ownership

The browser product layer is still in migration. `browser_ui/README.md` and `docs/js-ffi-boundary.md` explicitly describe the current state as transitional.

Current risk:

- JS view objects still retain some graph semantics beside runtime state.

Target direction:

- runtime should become the sole owner of committed graph, dependency, selection, and history semantics
- JS should keep only rendering and transient interaction state

### 11.2 Dual Public Surfaces

There are two browser-adjacent public surfaces:

- direct adapter-style FFI exports in `engine/moon.pkg`
- runtime/session exports in `runtime/moon.pkg`

The product browser path is clearly moving toward the runtime/session API, but both surfaces still exist and increase maintenance cost.

### 11.3 String-Based Dispatch

`BrowserRuntime::dispatch_json` is action-string driven. This is flexible for JS integration, but it trades away compile-time dispatch safety and makes protocol/version governance important.

### 11.4 Fixed Runtime Artifact Path

The browser bridge autoload targets a fixed release artifact path under `browser_ui/_build`. This simplifies bootstrapping but couples hosting/build layout to the UI loader.

## 12. Recommended Evolution Path

Based on the current codebase, the most coherent evolution path is:

1. Make `runtime/` the only browser-facing mutable state owner for committed diagram semantics.
2. Continue shrinking JS-side graph knowledge to view registry and transient previews only.
3. Keep `engine/` focused on domain and format compatibility, not browser orchestration.
4. Keep `geometry/` pure and reusable; avoid moving render math back into JS.
5. Prefer adding new browser features through runtime/session commands and engine-derived query results rather than new JS-only graph logic.

## 13. Summary

`kwiver` is best understood as a layered editor architecture:

- `engine/` is the canonical graph and format engine.
- `geometry/` is the pure mathematical rendering layer.
- `runtime/` is the browser service and command protocol layer.
- `browser_ui/` is the product shell currently being migrated toward a true runtime-backed single source of truth.

The architecture is already strong in its core layering. The main unfinished work is not domain modelling or geometry, but completing the ownership shift so the browser no longer duplicates committed graph semantics that already exist in MoonBit.
