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
fn browser_demo_json_int_or(
  root : Map[String, Json],
  key : String,
  fallback : Int,
) -> Int {
  match root.get(key) {
    Some(raw) => {
      let parsed : Result[Int, Error] = try? @json.from_json(raw)
      match parsed {
        Ok(value) => value
        Err(_) => fallback
      }
    }
    None => fallback
  }
}

///|
fn browser_demo_json_bool_or(
  root : Map[String, Json],
  key : String,
  fallback : Bool,
) -> Bool {
  match root.get(key) {
    Some(raw) => {
      let parsed : Result[Bool, Error] = try? @json.from_json(raw)
      match parsed {
        Ok(value) => value
        Err(_) => fallback
      }
    }
    None => fallback
  }
}

///|
fn browser_demo_dispatch_result_object(output_json : String) -> Map[String, Json]? {
  match browser_demo_parse_json_object(output_json) {
    Some(root) =>
      match root.get("result") {
        Some(raw) => {
          let parsed : Result[Map[String, Json], Error] = try? @json.from_json(raw)
          match parsed {
            Ok(result) => Some(result)
            Err(_) => None
          }
        }
        None => None
      }
    None => None
  }
}

///|
fn browser_demo_dispatch_result_string(output_json : String) -> String? {
  match browser_demo_parse_json_object(output_json) {
    Some(root) =>
      match root.get("result") {
        Some(raw) => {
          let parsed : Result[String, Error] = try? @json.from_json(raw)
          match parsed {
            Ok(result) => Some(result)
            Err(_) => None
          }
        }
        None => None
      }
    None => None
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
pub fn BrowserDemoSession::add_vertex(
  self : BrowserDemoSession,
  label : String,
  x : Int,
  y : Int,
) -> Int {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "add_vertex_json",
      Json::object({
        "label": Json::string(label),
        "x": Json::number(x.to_double()),
        "y": Json::number(y.to_double()),
      }),
    ),
  )
  match browser_demo_dispatch_result_object(output) {
    Some(result) => browser_demo_json_int_or(result, "id", -1)
    None => -1
  }
}

///|
pub fn BrowserDemoSession::add_edge(
  self : BrowserDemoSession,
  source_id : Int,
  target_id : Int,
  label? : String = "",
) -> Int {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "add_edge_json",
      Json::object({
        "source_id": Json::number(source_id.to_double()),
        "target_id": Json::number(target_id.to_double()),
        "label": Json::string(label),
      }),
    ),
  )
  match browser_demo_dispatch_result_object(output) {
    Some(result) => browser_demo_json_int_or(result, "id", -1)
    None => -1
  }
}

///|
pub fn BrowserDemoSession::apply_selection(
  self : BrowserDemoSession,
  selected_ids : Array[Int],
) -> Array[Int] {
  let payload : Array[Json] = []
  for id in selected_ids {
    payload.push(Json::number(id.to_double()))
  }

  ignore(self.dispatch_json(
    browser_demo_action_with_input("set_selection", Json::array(payload)),
  ))
  self.selection
}

///|
pub fn BrowserDemoSession::import_payload(self : BrowserDemoSession, payload : String) -> Bool {
  let output = self.dispatch_json(
    browser_demo_action_with_input("import_payload", Json::string(payload)),
  )
  match browser_demo_parse_json_object(output) {
    Some(root) => browser_demo_json_bool_or(root, "ok", false)
    None => false
  }
}

///|
pub fn BrowserDemoSession::render_tikz(self : BrowserDemoSession) -> String {
  let output = self.dispatch_json(browser_demo_action("render_tikz"))
  match browser_demo_dispatch_result_string(output) {
    Some(result) => result
    None => ""
  }
}

///|
pub fn BrowserDemoSession::render_tikz_json(self : BrowserDemoSession) -> String {
  let output = self.dispatch_json(browser_demo_action("render_tikz_json"))
  match browser_demo_dispatch_result_object(output) {
    Some(result) => browser_demo_json_string_or(result, "data", "")
    None => ""
  }
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
  ignore(session.add_vertex("A", 0, 0))
  ignore(session.add_vertex("B", 1, 0))
  ignore(session.add_edge(1, 2, label="f"))
  ignore(session.apply_selection([3]))

  let payload = session.payload()
  let restored = BrowserDemoSession::new()
  ignore(restored.import_payload(payload))
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
pub fn ffi_browser_demo_session_add_vertex(
  session : BrowserDemoSession,
  label : String,
  x : Int,
  y : Int,
) -> Int {
  session.add_vertex(label, x, y)
}

///|
pub fn ffi_browser_demo_session_add_edge(
  session : BrowserDemoSession,
  source_id : Int,
  target_id : Int,
  label? : String = "",
) -> Int {
  session.add_edge(source_id, target_id, label~)
}

///|
pub fn ffi_browser_demo_session_set_selection(
  session : BrowserDemoSession,
  selected_ids : Array[Int],
) -> Array[Int] {
  session.apply_selection(selected_ids)
}

///|
pub fn ffi_browser_demo_session_import_payload(
  session : BrowserDemoSession,
  payload : String,
) -> Bool {
  session.import_payload(payload)
}

///|
pub fn ffi_browser_demo_session_render_tikz(session : BrowserDemoSession) -> String {
  session.render_tikz()
}

///|
pub fn ffi_browser_demo_session_render_tikz_json(
  session : BrowserDemoSession,
) -> String {
  session.render_tikz_json()
}

///|
pub fn ffi_browser_demo_session_state_json(session : BrowserDemoSession) -> String {
  session.state_json()
}

///|
pub fn ffi_browser_demo_roundtrip_demo_json() -> String {
  browser_demo_roundtrip_demo_json()
}
