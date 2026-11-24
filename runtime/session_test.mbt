///|
fn runtime_test_json_get(root : Map[String, Json], key : String) -> Json {
  match root.get(key) {
    Some(value) => value
    None => panic()
  }
}

///|
fn runtime_test_json_optional_string(
  root : Map[String, Json],
  key : String,
) -> String? {
  match root.get(key) {
    Some(Json::Null) => None
    Some(raw) => try Some(@json.from_json(raw)) catch { _ => None }
    None => None
  }
}

///|
test "browser demo command envelope dispatches runtime action" {
  @test.assert_eq(@runtime.ffi_runtime_command_protocol(), "kwiver.command.v1")

  let session = @runtime.ffi_runtime_session_new()
  let output = @runtime.ffi_runtime_session_dispatch_command_json(
    session, "{\"protocol\":\"kwiver.command.v1\",\"action\":\"add_vertex_json\",\"origin\":\"test\",\"command_id\":\"cmd-1\",\"input\":{\"label\":\"A\",\"x\":0,\"y\":0}}",
  )
  let root : Map[String, Json] = @json.from_json(@json.parse(output))

  let ok : Bool = @json.from_json(runtime_test_json_get(root, "ok"))
  inspect(ok, content="true")
  @test.assert_eq(
    runtime_test_json_get(root, "action"),
    Json::string("add_vertex_json"),
  )
  @test.assert_eq(
    runtime_test_json_get(root, "protocol"),
    Json::string("kwiver.command.v1"),
  )
  @test.assert_eq(runtime_test_json_get(root, "origin"), Json::string("test"))
  @test.assert_eq(
    runtime_test_json_get(root, "command_id"),
    Json::string("cmd-1"),
  )
}

///|
test "browser demo command envelope rejects protocol mismatch" {
  let session = @runtime.ffi_runtime_session_new()
  let output = @runtime.ffi_runtime_session_dispatch_command_json(
    session, "{\"protocol\":\"kwiver.command.v2\",\"action\":\"add_vertex_json\",\"input\":{\"label\":\"A\",\"x\":0,\"y\":0}}",
  )
  let root : Map[String, Json] = @json.from_json(@json.parse(output))

  let ok : Bool = @json.from_json(runtime_test_json_get(root, "ok"))
  inspect(ok, content="false")
  let error = runtime_test_json_optional_string(root, "error")
  inspect(error is Some(_), content="true")
}
