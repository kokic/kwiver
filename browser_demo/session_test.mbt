///|
fn browser_demo_test_json_get(root : Map[String, Json], key : String) -> Json {
  match root.get(key) {
    Some(value) => value
    None => abort(["missing json field: ", key].join(""))
  }
}

///|
fn browser_demo_test_json_optional_string(
  root : Map[String, Json],
  key : String,
) -> String? {
  match root.get(key) {
    Some(Json::Null) => None
    Some(value) => {
      let parsed : Result[String, Error] = try? @json.from_json(value)
      match parsed {
        Ok(raw) => Some(raw)
        Err(_) => None
      }
    }
    None => None
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
test "browser demo session safe dispatch wrappers return error envelopes for malformed input" {
  let session = BrowserDemoSession::new()
  ignore(session.add_vertex("A", 0, 0))
  let before_payload = session.payload()

  let malformed = session.dispatch_json_safe("{")
  let malformed_root : Map[String, Json] = @json.from_json(@json.parse(malformed))
  let malformed_ok : Bool = @json.from_json(
    browser_demo_test_json_get(malformed_root, "ok"),
  )
  let malformed_action : String = @json.from_json(
    browser_demo_test_json_get(malformed_root, "action"),
  )
  let malformed_error : String = @json.from_json(
    browser_demo_test_json_get(malformed_root, "error"),
  )
  inspect(malformed_ok, content="false")
  inspect(malformed_action, content="unknown")
  inspect(malformed_error != "", content="true")
  inspect(session.cell_ids(), content="[1]")
  inspect(session.payload() == before_payload, content="true")

  let malformed_many = session.dispatch_many_json_safe("{")
  let malformed_many_root : Map[String, Json] = @json.from_json(
    @json.parse(malformed_many),
  )
  let malformed_many_ok : Bool = @json.from_json(
    browser_demo_test_json_get(malformed_many_root, "ok"),
  )
  let malformed_many_processed : Int = @json.from_json(
    browser_demo_test_json_get(malformed_many_root, "processed"),
  )
  let malformed_many_results : Array[Json] = @json.from_json(
    browser_demo_test_json_get(malformed_many_root, "results"),
  )
  let malformed_many_error : String = @json.from_json(
    browser_demo_test_json_get(malformed_many_root, "error"),
  )
  inspect(malformed_many_ok, content="false")
  inspect(malformed_many_processed, content="0")
  inspect(malformed_many_results.length(), content="0")
  inspect(malformed_many_error != "", content="true")
  inspect(session.cell_ids(), content="[1]")
}

///|
test "browser demo command envelope keeps stable metadata and checkpoints" {
  let session = BrowserDemoSession::new()
  let initial_payload = session.payload()

  let add_json = session.dispatch_command_json(
    [
      "{",
      "\"action\":\"add_vertex_json\",",
      "\"input\":{\"label\":\"A\",\"x\":0,\"y\":0},",
      "\"origin\":\"toolbar\",",
      "\"command_id\":\"cmd-1\",",
      "\"protocol\":\"kwiver.command.v1\"",
      "}",
    ].join(""),
  )
  let add_root : Map[String, Json] = @json.from_json(@json.parse(add_json))
  let add_sequence : Int = @json.from_json(browser_demo_test_json_get(add_root, "sequence"))
  let add_ok : Bool = @json.from_json(browser_demo_test_json_get(add_root, "ok"))
  let add_action : String = @json.from_json(browser_demo_test_json_get(add_root, "action"))
  let add_protocol : String = @json.from_json(
    browser_demo_test_json_get(add_root, "protocol"),
  )
  let add_origin = browser_demo_test_json_optional_string(add_root, "origin")
  let add_command_id = browser_demo_test_json_optional_string(add_root, "command_id")
  let add_changed : Bool = @json.from_json(browser_demo_test_json_get(add_root, "changed"))
  let add_undo_checkpoint = browser_demo_test_json_optional_string(
    add_root,
    "undo_checkpoint",
  )
  let add_redo_checkpoint = browser_demo_test_json_optional_string(
    add_root,
    "redo_checkpoint",
  )
  inspect(add_sequence, content="1")
  inspect(add_ok, content="true")
  inspect(add_action, content="add_vertex_json")
  inspect(add_protocol, content="kwiver.command.v1")
  inspect(add_origin, content="Some(\"toolbar\")")
  inspect(add_command_id, content="Some(\"cmd-1\")")
  inspect(add_changed, content="true")
  inspect(add_undo_checkpoint, content=["Some(\"", initial_payload, "\")"].join(""))
  inspect(
    add_redo_checkpoint,
    content=["Some(\"", session.payload(), "\")"].join(""),
  )

  let add_before : Map[String, Json] = @json.from_json(
    browser_demo_test_json_get(add_root, "before"),
  )
  let add_after : Map[String, Json] = @json.from_json(
    browser_demo_test_json_get(add_root, "after"),
  )
  let add_before_cell_ids : Array[Int] = @json.from_json(
    browser_demo_test_json_get(add_before, "cell_ids"),
  )
  let add_after_cell_ids : Array[Int] = @json.from_json(
    browser_demo_test_json_get(add_after, "cell_ids"),
  )
  inspect(add_before_cell_ids, content="[]")
  inspect(add_after_cell_ids, content="[1]")

  let selection_json = session.dispatch_command_json(
    "{\"action\":\"selection\",\"origin\":\"query\",\"command_id\":\"cmd-2\",\"protocol\":\"kwiver.command.v1\"}",
  )
  let selection_root : Map[String, Json] = @json.from_json(@json.parse(selection_json))
  let selection_sequence : Int = @json.from_json(
    browser_demo_test_json_get(selection_root, "sequence"),
  )
  let selection_ok : Bool = @json.from_json(
    browser_demo_test_json_get(selection_root, "ok"),
  )
  let selection_changed : Bool = @json.from_json(
    browser_demo_test_json_get(selection_root, "changed"),
  )
  inspect(selection_sequence, content="2")
  inspect(selection_ok, content="true")
  inspect(selection_changed, content="false")
  inspect(
    browser_demo_test_json_optional_string(selection_root, "undo_checkpoint"),
    content="None",
  )
  inspect(
    browser_demo_test_json_optional_string(selection_root, "redo_checkpoint"),
    content="None",
  )

  let unknown_json = session.dispatch_command_json(
    "{\"action\":\"unknown_browser_demo_action\",\"origin\":\"query\",\"command_id\":\"cmd-3\",\"protocol\":\"kwiver.command.v1\"}",
  )
  let unknown_root : Map[String, Json] = @json.from_json(@json.parse(unknown_json))
  let unknown_sequence : Int = @json.from_json(
    browser_demo_test_json_get(unknown_root, "sequence"),
  )
  let unknown_ok : Bool = @json.from_json(browser_demo_test_json_get(unknown_root, "ok"))
  let unknown_changed : Bool = @json.from_json(
    browser_demo_test_json_get(unknown_root, "changed"),
  )
  let unknown_error = browser_demo_test_json_optional_string(unknown_root, "error")
  inspect(unknown_sequence, content="3")
  inspect(unknown_ok, content="false")
  inspect(unknown_changed, content="false")
  inspect(unknown_error is Some(_), content="true")

  let malformed_json = session.dispatch_command_json("{")
  let malformed_root : Map[String, Json] = @json.from_json(@json.parse(malformed_json))
  let malformed_sequence : Int = @json.from_json(
    browser_demo_test_json_get(malformed_root, "sequence"),
  )
  let malformed_ok : Bool = @json.from_json(
    browser_demo_test_json_get(malformed_root, "ok"),
  )
  let malformed_action : String = @json.from_json(
    browser_demo_test_json_get(malformed_root, "action"),
  )
  inspect(malformed_sequence, content="4")
  inspect(malformed_ok, content="false")
  inspect(malformed_action, content="unknown")
  inspect(
    browser_demo_test_json_optional_string(malformed_root, "origin"),
    content="None",
  )
  inspect(
    browser_demo_test_json_optional_string(malformed_root, "command_id"),
    content="None",
  )
}

///|
test "browser demo command envelope rejects missing or mismatched protocol" {
  let session = BrowserDemoSession::new()
  let baseline_payload = session.payload()

  let missing_protocol_json = session.dispatch_command_json(
    [
      "{",
      "\"action\":\"add_vertex_json\",",
      "\"input\":{\"label\":\"A\",\"x\":0,\"y\":0},",
      "\"origin\":\"toolbar\",",
      "\"command_id\":\"proto-missing-1\"",
      "}",
    ].join(""),
  )
  let missing_root : Map[String, Json] = @json.from_json(@json.parse(missing_protocol_json))
  let missing_sequence : Int = @json.from_json(
    browser_demo_test_json_get(missing_root, "sequence"),
  )
  let missing_ok : Bool = @json.from_json(browser_demo_test_json_get(missing_root, "ok"))
  let missing_action : String = @json.from_json(
    browser_demo_test_json_get(missing_root, "action"),
  )
  let missing_changed : Bool = @json.from_json(
    browser_demo_test_json_get(missing_root, "changed"),
  )
  let missing_error = browser_demo_test_json_optional_string(missing_root, "error")
  let missing_protocol : String = @json.from_json(
    browser_demo_test_json_get(missing_root, "protocol"),
  )
  inspect(missing_sequence, content="1")
  inspect(missing_ok, content="false")
  inspect(missing_action, content="add_vertex_json")
  inspect(missing_changed, content="false")
  inspect(missing_error is Some(_), content="true")
  inspect(missing_protocol, content="kwiver.command.v1")
  inspect(session.payload() == baseline_payload, content="true")
  inspect(session.cell_ids(), content="[]")

  let mismatch_protocol_json = session.dispatch_command_json(
    [
      "{",
      "\"action\":\"add_vertex_json\",",
      "\"input\":{\"label\":\"B\",\"x\":1,\"y\":0},",
      "\"origin\":\"toolbar\",",
      "\"command_id\":\"proto-mismatch-1\",",
      "\"protocol\":\"kwiver.command.v0\"",
      "}",
    ].join(""),
  )
  let mismatch_root : Map[String, Json] = @json.from_json(@json.parse(mismatch_protocol_json))
  let mismatch_sequence : Int = @json.from_json(
    browser_demo_test_json_get(mismatch_root, "sequence"),
  )
  let mismatch_ok : Bool = @json.from_json(browser_demo_test_json_get(mismatch_root, "ok"))
  let mismatch_action : String = @json.from_json(
    browser_demo_test_json_get(mismatch_root, "action"),
  )
  let mismatch_changed : Bool = @json.from_json(
    browser_demo_test_json_get(mismatch_root, "changed"),
  )
  let mismatch_error = browser_demo_test_json_optional_string(mismatch_root, "error")
  inspect(mismatch_sequence, content="2")
  inspect(mismatch_ok, content="false")
  inspect(mismatch_action, content="add_vertex_json")
  inspect(mismatch_changed, content="false")
  inspect(mismatch_error is Some(_), content="true")
  inspect(session.payload() == baseline_payload, content="true")
  inspect(session.cell_ids(), content="[]")

  let valid_protocol_json = session.dispatch_command_json(
    [
      "{",
      "\"action\":\"add_vertex_json\",",
      "\"input\":{\"label\":\"C\",\"x\":2,\"y\":0},",
      "\"origin\":\"toolbar\",",
      "\"command_id\":\"proto-ok-1\",",
      "\"protocol\":\"kwiver.command.v1\"",
      "}",
    ].join(""),
  )
  let valid_root : Map[String, Json] = @json.from_json(@json.parse(valid_protocol_json))
  let valid_sequence : Int = @json.from_json(
    browser_demo_test_json_get(valid_root, "sequence"),
  )
  let valid_ok : Bool = @json.from_json(browser_demo_test_json_get(valid_root, "ok"))
  let valid_changed : Bool = @json.from_json(
    browser_demo_test_json_get(valid_root, "changed"),
  )
  inspect(valid_sequence, content="3")
  inspect(valid_ok, content="true")
  inspect(valid_changed, content="true")
  inspect(session.cell_ids(), content="[1]")
}

///|
test "browser demo command envelope import_payload closes loop with checkpoints" {
  let source = BrowserDemoSession::new()
  let a = source.add_vertex("A", 0, 0)
  let b = source.add_vertex("B", 1, 0)
  ignore(source.add_edge(a, b, label="f"))
  let payload = source.payload()

  let session = BrowserDemoSession::new()
  let before_payload = session.payload()

  let import_json = session.dispatch_command_json(
    [
      "{",
      "\"action\":\"import_payload\",",
      "\"input\":\"", payload, "\",",
      "\"origin\":\"bootstrap\",",
      "\"command_id\":\"import-1\",",
      "\"protocol\":\"kwiver.command.v1\"",
      "}",
    ].join(""),
  )

  let import_root : Map[String, Json] = @json.from_json(@json.parse(import_json))
  let import_sequence : Int = @json.from_json(
    browser_demo_test_json_get(import_root, "sequence"),
  )
  let import_ok : Bool = @json.from_json(browser_demo_test_json_get(import_root, "ok"))
  let import_action : String = @json.from_json(
    browser_demo_test_json_get(import_root, "action"),
  )
  let import_changed : Bool = @json.from_json(
    browser_demo_test_json_get(import_root, "changed"),
  )
  let import_result : String = @json.from_json(
    browser_demo_test_json_get(import_root, "result"),
  )

  inspect(import_sequence, content="1")
  inspect(import_ok, content="true")
  inspect(import_action, content="import_payload")
  inspect(import_changed, content="true")
  inspect(import_result == session.payload(), content="true")
  inspect(session.cell_ids(), content="[1, 2, 3]")
  inspect(session.selection(), content="[]")
  inspect(
    browser_demo_test_json_optional_string(import_root, "origin"),
    content="Some(\"bootstrap\")",
  )
  inspect(
    browser_demo_test_json_optional_string(import_root, "command_id"),
    content="Some(\"import-1\")",
  )
  inspect(
    browser_demo_test_json_optional_string(import_root, "undo_checkpoint"),
    content=["Some(\"", before_payload, "\")"].join(""),
  )
  inspect(
    browser_demo_test_json_optional_string(import_root, "redo_checkpoint"),
    content=["Some(\"", session.payload(), "\")"].join(""),
  )

  let before_state : Map[String, Json] = @json.from_json(
    browser_demo_test_json_get(import_root, "before"),
  )
  let after_state : Map[String, Json] = @json.from_json(
    browser_demo_test_json_get(import_root, "after"),
  )
  let before_cell_ids : Array[Int] = @json.from_json(
    browser_demo_test_json_get(before_state, "cell_ids"),
  )
  let after_cell_ids : Array[Int] = @json.from_json(
    browser_demo_test_json_get(after_state, "cell_ids"),
  )
  let after_selection : Array[Int] = @json.from_json(
    browser_demo_test_json_get(after_state, "selection"),
  )
  inspect(before_cell_ids, content="[]")
  inspect(after_cell_ids, content="[1, 2, 3]")
  inspect(after_selection, content="[]")
}

///|
test "browser demo command envelope create actions close loop with runtime snapshot" {
  let session = BrowserDemoSession::new()

  let add_a_json = session.dispatch_command_json(
    [
      "{",
      "\"action\":\"add_vertex_json\",",
      "\"input\":{\"label\":\"A\",\"x\":0,\"y\":0},",
      "\"origin\":\"toolbar\",",
      "\"command_id\":\"create-1\",",
      "\"protocol\":\"kwiver.command.v1\"",
      "}",
    ].join(""),
  )
  let add_a_root : Map[String, Json] = @json.from_json(@json.parse(add_a_json))
  let add_a_sequence : Int = @json.from_json(browser_demo_test_json_get(add_a_root, "sequence"))
  let add_a_ok : Bool = @json.from_json(browser_demo_test_json_get(add_a_root, "ok"))
  let add_a_action : String = @json.from_json(browser_demo_test_json_get(add_a_root, "action"))
  let add_a_result : Map[String, Json] = @json.from_json(
    browser_demo_test_json_get(add_a_root, "result"),
  )
  let add_a_id : Int = @json.from_json(browser_demo_test_json_get(add_a_result, "id"))
  let add_a_after : Map[String, Json] = @json.from_json(
    browser_demo_test_json_get(add_a_root, "after"),
  )
  let add_a_after_selection : Array[Int] = @json.from_json(
    browser_demo_test_json_get(add_a_after, "selection"),
  )
  let add_a_after_cell_ids : Array[Int] = @json.from_json(
    browser_demo_test_json_get(add_a_after, "cell_ids"),
  )
  inspect(add_a_sequence, content="1")
  inspect(add_a_ok, content="true")
  inspect(add_a_action, content="add_vertex_json")
  inspect(add_a_id, content="1")
  inspect(add_a_after_selection, content="[1]")
  inspect(add_a_after_cell_ids, content="[1]")

  let add_b_json = session.dispatch_command_json(
    [
      "{",
      "\"action\":\"add_vertex_json\",",
      "\"input\":{\"label\":\"B\",\"x\":1,\"y\":0},",
      "\"origin\":\"toolbar\",",
      "\"command_id\":\"create-2\",",
      "\"protocol\":\"kwiver.command.v1\"",
      "}",
    ].join(""),
  )
  let add_b_root : Map[String, Json] = @json.from_json(@json.parse(add_b_json))
  let add_b_sequence : Int = @json.from_json(browser_demo_test_json_get(add_b_root, "sequence"))
  let add_b_result : Map[String, Json] = @json.from_json(
    browser_demo_test_json_get(add_b_root, "result"),
  )
  let add_b_id : Int = @json.from_json(browser_demo_test_json_get(add_b_result, "id"))
  inspect(add_b_sequence, content="2")
  inspect(add_b_id, content="2")

  let add_edge_json = session.dispatch_command_json(
    [
      "{",
      "\"action\":\"add_edge_json\",",
      "\"input\":{\"source_id\":1,\"target_id\":2,\"label\":\"f\"},",
      "\"origin\":\"toolbar\",",
      "\"command_id\":\"create-3\",",
      "\"protocol\":\"kwiver.command.v1\"",
      "}",
    ].join(""),
  )
  let add_edge_root : Map[String, Json] = @json.from_json(@json.parse(add_edge_json))
  let add_edge_sequence : Int = @json.from_json(
    browser_demo_test_json_get(add_edge_root, "sequence"),
  )
  let add_edge_ok : Bool = @json.from_json(browser_demo_test_json_get(add_edge_root, "ok"))
  let add_edge_action : String = @json.from_json(
    browser_demo_test_json_get(add_edge_root, "action"),
  )
  let add_edge_result : Map[String, Json] = @json.from_json(
    browser_demo_test_json_get(add_edge_root, "result"),
  )
  let add_edge_id : Int = @json.from_json(
    browser_demo_test_json_get(add_edge_result, "id"),
  )
  let add_edge_after : Map[String, Json] = @json.from_json(
    browser_demo_test_json_get(add_edge_root, "after"),
  )
  let add_edge_after_selection : Array[Int] = @json.from_json(
    browser_demo_test_json_get(add_edge_after, "selection"),
  )
  let add_edge_after_cell_ids : Array[Int] = @json.from_json(
    browser_demo_test_json_get(add_edge_after, "cell_ids"),
  )
  inspect(add_edge_sequence, content="3")
  inspect(add_edge_ok, content="true")
  inspect(add_edge_action, content="add_edge_json")
  inspect(add_edge_id, content="3")
  inspect(add_edge_after_selection, content="[3]")
  inspect(add_edge_after_cell_ids, content="[1, 2, 3]")
  inspect(session.cell_ids(), content="[1, 2, 3]")
  inspect(session.selection(), content="[3]")

  let mut saw_edge = false
  for cell in session.all_cells() {
    match cell {
      @engine.CellData::Edge(edge) =>
        if edge.cell.id == add_edge_id {
          saw_edge = true
          inspect(edge.source, content="1")
          inspect(edge.target, content="2")
          inspect(edge.cell.label, content="f")
        }
      _ => ()
    }
  }
  inspect(saw_edge, content="true")
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

  let typed_session = BrowserDemoSession::new()
  let typed_source_id = typed_session.add_vertex("X", 0, 0)
  let typed_target_id = typed_session.add_vertex("Y", 1, 0)
  let typed_edge_id = typed_session.add_edge(typed_source_id, typed_target_id, label="h")
  let typed_batch = @engine.QuiverUiMutationBatch::new(
    [@engine.QuiverUiSetLabelPatch::new(typed_source_id, "X-typed")],
    [
      @engine.QuiverUiSetLabelColourPatch::new(
        typed_source_id,
        @engine.Colour::new(45, 75, 55, 1.0),
      ),
    ],
    [@engine.QuiverUiMoveVertexPatch::new(typed_source_id, 6, 8)],
    [
      @engine.QuiverUiSetEdgeOptionsPatch::new(
        typed_edge_id,
        @engine.EdgeOptions::default()
          .with_curve(-3)
          .with_label_alignment_left()
          .with_label_position(65),
      ),
    ],
    [
      @engine.QuiverUiReconnectEdgePatch::new(
        typed_edge_id,
        typed_target_id,
        typed_source_id,
      ),
    ],
  )
  let typed_result = typed_session.apply_mutation_batch(typed_batch)
  inspect(typed_result.label_results, content="[true]")
  inspect(typed_result.label_colour_results, content="[true]")
  inspect(typed_result.vertex_position_results, content="[true]")
  inspect(typed_result.edge_option_results, content="[true]")
  inspect(typed_result.edge_connection_results, content="[true]")
  inspect(typed_result.payload == typed_session.payload(), content="true")
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
  let tikz_result = source.render_tikz_result()
  inspect(tikz_result.data.contains("\\begin{tikzcd}"), content="true")
  inspect(tikz_result.metadata.stringify().contains("\"dependencies\":"), content="true")
  let tikz_result_json = source.render_tikz_result_json()
  inspect(tikz_result_json.contains("\"data\":\""), content="true")
  inspect(tikz_result_json.contains("\"metadata\":"), content="true")
  let fletcher = source.render_fletcher()
  inspect(fletcher.contains("diagram({"), content="true")
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
test "browser demo import_tikz_cd_result surfaces error and preserves cached state on failure" {
  let session = BrowserDemoSession::new()
  let seed = session.add_vertex("Seed", 0, 0)
  ignore(session.apply_selection([seed]))
  let before_payload = session.payload()

  let invalid = [
    "\\begin{tikzcd}\n",
    "A \\arrow[\"f\"] & B\n",
    "\\end{tikzcd}",
  ].join("")
  let imported = session.import_tikz_cd_result(invalid)

  inspect(imported.ok, content="false")
  inspect(imported.payload == before_payload, content="true")
  inspect(imported.error is Some(_), content="true")
  match imported.error {
    Some(message) => inspect(message.contains("missing target"), content="true")
    None => abort("expected import error")
  }
  inspect(imported.to_json_string().contains("\"error\":\""), content="true")

  inspect(session.payload() == before_payload, content="true")
  inspect(session.selection(), content="[1]")
  inspect(session.cell_ids(), content="[1]")
}

///|
test "browser demo typed reset and safe dispatch helpers keep cached state aligned" {
  let session = BrowserDemoSession::new()

  let add_output = session.dispatch_json_safe(
    "{\"action\":\"add_vertex_json\",\"input\":{\"label\":\"A\",\"x\":0,\"y\":0}}",
  )
  inspect(add_output.contains("\"ok\":true"), content="true")

  let batch_output = session.dispatch_many_json_safe(
    "[{\"action\":\"add_vertex_json\",\"input\":{\"label\":\"B\",\"x\":1,\"y\":0}}]",
  )
  inspect(batch_output.contains("\"ok\":true"), content="true")
  inspect(session.cell_ids(), content="[1, 2]")

  inspect(session.apply_selection([1]), content="[1]")
  session.reset()
  inspect(session.cell_ids(), content="[]")
  inspect(session.selection(), content="[]")

  let fresh = BrowserDemoSession::new()
  inspect(session.payload() == fresh.payload(), content="true")
}

///|
test "browser demo typed configurable render helpers forward dispatch input" {
  let session = BrowserDemoSession::new()
  let a = session.add_vertex("A", 0, 0)
  let b = session.add_vertex("B", 1, 0)
  ignore(session.add_edge(a, b, label="f"))

  let tikz_result = session.render_tikz_result_with_input(
    [
      "{",
      "\"settings\":{\"centre_diagram\":true},",
      "\"options\":{",
      "\"share_base_url\":\"https://q.uiver.app\",",
      "\"renderer\":\"svg\",",
      "\"macro_url\":\"https://example.com/macros.tex\",",
      "\"sep_em\":2.70",
      "}",
      "}",
    ].join(""),
  )
  inspect(tikz_result.data.contains("\\begin{tikzcd}[sep=large]"), content="true")
  inspect(tikz_result.data.contains("% https://q.uiver.app#r=svg&q="), content="true")
  inspect(
    tikz_result.data.contains(
      "&macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex",
    ),
    content="true",
  )

  let fallback_tikz_result = session.render_tikz_result_with_input("{")
  inspect(fallback_tikz_result.data.contains("\\begin{tikzcd}"), content="true")

  let fletcher = session.render_fletcher_with_input(
    [
      "{",
      "\"options\":{",
      "\"share_base_url\":\"https://q.uiver.app\",",
      "\"renderer\":\"svg\",",
      "\"macro_url\":\"https://example.com/macros.tex\"",
      "}",
      "}",
    ].join(""),
  )
  inspect(fletcher.contains("#diagram({"), content="true")
  inspect(fletcher.contains("// https://q.uiver.app#"), content="true")
  inspect(fletcher.contains("q="), content="true")
  inspect(
    fletcher.contains("&macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex"),
    content="true",
  )

  let html = session.render_html_embed_with_input(
    [
      "{",
      "\"settings\":{",
      "\"base_url\":\"https://q.uiver.app\",",
      "\"fixed_size\":true,",
      "\"width\":320,",
      "\"height\":240",
      "},",
      "\"options\":{",
      "\"renderer\":\"svg\",",
      "\"macro_url\":\"https://example.com/macros.tex\"",
      "}",
      "}",
    ].join(""),
  )
  inspect(html.contains("<iframe class=\"quiver-embed\""), content="true")
  inspect(html.contains("#r=svg&q="), content="true")
  inspect(
    html.contains("macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex"),
    content="true",
  )
}

///|
test "browser demo typed render config helpers support typed settings options and definitions" {
  let session = BrowserDemoSession::new()
  let a = session.add_vertex("A", 0, 0)
  let b = session.add_vertex("B", 1, 0)
  ignore(session.add_edge(a, b, label="f"))
  ignore(session.set_label_colour_hsla(a, 210, 80, 40, 1.0))

  let tikz_result = session.render_tikz_result_with_config(
    settings=@engine.TikzCdExportSettings::default().with_centre_diagram(),
    options=
      @engine.TikzCdExportOptions::default()
      .with_share_base_url("https://q.uiver.app")
      .with_renderer("svg")
      .with_macro_url("https://example.com/macros.tex")
      .with_sep_em(2.70),
    definitions=
      @engine.TikzCdExportDefinitions::default()
      .with_colour("edgeblue", @engine.Colour::new(210, 80, 40, 1.0)),
  )
  inspect(tikz_result.data.contains("\\begin{tikzcd}[sep=large]"), content="true")
  inspect(tikz_result.data.contains("% https://q.uiver.app#r=svg&q="), content="true")
  inspect(
    tikz_result.data.contains(
      "&macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex",
    ),
    content="true",
  )
  inspect(tikz_result.data.contains("edgeblue"), content="true")

  let fletcher = session.render_fletcher_with_config(
    settings=@engine.FletcherExportSettings::default().with_centre_diagram(),
    options=
      @engine.FletcherExportOptions::default()
      .with_share_base_url("https://q.uiver.app")
      .with_renderer("svg")
      .with_macro_url("https://example.com/macros.tex"),
  )
  inspect(fletcher.contains("diagram({"), content="true")
  inspect(
    fletcher.find("// https://q.uiver.app#r=svg&q=") is Some(_),
    content="true",
  )
  inspect(
    fletcher.find("&macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex") is Some(_),
    content="true",
  )

  let html = session.render_html_embed_with_config(
    @engine.HtmlEmbedExportSettings::default("https://q.uiver.app").with_fixed_size(
      320,
      240,
    ),
    options=
      @engine.HtmlEmbedExportOptions::default()
      .with_renderer("svg")
      .with_macro_url("https://example.com/macros.tex"),
  )
  inspect(html.contains("<iframe class=\"quiver-embed\""), content="true")
  inspect(html.contains("#r=svg&q="), content="true")
  inspect(
    html.contains("macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex"),
    content="true",
  )
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

  let tikz_result_json = ffi_browser_demo_session_render_tikz_result_json(target)
  inspect(tikz_result_json.contains("\"data\":\""), content="true")
  inspect(tikz_result_json.contains("\"metadata\":"), content="true")

  let demo_batch_json = ffi_browser_demo_session_apply_mutation_batch_demo_json()
  inspect(demo_batch_json.contains("\"label_results\":[true]"), content="true")
  inspect(
    demo_batch_json.contains("\"edge_connection_results\":[true]"),
    content="true",
  )
}

///|
test "browser demo ffi wrappers expose reset safe-dispatch and configurable render" {
  let session = ffi_browser_demo_session_new()

  let add_json = ffi_browser_demo_session_dispatch_json_safe(
    session,
    "{\"action\":\"add_vertex_json\",\"input\":{\"label\":\"A\",\"x\":0,\"y\":0}}",
  )
  inspect(add_json.contains("\"ok\":true"), content="true")

  let add_many_json = ffi_browser_demo_session_dispatch_many_json_safe(
    session,
    "[{\"action\":\"add_vertex_json\",\"input\":{\"label\":\"B\",\"x\":1,\"y\":0}}]",
  )
  inspect(add_many_json.contains("\"ok\":true"), content="true")

  ignore(ffi_browser_demo_session_add_edge(session, 1, 2, label="f"))

  let tikz_result_json = ffi_browser_demo_session_render_tikz_result_with_input_json(
    session,
    "{\"options\":{\"share_base_url\":\"https://q.uiver.app\",\"renderer\":\"svg\"}}",
  )
  inspect(tikz_result_json.contains("\"data\":\""), content="true")
  inspect(tikz_result_json.contains("% https://q.uiver.app#r=svg&q="), content="true")

  let fletcher = ffi_browser_demo_session_render_fletcher_with_input(
    session,
    "{\"options\":{\"share_base_url\":\"https://q.uiver.app\",\"renderer\":\"svg\"}}",
  )
  inspect(fletcher.contains("#diagram({"), content="true")
  inspect(fletcher.contains("// https://q.uiver.app#r=svg&q="), content="true")

  let html = ffi_browser_demo_session_render_html_embed_with_input(
    session,
    [
      "{",
      "\"settings\":{\"base_url\":\"https://q.uiver.app\",\"fixed_size\":true,\"width\":320,\"height\":240},",
      "\"options\":{\"renderer\":\"svg\"}",
      "}",
    ].join(""),
  )
  inspect(html.contains("<iframe class=\"quiver-embed\""), content="true")
  inspect(html.contains("#r=svg&q="), content="true")

  ffi_browser_demo_session_reset(session)
  inspect(ffi_browser_demo_session_all_cell_ids(session), content="[]")
}

///|
test "browser demo ffi command protocol export matches envelope protocol" {
  inspect(ffi_browser_demo_command_protocol(), content="kwiver.command.v1")

  let session = ffi_browser_demo_session_new()
  let envelope_json = ffi_browser_demo_session_dispatch_command_json(
    session,
    "{\"action\":\"selection\",\"protocol\":\"kwiver.command.v1\"}",
  )
  let envelope_root : Map[String, Json] = @json.from_json(@json.parse(envelope_json))
  let envelope_ok : Bool = @json.from_json(
    browser_demo_test_json_get(envelope_root, "ok"),
  )
  let envelope_protocol : String = @json.from_json(
    browser_demo_test_json_get(envelope_root, "protocol"),
  )
  inspect(envelope_ok, content="true")
  inspect(envelope_protocol, content="kwiver.command.v1")
}

///|
test "browser demo ffi command envelope wrapper exposes stable checkpoint contract" {
  let session = ffi_browser_demo_session_new()
  let initial_payload = session.payload()
  let add_json = ffi_browser_demo_session_dispatch_command_json(
    session,
    [
      "{",
      "\"action\":\"add_vertex_json\",",
      "\"input\":{\"label\":\"A\",\"x\":0,\"y\":0},",
      "\"origin\":\"ffi\",",
      "\"command_id\":\"ffi-1\",",
      "\"protocol\":\"kwiver.command.v1\"",
      "}",
    ].join(""),
  )
  let add_root : Map[String, Json] = @json.from_json(@json.parse(add_json))
  let add_sequence : Int = @json.from_json(browser_demo_test_json_get(add_root, "sequence"))
  let add_ok : Bool = @json.from_json(browser_demo_test_json_get(add_root, "ok"))
  let add_protocol : String = @json.from_json(
    browser_demo_test_json_get(add_root, "protocol"),
  )
  inspect(add_sequence, content="1")
  inspect(add_ok, content="true")
  inspect(add_protocol, content="kwiver.command.v1")
  inspect(
    browser_demo_test_json_optional_string(add_root, "undo_checkpoint"),
    content=["Some(\"", initial_payload, "\")"].join(""),
  )
  inspect(
    browser_demo_test_json_optional_string(add_root, "origin"),
    content="Some(\"ffi\")",
  )
  inspect(
    browser_demo_test_json_optional_string(add_root, "command_id"),
    content="Some(\"ffi-1\")",
  )

  let malformed_json = ffi_browser_demo_session_dispatch_command_json(session, "{")
  let malformed_root : Map[String, Json] = @json.from_json(
    @json.parse(malformed_json),
  )
  let malformed_sequence : Int = @json.from_json(
    browser_demo_test_json_get(malformed_root, "sequence"),
  )
  let malformed_ok : Bool = @json.from_json(
    browser_demo_test_json_get(malformed_root, "ok"),
  )
  inspect(malformed_sequence, content="2")
  inspect(malformed_ok, content="false")
}

///|
test "browser demo ffi command envelope wrapper import_payload closes loop with checkpoints" {
  let source = BrowserDemoSession::new()
  let a = source.add_vertex("A", 0, 0)
  let b = source.add_vertex("B", 1, 0)
  ignore(source.add_edge(a, b, label="f"))
  let payload = source.payload()

  let session = ffi_browser_demo_session_new()
  let before_payload = session.payload()

  let import_json = ffi_browser_demo_session_dispatch_command_json(
    session,
    [
      "{",
      "\"action\":\"import_payload\",",
      "\"input\":\"", payload, "\",",
      "\"origin\":\"ffi-bootstrap\",",
      "\"command_id\":\"ffi-import-1\",",
      "\"protocol\":\"kwiver.command.v1\"",
      "}",
    ].join(""),
  )
  let import_root : Map[String, Json] = @json.from_json(@json.parse(import_json))
  let import_sequence : Int = @json.from_json(
    browser_demo_test_json_get(import_root, "sequence"),
  )
  let import_ok : Bool = @json.from_json(browser_demo_test_json_get(import_root, "ok"))
  let import_action : String = @json.from_json(
    browser_demo_test_json_get(import_root, "action"),
  )
  let import_changed : Bool = @json.from_json(
    browser_demo_test_json_get(import_root, "changed"),
  )
  let import_result : String = @json.from_json(
    browser_demo_test_json_get(import_root, "result"),
  )

  inspect(import_sequence, content="1")
  inspect(import_ok, content="true")
  inspect(import_action, content="import_payload")
  inspect(import_changed, content="true")
  inspect(import_result == session.payload(), content="true")
  inspect(session.cell_ids(), content="[1, 2, 3]")
  inspect(session.selection(), content="[]")
  inspect(
    browser_demo_test_json_optional_string(import_root, "origin"),
    content="Some(\"ffi-bootstrap\")",
  )
  inspect(
    browser_demo_test_json_optional_string(import_root, "command_id"),
    content="Some(\"ffi-import-1\")",
  )
  inspect(
    browser_demo_test_json_optional_string(import_root, "undo_checkpoint"),
    content=["Some(\"", before_payload, "\")"].join(""),
  )
  inspect(
    browser_demo_test_json_optional_string(import_root, "redo_checkpoint"),
    content=["Some(\"", session.payload(), "\")"].join(""),
  )

  let after_state : Map[String, Json] = @json.from_json(
    browser_demo_test_json_get(import_root, "after"),
  )
  let after_cell_ids : Array[Int] = @json.from_json(
    browser_demo_test_json_get(after_state, "cell_ids"),
  )
  let after_selection : Array[Int] = @json.from_json(
    browser_demo_test_json_get(after_state, "selection"),
  )
  inspect(after_cell_ids, content="[1, 2, 3]")
  inspect(after_selection, content="[]")
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
