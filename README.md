# kwiver

> ⚠️ Disclaimer: This is an unofficial, community-driven port of [quiver](https://github.com/varkor/quiver). 
> It is not affiliated with, maintained by, or endorsed by varkor or the original quiver project. 

A reimplementation of the quiver commutative diagram editor.

## Acknowledgments

This project was inspired by and owes much to [quiver](https://github.com/varkor/quiver), a modern graphical editor for commutative diagrams created by [varkor](https://github.com/varkor). 

We gratefully acknowledge the original design, file format, and user experience that made this reimplementation possible.

## Quick Start

The browser UI in `webui/` autoloads the MoonBit release runtime artifact from `webui/_build/js/release/build/runtime/runtime.js`.

```sh
moon build --release --target-dir webui/_build
miniserve ./webui --port 8081
```

Open `http://localhost:8081/`.

Any static file server works as long as it serves `webui/` without rewriting paths. `miniserve` is just the documented default.

## Verification

Common local verification entrypoints:

```sh
moon test -v
node scripts/local_regression.mjs
node scripts/local_regression.mjs --smoke-only
```
