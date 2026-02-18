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
  inspect(restored.render_tikz_json().contains("\"data\":\""), content="true")
  inspect(restored.render_tikz_json().contains("\"metadata\":"), content="true")
}

///|
test "browser runtime render_tikz_json includes dependency metadata" {
  let runtime = BrowserRuntime::new()
  let source_id = runtime.add_vertex("A", 0, 0)
  let target_id = runtime.add_vertex("B", 1, 0)
  ignore(
    runtime.add_edge(
      source_id,
      target_id,
      label="f",
      options=@engine.EdgeOptions::at_level(1).with_shorten(10, 0),
    ),
  )

  let tikz_json = runtime.render_tikz_json()
  inspect(tikz_json.contains("\"dependencies\":"), content="true")
  inspect(tikz_json.contains("quiver"), content="true")
  inspect(tikz_json.contains("\"shortened arrows\":true"), content="true")
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
test "browser runtime import share text supports wrappers and iframe-only" {
  let source = BrowserRuntime::new()
  let source_id = source.add_vertex("A", 0, 0)
  let target_id = source.add_vertex("B", 1, 0)
  ignore(source.add_edge(source_id, target_id, label="f"))

  let tikz = source.render_tikz()

  let target = BrowserRuntime::new()
  target.set_selection([999])
  let imported_tikz = target.import_share_text(tikz)
  inspect(imported_tikz.payload == target.export_payload(), content="true")
  inspect(imported_tikz.renderer, content="None")
  inspect(imported_tikz.embed, content="false")
  inspect(target.all_cell_ids(), content="[1, 2, 3]")
  inspect(target.selection(), content="[]")

  let payload = source.export_payload()
  let iframe_only = [
    "<iframe src='https://q.uiver.app#r=svg&q=", payload, "&embed'></iframe>",
  ].join("")
  let imported_iframe = target.import_share_text(iframe_only)
  inspect(imported_iframe.payload == target.export_payload(), content="true")
  match imported_iframe.renderer {
    Some(value) => inspect(value, content="svg")
    None => abort("expected renderer")
  }
  inspect(imported_iframe.embed, content="true")
  inspect(target.all_cell_ids(), content="[1, 2, 3]")
  inspect(target.selection(), content="[]")
}

///|
test "browser runtime import text auto supports handwritten tikz and raw payload" {
  let runtime = BrowserRuntime::new()
  runtime.set_selection([999])

  let tikz = [
    "\\begin{tikzcd}\n", "A \\arrow[r, \"f\"] & B\n", "\\end{tikzcd}",
  ].join("")
  let imported_tikz = runtime.import_text_auto(tikz)
  inspect(imported_tikz.payload == runtime.export_payload(), content="true")
  inspect(imported_tikz.renderer, content="None")
  inspect(imported_tikz.embed, content="false")
  inspect(runtime.all_cell_ids(), content="[1, 2, 3]")
  inspect(runtime.selection(), content="[]")

  let source = BrowserRuntime::new()
  ignore(source.add_vertex("X", 0, 0))
  let payload = source.export_payload()

  let imported_payload = runtime.import_text_auto(payload)
  inspect(imported_payload.payload, content=payload)
  inspect(imported_payload.renderer, content="None")
  inspect(imported_payload.embed, content="false")
  inspect(runtime.all_cell_ids(), content="[1]")
  inspect(runtime.selection(), content="[]")
}

///|
test "browser runtime json import and paste wrappers support js consumers" {
  let source = BrowserRuntime::new()
  let left_id = source.add_vertex("L", 2, 3)
  let right_id = source.add_vertex("R", 4, 3)
  let edge_id = source.add_edge(left_id, right_id, label="h")
  source.set_selection([edge_id])
  let selection_payload = source.export_selection()

  let target = BrowserRuntime::new()
  let import_json = target.import_text_auto_json(source.render_tikz())
  inspect(import_json.contains("\"payload\":\""), content="true")
  inspect(import_json.contains("\"embed\":false"), content="true")
  inspect(import_json.contains("\"renderer\":null"), content="true")
  inspect(target.all_cell_ids(), content="[1, 2, 3]")
  inspect(target.selection(), content="[]")

  let pasted_json = target.paste_selection_json(
    selection_payload,
    10,
    20,
    start_id=1,
  )
  inspect(pasted_json.contains("\"imported_ids\":"), content="true")
  inspect(pasted_json.contains("\"id_remap\":"), content="true")
  inspect(target.selection().length(), content="3")
}

///|
test "browser runtime fletcher import/export roundtrips with metadata" {
  let source = BrowserRuntime::new()
  let source_id = source.add_vertex("A", 0, 0)
  let target_id = source.add_vertex("B", 1, 0)
  ignore(source.add_edge(source_id, target_id, label="f"))

  let options = @engine.FletcherExportOptions::default()
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

  let settings = @engine.HtmlEmbedExportSettings::default("https://q.uiver.app")
    .with_fixed_size(400, 320)
  let options = @engine.HtmlEmbedExportOptions::default()
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
    runtime.set_label_colour(edge_id, @engine.Colour::new(240, 100, 50, 1.0)),
    content="true",
  )
  inspect(runtime.move_vertex(source_id, 9, 4), content="true")

  let options = @engine.EdgeOptions::at_level(5)
    .with_curve(-2)
    .with_style_tail("hook", side="top")
  inspect(runtime.set_edge_options(edge_id, options), content="true")
  inspect(runtime.reconnect_edge(edge_id, target_id, source_id), content="true")

  let quiver = @engine.Quiver::import_base64_v0(runtime.export_payload())
  let mut source_vertex : @engine.Vertex? = None
  let mut edge_value : @engine.Edge? = None
  for cell in quiver.all_cells() {
    match cell {
      @engine.CellData::Vertex(vertex) =>
        if vertex.cell.id == source_id {
          source_vertex = Some(vertex)
        }
      @engine.CellData::Edge(edge) =>
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
test "browser runtime applies mutation batch through ffi adapter" {
  let runtime = BrowserRuntime::new()
  let source_id = runtime.add_vertex("A", 0, 0)
  let target_id = runtime.add_vertex("B", 2, 0)
  let edge_id = runtime.add_edge(source_id, target_id, label="f")
  runtime.set_selection([source_id, edge_id])

  let batch = @engine.QuiverUiMutationBatch::new(
    [@engine.QuiverUiSetLabelPatch::new(source_id, "A2")],
    [],
    [@engine.QuiverUiMoveVertexPatch::new(source_id, 5, 7)],
    [
      @engine.QuiverUiSetEdgeOptionsPatch::new(
        edge_id,
        @engine.EdgeOptions::at_level(1).with_curve(-1),
      ),
    ],
    [
      @engine.QuiverUiReconnectEdgePatch::new(edge_id, target_id, source_id),
    ],
  )

  let result = runtime.apply_mutation_batch(batch)
  inspect(result.label_results, content="[true]")
  inspect(result.vertex_position_results, content="[true]")
  inspect(result.edge_option_results, content="[true]")
  inspect(result.edge_connection_results, content="[true]")
  inspect(result.payload == runtime.export_payload(), content="true")
  inspect(runtime.selection(), content="[1, 3]")

  let quiver = @engine.Quiver::import_base64_v0(result.payload)
  let mut source_vertex : @engine.Vertex? = None
  let mut edge_value : @engine.Edge? = None
  for cell in quiver.all_cells() {
    match cell {
      @engine.CellData::Vertex(vertex) =>
        if vertex.cell.id == source_id {
          source_vertex = Some(vertex)
        }
      @engine.CellData::Edge(edge) =>
        if edge.cell.id == edge_id {
          edge_value = Some(edge)
        }
    }
  }

  match source_vertex {
    Some(vertex) => {
      inspect(vertex.cell.label, content="A2")
      // Base64 canonical export normalises positions by top-left offset.
      inspect(vertex.x, content="3")
      inspect(vertex.y, content="7")
    }
    None => abort("expected updated source vertex")
  }

  match edge_value {
    Some(edge) => {
      inspect(edge.source == target_id, content="true")
      inspect(edge.target == source_id, content="true")
      inspect(edge.options.curve, content="-1")
    }
    None => abort("expected updated edge")
  }
}

///|
test "browser runtime apply_mutation_batch_json forwards plain json input" {
  let runtime = BrowserRuntime::new()
  let source_id = runtime.add_vertex("A", 0, 0)
  let target_id = runtime.add_vertex("B", 1, 0)
  let edge_id = runtime.add_edge(source_id, target_id, label="f")

  let batch_json = [
    "{",
    "\"labels\":[{\"cell_id\":1,\"label\":\"A-json\"}],",
    "\"edge_connections\":[{\"edge_id\":3,\"source_id\":2,\"target_id\":1}]",
    "}",
  ].join("")

  let result_json = runtime.apply_mutation_batch_json(batch_json)
  inspect(result_json.contains("\"label_results\":[true]"), content="true")
  inspect(result_json.contains("\"edge_connection_results\":[true]"), content="true")

  let quiver = @engine.Quiver::import_base64_v0(runtime.export_payload())
  let mut source_vertex : @engine.Vertex? = None
  let mut edge_value : @engine.Edge? = None
  for cell in quiver.all_cells() {
    match cell {
      @engine.CellData::Vertex(vertex) =>
        if vertex.cell.id == source_id {
          source_vertex = Some(vertex)
        }
      @engine.CellData::Edge(edge) =>
        if edge.cell.id == edge_id {
          edge_value = Some(edge)
        }
    }
  }

  match source_vertex {
    Some(vertex) => inspect(vertex.cell.label, content="A-json")
    None => abort("expected updated source vertex")
  }
  match edge_value {
    Some(edge) => {
      inspect(edge.source == target_id, content="true")
      inspect(edge.target == source_id, content="true")
    }
    None => abort("expected updated edge")
  }
}

///|
test "browser runtime exposes dependency graph queries" {
  let runtime = BrowserRuntime::new()
  let source_id = runtime.add_vertex("A", 0, 0)
  let target_id = runtime.add_vertex("B", 1, 0)
  let edge_id = runtime.add_edge(source_id, target_id, label="f")
  let higher_edge_id = runtime.add_edge(
    edge_id,
    target_id,
    label="alpha",
    options=@engine.EdgeOptions::at_level(2),
  )

  inspect(runtime.all_cells().length(), content="4")
  inspect(runtime.dependencies_of(source_id), content="[3]")
  inspect(runtime.dependencies_of(target_id), content="[3, 4]")
  inspect(runtime.reverse_dependencies_of(edge_id), content="[1, 2]")
  inspect(runtime.transitive_dependencies([source_id]), content="[1, 3, 4]")
  inspect(
    runtime.transitive_dependencies([edge_id], exclude_roots=true),
    content="[4]",
  )
  inspect(
    runtime.transitive_reverse_dependencies([higher_edge_id]),
    content="[1, 2, 3, 4]",
  )
  inspect(runtime.connected_components([source_id]), content="[1, 2, 3, 4]")
}

///|
test "browser runtime mutation helpers reject mismatched ids" {
  let runtime = BrowserRuntime::new()
  let vertex_id = runtime.add_vertex("A", 0, 0)

  inspect(runtime.move_vertex(999, 1, 1), content="false")
  inspect(runtime.set_label(999, "X"), content="false")
  inspect(
    runtime.set_edge_options(vertex_id, @engine.EdgeOptions::at_level(1)),
    content="false",
  )
  inspect(
    runtime.reconnect_edge(vertex_id, vertex_id, vertex_id),
    content="false",
  )
}

///|
test "browser runtime snapshot mirrors ffi snapshot data" {
  let runtime = BrowserRuntime::new()
  let source_id = runtime.add_vertex("A", 0, 0)
  let target_id = runtime.add_vertex("B", 1, 0)
  ignore(runtime.add_edge(source_id, target_id, label="f"))

  let snapshot = runtime.snapshot()
  inspect(snapshot.payload == runtime.export_payload(), content="true")
  inspect(snapshot.cell_ids, content="[1, 2, 3]")
  inspect(snapshot.vertices.length(), content="2")
  inspect(snapshot.edges.length(), content="1")
  inspect(snapshot.dependencies.length(), content="3")
  inspect(snapshot.vertices[0].label, content="A")
  inspect(snapshot.edges[0].label, content="f")
  inspect(snapshot.edges[0].source_id, content="1")
  inspect(snapshot.edges[0].target_id, content="2")
  inspect(snapshot.dependencies[0].dependencies, content="[3]")
  inspect(snapshot.dependencies[2].reverse_dependencies, content="[1, 2]")
}

///|
test "browser runtime snapshot_json exposes plain json for js ui" {
  let runtime = BrowserRuntime::new()
  let source_id = runtime.add_vertex("A", 0, 0)
  let target_id = runtime.add_vertex("B", 1, 0)
  ignore(runtime.add_edge(source_id, target_id, label="f"))

  let snapshot_json = runtime.snapshot_json()
  inspect(snapshot_json.contains("\"payload\":\""), content="true")
  inspect(snapshot_json.contains("\"cell_ids\":[1,2,3]"), content="true")
  inspect(snapshot_json.contains("\"vertices\":"), content="true")
  inspect(snapshot_json.contains("\"edges\":"), content="true")
  inspect(snapshot_json.contains("\"dependencies\":"), content="true")
}

