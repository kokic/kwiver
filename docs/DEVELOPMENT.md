# Development Guide

## Purpose

This guide is the day-to-day entrypoint for contributors working on `kwiver`.
It focuses on how to build, test, and change the repository without fighting the current architecture.

For a higher-level system overview, read [../ARCHITECTURE.md](../ARCHITECTURE.md).
For JS/MoonBit ownership rules, read [js-ffi-boundary.md](js-ffi-boundary.md).

## Tooling

The repository currently relies on a small toolchain:

- `moon` for building, checking, and testing MoonBit packages
- `node` for regression scripts and browser smoke tests
- `miniserve` or another static file server for local browser preview

There is no `package.json` in this repository. The checked-in Node scripts use built-in Node modules only.

## Quick Start

Build the release runtime artifact into the fixed browser autoload path:

```sh
moon build --release --target-dir browser_ui/_build
```

Serve the browser UI directory:

```sh
miniserve ./browser_ui --port 8081
```

Then open `http://localhost:8081/`.

The browser bridge expects the runtime artifact at:

```text
browser_ui/_build/js/release/build/runtime/runtime.js
```

If you change the build location, the browser bridge will not find the runtime unless you also change the JS loader.

## Repository Map

| Path | Owns |
| --- | --- |
| `engine/` | Canonical diagram graph, import/export, UI adapter DTOs, selection-derived state |
| `geometry/` | Pure curve/arrow math and render-plan generation |
| `runtime/` | Browser-facing runtime/session API and JS export surface |
| `browser_ui/` | DOM/UI shell, bridge code, smoke tests, static assets |
| `scripts/` | Regression runners, parser corpus sync, upstream scanning helpers |

## Command Reference

| Goal | Command |
| --- | --- |
| Type-check the repository | `moon check` |
| Run MoonBit tests | `moon test -v` |
| Build browser runtime artifact | `moon build --release --target-dir browser_ui/_build` |
| Run full regression | `node scripts/local_regression.mjs` |
| Run smoke-only regression | `node scripts/local_regression.mjs --smoke-only` |
| Resync parser corpus generated data | `node scripts/sync_parser_corpus_manifest.mjs` |

`scripts/local_regression.mjs` currently runs these steps in order:

1. Sync parser corpus manifest data into `engine/tikz_parser_corpus_manifest_data.mbt`.
2. Build the release runtime into `browser_ui/_build`.
3. Run `moon test -v` unless `--smoke-only` is used.
4. Run browser/runtime smoke tests from `browser_ui/tests/`.

When in doubt, prefer the full regression script before merging.

## Development Rules

### 1. Keep committed diagram state in MoonBit

`engine/` is the canonical owner of diagram structure and dependency semantics.
If a feature changes committed graph state, import/export semantics, selection summaries, or undo/redo inputs, the change should land in MoonBit first and only be exposed to JS through the runtime boundary.

### 2. Treat `runtime/` as the browser contract

Browser code should prefer `runtime/` session/command APIs over reaching into `engine/` internals directly.
If you add a browser-visible feature, first ask whether it belongs as:

- a new runtime command
- a richer runtime response payload
- a new pure geometry export

### 3. Keep `geometry/` pure

Arrow path generation, clipping, and label positioning should stay deterministic and reusable.
Do not move render math back into UI event handlers unless the state is purely transient and browser-local.

### 4. Keep JS focused on rendering and transient interaction state

The browser UI is still in transition, but new work should reduce JS-side graph ownership rather than expand it.
If a JS patch starts duplicating dependency logic or canonical selection reasoning, it is probably being added in the wrong layer.

## Common Workflows

### Change domain logic in `engine/`

1. Update the relevant MoonBit implementation and `*_test.mbt` coverage.
2. Run `moon test -v`.
3. If the browser-visible API or serialized payload changed, run `node scripts/local_regression.mjs`.

### Change curve/layout logic in `geometry/`

1. Keep the change in `geometry/` unless it truly affects domain semantics.
2. Update geometry tests.
3. Run at least `moon test -v`; run full regression if the browser renderer depends on the output shape.

### Change browser-facing runtime/session behavior

1. Update `runtime/` first, then the bridge/tests in `browser_ui/`.
2. Rebuild the release artifact:

```sh
moon build --release --target-dir browser_ui/_build
```

3. Run `node scripts/local_regression.mjs`.

### Change parser corpus fixtures or manifest data

Source of truth lives in:

- `browser_ui/tests/parser_corpus_manifest.json`
- `browser_ui/tests/parser.tex`
- `browser_ui/tests/parser_external.tex`
- `browser_ui/tests/parser_external_invalid.tex`

After editing any of them:

1. Run `node scripts/sync_parser_corpus_manifest.mjs`.
2. Review the generated diff in `engine/tikz_parser_corpus_manifest_data.mbt`.
3. Run `node scripts/local_regression.mjs`.

## Before Opening a PR

Use this minimal checklist:

1. Run the narrowest relevant command while iterating, then run `node scripts/local_regression.mjs` before merge when the browser/runtime boundary is involved.
2. Review generated-file diffs instead of blindly committing them.
3. Update documentation if the workflow, protocol, or ownership boundary changed.
