///|
fn runtime_test_json_get(root : Map[String, Json], key : String) -> Json {
  match root.get(key) {
    Some(value) => value
    None => abort("missing json key")
  }
}
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
test "browser runtime add remove flush json wrappers update selection" {
  let runtime = BrowserRuntime::new()

  let add_vertex_json = runtime.add_vertex_json("{\"label\":\"A\",\"x\":0,\"y\":0}")
  inspect(add_vertex_json.contains("\"id\":1"), content="true")
  inspect(runtime.selection(), content="[1]")

  ignore(runtime.add_vertex("B", 1, 0))
  let add_edge_json = runtime.add_edge_json(
    "{\"source_id\":1,\"target_id\":2,\"label\":\"f\"}",
  )
  inspect(add_edge_json.contains("\"id\":3"), content="true")
  inspect(runtime.selection(), content="[3]")

  let remove_json = runtime.remove_json("{\"cell_id\":1,\"when\":9}")
  inspect(remove_json.contains("\"removed_ids\":"), content="true")
  inspect(runtime.selection(), content="[]")

  let flush_json = runtime.flush_json("{\"when\":9}")
  inspect(flush_json.contains("\"payload\":\""), content="true")
  inspect(runtime.all_cell_ids(), content="[2]")
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

  let fletcher = {
    let options = @engine.FletcherExportOptions::default()
      .with_share_base_url("https://q.uiver.app")
      .with_renderer("svg")
      .with_macro_url("https://example.com/macros.tex")
    source.render_fletcher(options~)
  }

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
  inspect(runtime.set_edge_offset(edge_id, 11), content="true")
  inspect(runtime.set_edge_curve(edge_id, -3), content="true")
  inspect(runtime.set_edge_shorten(edge_id, 6, 4), content="true")
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
      inspect(edge.options.offset, content="11")
      inspect(edge.options.curve, content="-3")
      inspect(edge.options.shorten.source, content="6")
      inspect(edge.options.shorten.target, content="4")
      inspect(edge.options.style.tail.name, content="hook")
      inspect(edge.options.level, content="1")
    }
    None => abort("expected updated edge")
  }
}

///|
test "browser runtime single mutation json wrappers expose ok payload contract" {
  let runtime = BrowserRuntime::new()
  let source_id = runtime.add_vertex("A", 0, 0)
  let target_id = runtime.add_vertex("B", 2, 0)
  let edge_id = runtime.add_edge(source_id, target_id, label="f")

  let set_label_json = runtime.set_label_json(
    ["{\"cell_id\":", source_id.to_string(), ",\"label\":\"A-json\"}"].join(""),
  )
  inspect(set_label_json.contains("\"ok\":true"), content="true")
  inspect(set_label_json.contains("\"payload\":\""), content="true")

  let set_label_colour_json = runtime.set_label_colour_json(
    [
      "{\"cell_id\":",
      edge_id.to_string(),
      ",\"label_colour\":{\"h\":240,\"s\":100,\"l\":50,\"a\":1}}",
    ].join(""),
  )
  inspect(set_label_colour_json.contains("\"ok\":true"), content="true")

  let move_vertex_json = runtime.move_vertex_json(
    [
      "{\"vertex_id\":",
      source_id.to_string(),
      ",\"x\":5,\"y\":7}",
    ].join(""),
  )
  inspect(move_vertex_json.contains("\"ok\":true"), content="true")

  let set_edge_options_json = runtime.set_edge_options_json(
    [
      "{",
      "\"edge_id\":", edge_id.to_string(), ",",
      "\"options\":{",
      "\"label_alignment\":\"left\",",
      "\"label_position\":50,",
      "\"offset\":0,",
      "\"curve\":-2,",
      "\"radius\":0,",
      "\"angle\":0,",
      "\"shorten_source\":0,",
      "\"shorten_target\":0,",
      "\"level\":9,",
      "\"shape\":\"bezier\",",
      "\"colour\":{\"h\":0,\"s\":100,\"l\":50,\"a\":1},",
      "\"edge_alignment_source\":true,",
      "\"edge_alignment_target\":true,",
      "\"style\":{",
      "\"name\":\"arrow\",",
      "\"tail\":{\"name\":\"mono\",\"side\":\"top\"},",
      "\"body\":{\"name\":\"barred\",\"side\":\"center\"},",
      "\"head\":{\"name\":\"epi\",\"side\":\"bottom\"}",
      "}",
      "}",
      "}",
    ].join(""),
  )
  inspect(set_edge_options_json.contains("\"ok\":true"), content="true")
  let set_edge_offset_json = runtime.set_edge_offset_json(
    [
      "{\"edge_id\":",
      edge_id.to_string(),
      ",\"offset\":11}",
    ].join(""),
  )
  inspect(set_edge_offset_json.contains("\"ok\":true"), content="true")
  let set_edge_curve_json = runtime.set_edge_curve_json(
    [
      "{\"edge_id\":",
      edge_id.to_string(),
      ",\"curve\":-3}",
    ].join(""),
  )
  inspect(set_edge_curve_json.contains("\"ok\":true"), content="true")
  let set_edge_shorten_json = runtime.set_edge_shorten_json(
    [
      "{\"edge_id\":",
      edge_id.to_string(),
      ",\"shorten_source\":6,\"shorten_target\":4}",
    ].join(""),
  )
  inspect(set_edge_shorten_json.contains("\"ok\":true"), content="true")

  let reconnect_edge_json = runtime.reconnect_edge_json(
    [
      "{\"edge_id\":",
      edge_id.to_string(),
      ",\"source_id\":",
      target_id.to_string(),
      ",\"target_id\":",
      source_id.to_string(),
      "}",
    ].join(""),
  )
  inspect(reconnect_edge_json.contains("\"ok\":true"), content="true")

  let missing_json = runtime.set_label_json("{\"cell_id\":999,\"label\":\"missing\"}")
  inspect(missing_json.contains("\"ok\":false"), content="true")

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
      inspect(vertex.cell.label, content="A-json")
      // Base64 canonical export normalises positions by top-left offset.
      inspect(vertex.x, content="3")
      inspect(vertex.y, content="7")
    }
    None => abort("expected updated source vertex")
  }

  match edge_value {
    Some(edge) => {
      inspect(edge.cell.label_colour.h, content="240")
      inspect(edge.source == target_id, content="true")
      inspect(edge.target == source_id, content="true")
      inspect(edge.options.offset, content="11")
      inspect(edge.options.curve, content="-3")
      inspect(edge.options.shorten.source, content="6")
      inspect(edge.options.shorten.target, content="4")
      inspect(edge.options.style.body.name, content="barred")
      inspect(edge.options.style.head.name, content="epi")
      inspect(edge.options.level, content="1")
    }
    None => abort("expected updated edge")
  }
}

///|
test "browser runtime dispatch_json routes action envelopes for ui loop" {
  let runtime = BrowserRuntime::new()

  let add_a_dispatch = runtime.dispatch_json(
    "{\"action\":\"add_vertex_json\",\"input\":{\"label\":\"A\",\"x\":0,\"y\":0}}",
  )
  let add_a_root : Map[String, Json] = @json.from_json(@json.parse(add_a_dispatch))
  let add_a_ok : Bool = @json.from_json(runtime_test_json_get(add_a_root, "ok"))
  inspect(add_a_ok, content="true")
  let add_a_result : Map[String, Json] = @json.from_json(
    runtime_test_json_get(add_a_root, "result"),
  )
  let add_a_id : Int = @json.from_json(runtime_test_json_get(add_a_result, "id"))
  inspect(add_a_id, content="1")

  let add_b_dispatch = runtime.dispatch_json(
    "{\"action\":\"add_vertex_json\",\"input\":{\"label\":\"B\",\"x\":1,\"y\":0}}",
  )
  let add_b_root : Map[String, Json] = @json.from_json(@json.parse(add_b_dispatch))
  let add_b_result : Map[String, Json] = @json.from_json(
    runtime_test_json_get(add_b_root, "result"),
  )
  let add_b_id : Int = @json.from_json(runtime_test_json_get(add_b_result, "id"))
  inspect(add_b_id, content="2")

  let add_edge_dispatch = runtime.dispatch_json(
    "{\"action\":\"add_edge_json\",\"input\":{\"source_id\":1,\"target_id\":2,\"label\":\"f\"}}",
  )
  let add_edge_root : Map[String, Json] = @json.from_json(
    @json.parse(add_edge_dispatch),
  )
  let add_edge_result : Map[String, Json] = @json.from_json(
    runtime_test_json_get(add_edge_root, "result"),
  )
  let edge_id : Int = @json.from_json(runtime_test_json_get(add_edge_result, "id"))
  inspect(edge_id, content="3")
  inspect(runtime.selection(), content="[3]")

  let set_offset_dispatch = runtime.dispatch_json(
    "{\"action\":\"set_edge_offset_json\",\"input\":{\"edge_id\":3,\"offset\":11}}",
  )
  let set_offset_root : Map[String, Json] = @json.from_json(
    @json.parse(set_offset_dispatch),
  )
  let set_offset_result : Map[String, Json] = @json.from_json(
    runtime_test_json_get(set_offset_root, "result"),
  )
  let set_offset_ok : Bool = @json.from_json(
    runtime_test_json_get(set_offset_result, "ok"),
  )
  inspect(set_offset_ok, content="true")

  let snapshot_dispatch = runtime.dispatch_json("{\"action\":\"snapshot_json\"}")
  let snapshot_root : Map[String, Json] = @json.from_json(
    @json.parse(snapshot_dispatch),
  )
  let snapshot_result : Map[String, Json] = @json.from_json(
    runtime_test_json_get(snapshot_root, "result"),
  )
  let snapshot_cell_ids : Array[Int] = @json.from_json(
    runtime_test_json_get(snapshot_result, "cell_ids"),
  )
  inspect(snapshot_cell_ids, content="[1, 2, 3]")

  let deps_dispatch = runtime.dispatch_json(
    "{\"action\":\"dependencies_of_json\",\"input\":{\"cell_id\":1}}",
  )
  let deps_root : Map[String, Json] = @json.from_json(@json.parse(deps_dispatch))
  let deps_result : Array[Int] = @json.from_json(runtime_test_json_get(deps_root, "result"))
  inspect(deps_result, content="[3]")

  let reverse_deps_dispatch = runtime.dispatch_json(
    "{\"action\":\"reverse_dependencies_of_json\",\"input\":{\"cell_id\":3}}",
  )
  let reverse_deps_root : Map[String, Json] = @json.from_json(
    @json.parse(reverse_deps_dispatch),
  )
  let reverse_deps_result : Array[Int] = @json.from_json(
    runtime_test_json_get(reverse_deps_root, "result"),
  )
  inspect(reverse_deps_result, content="[1, 2]")

  let transitive_deps_dispatch = runtime.dispatch_json(
    "{\"action\":\"transitive_dependencies_json\",\"input\":{\"roots\":[1],\"exclude_roots\":true}}",
  )
  let transitive_deps_root : Map[String, Json] = @json.from_json(
    @json.parse(transitive_deps_dispatch),
  )
  let transitive_deps_result : Array[Int] = @json.from_json(
    runtime_test_json_get(transitive_deps_root, "result"),
  )
  inspect(transitive_deps_result, content="[3]")

  let transitive_reverse_dispatch = runtime.dispatch_json(
    "{\"action\":\"transitive_reverse_dependencies_json\",\"input\":{\"roots\":[3]}}",
  )
  let transitive_reverse_root : Map[String, Json] = @json.from_json(
    @json.parse(transitive_reverse_dispatch),
  )
  let transitive_reverse_result : Array[Int] = @json.from_json(
    runtime_test_json_get(transitive_reverse_root, "result"),
  )
  inspect(transitive_reverse_result, content="[1, 2, 3]")

  let components_dispatch = runtime.dispatch_json(
    "{\"type\":\"connected_components_json\",\"input\":{\"roots\":[1]}}",
  )
  let components_root : Map[String, Json] = @json.from_json(
    @json.parse(components_dispatch),
  )
  let components_action : String = @json.from_json(
    runtime_test_json_get(components_root, "action"),
  )
  let components_result : Array[Int] = @json.from_json(
    runtime_test_json_get(components_root, "result"),
  )
  inspect(components_action, content="connected_components_json")
  inspect(components_result, content="[1, 2, 3]")

  let payload_dispatch = runtime.dispatch_json("{\"action\":\"export_payload\"}")
  let payload_root : Map[String, Json] = @json.from_json(@json.parse(payload_dispatch))
  let payload_value : String = @json.from_json(
    runtime_test_json_get(payload_root, "result"),
  )
  inspect(payload_value == runtime.export_payload(), content="true")

  let tikz_dispatch = runtime.dispatch_json(
    [
      "{",
      "\"action\":\"render_tikz_json\",",
      "\"input\":{",
      "\"settings\":{\"centre_diagram\":true},",
      "\"options\":{",
      "\"share_base_url\":\"https://q.uiver.app\",",
      "\"renderer\":\"svg\",",
      "\"sep_em\":2.70",
      "}",
      "}",
      "}",
    ].join(""),
  )
  let tikz_root : Map[String, Json] = @json.from_json(@json.parse(tikz_dispatch))
  let tikz_result : Map[String, Json] = @json.from_json(
    runtime_test_json_get(tikz_root, "result"),
  )
  let tikz_data : String = @json.from_json(runtime_test_json_get(tikz_result, "data"))
  inspect(tikz_data.contains("\\begin{tikzcd}[sep=large]"), content="true")
  inspect(tikz_data.contains("% https://q.uiver.app#r=svg&q="), content="true")

  let fletcher_dispatch = runtime.dispatch_json(
    [
      "{",
      "\"action\":\"render_fletcher\",",
      "\"input\":{\"options\":{\"share_base_url\":\"https://q.uiver.app\",\"renderer\":\"svg\"}}",
      "}",
    ].join(""),
  )
  let fletcher_root : Map[String, Json] = @json.from_json(
    @json.parse(fletcher_dispatch),
  )
  let fletcher_data : String = @json.from_json(
    runtime_test_json_get(fletcher_root, "result"),
  )
  inspect(fletcher_data.contains("#diagram({"), content="true")
  inspect(fletcher_data.contains("// https://q.uiver.app#r=svg&q="), content="true")

  let html_dispatch = runtime.dispatch_json(
    [
      "{",
      "\"action\":\"render_html_embed\",",
      "\"input\":{",
      "\"settings\":{\"base_url\":\"https://q.uiver.app\",\"fixed_size\":true,\"width\":320,\"height\":240},",
      "\"options\":{\"renderer\":\"svg\"}",
      "}",
      "}",
    ].join(""),
  )
  let html_root : Map[String, Json] = @json.from_json(@json.parse(html_dispatch))
  let html_data : String = @json.from_json(runtime_test_json_get(html_root, "result"))
  inspect(html_data.contains("<iframe class=\"quiver-embed\""), content="true")
  inspect(html_data.contains("#r=svg&q="), content="true")

  let export_selection_dispatch = runtime.dispatch_json(
    "{\"action\":\"export_selection\",\"input\":{\"include_dependencies\":false}}",
  )
  let export_selection_root : Map[String, Json] = @json.from_json(
    @json.parse(export_selection_dispatch),
  )
  let export_selection_value : String = @json.from_json(
    runtime_test_json_get(export_selection_root, "result"),
  )
  inspect(
    export_selection_value == runtime.export_selection(include_dependencies=false),
    content="true",
  )

  let reset_dispatch = runtime.dispatch_json("{\"action\":\"reset\"}")
  let reset_root : Map[String, Json] = @json.from_json(@json.parse(reset_dispatch))
  let reset_ok : Bool = @json.from_json(runtime_test_json_get(reset_root, "ok"))
  inspect(reset_ok, content="true")
  inspect(runtime.all_cell_ids(), content="[]")
  inspect(runtime.selection(), content="[]")

  let import_payload_dispatch = runtime.dispatch_json(
    [
      "{\"action\":\"import_payload\",\"input\":{\"payload\":\"",
      payload_value,
      "\"}}",
    ].join(""),
  )
  let import_payload_root : Map[String, Json] = @json.from_json(
    @json.parse(import_payload_dispatch),
  )
  let import_payload_value : String = @json.from_json(
    runtime_test_json_get(import_payload_root, "result"),
  )
  inspect(import_payload_value == payload_value, content="true")
  inspect(runtime.all_cell_ids(), content="[1, 2, 3]")

  let set_selection_dispatch = runtime.dispatch_json(
    "{\"action\":\"set_selection\",\"input\":[3]}",
  )
  let set_selection_root : Map[String, Json] = @json.from_json(
    @json.parse(set_selection_dispatch),
  )
  let set_selection_result : Array[Int] = @json.from_json(
    runtime_test_json_get(set_selection_root, "result"),
  )
  inspect(set_selection_result, content="[3]")

  let selection_dispatch = runtime.dispatch_json("{\"action\":\"selection\"}")
  let selection_root : Map[String, Json] = @json.from_json(
    @json.parse(selection_dispatch),
  )
  let selection_result : Array[Int] = @json.from_json(
    runtime_test_json_get(selection_root, "result"),
  )
  inspect(selection_result, content="[3]")

  let unknown_dispatch = runtime.dispatch_json("{\"action\":\"unknown-action\"}")
  let unknown_root : Map[String, Json] = @json.from_json(
    @json.parse(unknown_dispatch),
  )
  let unknown_ok : Bool = @json.from_json(runtime_test_json_get(unknown_root, "ok"))
  let unknown_error : String = @json.from_json(
    runtime_test_json_get(unknown_root, "error"),
  )
  inspect(unknown_ok, content="false")
  inspect(unknown_error.contains("unknown runtime dispatch action"), content="true")
}

///|
test "browser runtime dispatch_many_json batches ordered action envelopes" {
  let runtime = BrowserRuntime::new()
  let batch_json = [
    "[",
    "{\"action\":\"add_vertex_json\",\"input\":{\"label\":\"A\",\"x\":0,\"y\":0}},",
    "{\"action\":\"add_vertex_json\",\"input\":{\"label\":\"B\",\"x\":1,\"y\":0}},",
    "{\"action\":\"add_edge_json\",\"input\":{\"source_id\":1,\"target_id\":2,\"label\":\"f\"}},",
    "{\"action\":\"set_selection\",\"input\":[1,3]},",
    "{\"action\":\"export_selection\",\"input\":{\"include_dependencies\":false}}",
    "]",
  ].join("")

  let batch_dispatch = runtime.dispatch_many_json(batch_json)
  let batch_root : Map[String, Json] = @json.from_json(@json.parse(batch_dispatch))
  let batch_ok : Bool = @json.from_json(runtime_test_json_get(batch_root, "ok"))
  let processed : Int = @json.from_json(
    runtime_test_json_get(batch_root, "processed"),
  )
  let results : Array[Json] = @json.from_json(
    runtime_test_json_get(batch_root, "results"),
  )

  inspect(batch_ok, content="true")
  inspect(processed, content="5")
  inspect(results.length(), content="5")

  let first_result : Map[String, Json] = @json.from_json(results[0])
  let first_action : String = @json.from_json(
    runtime_test_json_get(first_result, "action"),
  )
  inspect(first_action, content="add_vertex_json")

  let last_result : Map[String, Json] = @json.from_json(results[4])
  let exported_selection : String = @json.from_json(
    runtime_test_json_get(last_result, "result"),
  )
  inspect(
    exported_selection == runtime.export_selection(include_dependencies=false),
    content="true",
  )

  let payload_value : String = @json.from_json(
    runtime_test_json_get(batch_root, "payload"),
  )
  inspect(payload_value == runtime.export_payload(), content="true")
  inspect(runtime.all_cell_ids(), content="[1, 2, 3]")
  inspect(runtime.selection(), content="[1, 3]")
}

///|
test "browser runtime dispatch_many_json supports stop_on_error short-circuit" {
  let runtime = BrowserRuntime::new()
  let batch_json = [
    "{",
    "\"stop_on_error\":true,",
    "\"actions\":[",
    "{\"action\":\"add_vertex_json\",\"input\":{\"label\":\"A\",\"x\":0,\"y\":0}},",
    "{\"action\":\"unknown-action\"},",
    "{\"action\":\"add_vertex_json\",\"input\":{\"label\":\"B\",\"x\":2,\"y\":0}}",
    "]",
    "}",
  ].join("")

  let batch_dispatch = runtime.dispatch_many_json(batch_json)
  let batch_root : Map[String, Json] = @json.from_json(@json.parse(batch_dispatch))
  let batch_ok : Bool = @json.from_json(runtime_test_json_get(batch_root, "ok"))
  let processed : Int = @json.from_json(
    runtime_test_json_get(batch_root, "processed"),
  )
  let results : Array[Json] = @json.from_json(
    runtime_test_json_get(batch_root, "results"),
  )
  inspect(batch_ok, content="false")
  inspect(processed, content="2")
  inspect(results.length(), content="2")

  let second_result : Map[String, Json] = @json.from_json(results[1])
  let second_ok : Bool = @json.from_json(runtime_test_json_get(second_result, "ok"))
  inspect(second_ok, content="false")
  inspect(runtime.all_cell_ids(), content="[1]")
  inspect(runtime.selection(), content="[1]")
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
    runtime.set_edge_label_alignment(vertex_id, "left"),
    content="false",
  )
  inspect(runtime.set_edge_label_position(vertex_id, 50), content="false")
  inspect(runtime.set_edge_offset(vertex_id, 1), content="false")
  inspect(runtime.set_edge_curve(vertex_id, 1), content="false")
  inspect(runtime.set_edge_shorten(vertex_id, 1, 1), content="false")
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

///|
test "browser runtime ffi wrappers expose js entrypoint surface" {
  let runtime = ffi_browser_runtime_new()

  let add_a_json = ffi_browser_runtime_add_vertex_json(
    runtime,
    "{\"label\":\"A\",\"x\":0,\"y\":0}",
  )
  inspect(add_a_json.contains("\"id\":1"), content="true")

  let add_b_json = ffi_browser_runtime_add_vertex_json(
    runtime,
    "{\"label\":\"B\",\"x\":1,\"y\":0}",
  )
  inspect(add_b_json.contains("\"id\":2"), content="true")

  let add_edge_json = ffi_browser_runtime_add_edge_json(
    runtime,
    "{\"source_id\":1,\"target_id\":2,\"label\":\"f\"}",
  )
  inspect(add_edge_json.contains("\"id\":3"), content="true")
  inspect(ffi_browser_runtime_all_cells(runtime).length(), content="3")
  let all_cells_json = ffi_browser_runtime_all_cells_json(runtime)
  inspect(all_cells_json.contains("\"kind\":\"vertex\""), content="true")
  inspect(all_cells_json.contains("\"kind\":\"edge\""), content="true")
  inspect(all_cells_json.contains("\"source_id\":1"), content="true")
  inspect(all_cells_json.contains("\"target_id\":2"), content="true")
  inspect(all_cells_json.contains("\"options\":"), content="true")

  let set_label_json = ffi_browser_runtime_set_label_json(
    runtime,
    "{\"cell_id\":3,\"label\":\"f-updated\"}",
  )
  inspect(set_label_json.contains("\"ok\":true"), content="true")
  let set_label_colour_json = ffi_browser_runtime_set_label_colour_json(
    runtime,
    "{\"cell_id\":3,\"label_colour\":{\"h\":240,\"s\":100,\"l\":50,\"a\":1}}",
  )
  inspect(set_label_colour_json.contains("\"ok\":true"), content="true")
  let move_vertex_json = ffi_browser_runtime_move_vertex_json(
    runtime,
    "{\"vertex_id\":1,\"x\":2,\"y\":3}",
  )
  inspect(move_vertex_json.contains("\"ok\":true"), content="true")
  let set_edge_options_json = ffi_browser_runtime_set_edge_options_json(
    runtime,
    [
      "{",
      "\"edge_id\":3,",
      "\"options\":{",
      "\"label_alignment\":\"left\",",
      "\"label_position\":50,",
      "\"offset\":0,",
      "\"curve\":-2,",
      "\"radius\":0,",
      "\"angle\":0,",
      "\"shorten_source\":0,",
      "\"shorten_target\":0,",
      "\"level\":9,",
      "\"shape\":\"bezier\",",
      "\"colour\":{\"h\":0,\"s\":100,\"l\":50,\"a\":1},",
      "\"edge_alignment_source\":true,",
      "\"edge_alignment_target\":true,",
      "\"style\":{",
      "\"name\":\"arrow\",",
      "\"tail\":{\"name\":\"mono\",\"side\":\"top\"},",
      "\"body\":{\"name\":\"barred\",\"side\":\"center\"},",
      "\"head\":{\"name\":\"epi\",\"side\":\"bottom\"}",
      "}",
      "}",
      "}",
    ].join(""),
  )
  inspect(set_edge_options_json.contains("\"ok\":true"), content="true")
  let set_edge_label_alignment_json =
    ffi_browser_runtime_set_edge_label_alignment_json(
      runtime,
      "{\"edge_id\":3,\"label_alignment\":\"right\"}",
    )
  inspect(set_edge_label_alignment_json.contains("\"ok\":true"), content="true")
  let set_edge_label_position_json = ffi_browser_runtime_set_edge_label_position_json(
    runtime,
    "{\"edge_id\":3,\"label_position\":80}",
  )
  inspect(set_edge_label_position_json.contains("\"ok\":true"), content="true")
  let set_edge_offset_json = ffi_browser_runtime_set_edge_offset_json(
    runtime,
    "{\"edge_id\":3,\"offset\":11}",
  )
  inspect(set_edge_offset_json.contains("\"ok\":true"), content="true")
  let set_edge_curve_json = ffi_browser_runtime_set_edge_curve_json(
    runtime,
    "{\"edge_id\":3,\"curve\":-3}",
  )
  inspect(set_edge_curve_json.contains("\"ok\":true"), content="true")
  let set_edge_shorten_json = ffi_browser_runtime_set_edge_shorten_json(
    runtime,
    "{\"edge_id\":3,\"shorten_source\":6,\"shorten_target\":4}",
  )
  inspect(set_edge_shorten_json.contains("\"ok\":true"), content="true")
  let reconnect_edge_json = ffi_browser_runtime_reconnect_edge_json(
    runtime,
    "{\"edge_id\":3,\"source_id\":2,\"target_id\":1}",
  )
  inspect(reconnect_edge_json.contains("\"ok\":true"), content="true")

  ffi_browser_runtime_set_selection(runtime, [3])
  inspect(ffi_browser_runtime_selection(runtime), content="[3]")

  let selection_payload = ffi_browser_runtime_export_selection(runtime)
  inspect(selection_payload != "", content="true")

  let snapshot_json = ffi_browser_runtime_snapshot_json(runtime)
  inspect(snapshot_json.contains("\"cell_ids\":[1,2,3]"), content="true")

  let tikz_json = ffi_browser_runtime_render_tikz_json(runtime)
  inspect(tikz_json.contains("\"data\":\""), content="true")
  inspect(tikz_json.contains("\"metadata\":"), content="true")
  let fletcher_out = ffi_browser_runtime_render_fletcher(runtime)
  inspect(fletcher_out.contains("#diagram({"), content="true")
  let html_out = ffi_browser_runtime_render_html_embed(
    runtime,
    @engine.HtmlEmbedExportSettings::default("https://q.uiver.app").with_fixed_size(
      320,
      240,
    ),
  )
  inspect(html_out.contains("<iframe class=\"quiver-embed\""), content="true")

  let imported_json = ffi_browser_runtime_import_text_auto_json(
    runtime,
    "\\begin{tikzcd}\nX \\arrow[r, \"g\"] & Y\n\\end{tikzcd}",
  )
  inspect(imported_json.contains("\"payload\":\""), content="true")
  inspect(imported_json.contains("\"embed\":false"), content="true")
  inspect(ffi_browser_runtime_selection(runtime), content="[]")

  let source = ffi_browser_runtime_new()
  ignore(
    ffi_browser_runtime_add_vertex_json(
      source,
      "{\"label\":\"L\",\"x\":2,\"y\":3}",
    ),
  )
  ignore(
    ffi_browser_runtime_add_vertex_json(
      source,
      "{\"label\":\"R\",\"x\":4,\"y\":3}",
    ),
  )
  ignore(
    ffi_browser_runtime_add_edge_json(
      source,
      "{\"source_id\":1,\"target_id\":2,\"label\":\"h\"}",
    ),
  )
  ffi_browser_runtime_set_selection(source, [3])

  let pasted_json = ffi_browser_runtime_paste_selection_json(
    runtime,
    ffi_browser_runtime_export_selection(source),
    10,
    20,
    start_id=1,
  )
  inspect(pasted_json.contains("\"imported_ids\":"), content="true")

  let batch_json = ffi_browser_runtime_apply_mutation_batch_json(
    runtime,
    "{\"labels\":[{\"cell_id\":1,\"label\":\"X2\"}]}",
  )
  inspect(batch_json.contains("\"label_results\":[true]"), content="true")

  let remove_json = ffi_browser_runtime_remove_json(
    runtime,
    "{\"cell_id\":1,\"when\":9}",
  )
  inspect(remove_json.contains("\"removed_ids\":"), content="true")

  let flush_json = ffi_browser_runtime_flush_json(runtime, "{\"when\":9}")
  inspect(flush_json.contains("\"payload\":\""), content="true")

  inspect(ffi_browser_runtime_export_payload(runtime) != "", content="true")
  ffi_browser_runtime_reset(runtime)
  inspect(ffi_browser_runtime_selection(runtime), content="[]")
}

///|
test "browser runtime ffi dispatch wrapper exposes single-entrypoint ui surface" {
  let runtime = ffi_browser_runtime_new()

  let add_a_dispatch = ffi_browser_runtime_dispatch_json(
    runtime,
    "{\"action\":\"add_vertex_json\",\"input\":{\"label\":\"A\",\"x\":0,\"y\":0}}",
  )
  let add_a_root : Map[String, Json] = @json.from_json(@json.parse(add_a_dispatch))
  let add_a_ok : Bool = @json.from_json(runtime_test_json_get(add_a_root, "ok"))
  let add_a_action : String = @json.from_json(
    runtime_test_json_get(add_a_root, "action"),
  )
  inspect(add_a_ok, content="true")
  inspect(add_a_action, content="add_vertex_json")

  let add_b_dispatch = ffi_browser_runtime_dispatch_json(
    runtime,
    "{\"action\":\"add_vertex_json\",\"input\":{\"label\":\"B\",\"x\":1,\"y\":0}}",
  )
  let add_b_root : Map[String, Json] = @json.from_json(@json.parse(add_b_dispatch))
  let add_b_ok : Bool = @json.from_json(runtime_test_json_get(add_b_root, "ok"))
  inspect(add_b_ok, content="true")

  let add_edge_dispatch = ffi_browser_runtime_dispatch_json(
    runtime,
    "{\"action\":\"add_edge_json\",\"input\":{\"source_id\":1,\"target_id\":2,\"label\":\"f\"}}",
  )
  let add_edge_root : Map[String, Json] = @json.from_json(
    @json.parse(add_edge_dispatch),
  )
  let add_edge_ok : Bool = @json.from_json(
    runtime_test_json_get(add_edge_root, "ok"),
  )
  inspect(add_edge_ok, content="true")

  let snapshot_dispatch = ffi_browser_runtime_dispatch_json(
    runtime,
    "{\"action\":\"snapshot_json\"}",
  )
  let snapshot_root : Map[String, Json] = @json.from_json(
    @json.parse(snapshot_dispatch),
  )
  let snapshot_result : Map[String, Json] = @json.from_json(
    runtime_test_json_get(snapshot_root, "result"),
  )
  let cell_ids : Array[Int] = @json.from_json(
    runtime_test_json_get(snapshot_result, "cell_ids"),
  )
  inspect(cell_ids, content="[1, 2, 3]")

  let deps_dispatch = ffi_browser_runtime_dispatch_json(
    runtime,
    "{\"type\":\"dependencies_of_json\",\"input\":{\"cell_id\":1}}",
  )
  let deps_root : Map[String, Json] = @json.from_json(@json.parse(deps_dispatch))
  let deps_action : String = @json.from_json(runtime_test_json_get(deps_root, "action"))
  let deps_result : Array[Int] = @json.from_json(runtime_test_json_get(deps_root, "result"))
  inspect(deps_action, content="dependencies_of_json")
  inspect(deps_result, content="[3]")

  let payload_dispatch = ffi_browser_runtime_dispatch_json(
    runtime,
    "{\"action\":\"export_payload\"}",
  )
  let payload_root : Map[String, Json] = @json.from_json(
    @json.parse(payload_dispatch),
  )
  let payload_value : String = @json.from_json(
    runtime_test_json_get(payload_root, "result"),
  )

  let tikz_dispatch = ffi_browser_runtime_dispatch_json(
    runtime,
    [
      "{",
      "\"action\":\"render_tikz_json\",",
      "\"input\":{",
      "\"settings\":{\"centre_diagram\":true},",
      "\"options\":{\"share_base_url\":\"https://q.uiver.app\",\"renderer\":\"svg\",\"sep_em\":2.70}",
      "}",
      "}",
    ].join(""),
  )
  let tikz_root : Map[String, Json] = @json.from_json(@json.parse(tikz_dispatch))
  let tikz_result : Map[String, Json] = @json.from_json(
    runtime_test_json_get(tikz_root, "result"),
  )
  let tikz_data : String = @json.from_json(runtime_test_json_get(tikz_result, "data"))
  inspect(tikz_data.contains("\\begin{tikzcd}[sep=large]"), content="true")
  inspect(tikz_data.contains("% https://q.uiver.app#r=svg&q="), content="true")

  let fletcher_dispatch = ffi_browser_runtime_dispatch_json(
    runtime,
    [
      "{",
      "\"action\":\"render_fletcher\",",
      "\"input\":{\"options\":{\"share_base_url\":\"https://q.uiver.app\",\"renderer\":\"svg\"}}",
      "}",
    ].join(""),
  )
  let fletcher_root : Map[String, Json] = @json.from_json(
    @json.parse(fletcher_dispatch),
  )
  let fletcher_data : String = @json.from_json(
    runtime_test_json_get(fletcher_root, "result"),
  )
  inspect(fletcher_data.contains("#diagram({"), content="true")
  inspect(fletcher_data.contains("// https://q.uiver.app#r=svg&q="), content="true")

  let html_dispatch = ffi_browser_runtime_dispatch_json(
    runtime,
    [
      "{",
      "\"action\":\"render_html_embed\",",
      "\"input\":{",
      "\"settings\":{\"base_url\":\"https://q.uiver.app\",\"fixed_size\":true,\"width\":320,\"height\":240},",
      "\"options\":{\"renderer\":\"svg\"}",
      "}",
      "}",
    ].join(""),
  )
  let html_root : Map[String, Json] = @json.from_json(@json.parse(html_dispatch))
  let html_data : String = @json.from_json(runtime_test_json_get(html_root, "result"))
  inspect(html_data.contains("<iframe class=\"quiver-embed\""), content="true")
  inspect(html_data.contains("#r=svg&q="), content="true")

  let export_selection_dispatch = ffi_browser_runtime_dispatch_json(
    runtime,
    "{\"action\":\"export_selection\",\"input\":{\"include_dependencies\":false}}",
  )
  let export_selection_root : Map[String, Json] = @json.from_json(
    @json.parse(export_selection_dispatch),
  )
  let export_selection_value : String = @json.from_json(
    runtime_test_json_get(export_selection_root, "result"),
  )
  inspect(export_selection_value != "", content="true")

  let reset_dispatch = ffi_browser_runtime_dispatch_json(
    runtime,
    "{\"action\":\"reset\"}",
  )
  let reset_root : Map[String, Json] = @json.from_json(@json.parse(reset_dispatch))
  let reset_ok : Bool = @json.from_json(runtime_test_json_get(reset_root, "ok"))
  inspect(reset_ok, content="true")
  inspect(ffi_browser_runtime_all_cell_ids(runtime), content="[]")

  let import_payload_dispatch = ffi_browser_runtime_dispatch_json(
    runtime,
    ["{\"action\":\"import_payload\",\"input\":\"", payload_value, "\"}"].join(""),
  )
  let import_payload_root : Map[String, Json] = @json.from_json(
    @json.parse(import_payload_dispatch),
  )
  let import_payload_value : String = @json.from_json(
    runtime_test_json_get(import_payload_root, "result"),
  )
  inspect(import_payload_value == payload_value, content="true")
  inspect(ffi_browser_runtime_all_cell_ids(runtime), content="[1, 2, 3]")

  let unknown_dispatch = ffi_browser_runtime_dispatch_json(
    runtime,
    "{\"action\":\"unknown-action\"}",
  )
  let unknown_root : Map[String, Json] = @json.from_json(
    @json.parse(unknown_dispatch),
  )
  let unknown_ok : Bool = @json.from_json(runtime_test_json_get(unknown_root, "ok"))
  inspect(unknown_ok, content="false")
}

///|
test "browser runtime ffi dispatch_many wrapper batches ui envelopes" {
  let runtime = ffi_browser_runtime_new()
  let batch_json = [
    "[",
    "{\"action\":\"add_vertex_json\",\"input\":{\"label\":\"A\",\"x\":0,\"y\":0}},",
    "{\"action\":\"add_vertex_json\",\"input\":{\"label\":\"B\",\"x\":1,\"y\":0}},",
    "{\"action\":\"add_edge_json\",\"input\":{\"source_id\":1,\"target_id\":2,\"label\":\"f\"}},",
    "{\"action\":\"snapshot_json\"}",
    "]",
  ].join("")

  let batch_dispatch = ffi_browser_runtime_dispatch_many_json(runtime, batch_json)
  let batch_root : Map[String, Json] = @json.from_json(@json.parse(batch_dispatch))
  let batch_ok : Bool = @json.from_json(runtime_test_json_get(batch_root, "ok"))
  let processed : Int = @json.from_json(
    runtime_test_json_get(batch_root, "processed"),
  )
  let results : Array[Json] = @json.from_json(
    runtime_test_json_get(batch_root, "results"),
  )
  inspect(batch_ok, content="true")
  inspect(processed, content="4")
  inspect(results.length(), content="4")
  inspect(ffi_browser_runtime_all_cell_ids(runtime), content="[1, 2, 3]")

  let snapshot_entry : Map[String, Json] = @json.from_json(results[3])
  let snapshot_result : Map[String, Json] = @json.from_json(
    runtime_test_json_get(snapshot_entry, "result"),
  )
  let cell_ids : Array[Int] = @json.from_json(
    runtime_test_json_get(snapshot_result, "cell_ids"),
  )
  inspect(cell_ids, content="[1, 2, 3]")
}

///|
test "browser runtime ffi wrappers support format-specific import json" {
  let source = BrowserRuntime::new()
  let source_id = source.add_vertex("A", 0, 0)
  let target_id = source.add_vertex("B", 1, 0)
  ignore(source.add_edge(source_id, target_id, label="f"))

  let payload = source.export_payload()
  let share_url = [
    "https://q.uiver.app#r=svg&q=",
    payload,
    "&macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex",
  ].join("")

  let target = ffi_browser_runtime_new()

  let share_url_json = ffi_browser_runtime_import_share_url_json(target, share_url)
  inspect(share_url_json.contains("\"renderer\":\"svg\""), content="true")
  inspect(
    share_url_json.contains("\"macro_url\":\"https://example.com/macros.tex\""),
    content="true",
  )

  let tikz_json = ffi_browser_runtime_import_tikz_cd_json(target, source.render_tikz())
  inspect(tikz_json.contains("\"renderer\":null"), content="true")
  inspect(tikz_json.contains("\"embed\":false"), content="true")

  let options = @engine.FletcherExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .with_renderer("svg")
    .with_macro_url("https://example.com/macros.tex")
  let fletcher = source.render_fletcher(options~)

  let share_text_json = ffi_browser_runtime_import_share_text_json(target, fletcher)
  inspect(share_text_json.contains("\"renderer\":\"svg\""), content="true")
  inspect(
    share_text_json.contains("\"macro_url\":\"https://example.com/macros.tex\""),
    content="true",
  )

  let fletcher_json = ffi_browser_runtime_import_fletcher_json(target, fletcher)
  inspect(fletcher_json.contains("\"renderer\":\"svg\""), content="true")
  inspect(fletcher_json.contains("\"embed\":false"), content="true")

  let settings = @engine.HtmlEmbedExportSettings::default("https://q.uiver.app")
    .with_fixed_size(400, 320)
  let html = {
    let options = @engine.HtmlEmbedExportOptions::default()
      .with_share_base_url("https://q.uiver.app")
      .with_renderer("svg")
      .with_macro_url("https://example.com/macros.tex")
    source.render_html_embed(settings, options~)
  }

  let html_json = ffi_browser_runtime_import_html_embed_json(target, html)
  inspect(html_json.contains("\"renderer\":\"svg\""), content="true")
  inspect(html_json.contains("\"embed\":true"), content="true")
}

///|
test "browser runtime ffi wrappers expose graph query arrays and json" {
  let runtime = ffi_browser_runtime_new()
  ignore(ffi_browser_runtime_add_vertex_json(runtime, "{\"label\":\"A\",\"x\":0,\"y\":0}"))
  ignore(ffi_browser_runtime_add_vertex_json(runtime, "{\"label\":\"B\",\"x\":1,\"y\":0}"))
  ignore(
    ffi_browser_runtime_add_edge_json(
      runtime,
      "{\"source_id\":1,\"target_id\":2,\"label\":\"f\"}",
    ),
  )
  ignore(
    ffi_browser_runtime_add_edge_json(
      runtime,
      "{\"source_id\":3,\"target_id\":2,\"label\":\"alpha\"}",
    ),
  )

  inspect(ffi_browser_runtime_all_cell_ids(runtime), content="[1, 2, 3, 4]")
  inspect(ffi_browser_runtime_all_cell_ids_json(runtime), content="[1,2,3,4]")

  inspect(ffi_browser_runtime_dependencies_of(runtime, 1), content="[3]")
  inspect(ffi_browser_runtime_dependencies_of_json(runtime, 1), content="[3]")
  inspect(ffi_browser_runtime_dependencies_of(runtime, 2), content="[3, 4]")
  inspect(ffi_browser_runtime_dependencies_of_json(runtime, 2), content="[3,4]")

  inspect(ffi_browser_runtime_reverse_dependencies_of(runtime, 3), content="[1, 2]")
  inspect(
    ffi_browser_runtime_reverse_dependencies_of_json(runtime, 3),
    content="[1,2]",
  )

  inspect(
    ffi_browser_runtime_transitive_dependencies(runtime, [1]),
    content="[1, 3, 4]",
  )
  inspect(
    ffi_browser_runtime_transitive_dependencies_json(runtime, [3], exclude_roots=true),
    content="[4]",
  )

  inspect(
    ffi_browser_runtime_transitive_reverse_dependencies(runtime, [4]),
    content="[1, 2, 3, 4]",
  )
  inspect(
    ffi_browser_runtime_transitive_reverse_dependencies_json(runtime, [4]),
    content="[1,2,3,4]",
  )

  inspect(
    ffi_browser_runtime_connected_components(runtime, [1]),
    content="[1, 2, 3, 4]",
  )
  inspect(
    ffi_browser_runtime_connected_components_json(runtime, [1]),
    content="[1,2,3,4]",
  )
}
