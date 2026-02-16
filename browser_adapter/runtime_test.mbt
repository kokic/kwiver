test "browser runtime roundtrips payload across sessions" {
  let runtime = BrowserRuntime::new()
  let source_id = runtime.add_vertex("A", 0, 0)
  let target_id = runtime.add_vertex("B", 1, 0)
  let edge_id = runtime.add_edge(source_id, target_id, label="f")
  runtime.set_selection([source_id, target_id, edge_id])

  let payload = runtime.export_payload()
  let selection_payload = runtime.export_selection()
  inspect(selection_payload != "", content="true")

  let restored = BrowserRuntime::new()
  ignore(restored.import_payload(payload))
  inspect(restored.all_cell_ids(), content="[1, 2, 3]")
  inspect(restored.export_payload() == payload, content="true")
  inspect(restored.render_tikz().contains("\\begin{tikzcd}"), content="true")
}

///|
test "browser runtime remove and flush use ffi adapter" {
  let runtime = BrowserRuntime::new()
  let source_id = runtime.add_vertex("A", 0, 0)
  let target_id = runtime.add_vertex("B", 1, 0)
  let edge_id = runtime.add_edge(source_id, target_id, label="g")
  runtime.set_selection([source_id, edge_id])

  let removed = runtime.remove(source_id, 42)
  inspect(removed.length(), content="2")
  runtime.flush(42)
  inspect(runtime.all_cell_ids(), content="[2]")
  inspect(runtime.selection(), content="[]")
}

///|
test "browser runtime import share url and paste selection" {
  let source = BrowserRuntime::new()
  let left_id = source.add_vertex("L", 2, 3)
  let right_id = source.add_vertex("R", 4, 3)
  let edge_id = source.add_edge(left_id, right_id, label="h")
  source.set_selection([edge_id])

  let selection_payload = source.export_selection()
  let payload = source.export_payload()
  let share_url = [
    "https://q.uiver.app#r=svg&q=",
    payload,
    "&macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex",
  ].join("")

  let target = BrowserRuntime::new()
  let imported = target.import_share_url(share_url)
  inspect(imported.payload == target.export_payload(), content="true")
  match imported.renderer {
    Some(value) => inspect(value, content="svg")
    None => abort("expected renderer")
  }
  match imported.macro_url {
    Some(value) => inspect(value, content="https://example.com/macros.tex")
    None => abort("expected macro_url")
  }
  inspect(imported.embed, content="false")

  let pasted = target.paste_selection(selection_payload, 10, 20, start_id=1)
  inspect(pasted.imported_ids.length(), content="3")
  inspect(target.selection().length(), content="3")
}
