# tikz-cd Parser Support Matrix

Updated: 2026-04-07

This document tracks the current behavior of the handwritten `tikz-cd` importer in `engine/quiver_export_tikz.mbt`.
The parser is intentionally strict and fail-fast by default: malformed inputs return typed import errors instead of permissive fallback.

## Supported

- Environment wrappers: `\begin{tikzcd}...\end{tikzcd}`, `tikzcd*`, and common display-math wrappers.
- Diagram options: `ampersand replacement`, `sep`, `column sep`, `row sep`, and common style keys used by upstream exports.
- Endpoint references: direction shorthand (`r`, `l`, `u`, `d`, diagonals), matrix coordinates (`from=1-1`), braced keys, named edge references, and forward references.
- Label syntax: quoted/braced/bare labels, suffix forms (`'`, `''`, `^`, `_`, `|`), and label-local options (`swap`, `description`, `pos`, `near start`, `near end`, `marking`).
- Arrow/style options: common presets and aliases, `dashed`, harpoon side options, colour/draw/text options, and non-arrow decoration mappings.
- Geometry options: `shorten <=`, `shorten >=`, `curve`, `shift`, `bend left/right`, `between={...}{...}`, and loop geometry keys (`loop`, `in`, `out`, `distance`).
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

## Currently Accepted for Compatibility (Under Review)

- A named-reference snippet that was historically listed as invalid in `parser.tex` currently imports successfully.

These behaviors are covered by regression tests so changes are explicit.

## Planned

- Continue expanding external corpus coverage using real-world upstream snippets.
- Split corpus documentation into per-feature examples with expected outcomes (`supported`, `fail-fast`, `accepted-compat`).
- Decide whether currently accepted compatibility cases should remain accepted or be tightened into fail-fast errors.
- Add browser-level import fixture tests that consume the same snippet corpus through runtime bridge entrypoints.

## Regression Entry Points

- `engine/quiver_export_tikz_test.mbt`:
  - `tikz-cd parser corpus valid snippets from parser.tex import successfully`
  - `tikz-cd parser corpus invalid snippets from parser.tex return structured errors`
  - `tikz-cd parser corpus compatibility snippets from parser.tex now fail fast`
  - `tikz-cd parser corpus compatibility snippets currently accepted from parser.tex`
