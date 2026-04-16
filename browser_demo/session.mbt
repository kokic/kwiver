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
fn browser_demo_json_optional_string(
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
fn browser_demo_optional_string_json(value : String?) -> Json {
  match value {
    Some(raw) => Json::string(raw)
    None => Json::null()
  }
}

///|
fn browser_demo_int_array_json(values : Array[Int]) -> Json {
  let out : Array[Json] = []
  for value in values {
    out.push(Json::number(value.to_double()))
  }
  Json::array(out)
}

///|
fn browser_demo_int_arrays_equal(lhs : Array[Int], rhs : Array[Int]) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for i = 0; i < lhs.length(); i = i + 1 {
    if lhs[i] != rhs[i] {
      return false
    }
  }
  true
}

///|
fn browser_demo_state_json(
  payload : String,
  selection : Array[Int],
  cell_ids : Array[Int],
) -> Json {
  Json::object({
    "payload": Json::string(payload),
    "selection": browser_demo_int_array_json(selection),
    "cell_ids": browser_demo_int_array_json(cell_ids),
  })
}

///|
fn browser_demo_action(action : String) -> String {
  Json::object({ "action": Json::string(action) }).stringify()
}

///|
fn browser_demo_command_protocol() -> String {
  "kwiver.command.v1"
}

///|
fn browser_demo_dispatch_error_output(action : String, message : String) -> String {
  Json::object({
    "ok": Json::boolean(false),
    "action": Json::string(action),
    "result": Json::null(),
    "error": Json::string(message),
  }).stringify()
}

///|
pub struct BrowserDemoSession {
  runtime : @browser_adapter.BrowserRuntime
  mut command_sequence : Int
}

///|
fn BrowserDemoSession::dispatch_json_safe(
  self : BrowserDemoSession,
  action_json : String,
) -> String {
  @browser_adapter.ffi_browser_runtime_dispatch_json_safe(self.runtime, action_json)
}

///|
fn BrowserDemoSession::query_result(self : BrowserDemoSession, action : String) -> Json? {
  match browser_demo_parse_json_object(self.dispatch_json_safe(browser_demo_action(action))) {
    Some(root) => root.get("result")
    None => None
  }
}

///|
fn BrowserDemoSession::payload(self : BrowserDemoSession) -> String {
  match self.query_result("export_payload") {
    Some(raw) => {
      let parsed : Result[String, Error] = try? @json.from_json(raw)
      match parsed {
        Ok(payload) => payload
        Err(_) => ""
      }
    }
    None => ""
  }
}

///|
fn BrowserDemoSession::selection(self : BrowserDemoSession) -> Array[Int] {
  match self.query_result("selection") {
    Some(raw) => {
      let parsed : Result[Array[Int], Error] = try? @json.from_json(raw)
      match parsed {
        Ok(selection) => selection
        Err(_) => []
      }
    }
    None => []
  }
}

///|
fn BrowserDemoSession::all_cell_ids(self : BrowserDemoSession) -> Array[Int] {
  match self.query_result("all_cell_ids_json") {
    Some(raw) => {
      let parsed : Result[Array[Int], Error] = try? @json.from_json(raw)
      match parsed {
        Ok(cell_ids) => cell_ids
        Err(_) => []
      }
    }
    None => []
  }
}

///|
pub fn BrowserDemoSession::new() -> BrowserDemoSession {
  {
    runtime: @browser_adapter.ffi_browser_runtime_new(),
    command_sequence: 0,
  }
}

///|
pub fn BrowserDemoSession::dispatch_command_json(
  self : BrowserDemoSession,
  command_json : String,
) -> String {
  let before_payload = self.payload()
  let before_selection = self.selection()
  let before_cell_ids = self.all_cell_ids()

  let protocol = browser_demo_command_protocol()
  let mut origin : String? = None
  let mut command_id : String? = None
  let mut requested_action = "unknown"
  let mut protocol_error : String? = None

  match browser_demo_parse_json_object(command_json) {
    Some(command_root) => {
      origin = browser_demo_json_optional_string(command_root, "origin")
      command_id = browser_demo_json_optional_string(command_root, "command_id")
      requested_action = browser_demo_json_string_or(
        command_root,
        "action",
        requested_action,
      )
      match browser_demo_json_optional_string(command_root, "protocol") {
        Some(requested_protocol) =>
          if requested_protocol != protocol {
            protocol_error = Some(
              [
                "command protocol mismatch: expected ",
                protocol,
                ", got ",
                requested_protocol,
              ].join(""),
            )
          }
        None =>
          protocol_error = Some(
            [
              "missing command protocol: expected ",
              protocol,
            ].join(""),
          )
      }
    }
    None =>
      protocol_error = Some(
        [
          "malformed command envelope: expected protocol ",
          protocol,
        ].join(""),
      )
  }

  self.command_sequence += 1
  let sequence = self.command_sequence

  let dispatch_output = match protocol_error {
    Some(message) => browser_demo_dispatch_error_output(requested_action, message)
    None => self.dispatch_json_safe(command_json)
  }

  let mut ok = false
  let mut action = requested_action
  let mut result : Json = Json::null()
  let mut error : String? = Some("dispatch output parse failed")
  match browser_demo_parse_json_object(dispatch_output) {
    Some(dispatch_root) => {
      ok = browser_demo_json_bool_or(dispatch_root, "ok", false)
      action = browser_demo_json_string_or(dispatch_root, "action", action)
      match dispatch_root.get("result") {
        Some(runtime_result) => result = runtime_result
        None => ()
      }
      error = browser_demo_json_optional_string(dispatch_root, "error")
    }
    None => ()
  }

  let after_payload = self.payload()
  let after_selection = self.selection()
  let after_cell_ids = self.all_cell_ids()
  let changed = before_payload != after_payload ||
    !browser_demo_int_arrays_equal(before_selection, after_selection) ||
    !browser_demo_int_arrays_equal(before_cell_ids, after_cell_ids)

  let undo_checkpoint = if changed {
    Some(before_payload)
  } else {
    None
  }
  let redo_checkpoint = if changed {
    Some(after_payload)
  } else {
    None
  }

  Json::object({
    "sequence": Json::number(sequence.to_double()),
    "ok": Json::boolean(ok),
    "action": Json::string(action),
    "protocol": Json::string(protocol),
    "origin": browser_demo_optional_string_json(origin),
    "command_id": browser_demo_optional_string_json(command_id),
    "result": result,
    "error": browser_demo_optional_string_json(error),
    "changed": Json::boolean(changed),
    "undo_checkpoint": browser_demo_optional_string_json(undo_checkpoint),
    "redo_checkpoint": browser_demo_optional_string_json(redo_checkpoint),
    "before": browser_demo_state_json(
      before_payload,
      before_selection,
      before_cell_ids,
    ),
    "after": browser_demo_state_json(
      after_payload,
      after_selection,
      after_cell_ids,
    ),
  }).stringify()
}

///|
pub fn ffi_browser_demo_command_protocol() -> String {
  browser_demo_command_protocol()
}

///|
pub fn ffi_browser_demo_session_new() -> BrowserDemoSession {
  BrowserDemoSession::new()
}

///|
pub fn ffi_browser_demo_session_dispatch_command_json(
  session : BrowserDemoSession,
  command_json : String,
) -> String {
  session.dispatch_command_json(command_json)
}
