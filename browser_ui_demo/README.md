# Browser UI Loop Demo

This page is now the Task 8 Step 5 editor shell prototype, built on top of the Task 6 runtime demo foundation.

It wires:

- JS browser UI (`browser_ui_demo/app.js`)
- MoonBit data/runtime layer (`browser_demo` package JS build output)

## Run

From `kwiver/`:

```sh
moon build
python -m http.server 8080
```

Then open:

`http://localhost:8080/browser_ui_demo/`

## Scope

The page demonstrates an end-to-end UI loop for:

- add vertex / add edge / remove
- set selection / export selection / paste selection
- import payload / auto import text
- dependency queries
- render outputs (`tikz-cd` / `fletcher` / `html embed`)
- live state panels (`state_json`, `snapshot_json`, `all_cells_json`)
- canvas preview (vertex/edge projection from `snapshot_json`)
- command pipeline (`dispatchCommand`) with:
- typed UI command emitters
- JSON command inspector (accepts both `{type,...}` UI commands and `{action|type,...}` runtime action envelopes)
- runtime command-envelope dispatch (`ffi_browser_demo_session_dispatch_command_json`) for checkpoint-aware mutation routing
- unified command history / last command / last result panes
- gesture layer wired into the command pipeline:
- drag box to select vertices
- drag one selected vertex to move all selected vertices
- shift+drag between vertices to create edges with curved preview
- click edge hit layer to select edges (supports Ctrl/Cmd toggle)
- double click vertex/edge label for inline quick edit
- keyboard delete for selected cells
- undo/redo skeleton via `Ctrl/Cmd+Z`, `Shift+Ctrl/Cmd+Z`, `Ctrl/Cmd+Y`
- keyboard editor shortcuts via command pipeline:
- `Ctrl/Cmd+A` select all cells
- `Ctrl/Cmd+C` copy selection payload (system clipboard with local fallback)
- `Ctrl/Cmd+X` cut selection
- `Ctrl/Cmd+V` paste selection near current focus
