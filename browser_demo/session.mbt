///|
fn browser_demo_int_array_json(values : Array[Int]) -> Json {
  let out : Array[Json] = []
  for value in values {
    out.push(Json::number(value.to_double()))
  }
  Json::array(out)
}

///|
fn browser_demo_parse_json_object(input : String) -> Map[String, Json]? {
  let parsed : Result[Json, Error] = try? @json.parse(input)
  match parsed {
    Ok(Json::Object(root)) => Some(root)
    _ => None
  }
}

///|
fn browser_demo_json_string_or(
  root : Map[String, Json],
  key : String,
  fallback : String,
) -> String {
  match root.get(key) {
    Some(raw) => {
      let parsed : Result[String, Error] = try? @json.from_json(raw)
      match parsed {
        Ok(value) => value
        Err(_) => fallback
      }
    }
    None => fallback
  }
}

///|
fn browser_demo_json_int_array_or(
  root : Map[String, Json],
  key : String,
  fallback : Array[Int],
) -> Array[Int] {
  match root.get(key) {
    Some(raw) => {
      let parsed : Result[Array[Int], Error] = try? @json.from_json(raw)
      match parsed {
        Ok(value) => value
        Err(_) => fallback
      }
    }
    None => fallback
  }
}

///|
fn browser_demo_action(action : String) -> String {
  Json::object({ "action": Json::string(action) }).stringify()
}

///|
fn browser_demo_action_with_input(action : String, input : Json) -> String {
  Json::object({
    "action": Json::string(action),
    "input": input,
  }).stringify()
}

///|
pub struct BrowserDemoSession {
  runtime : @browser_adapter.BrowserRuntime
  mut payload : String
  mut selection : Array[Int]
}

///|
pub fn BrowserDemoSession::new() -> BrowserDemoSession {
  let runtime = @browser_adapter.ffi_browser_runtime_new()
  {
    runtime,
    payload: @browser_adapter.ffi_browser_runtime_export_payload(runtime),
    selection: @browser_adapter.ffi_browser_runtime_selection(runtime),
  }
}

///|
fn BrowserDemoSession::sync_from_runtime(self : BrowserDemoSession) -> Unit {
  self.payload = @browser_adapter.ffi_browser_runtime_export_payload(self.runtime)
  self.selection = @browser_adapter.ffi_browser_runtime_selection(self.runtime)
}

///|
fn BrowserDemoSession::sync_from_dispatch_output(
  self : BrowserDemoSession,
  output_json : String,
) -> Unit {
  match browser_demo_parse_json_object(output_json) {
    Some(root) => {
      self.payload = browser_demo_json_string_or(
        root,
        "payload",
        @browser_adapter.ffi_browser_runtime_export_payload(self.runtime),
      )
      self.selection = browser_demo_json_int_array_or(
        root,
        "selection",
        @browser_adapter.ffi_browser_runtime_selection(self.runtime),
      )
    }
    None => self.sync_from_runtime()
  }
}

///|
pub fn BrowserDemoSession::dispatch_json(
  self : BrowserDemoSession,
  action_json : String,
) -> String {
  let output = @browser_adapter.ffi_browser_runtime_dispatch_json(
    self.runtime,
    action_json,
  )
  self.sync_from_dispatch_output(output)
  output
}

///|
pub fn BrowserDemoSession::dispatch_many_json(
  self : BrowserDemoSession,
  batch_json : String,
) -> String {
  let output = @browser_adapter.ffi_browser_runtime_dispatch_many_json(
    self.runtime,
    batch_json,
  )
  self.sync_from_dispatch_output(output)
  output
}

///|
pub fn BrowserDemoSession::payload(self : BrowserDemoSession) -> String {
  self.payload
}

///|
pub fn BrowserDemoSession::selection(self : BrowserDemoSession) -> Array[Int] {
  self.selection
}

///|
pub fn BrowserDemoSession::cell_ids(self : BrowserDemoSession) -> Array[Int] {
  @browser_adapter.ffi_browser_runtime_all_cell_ids(self.runtime)
}

///|
pub fn BrowserDemoSession::state_json(self : BrowserDemoSession) -> String {
  Json::object({
    "payload": Json::string(self.payload),
    "selection": browser_demo_int_array_json(self.selection),
    "cell_ids": browser_demo_int_array_json(self.cell_ids()),
  }).stringify()
}

///|
pub fn browser_demo_roundtrip_demo_json() -> String {
  let session = BrowserDemoSession::new()
  ignore(
    session.dispatch_json(
      browser_demo_action_with_input(
        "add_vertex_json",
        Json::object({
          "label": Json::string("A"),
          "x": Json::number(0.0),
          "y": Json::number(0.0),
        }),
      ),
    ),
  )
  ignore(
    session.dispatch_json(
      browser_demo_action_with_input(
        "add_vertex_json",
        Json::object({
          "label": Json::string("B"),
          "x": Json::number(1.0),
          "y": Json::number(0.0),
        }),
      ),
    ),
  )
  ignore(
    session.dispatch_json(
      browser_demo_action_with_input(
        "add_edge_json",
        Json::object({
          "source_id": Json::number(1.0),
          "target_id": Json::number(2.0),
          "label": Json::string("f"),
        }),
      ),
    ),
  )
  ignore(
    session.dispatch_json(
      browser_demo_action_with_input(
        "set_selection",
        Json::array([Json::number(3.0)]),
      ),
    ),
  )

  let payload = session.payload()
  let restored = BrowserDemoSession::new()
  ignore(
    restored.dispatch_json(
      browser_demo_action_with_input("import_payload", Json::string(payload)),
    ),
  )
  ignore(restored.dispatch_json(browser_demo_action("selection")))

  let restored_payload = restored.payload()
  Json::object({
    "ok": Json::boolean(payload == restored_payload),
    "payload": Json::string(payload),
    "restored_payload": Json::string(restored_payload),
    "cell_ids": browser_demo_int_array_json(restored.cell_ids()),
    "selection": browser_demo_int_array_json(restored.selection()),
  }).stringify()
}

///|
pub fn ffi_browser_demo_session_new() -> BrowserDemoSession {
  BrowserDemoSession::new()
}

///|
pub fn ffi_browser_demo_session_dispatch_json(
  session : BrowserDemoSession,
  action_json : String,
) -> String {
  session.dispatch_json(action_json)
}

///|
pub fn ffi_browser_demo_session_dispatch_many_json(
  session : BrowserDemoSession,
  batch_json : String,
) -> String {
  session.dispatch_many_json(batch_json)
}

///|
pub fn ffi_browser_demo_session_state_json(session : BrowserDemoSession) -> String {
  session.state_json()
}

///|
pub fn ffi_browser_demo_roundtrip_demo_json() -> String {
  browser_demo_roundtrip_demo_json()
}
