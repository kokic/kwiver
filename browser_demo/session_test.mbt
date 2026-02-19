///|
fn browser_demo_test_json_get(root : Map[String, Json], key : String) -> Json {
  match root.get(key) {
    Some(value) => value
    None => abort(["missing json field: ", key].join(""))
  }
}

///|
test "browser demo session dispatch keeps cached state in sync" {
  let session = BrowserDemoSession::new()
  ignore(
    session.dispatch_json(
      Json::object({
        "action": Json::string("add_vertex_json"),
        "input": Json::object({
          "label": Json::string("A"),
          "x": Json::number(0.0),
          "y": Json::number(0.0),
        }),
      }).stringify(),
    ),
  )
  ignore(
    session.dispatch_json(
      Json::object({
        "action": Json::string("add_vertex_json"),
        "input": Json::object({
          "label": Json::string("B"),
          "x": Json::number(1.0),
          "y": Json::number(0.0),
        }),
      }).stringify(),
    ),
  )
  ignore(
    session.dispatch_json(
      Json::object({
        "action": Json::string("add_edge_json"),
        "input": Json::object({
          "source_id": Json::number(1.0),
          "target_id": Json::number(2.0),
          "label": Json::string("f"),
        }),
      }).stringify(),
    ),
  )
  ignore(
    session.dispatch_json(
      Json::object({
        "action": Json::string("set_selection"),
        "input": Json::array([Json::number(1.0), Json::number(3.0)]),
      }).stringify(),
    ),
  )

  let state_root : Map[String, Json] = @json.from_json(
    @json.parse(session.state_json()),
  )
  let payload : String = @json.from_json(
    browser_demo_test_json_get(state_root, "payload"),
  )
  inspect(payload == session.payload(), content="true")

  let selection : Array[Int] = @json.from_json(
    browser_demo_test_json_get(state_root, "selection"),
  )
  inspect(selection, content="[1, 3]")
  inspect(session.selection(), content="[1, 3]")

  let cell_ids : Array[Int] = @json.from_json(
    browser_demo_test_json_get(state_root, "cell_ids"),
  )
  inspect(cell_ids, content="[1, 2, 3]")
}

///|
test "browser demo typed helper APIs cover add/import/render flow" {
  let session = BrowserDemoSession::new()
  let a = session.add_vertex("A", 0, 0)
  let b = session.add_vertex("B", 1, 0)
  let e = session.add_edge(a, b, label="f")
  inspect([a, b, e], content="[1, 2, 3]")

  inspect(session.apply_selection([3]), content="[3]")
  inspect(session.selection(), content="[3]")

  let tikz = session.render_tikz()
  inspect(tikz.contains("\\begin{tikzcd}"), content="true")
  inspect(tikz.contains("\\arrow[r, \"f\"]"), content="true")

  let tikz_json_data = session.render_tikz_json()
  inspect(tikz_json_data.contains("\\begin{tikzcd}"), content="true")

  let payload = session.payload()
  let restored = BrowserDemoSession::new()
  inspect(restored.import_payload(payload), content="true")
  inspect(restored.cell_ids(), content="[1, 2, 3]")

  let all_cells = restored.all_cells()
  inspect(all_cells.length(), content="3")
  let mut vertex_count = 0
  let mut edge_count = 0
  for cell in all_cells {
    match cell {
      @engine.CellData::Vertex(_) => vertex_count += 1
      @engine.CellData::Edge(_) => edge_count += 1
    }
  }
  inspect(vertex_count, content="2")
  inspect(edge_count, content="1")
}

///|
test "browser demo typed mutation helpers support incremental edits and removals" {
  let session = BrowserDemoSession::new()
  let source_id = session.add_vertex("A", 0, 0)
  let target_id = session.add_vertex("B", 1, 0)
  let edge_id = session.add_edge(source_id, target_id, label="f")

  inspect(session.set_label(edge_id, "g"), content="true")
  inspect(
    session.set_label_colour_hsla(source_id, 210, 80, 40, 0.5),
    content="true",
  )
  inspect(session.move_vertex(target_id, 2, 0), content="true")
  inspect(
    session.patch_edge_options_json(
      edge_id,
      "{\"curve\":2,\"shorten\":{\"source\":5,\"target\":7}}",
    ),
    content="true",
  )
  inspect(session.patch_edge_options_json(edge_id, "{"), content="false")

  inspect(session.apply_selection([edge_id]), content="[3]")
  let selection_payload = session.export_selection()
  inspect(selection_payload != "", content="true")

  let snapshot_json = session.snapshot_json()
  inspect(snapshot_json.contains("\"curve\":2"), content="true")
  inspect(snapshot_json.contains("\"shorten_source\":5"), content="true")
  inspect(snapshot_json.contains("\"shorten_target\":7"), content="true")

  let tikz = session.render_tikz()
  inspect(tikz.contains("\"g\""), content="true")
  inspect(
    tikz.contains("shorten <=5pt") || tikz.contains("between={"),
    content="true",
  )
  inspect(
    tikz.contains("shorten >=7pt") || tikz.contains("between={"),
    content="true",
  )

  let removed_ids = session.remove(source_id, when=9)
  removed_ids.sort()
  inspect(removed_ids, content="[1, 3]")
  inspect(session.flush(9), content="true")
  inspect(session.cell_ids(), content="[2]")
}

///|
test "browser demo typed edge mutation helpers cover granular runtime actions" {
  let session = BrowserDemoSession::new()
  let source_id = session.add_vertex("A", 0, 0)
  let target_id = session.add_vertex("B", 1, 0)
  let next_target_id = session.add_vertex("C", 2, 0)
  let edge_id = session.add_edge(source_id, target_id, label="f")

  inspect(
    session.set_label_colour_hsla(source_id, 210, 80, 40, 0.5),
    content="true",
  )
  inspect(
    session.set_edge_options_json(
      edge_id,
      [
        "{",
        "\"label_alignment\":\"over\",",
        "\"label_position\":40,",
        "\"offset\":1,",
        "\"curve\":3,",
        "\"radius\":0,",
        "\"angle\":0,",
        "\"shorten_source\":0,",
        "\"shorten_target\":0,",
        "\"level\":0,",
        "\"shape\":\"bezier\",",
        "\"colour\":{\"h\":0,\"s\":100,\"l\":50,\"a\":1},",
        "\"edge_alignment_source\":true,",
        "\"edge_alignment_target\":true,",
        "\"style\":{",
        "\"name\":\"arrow\",",
        "\"tail\":{\"name\":\"none\",\"side\":\"center\"},",
        "\"body\":{\"name\":\"none\",\"side\":\"center\"},",
        "\"head\":{\"name\":\"epi\",\"side\":\"center\"}",
        "}",
        "}",
      ].join(""),
    ),
    content="true",
  )
  inspect(session.set_edge_label_alignment(edge_id, "left"), content="true")
  inspect(session.set_edge_label_position(edge_id, 25), content="true")
  inspect(session.set_edge_offset(edge_id, 2), content="true")
  inspect(session.set_edge_curve(edge_id, 8), content="true")
  inspect(session.set_edge_shorten(edge_id, 4, 6), content="true")
  inspect(session.reconnect_edge(edge_id, source_id, next_target_id), content="true")

  inspect(session.set_edge_label_alignment(edge_id, "invalid"), content="false")
  inspect(session.set_edge_options_json(edge_id, "{"), content="false")

  let mut saw_source = false
  let mut saw_edge = false
  for cell in session.all_cells() {
    match cell {
      @engine.CellData::Vertex(vertex) =>
        if vertex.cell.id == source_id {
          saw_source = true
          inspect(vertex.cell.label_colour.h, content="210")
          inspect(vertex.cell.label_colour.s, content="80")
          inspect(vertex.cell.label_colour.l, content="40")
          inspect(vertex.cell.label_colour.a, content="0.5")
        }
      @engine.CellData::Edge(edge) =>
        if edge.cell.id == edge_id {
          saw_edge = true
          inspect(edge.source, content="1")
          inspect(edge.target, content="3")
          inspect(
            edge.options.label_alignment is @engine.LabelAlignment::Left,
            content="true",
          )
          inspect(edge.options.label_position, content="25")
          inspect(edge.options.offset, content="2")
          inspect(edge.options.curve, content="8")
          inspect(edge.options.shorten.source, content="4")
          inspect(edge.options.shorten.target, content="6")
        }
    }
  }
  inspect(saw_source, content="true")
  inspect(saw_edge, content="true")
}

///|
test "browser demo typed mutation batch helper returns per-op results" {
  let session = BrowserDemoSession::new()
  let source_id = session.add_vertex("A", 0, 0)
  let target_id = session.add_vertex("B", 1, 0)
  let edge_id = session.add_edge(source_id, target_id, label="f")

  let batch_json = [
    "{",
    "\"labels\":[{\"cell_id\":1,\"label\":\"A-batch\"}],",
    "\"label_colours\":[{\"cell_id\":1,\"label_colour\":{\"h\":30,\"s\":90,\"l\":60,\"a\":1}}],",
    "\"vertex_positions\":[{\"vertex_id\":1,\"x\":5,\"y\":7}],",
    "\"edge_options\":[{\"edge_id\":3,\"options\":{",
    "\"label_alignment\":\"right\",",
    "\"label_position\":80,",
    "\"offset\":0,",
    "\"curve\":-1,",
    "\"radius\":0,",
    "\"angle\":0,",
    "\"shorten_source\":1,",
    "\"shorten_target\":2,",
    "\"level\":0,",
    "\"shape\":\"bezier\",",
    "\"colour\":{\"h\":0,\"s\":100,\"l\":50,\"a\":1},",
    "\"edge_alignment_source\":true,",
    "\"edge_alignment_target\":true,",
    "\"style\":{",
    "\"name\":\"arrow\",",
    "\"tail\":{\"name\":\"none\",\"side\":\"center\"},",
    "\"body\":{\"name\":\"none\",\"side\":\"center\"},",
    "\"head\":{\"name\":\"epi\",\"side\":\"center\"}",
    "}}}],",
    "\"edge_connections\":[{\"edge_id\":3,\"source_id\":2,\"target_id\":1}]",
    "}",
  ].join("")

  let result = session.apply_mutation_batch_json(batch_json)
  inspect(result.label_results, content="[true]")
  inspect(result.label_colour_results, content="[true]")
  inspect(result.vertex_position_results, content="[true]")
  inspect(result.edge_option_results, content="[true]")
  inspect(result.edge_connection_results, content="[true]")
  inspect(result.payload == session.payload(), content="true")

  let snapshot = session.snapshot()
  inspect(snapshot.payload == session.payload(), content="true")
  inspect(snapshot.cell_ids, content="[1, 2, 3]")
  inspect(snapshot.vertices.length(), content="2")
  inspect(snapshot.edges.length(), content="1")

  let mut saw_source = false
  let mut saw_edge = false
  for cell in session.all_cells() {
    match cell {
      @engine.CellData::Vertex(vertex) =>
        if vertex.cell.id == source_id {
          saw_source = true
          inspect(vertex.cell.label, content="A-batch")
          inspect(vertex.x, content="5")
          inspect(vertex.y, content="7")
          inspect(vertex.cell.label_colour.h, content="30")
          inspect(vertex.cell.label_colour.s, content="90")
          inspect(vertex.cell.label_colour.l, content="60")
        }
      @engine.CellData::Edge(edge) =>
        if edge.cell.id == edge_id {
          saw_edge = true
          inspect(edge.source, content="2")
          inspect(edge.target, content="1")
          inspect(edge.options.curve, content="-1")
          inspect(edge.options.shorten.source, content="1")
          inspect(edge.options.shorten.target, content="2")
          inspect(
            edge.options.label_alignment is @engine.LabelAlignment::Right,
            content="true",
          )
          inspect(edge.options.label_position, content="80")
        }
    }
  }
  inspect(saw_source, content="true")
  inspect(saw_edge, content="true")
}

///|
test "browser demo typed query helpers expose dependency closures" {
  let session = BrowserDemoSession::new()
  let a = session.add_vertex("A", 0, 0)
  let b = session.add_vertex("B", 1, 0)
  let f = session.add_edge(a, b, label="f")

  inspect(session.dependencies_of(a), content="[3]")
  inspect(session.reverse_dependencies_of(f), content="[1, 2]")
  inspect(
    session.transitive_dependencies([a], exclude_roots=true),
    content="[3]",
  )
  inspect(session.transitive_reverse_dependencies([f]), content="[1, 2, 3]")
  inspect(session.connected_components([a]), content="[1, 2, 3]")
}

///|
test "browser demo typed import and render helpers support text formats" {
  let source = BrowserDemoSession::new()
  let a = source.add_vertex("A", 0, 0)
  let b = source.add_vertex("B", 1, 0)
  ignore(source.add_edge(a, b, label="f"))

  let tikz = source.render_tikz()
  inspect(tikz.contains("\\begin{tikzcd}"), content="true")
  let fletcher = source.render_fletcher()
  inspect(fletcher.contains("#diagram({"), content="true")
  let html = source.render_html_embed()
  inspect(html.contains("<iframe class=\"quiver-embed\""), content="true")

  let imported_tikz = BrowserDemoSession::new()
  inspect(imported_tikz.import_tikz_cd(tikz), content="true")
  inspect(imported_tikz.cell_ids(), content="[1, 2, 3]")

  let imported_auto = BrowserDemoSession::new()
  inspect(imported_auto.import_text_auto(tikz), content="true")
  inspect(imported_auto.cell_ids(), content="[1, 2, 3]")

  let starred_tikz = [
    "\\begin{tikzcd*}\n", "X \\arrow[r, \"g\"] & Y\n", "\\end{tikzcd*}",
  ].join("")
  let imported_starred = BrowserDemoSession::new()
  inspect(imported_starred.import_text_auto(starred_tikz), content="true")
  inspect(imported_starred.cell_ids(), content="[1, 2, 3]")

  let imported_share_text = BrowserDemoSession::new()
  inspect(imported_share_text.import_share_text(fletcher), content="true")
  inspect(imported_share_text.cell_ids(), content="[1, 2, 3]")

  let cells_json : Array[Map[String, Json]] = @json.from_json(
    @json.parse(source.all_cells_json()),
  )
  inspect(cells_json.length(), content="3")
}

///|
test "browser demo typed format-specific import and paste helpers" {
  let source = BrowserDemoSession::new()
  let source_id = source.add_vertex("A", 0, 0)
  let target_id = source.add_vertex("B", 1, 0)
  let edge_id = source.add_edge(source_id, target_id, label="f")

  let share_url = ["https://q.uiver.app#r=svg&q=", source.payload(), "&embed"].join("")
  let imported_share_url = BrowserDemoSession::new()
  let imported_share_url_result = imported_share_url.import_share_url_result(
    share_url,
  )
  inspect(imported_share_url_result.ok, content="true")
  inspect(imported_share_url_result.renderer, content="Some(\"svg\")")
  inspect(imported_share_url_result.embed, content="true")
  inspect(
    imported_share_url_result.payload == imported_share_url.payload(),
    content="true",
  )
  inspect(imported_share_url.cell_ids(), content="[1, 2, 3]")

  let fletcher = source.render_fletcher()
  let imported_fletcher = BrowserDemoSession::new()
  let imported_fletcher_result = imported_fletcher.import_fletcher_result(fletcher)
  inspect(imported_fletcher_result.ok, content="true")
  inspect(imported_fletcher_result.renderer, content="None")
  inspect(imported_fletcher_result.embed, content="false")
  inspect(imported_fletcher.cell_ids(), content="[1, 2, 3]")

  let html = source.render_html_embed()
  let imported_html = BrowserDemoSession::new()
  let imported_html_result = imported_html.import_html_embed_result(html)
  inspect(imported_html_result.ok, content="true")
  inspect(imported_html_result.embed, content="true")
  inspect(imported_html.cell_ids(), content="[1, 2, 3]")

  inspect(source.apply_selection([edge_id]), content="[3]")
  let selection_payload = source.export_selection()

  let target = BrowserDemoSession::new()
  ignore(target.add_vertex("Existing", 0, 0))
  let paste_result = target.paste_selection_result(
    selection_payload,
    10,
    20,
    start_id=1,
  )
  inspect(paste_result.ok, content="true")
  inspect(paste_result.imported_ids, content="[2, 3, 4]")
  inspect(paste_result.id_remap.length(), content="3")
  inspect(target.cell_ids(), content="[1, 2, 3, 4]")
}

///|
test "browser demo ffi result json wrappers expose import and paste metadata" {
  let source = ffi_browser_demo_session_new()
  ignore(ffi_browser_demo_session_add_vertex(source, "A", 0, 0))
  ignore(ffi_browser_demo_session_add_vertex(source, "B", 1, 0))
  ignore(ffi_browser_demo_session_add_edge(source, 1, 2, label="f"))

  let share_url = [
    "https://q.uiver.app#r=svg&q=",
    source.payload(),
    "&embed",
  ].join("")

  let target = ffi_browser_demo_session_new()
  let import_json = ffi_browser_demo_session_import_share_url_result_json(
    target,
    share_url,
  )
  let import_root : Map[String, Json] = @json.from_json(@json.parse(import_json))
  let import_ok : Bool = @json.from_json(browser_demo_test_json_get(import_root, "ok"))
  let import_renderer : String = @json.from_json(
    browser_demo_test_json_get(import_root, "renderer"),
  )
  let import_embed : Bool = @json.from_json(
    browser_demo_test_json_get(import_root, "embed"),
  )
  inspect(import_ok, content="true")
  inspect(import_renderer, content="svg")
  inspect(import_embed, content="true")

  inspect(ffi_browser_demo_session_set_selection(source, [3]), content="[3]")
  let selection_payload = ffi_browser_demo_session_export_selection(source)
  let target_paste = ffi_browser_demo_session_new()
  ignore(ffi_browser_demo_session_add_vertex(target_paste, "X", 0, 0))

  let paste_json = ffi_browser_demo_session_paste_selection_result_json(
    target_paste,
    selection_payload,
    10,
    20,
    start_id=1,
  )
  let paste_root : Map[String, Json] = @json.from_json(@json.parse(paste_json))
  let paste_ok : Bool = @json.from_json(browser_demo_test_json_get(paste_root, "ok"))
  let imported_ids : Array[Int] = @json.from_json(
    browser_demo_test_json_get(paste_root, "imported_ids"),
  )
  let id_remap : Array[Map[String, Json]] = @json.from_json(
    browser_demo_test_json_get(paste_root, "id_remap"),
  )
  inspect(paste_ok, content="true")
  inspect(imported_ids, content="[2, 3, 4]")
  inspect(id_remap.length(), content="3")

  let batch_json = [
    "{",
    "\"labels\":[{\"cell_id\":1,\"label\":\"A-ffi\"}],",
    "\"edge_connections\":[{\"edge_id\":3,\"source_id\":2,\"target_id\":1}]",
    "}",
  ].join("")
  let batch_result_json = ffi_browser_demo_session_apply_mutation_batch_json(
    target,
    batch_json,
  )
  let batch_root : Map[String, Json] = @json.from_json(
    @json.parse(batch_result_json),
  )
  let label_results : Array[Bool] = @json.from_json(
    browser_demo_test_json_get(batch_root, "label_results"),
  )
  let edge_connection_results : Array[Bool] = @json.from_json(
    browser_demo_test_json_get(batch_root, "edge_connection_results"),
  )
  inspect(label_results, content="[true]")
  inspect(edge_connection_results, content="[true]")
}

///|
test "browser demo roundtrip scenario reimports payload through dispatch envelope" {
  let root : Map[String, Json] = @json.from_json(
    @json.parse(browser_demo_roundtrip_demo_json()),
  )
  let ok : Bool = @json.from_json(browser_demo_test_json_get(root, "ok"))
  inspect(ok, content="true")

  let payload : String = @json.from_json(browser_demo_test_json_get(root, "payload"))
  let restored : String = @json.from_json(
    browser_demo_test_json_get(root, "restored_payload"),
  )
  inspect(payload == restored, content="true")

  let cell_ids : Array[Int] = @json.from_json(
    browser_demo_test_json_get(root, "cell_ids"),
  )
  inspect(cell_ids, content="[1, 2, 3]")

  let selection : Array[Int] = @json.from_json(
    browser_demo_test_json_get(root, "selection"),
  )
  inspect(selection, content="[]")
}
