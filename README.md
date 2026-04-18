# kwiver

> ⚠️ Disclaimer: This is an unofficial, community-driven port of [quiver](https://github.com/varkor/quiver). 
> It is not affiliated with, maintained by, or endorsed by varkor or the original quiver project. 

An reimplementation of the quiver commutative diagram editor.

## Acknowledgments

This project was inspired by and owes much to [quiver](https://github.com/varkor/quiver), a modern graphical editor for commutative diagrams created by [varkor](https://github.com/varkor). 

We gratefully acknowledge the original design, file format, and user experience that made this reimplementation possible.

## Browser UI (`browser_ui`)

The product UI is `browser_ui/`, backed by MoonBit runtime/state APIs from the `runtime` package build output.

```sh
moon build --release --target-dir browser_ui/_build
miniserve ./browser_ui --port 8081
```

Open `http://localhost:8081/`.

## Tokei

```sh
> tokei -e *_test.mbt -e *.mjs -e *.js

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Language              Files        Lines         Code     Comments       Blanks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CSS                       2         3210         2560          193          457
 JSON                      3         1084         1084            0            0
 Markdown                  3          591            0          407          184
 MoonBit                  26        20805        18409         1010         1386
 SVG                      28           39           39            0            0
 TeX                       3          728          476          125          127
─────────────────────────────────────────────────────────────────────────────────
 HTML                      1           55           49            6            0
 |- JavaScript             1           57           34           15            8
 (Total)                              112           83           21            8
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Total                    66        26569        22651         1756         2162
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
