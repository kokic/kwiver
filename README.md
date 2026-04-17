# kwiver

> ⚠️ Disclaimer: This is an unofficial, community-driven port of [quiver](https://github.com/varkor/quiver). 
> It is not affiliated with, maintained by, or endorsed by varkor or the original quiver project. 

An reimplementation of the quiver commutative diagram editor.

## Acknowledgments

This project was inspired by and owes much to [quiver](https://github.com/varkor/quiver), a modern graphical editor for commutative diagrams created by [varkor](https://github.com/varkor). 

We gratefully acknowledge the original design, file format, and user experience that made this reimplementation possible.

## JS FFI Boundary

The browser/runtime integration surface is documented in `docs/js-ffi-boundary.md` and implemented in `engine/quiver_ui_ffi.mbt`.
`runtime/` provides the runtime session layer consumed by the browser bridge.
The current handwritten `tikz-cd` import compatibility matrix is documented in `docs/tikz-cd-parser-support.md`.

## Browser UI (`browser_ui`)

The product UI is `browser_ui/`, backed by MoonBit runtime/state APIs from the `runtime` package build output.
Runtime command dispatch uses the stable command-envelope contract (`ffi_runtime_session_dispatch_command_json`) through the JS bridge layer.

Current migration priority:

- remove duplicated graph semantics between JS `ui.quiver` state and MoonBit runtime state
- keep JS focused on rendering and transient interaction state only
- treat release-gate polishing and additional parser work as secondary until the browser graph state has a single source of truth

```sh
moon build --release --target-dir browser_ui/_build
miniserve ./browser_ui
```

Open `http://localhost:8080/`.

Runbook notes:

- serve from the `kwiver/` repository root (the same directory that contains `browser_ui/`)
- if startup shows `Kwiver runtime unavailable`, verify the fixed path above exists under the served root
- if needed, rebuild artifacts first with `moon build --release --target-dir browser_ui/_build`

Run local regressions:

```sh
node scripts/local_regression.mjs
```

The runner auto-syncs parser corpus generated data before executing tests.

Run smoke-only checks (skip `moon test -v`):

```sh
node scripts/local_regression.mjs --smoke-only
```

A targeted manual browser checklist for `browser_ui` is documented in `docs/browser-ui-manual-checklist.md`.
Run it after reconnect/import/export/persistence changes, once lightweight regression checks are green.

## Tokei

```sh
> tokei -e *_test.mbt -e *.mjs -e *.js

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Language              Files        Lines         Code     Comments       Blanks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CSS                       2         3210         2560          193          457
 JSON                      3         1084         1084            0            0
 Markdown                  2          116            0           77           39
 MoonBit                  23        18616        16462          903         1251
 SVG                      28           39           39            0            0
 TeX                       3          728          476          125          127
─────────────────────────────────────────────────────────────────────────────────
 HTML                      1           55           49            6            0
 |- JavaScript             1           57           34           15            8
 (Total)                              112           83           21            8
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Total                    62        23905        20704         1319         1882
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
