# kwiver

> ⚠️ Disclaimer: This is an unofficial, community-driven port of [quiver](https://github.com/varkor/quiver). 
> It is not affiliated with, maintained by, or endorsed by varkor or the original quiver project. 

An reimplementation of the quiver commutative diagram editor.

## Acknowledgments

This project was inspired by and owes much to [quiver](https://github.com/varkor/quiver), a modern graphical editor for commutative diagrams created by [varkor](https://github.com/varkor). 

We gratefully acknowledge the original design, file format, and user experience that made this reimplementation possible.

## JS FFI Boundary

The browser/runtime integration surface is documented in `docs/js-ffi-boundary.md` and implemented in `engine/quiver_ui_ffi.mbt`.
`browser_demo/` provides the runtime session layer consumed by the browser bridge.
The current handwritten `tikz-cd` import compatibility matrix is documented in `docs/tikz-cd-parser-support.md`.

## Browser UI (`browser_ui_upstream`)

The product UI is `browser_ui_upstream/`, backed by MoonBit runtime/state APIs from the `browser_demo` package build output.
Runtime command dispatch uses the stable command-envelope contract (`ffi_browser_demo_session_dispatch_command_json`) through the JS bridge layer.

```sh
moon build --release
miniserve ./
```

Open `http://localhost:8080/browser_ui_upstream`.

Runtime bootstrap expects MoonBit browser demo artifacts to be reachable from the server root:

- release candidate: `_build/js/release/build/browser_demo/browser_demo.js`
- debug candidate: `_build/js/debug/build/browser_demo/browser_demo.js`

Runbook notes:

- serve from the `kwiver/` repository root (the same directory that contains `_build/` and `browser_ui_upstream/`)
- if startup shows `Kwiver runtime unavailable`, verify the two candidate paths above exist under the served root
- if needed, rebuild artifacts first (`moon build` for debug or `moon build --release` for release)

Run browser bridge smoke checks:

```sh
node browser_ui_upstream/tests/kwiver_bridge_smoke.test.mjs
node browser_ui_upstream/tests/toolbar_update_fail_fast.test.mjs
node browser_ui_upstream/tests/runtime_smoke_non_mock.test.mjs
```

Manual release checks for `browser_ui_upstream` are documented in `docs/browser-ui-manual-checklist.md`.

Run core MoonBit regressions:

```sh
moon test -v
```

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
