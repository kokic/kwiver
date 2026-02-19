# kwiver

> ⚠️ Disclaimer: This is an unofficial, community-driven port of [quiver](https://github.com/varkor/quiver). 
> It is not affiliated with, maintained by, or endorsed by varkor or the original quiver project. 

An reimplementation of the quiver commutative diagram editor.

## Acknowledgments

This project was inspired by and owes much to [quiver](https://github.com/varkor/quiver), a modern graphical editor for commutative diagrams created by [varkor](https://github.com/varkor). 

We gratefully acknowledge the original design, file format, and user experience that made this reimplementation possible.

## JS FFI Boundary

A first-pass browser integration surface is documented in docs/js-ffi-boundary.md and implemented in engine/quiver_ui_ffi.mbt.

## Tokei

```sh
> tokei -e *_test.mbt # commit 0081cd015d46e5f3fa6fbb34d467ad7f839218ca

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Language              Files        Lines         Code     Comments       Blanks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 JSON                      1           11           11            0            0
 Markdown                  2          121            0           95           26
 MoonBit                  16        12202        10461          751          990
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Total                    19        12334        10472          846         1016
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
