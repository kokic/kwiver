# Upstream UI Bridge

This directory is a direct copy of upstream `quiver/src` UI files, with a thin kwiver bridge layer.

## What Is Patched

- `quiver.mjs` routes `tikz-cd` / `fletcher` / `html` export through kwiver (`browser_demo` runtime).
- `quiver.mjs` routes `tikz-cd` import through kwiver (`import_text_auto_json` in runtime).
- `kwiver_bridge.mjs` is the bridge module that talks to MoonBit build output.
- command protocol is sourced from runtime via `ffi_browser_demo_command_protocol()`.
- bridge calls use `ffi_browser_demo_session_dispatch_command_json` as the command entrypoint.
