# JS / FFI Boundary

## Purpose

This document defines the working boundary between browser-side JavaScript and the MoonBit runtime.
It reflects the repository as it exists today: the migration away from duplicated JS graph ownership is still in progress, so new work needs extra discipline.

## Canonical Rule

Committed diagram semantics belong in MoonBit.

That includes:

- graph structure and dependency relationships
- import/export behavior
- selection-derived summaries and capability flags
- undo/redo checkpoints and payload snapshots
- reusable geometry that must stay consistent across browser flows

The browser UI should primarily own:

- DOM state
- rendering lifecycle
- pointer/keyboard interaction plumbing
- transient view-only state that does not become canonical diagram state

## Put Logic In MoonBit When

The feature:

- mutates the canonical diagram model
- needs dependency closure or connected-component reasoning
- should be reused by more than one browser interaction path
- affects export/import correctness
- needs to be serialized, snapshotted, or replayed later
- is geometry/math that should stay deterministic and testable

In practice, these changes usually belong in `engine/`, `geometry/`, or `runtime/`.

## Put Logic In JS When

The feature is strictly browser-local:

- DOM mounting and teardown
- event wiring
- viewport handling
- hover state, drag affordances, or preview-only visuals
- presentation-only transformations that do not define canonical editor behavior

If the browser needs new committed-state information, add it to the runtime contract instead of reconstructing it from JS-owned shadow state.

## Preferred Integration Path

When a browser feature needs new behavior, prefer this order:

1. Add or update domain logic in `engine/` or `geometry/`.
2. Expose it through `runtime/` as a command, DTO, or pure helper export.
3. Consume that contract from `browser_ui/kwiver_bridge.mjs`.
4. Keep `browser_ui/` focused on rendering and interaction.

Avoid adding new direct browser dependencies on `engine`-style internal semantics.

## Review Checklist

Use these questions during review:

1. Does this JS change introduce new canonical graph ownership?
2. Could the logic be expressed once in MoonBit and reused through the runtime?
3. Does the change require new runtime smoke coverage?
4. If the browser-facing MoonBit export surface changed, was `browser_ui/_build/js/release/build/runtime/runtime.js` rebuilt?

If the answer to the first question is "yes", the patch should usually be redesigned before merge.
