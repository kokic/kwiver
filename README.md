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
moon build --release
miniserve ./
```

Open `http://localhost:8080/browser_ui`.

Runtime bootstrap expects MoonBit browser demo artifacts to be reachable from the server root:

- release candidate: `_build/js/release/build/runtime/runtime.js`
- debug candidate: `_build/js/debug/build/runtime/runtime.js`

Runbook notes:

- serve from the `kwiver/` repository root (the same directory that contains `_build/` and `browser_ui/`)
- if startup shows `Kwiver runtime unavailable`, verify the two candidate paths above exist under the served root
- if needed, rebuild artifacts first (`moon build` for debug or `moon build --release` for release)

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
> tokei -e *_test.mbt

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Language              Files        Lines         Code     Comments       Blanks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 JSON                      1           11           11            0            0
 Markdown                  2          296            0          261           35
 MoonBit                  17        16353        14122          984         1247
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Total                    20        16660        14133         1245         1282
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
