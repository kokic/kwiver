# Upstream UI Bridge

This directory is a direct copy of upstream `quiver/src` UI files, with a kwiver bridge layer.

Current migration status: the bridge is not finished. Some graph semantics still exist in both upstream-style JS objects and MoonBit runtime state. The highest-priority task is to remove that duplication and leave JS with render/interaction-transient state only.

## What Is Patched

- `quiver.mjs` routes `tikz-cd` / `fletcher` / `html` export through kwiver (`runtime` runtime).
- `quiver.mjs` routes `tikz-cd` import through kwiver (`import_text_auto_json` in runtime).
- `kwiver_bridge.mjs` is the bridge module that talks to MoonBit build output.
- command protocol is sourced from runtime via `ffi_runtime_command_protocol()`.
- bridge calls use `ffi_runtime_session_dispatch_command_json` as the command entrypoint.

Do not treat the current JS graph ownership as final architecture. New work should reduce JS graph-state responsibility, not expand it.

## Smoke Check

Run full local regression (MoonBit + JS smoke):

```sh
node scripts/local_regression.mjs
```

Run smoke-only mode (skip `moon test -v`):

```sh
node scripts/local_regression.mjs --smoke-only
```

Parser corpus fixture expectations are declared in `tests/parser_corpus_manifest.json` and shared with engine tests via the sync script.

The smoke suite verifies protocol enforcement, startup fail-fast formatting, command routing for interaction/export entrypoints, non-mock runtime command dispatch against built runtime artifacts, and parser.tex corpus import/fail-fast behavior through runtime bridge entrypoints.
These checks do not mean the browser graph migration is complete; they only guard the current bridge/runtime boundary while JS graph ownership is still being removed.
