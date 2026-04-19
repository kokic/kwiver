# Maintenance Guide

## Purpose

This guide is for maintainers responsible for keeping the repository releasable and the checked-in browser artifact in sync with the MoonBit sources.

## Maintainer Responsibilities

The recurring maintenance duties in this repository are:

- keeping the checked-in browser runtime artifact in sync with the MoonBit code
- keeping parser corpus generated data in sync with its source fixtures
- protecting the JS/MoonBit ownership boundary while migration is still in progress
- verifying releases before publishing GitHub Pages artifacts

## Generated Artifacts

Two generated files matter operationally:

| Generated file | Source of truth | Command | Commit policy |
| --- | --- | --- | --- |
| `browser_ui/_build/js/release/build/runtime/runtime.js` | `engine/`, `geometry/`, and `runtime/` browser-facing MoonBit exports | `moon build --release --target-dir browser_ui/_build` | Commit updated output before a release, and whenever you intentionally want the checked-in browser artifact to match source changes |
| `engine/tikz_parser_corpus_manifest_data.mbt` | `browser_ui/tests/parser_corpus_manifest.json` plus parser fixture `.tex` files | `node scripts/sync_parser_corpus_manifest.mjs` | Commit whenever the manifest or fixture sources change |

Do not hand-edit either generated file.

## Why The Runtime Artifact Is Checked In

`.github/workflows/main.yml` deploys GitHub Pages when a GitHub Release is published, but the workflow does not build MoonBit output during deployment.
It uploads the existing `browser_ui/` tree as the Pages artifact.

That means release readiness depends on the repository already containing an up-to-date:

```text
browser_ui/_build/js/release/build/runtime/runtime.js
```

If this file is stale at release time, Pages can publish an outdated runtime even when the source files are correct.

## Release Checklist

Run this checklist before publishing a release:

1. Run full local regression:

```sh
node scripts/local_regression.mjs
```

2. Rebuild the checked-in browser runtime artifact:

```sh
moon build --release --target-dir browser_ui/_build
```

3. Review the diff for `browser_ui/_build/js/release/build/runtime/runtime.js` and commit it if it changed.
4. Confirm any parser corpus source edits were followed by `node scripts/sync_parser_corpus_manifest.mjs` and the generated MoonBit file was committed.
5. Publish the GitHub Release.
6. Watch the `Release Browser UI` workflow in GitHub Actions and confirm Pages deployment succeeds.
7. Sanity-check the deployed browser UI after Pages finishes.

## Routine Maintenance Playbooks

### When runtime protocol or command payloads change

1. Keep `ffi_runtime_command_protocol()` and session envelopes coherent.
2. Update `browser_ui/kwiver_bridge.mjs` if request/response shapes or required exports changed.
3. Re-run `node scripts/local_regression.mjs`.
4. Rebuild and review the checked-in runtime artifact.

### When parser import behavior changes

1. Update MoonBit tests in `engine/` and/or `runtime/`.
2. Update parser fixtures or `parser_corpus_manifest.json` only when the expected behavior intentionally changed.
3. Run the manifest sync script and review the generated file.
4. Run full regression.

### When browser-side ownership starts growing again

Use [js-ffi-boundary.md](js-ffi-boundary.md) as the decision document.
If a patch adds new canonical graph semantics in JS, treat that as architectural debt unless there is a short-lived migration reason documented in the diff.

### When scanning upstream examples

`scripts/scan_upstream_tikz_snippets.mjs` can batch-scan `tikzcd` snippets from a sibling checkout at `../quiver`.
This is optional, but useful when evaluating parser coverage against upstream examples.

Example:

```sh
node scripts/scan_upstream_tikz_snippets.mjs --include-tests
```

The script assumes the upstream repository exists at `../quiver`.

## Failure Modes

### Pages deploys, but the browser runtime is outdated

Most likely cause: `browser_ui/_build/js/release/build/runtime/runtime.js` was not rebuilt and committed before the release.

### Parser corpus tests disagree with engine expectations

Most likely cause: parser manifest or fixture sources changed without rerunning:

```sh
node scripts/sync_parser_corpus_manifest.mjs
```

### Browser smoke tests fail after runtime changes

Most likely cause: runtime export names, command protocol, or response payloads drifted without corresponding updates in `browser_ui/kwiver_bridge.mjs` or the smoke tests.
