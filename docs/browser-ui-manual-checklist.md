# Browser UI Manual Checklist

Updated: 2026-04-07

This project intentionally avoids heavy headless-browser E2E frameworks at the current stage.
Use the lightweight checklist below as a release gate for `browser_ui_upstream`.

## Preconditions

- Build runtime artifacts:
  - `moon build --release`
- Serve repository root (the same directory containing `_build/` and `browser_ui_upstream/`):
  - `miniserve ./`
- Open:
  - `http://localhost:8080/browser_ui_upstream`

## Automated Lightweight Checks

Run JS smoke checks:

```sh
node browser_ui_upstream/tests/kwiver_bridge_smoke.test.mjs
node browser_ui_upstream/tests/toolbar_update_fail_fast.test.mjs
node browser_ui_upstream/tests/runtime_smoke_non_mock.test.mjs
```

Expected:

- all commands pass (`kwiver bridge smoke passed`, `toolbar update fail-fast smoke passed`, `runtime non-mock smoke passed`)
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
