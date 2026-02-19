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
