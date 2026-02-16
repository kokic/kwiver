///|
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
    "https://q.uiver.app#r=svg&q=", payload, "&macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex",
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

///|
test "browser runtime fletcher import/export roundtrips with metadata" {
  let source = BrowserRuntime::new()
  let source_id = source.add_vertex("A", 0, 0)
  let target_id = source.add_vertex("B", 1, 0)
  ignore(source.add_edge(source_id, target_id, label="f"))

  let options = @kwiver.FletcherExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .with_renderer("svg")
    .with_macro_url("https://example.com/macros.tex")
  let fletcher = source.render_fletcher(options~)

  let target = BrowserRuntime::new()
  target.set_selection([999])
  let imported = target.import_fletcher(fletcher)
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
  inspect(target.all_cell_ids(), content="[1, 2, 3]")
  inspect(target.selection(), content="[]")
}

///|
test "browser runtime html import/export roundtrips with embed metadata" {
  let source = BrowserRuntime::new()
  ignore(source.add_vertex("A", 0, 0))

  let settings = @kwiver.HtmlEmbedExportSettings::default("https://q.uiver.app")
    .with_fixed_size(400, 320)
  let options = @kwiver.HtmlEmbedExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .with_renderer("svg")
    .with_macro_url("https://example.com/macros.tex")
  let html = source.render_html_embed(settings, options~)

  let target = BrowserRuntime::new()
  target.set_selection([1])
  let imported = target.import_html_embed(html)
  inspect(imported.payload == target.export_payload(), content="true")
  match imported.renderer {
    Some(value) => inspect(value, content="svg")
    None => abort("expected renderer")
  }
  match imported.macro_url {
    Some(value) => inspect(value, content="https://example.com/macros.tex")
    None => abort("expected macro_url")
  }
  inspect(imported.embed, content="true")
  inspect(target.all_cell_ids(), content="[1]")
  inspect(target.selection(), content="[]")
}

///|
test "browser runtime applies incremental mutations via ffi surface" {
  let runtime = BrowserRuntime::new()
  let source_id = runtime.add_vertex("A", 0, 0)
  let target_id = runtime.add_vertex("B", 2, 0)
  let edge_id = runtime.add_edge(source_id, target_id, label="m")

  inspect(runtime.set_label(source_id, "A2"), content="true")
  inspect(
    runtime.set_label_colour(edge_id, @kwiver.Colour::new(240, 100, 50, 1.0)),
    content="true",
  )
  inspect(runtime.move_vertex(source_id, 9, 4), content="true")

  let options = @kwiver.EdgeOptions::at_level(5)
    .with_curve(-2)
    .with_style_tail("hook", side="top")
  inspect(runtime.set_edge_options(edge_id, options), content="true")
  inspect(runtime.reconnect_edge(edge_id, target_id, source_id), content="true")

  let quiver = @kwiver.Quiver::import_base64_v0(runtime.export_payload())
  let mut source_vertex : @kwiver.Vertex? = None
  let mut edge_value : @kwiver.Edge? = None
  for cell in quiver.all_cells() {
    match cell {
      @kwiver.CellData::Vertex(vertex) =>
        if vertex.cell.id == source_id {
          source_vertex = Some(vertex)
        }
      @kwiver.CellData::Edge(edge) =>
        if edge.cell.id == edge_id {
          edge_value = Some(edge)
        }
    }
  }

  match source_vertex {
    Some(vertex) => {
      inspect(vertex.cell.label, content="A2")
      // Base64 canonical export normalises positions by top-left offset.
      inspect(vertex.x, content="7")
      inspect(vertex.y, content="4")
    }
    None => abort("expected updated source vertex")
  }

  match edge_value {
    Some(edge) => {
      inspect(edge.cell.label_colour.h, content="240")
      inspect(edge.source == target_id, content="true")
      inspect(edge.target == source_id, content="true")
      inspect(edge.options.curve, content="-2")
      inspect(edge.options.style.tail.name, content="hook")
      inspect(edge.options.level, content="1")
    }
    None => abort("expected updated edge")
  }
}

///|
test "browser runtime mutation helpers reject mismatched ids" {
  let runtime = BrowserRuntime::new()
  let vertex_id = runtime.add_vertex("A", 0, 0)

  inspect(runtime.move_vertex(999, 1, 1), content="false")
  inspect(runtime.set_label(999, "X"), content="false")
  inspect(
    runtime.set_edge_options(vertex_id, @kwiver.EdgeOptions::at_level(1)),
    content="false",
  )
  inspect(
    runtime.reconnect_edge(vertex_id, vertex_id, vertex_id),
    content="false",
  )
}
