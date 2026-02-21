# kwiver

> ⚠️ Disclaimer: This is an unofficial, community-driven port of [quiver](https://github.com/varkor/quiver). 
> It is not affiliated with, maintained by, or endorsed by varkor or the original quiver project. 

An reimplementation of the quiver commutative diagram editor.

## Acknowledgments

This project was inspired by and owes much to [quiver](https://github.com/varkor/quiver), a modern graphical editor for commutative diagrams created by [varkor](https://github.com/varkor). 

We gratefully acknowledge the original design, file format, and user experience that made this reimplementation possible.

## JS FFI Boundary

A first-pass browser integration surface is documented in docs/js-ffi-boundary.md and implemented in engine/quiver_ui_ffi.mbt.
An end-to-end thin UI-loop scaffold package is available in browser_demo/.

## Browser UI Loop Demo (Task 6 + Task 8 Progress)

A runnable browser demo is available in `browser_ui_demo/` and uses JS UI + MoonBit runtime/state APIs from the `browser_demo` package build output.
It now includes an editor-shell layout, a unified JS command dispatch pipeline, gesture wiring (box-select, multi-drag, shift-drag connect, edge hit select, quick label edit), and keyboard editor shortcuts (`Ctrl/Cmd+A/C/X/V`, delete, undo/redo).
`browser_demo` also now exposes a stable command-envelope checkpoint API (`ffi_browser_demo_session_dispatch_command_json`) for production JS shells to route commands and manage undo/redo checkpoints with deterministic payload snapshots.

```sh
moon build
python -m http.server 8080
```

Open `http://localhost:8080/browser_ui_demo/`.

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
