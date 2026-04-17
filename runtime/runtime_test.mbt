///|
fn runtime_dispatch_test_json_get(root : Map[String, Json], key : String) -> Json {
  match root.get(key) {
    Some(value) => value
    None => panic()
  }
}

///|
test "browser runtime dispatch_json_safe handles add_vertex action" {
  let runtime = ffi_runtime_new()
  let output = ffi_runtime_dispatch_json_safe(
    runtime,
    "{\"action\":\"add_vertex_json\",\"input\":{\"label\":\"A\",\"x\":0,\"y\":0}}",
  )
  let root : Map[String, Json] = @json.from_json(@json.parse(output))

  let ok : Bool = @json.from_json(runtime_dispatch_test_json_get(root, "ok"))
  inspect(ok, content="true")
  inspect(
    runtime_dispatch_test_json_get(root, "action"),
    content="String(\"add_vertex_json\")",
  )
}

///|
test "browser runtime dispatch_json_safe wraps malformed json as error envelope" {
  let runtime = ffi_runtime_new()
  let output = ffi_runtime_dispatch_json_safe(runtime, "{")
  let root : Map[String, Json] = @json.from_json(@json.parse(output))

  let ok : Bool = @json.from_json(runtime_dispatch_test_json_get(root, "ok"))
  inspect(ok, content="false")
  inspect(
    runtime_dispatch_test_json_get(root, "action"),
    content="String(\"unknown\")",
  )
}
