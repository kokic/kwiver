///|
fn browser_demo_test_json_get(root : Map[String, Json], key : String) -> Json {
  match root.get(key) {
    Some(value) => value
    None => panic()
  }
}

///|
fn browser_demo_test_json_optional_string(
  root : Map[String, Json],
  key : String,
) -> String? {
  match root.get(key) {
    Some(Json::Null) => None
    Some(raw) => {
      let parsed : Result[String, Error] = try? @json.from_json(raw)
      match parsed {
        Ok(value) => Some(value)
        Err(_) => None
      }
    }
    None => None
  }
}

///|
test "browser demo command envelope dispatches runtime action" {
  inspect(ffi_browser_demo_command_protocol(), content="kwiver.command.v1")

  let session = ffi_browser_demo_session_new()
  let output = ffi_browser_demo_session_dispatch_command_json(
    session,
    "{\"protocol\":\"kwiver.command.v1\",\"action\":\"add_vertex_json\",\"origin\":\"test\",\"command_id\":\"cmd-1\",\"input\":{\"label\":\"A\",\"x\":0,\"y\":0}}",
  )
  let root : Map[String, Json] = @json.from_json(@json.parse(output))

  let ok : Bool = @json.from_json(browser_demo_test_json_get(root, "ok"))
  inspect(ok, content="true")
  inspect(
    browser_demo_test_json_get(root, "action"),
    content="String(\"add_vertex_json\")",
  )
  inspect(
    browser_demo_test_json_get(root, "protocol"),
    content="String(\"kwiver.command.v1\")",
  )
  inspect(
    browser_demo_test_json_get(root, "origin"),
    content="String(\"test\")",
  )
  inspect(
    browser_demo_test_json_get(root, "command_id"),
    content="String(\"cmd-1\")",
  )
}

///|
test "browser demo command envelope rejects protocol mismatch" {
  let session = ffi_browser_demo_session_new()
  let output = ffi_browser_demo_session_dispatch_command_json(
    session,
    "{\"protocol\":\"kwiver.command.v2\",\"action\":\"add_vertex_json\",\"input\":{\"label\":\"A\",\"x\":0,\"y\":0}}",
  )
  let root : Map[String, Json] = @json.from_json(@json.parse(output))

  let ok : Bool = @json.from_json(browser_demo_test_json_get(root, "ok"))
  inspect(ok, content="false")
  let error = browser_demo_test_json_optional_string(root, "error")
  inspect(error is Some(_), content="true")
}
