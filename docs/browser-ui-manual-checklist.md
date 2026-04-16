# Browser UI Manual Checklist

Updated: 2026-04-14

Status: deferred until the browser graph model has a single source of truth.

This project intentionally avoids heavy headless-browser E2E frameworks at the current stage.
Keep this checklist as a post-migration acceptance pass for `browser_ui_upstream`, not as the current implementation priority.

## Preconditions

- Single-source migration is stable:
  - JS no longer owns an independent graph topology alongside runtime state.
  - Connect/history/import/selection behavior reads from one graph source of truth.
- Build runtime artifacts:
  - `moon build --release`
- Serve repository root (the same directory containing `_build/` and `browser_ui_upstream/`):
  - `miniserve ./`
- Open:
  - `http://localhost:8080/browser_ui_upstream`

## Automated Lightweight Checks

These checks are still useful during migration, but they do not replace the single-source migration milestone above.

Run smoke-only regression:

```sh
node scripts/local_regression.mjs --smoke-only
```

Expected:

- command exits successfully and includes:
  - `kwiver bridge smoke passed`
  - `toolbar update fail-fast smoke passed`
  - `runtime non-mock smoke passed`
  - `runtime parser corpus non-mock passed`
- no uncaught runtime exceptions in terminal output

## Manual Product Checks

1. Runtime bootstrap
- Page loads without `Kwiver runtime unavailable` banner.
- Dev console has no startup bridge/protocol errors.

2. Basic editing flow
- Create two vertices and one edge.
- Move a vertex; edge geometry updates visually.
- Edit label/edge options; UI reflects updates.

3. Import/export flow
- Export `tikz-cd`; output contains a valid `\begin{tikzcd}` block.
- Import a small handwritten `tikz-cd` snippet; diagram appears and is editable.
- Export share payload/base64 and re-import; cell count and structure are preserved.

4. Recovery/fail-fast behavior
- Trigger one invalid import input and verify UI shows a typed failure path (not silent fallback).
- Reset action clears runtime state and allows fresh edits.
