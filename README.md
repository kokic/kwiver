# kwiver

> ⚠️ Disclaimer: This is an unofficial, community-driven port of [quiver](https://github.com/varkor/quiver). 
> It is not affiliated with, maintained by, or endorsed by varkor or the original quiver project. 

A reimplementation of the quiver commutative diagram editor.

## Acknowledgments

This project was inspired by and owes much to [quiver](https://github.com/varkor/quiver), a modern graphical editor for commutative diagrams created by [varkor](https://github.com/varkor). 

We gratefully acknowledge the original design, file format, and user experience that made this reimplementation possible.

## Repository Layout

| Path | Responsibility |
| --- | --- |
| `engine/` | Canonical diagram model, import/export, selection queries, browser-facing adapter APIs |
| `geometry/` | Pure arrow geometry, clipping, label placement, render plans |
| `runtime/` | Browser runtime/session layer and JS-facing command protocol |
| `browser_ui/` | Browser UI shell, runtime bridge, smoke tests, static assets |
| `scripts/` | Local regression helpers and parser corpus maintenance scripts |
| `docs/` | Development, maintenance, and boundary documentation |

The project architecture is described in [ARCHITECTURE.md](ARCHITECTURE.md).

## Quick Start

The browser UI in `browser_ui/` autoloads the MoonBit release runtime artifact from `browser_ui/_build/js/release/build/runtime/runtime.js`.

```sh
moon build --release --target-dir browser_ui/_build
miniserve ./browser_ui --port 8081
```

Open `http://localhost:8081/`.

Any static file server works as long as it serves `browser_ui/` without rewriting paths. `miniserve` is just the documented default.

## Development Docs

- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md): local setup, command reference, package boundaries, and contributor workflows
- [docs/MAINTENANCE.md](docs/MAINTENANCE.md): release process, generated artifacts, and maintainer checklists
- [docs/js-ffi-boundary.md](docs/js-ffi-boundary.md): rules for what belongs in MoonBit vs. browser-side JS

## Verification

Common local verification entrypoints:

```sh
moon test -v
node scripts/local_regression.mjs
node scripts/local_regression.mjs --smoke-only
```
