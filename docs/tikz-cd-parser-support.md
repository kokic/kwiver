# tikz-cd Parser Support Matrix

Updated: 2026-04-14

This document tracks the current behavior of the handwritten `tikz-cd` importer in `engine/quiver_export_tikz_parser.mbt` (wired through `engine/quiver_export_tikz.mbt`).
The parser is intentionally strict and fail-fast by default: malformed inputs return typed import errors instead of permissive fallback.

## Corpus Manifest

- Manifest: `browser_ui_upstream/tests/parser_corpus_manifest.json`
- Fixture text sources:
  - `browser_ui_upstream/tests/parser.tex` (baseline)
  - `browser_ui_upstream/tests/parser_external.tex` (real snippets from `quiver/package/quiver-doc.tex` and upstream quiver export forms)
  - `browser_ui_upstream/tests/parser_external_invalid.tex` (real-style strict fail-fast snippets)
- Fixture policy invariants:
  - `parser_external.tex`: `valid` + `engine_group=valid` + `runtime_expectation=import_success`
  - `parser_external_invalid.tex`: `invalid` + fail-fast groups + `runtime_expectation=fail_fast`
- Generated MoonBit corpus data: `engine/tikz_parser_corpus_manifest_data.mbt`
- Sync command: `node scripts/sync_parser_corpus_manifest.mjs`

Both runtime JS corpus checks and engine corpus checks are driven from the same manifest+fixture sources.
The current manifest contains 117 cases.
The current manifest has no `runtime_expectation=skip` entries: all cases are asserted as either `import_success` or `fail_fast`.
Parser corpus maintenance is currently secondary to the browser single-source-of-truth migration.

## Policy Decisions (2026-04-12)

- `compat-invalid-level-1-clamped` remains supported for compatibility:
  - numeric `scaling nfold` values outside the preferred range are clamped instead of fail-fast.
- `valid-zero-length-edge-reference-chain` remains supported:
  - `name=0` followed by `from=0` is treated as a valid higher-cell reference chain endpoint.
- Additional `parser.tex` invalid-title snippets remain supported on strict/runtime paths and are now tracked as `valid/import_success`:
  - `Loop`,
  - `Zero length arrow.`,
  - `No &.`,
  - `Multiple node errors.`.
- External corpus now also tracks selected upstream `src/tests/parser.tex` baseline shapes as `parser_external.tex` valid cases:
  - concatenated/spaced control-sequence label variants,
  - `description` label suffix form,
  - inline direction shorthand form (`A \arrow[r] & B`),
  - explicit edge colour literal and combined vertex `\textcolor` + edge draw/text colours,
  - `leftarrow` ordering variants.
- `curve={height=..., pos=...}` is supported in strict mode:
  - `pos` is validated as a numeric fraction/range value and accepted for compatibility.
  - External corpus now covers representative values `0.2`, `0.5`, and `0.8`, plus leading-dot form `.2`.
  - Curly-key order is treated as order-insensitive (`height=...,pos=...` and `pos=...,height=...`).
- Inputs that begin with a `tikzcd` environment are now always handled by the tikz importer path:
  - malformed environments (for example missing `\end{tikzcd}`) return structured tikz syntax errors instead of falling through to base64 import errors.
- Fail-fast parser errors now include concrete line/column locations for environment/body validation and unresolved reference paths:
  - missing target/direction, unresolved `from`/`to` refs, and loop/reference consistency failures report non-zero positions.
  - UI diagnostics can map these directly to caret/highlight locations instead of relying on message-only output.
- `parser_external.tex` now also covers `quiver-doc` tail/body presets with `ampersand replacement=\&`:
  - `tail reversed`, `2tail`, and `no body`.
- `parser_external.tex` also tracks representative upstream export forms:
  - `hook'` + `harpoon'`,
  - loop geometry (`loop`, `in`, `out`, `distance`),
  - `between` + `shorten` mixed option order,
  - `maps to` with explicit `no head`,
  - marking/decoration + colour combos (`\shortmid`, `\dashv`, hollow-bullet pairs),
  - label suffix combinations that include both `pos` and `text`,
  - explicit center and non-center `start/end anchor` values, plus phantom helper named-reference chains,
  - braced endpoint keys with named refs (`{from}=...`, `{to}=...`),
  - mixed-unit `shift` options (including `mm/cm`), decimal/integer `bend` values, and `loop left/right` side tokens,
  - exporter-style `shift right` / `shift left` flag forms without explicit magnitudes,
  - `between={...}{...}` combined with `shift` options (the quiver-doc 1.6.0 compatibility shape),
  - display-math and `tikzcd*` wrappers with representative diagram option forms (`cramped`, `sep` keys, `sep/` tokens),
  - supported `every arrow/.append style=...` diagram option keys,
  - supported `every label/.append style=...`, `every cell/.append style=...`, `every matrix/.append style=...`, `every diagram/.append style=...`, `every edge/.append style=...`, and `every row/.append style=...` diagram option keys.
- `parser_external_invalid.tex` tracks strict fail-fast behavior for real-style external snippets:
  - out-of-range `curve ... pos`,
  - non-numeric `curve ... pos`,
  - negative `curve ... pos`,
  - missing `curve ... height`,
  - out-of-range `between` endpoint,
  - non-numeric loop `distance`,
  - out-of-range `draw` colour channels,
  - out-of-range label-suffix `text` colour channels,
  - non-numeric label-suffix `pos`,
  - endpoint references with internal whitespace,
  - empty arrow `name` option,
  - non-numeric `shift` magnitudes,
  - zero-angle `bend` options,
  - non-positive loop `distance`,
  - empty diagram `sep` values,
  - empty slash-style `sep/` suffixes,
  - empty style values for supported style keys (for example `every label/.append style=`),
  - unresolved named refs with `tail reversed`,
  - same source/target without `loop` under `2tail`.

External fail-fast snippets include parser-derived and real-style variants; the `curve(..., pos=...)` compatibility cases are tracked in `parser_external.tex`. All are covered by both engine/runtime corpus checks.
- `parser.tex` baseline cases for `dashed` and loop-radii/angle/direction forms are now classified as `valid` on both engine and runtime paths (no engine-only skip classification).
- `parser.tex` baseline case `These...` (comments around `\begin{tikzcd}`/`\end{tikzcd}`) is tracked as `valid/import_success`.
- `parser.tex` baseline decoration cases `Coloured barred arrow.`, `Double barred arrow.`, `Solid bullet arrow.`, and `Hollow bullet arrow.` are tracked as `valid/import_success`.

## Supported

- Environment wrappers: `\begin{tikzcd}...\end{tikzcd}`, `tikzcd*`, and common display-math wrappers.
- Diagram options: `ampersand replacement`, `sep`, `column sep`, `row sep`, slash-style sep tokens (`sep/...`, `row sep/...`, `column sep/...`), and supported style keys (`every arrow/label/cell/matrix/diagram/edge/row/column`).
- Endpoint references: direction shorthand (`r`, `l`, `u`, `d`, diagonals), matrix coordinates (`from=1-1`), braced keys, named edge references, and forward references.
- Named reference chains such as `name=0` followed by `from=0` are treated as valid higher-cell endpoints when references resolve.
- Label syntax: quoted/braced/bare labels, suffix forms (`'`, `''`, `^`, `_`, `|`), and label-local options (`swap`, `description`, `pos`, `near start`, `near end`, `marking`).
- Arrow/style options: common presets and aliases, `dashed`, harpoon side options, colour/draw/text options, start/end anchors (non-empty values), and non-arrow decoration mappings.
- Geometry options: `shorten <=`, `shorten >=`, `curve` (including optional `pos`), `shift` (including `pt/ex/em/mm/cm` units), `bend left/right`, `between={...}{...}`, and loop geometry keys (`loop`, `in`, `out`, `distance`).
- Robust tokenization behavior: escaped delimiters, quoted content with commas/brackets, LaTeX comments, and row separator variants (`\\`, `\\*`, `\cr`, `\crcr`, `\tabularnewline`).

## Explicitly Unsupported (Fail-Fast)

- Unknown diagram options, arrow options, or label suffix options.
- Unresolved endpoint references (for example `from=A, to=B` without resolvable named references).
- Invalid colour literals (for example channel range overflow or malformed `rgb,...` tokens).
- Invalid `scaling nfold` values (for example non-numeric tokens such as `unknown`).
- Invalid `\textcolor` vertex labels (including malformed literals or missing label node payload).
- Non-loop arrows whose source and target resolve to the same cell.
- Loop arrows whose resolved source and target differ.
- Malformed environment structure and tokenization errors (missing delimiters, trailing garbage, unterminated options).

## Planned

- Freeze proactive corpus expansion while browser graph migration is still incomplete.
- Only add or adjust corpus cases when fixing a concrete parser parity bug from upstream behavior.
- Split corpus documentation into per-feature examples with expected outcomes (`supported`, `fail-fast`) only when it directly supports active migration/parity work.

## Regression Entry Points

- `engine/quiver_export_tikz_test.mbt`:
  - `tikz-cd parser corpus valid snippets from parser.tex import successfully`
  - `tikz-cd parser corpus invalid snippets from parser.tex return structured errors`
  - `tikz-cd parser corpus compatibility snippets from parser.tex now fail fast`
  - `tikz-cd parser corpus keeps parser_external fixture expectations stable`
  - `tikz-cd parser corpus keeps parser_external_invalid fixture fail-fast expectations stable`
  - `tikz-cd import parser supports named edge references in from/to`
- `browser_ui_upstream/tests/parser_corpus_runtime_non_mock.test.mjs`:
  - runtime bridge import/fail-fast assertions for selected `parser.tex`, `parser_external.tex`, and `parser_external_invalid.tex` fixtures
- `scripts/scan_upstream_tikz_snippets.mjs`:
  - ad-hoc upstream snippet scan (`../quiver`) through runtime import path; defaults to documentation/examples only, with optional `--include-tests` for full upstream test corpus diagnostics.
