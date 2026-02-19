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

  let mut saw_edge = false
  for cell in session.all_cells() {
    match cell {
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
      _ => ()
    }
  }
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

  let share_url = ["https://q.uiver.app#q=", source.payload()].join("")
  let imported_share_url = BrowserDemoSession::new()
  inspect(imported_share_url.import_share_url(share_url), content="true")
  inspect(imported_share_url.cell_ids(), content="[1, 2, 3]")

  let fletcher = source.render_fletcher()
  let imported_fletcher = BrowserDemoSession::new()
  inspect(imported_fletcher.import_fletcher(fletcher), content="true")
  inspect(imported_fletcher.cell_ids(), content="[1, 2, 3]")

  let html = source.render_html_embed()
  let imported_html = BrowserDemoSession::new()
  inspect(imported_html.import_html_embed(html), content="true")
  inspect(imported_html.cell_ids(), content="[1, 2, 3]")

  inspect(source.apply_selection([edge_id]), content="[3]")
  let selection_payload = source.export_selection()

  let target = BrowserDemoSession::new()
  ignore(target.add_vertex("Existing", 0, 0))
  let imported_ids = target.paste_selection(
    selection_payload,
    10,
    20,
    start_id=1,
  )
  inspect(imported_ids, content="[2, 3, 4]")
  inspect(target.cell_ids(), content="[1, 2, 3, 4]")
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
