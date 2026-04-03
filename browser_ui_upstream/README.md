# Upstream UI Bridge

This directory is a direct copy of upstream `quiver/src` UI files, with a thin kwiver bridge layer.

## What Is Patched

- `quiver.mjs` routes `tikz-cd` / `fletcher` / `html` export through kwiver (`browser_demo` runtime).
- `quiver.mjs` routes `tikz-cd` import through kwiver (`import_text_auto_json` in runtime).
- `kwiver_bridge.mjs` is the bridge module that talks to MoonBit build output.
- command protocol is sourced from runtime via `ffi_browser_demo_command_protocol()`.
- bridge calls use `ffi_browser_demo_session_dispatch_command_json` as the command entrypoint.

## Smoke Check

Run JS-side bridge smoke tests:

```sh
node browser_ui_upstream/tests/kwiver_bridge_smoke.test.mjs
node browser_ui_upstream/tests/toolbar_update_fail_fast.test.mjs
```

The smoke suite verifies protocol enforcement, startup fail-fast formatting, and runtime-first action routing for interaction/export entrypoints.
