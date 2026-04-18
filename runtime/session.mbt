///|
fn runtime_parse_json_object(input : String) -> Map[String, Json]? {
  let parsed : Result[Json, Error] = try? @json.parse(input)
  match parsed {
    Ok(Json::Object(root)) => Some(root)
    _ => None
  }
}

///|
fn runtime_json_string_or(
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
fn runtime_json_optional_string(
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
fn runtime_json_bool_or(
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
fn runtime_optional_string_json(value : String?) -> Json {
  match value {
    Some(raw) => Json::string(raw)
    None => Json::null()
  }
}

///|
fn runtime_int_array_json(values : Array[Int]) -> Json {
  let out : Array[Json] = []
  for value in values {
    out.push(Json::number(value.to_double()))
  }
  Json::array(out)
}

///|
fn runtime_int_arrays_equal(lhs : Array[Int], rhs : Array[Int]) -> Bool {
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
fn runtime_state_json(
  payload : String,
  selection : Array[Int],
  cell_ids : Array[Int],
) -> Json {
  Json::object({
    "payload": Json::string(payload),
    "selection": runtime_int_array_json(selection),
    "cell_ids": runtime_int_array_json(cell_ids),
  })
}

///|
fn runtime_action(action : String) -> String {
  Json::object({ "action": Json::string(action) }).stringify()
}

///|
fn runtime_command_protocol() -> String {
  "kwiver.command.v1"
}

///|
fn runtime_dispatch_error_output(action : String, message : String) -> String {
  Json::object({
    "ok": Json::boolean(false),
    "action": Json::string(action),
    "result": Json::null(),
    "error": Json::string(message),
  }).stringify()
}

///|
pub struct BrowserDemoSession {
  runtime : BrowserRuntime
  mut command_sequence : Int
}

///|
fn BrowserDemoSession::dispatch_json_safe(
  self : BrowserDemoSession,
  action_json : String,
) -> String {
  ffi_runtime_dispatch_json_safe(self.runtime, action_json)
}

///|
fn BrowserDemoSession::query_result(self : BrowserDemoSession, action : String) -> Json? {
  match runtime_parse_json_object(self.dispatch_json_safe(runtime_action(action))) {
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
    runtime: ffi_runtime_new(),
    command_sequence: 0,
  }
}

///|
pub fn BrowserDemoSession::dispatch_command_json(
  self : BrowserDemoSession,
  command_json : String,
) -> String {
  // Session responses are stateful envelopes around the stateless runtime
  // dispatch API, so snapshot before/after state up front.
  let before_payload = self.payload()
  let before_selection = self.selection()
  let before_cell_ids = self.all_cell_ids()

  let protocol = runtime_command_protocol()
  let mut origin : String? = None
  let mut command_id : String? = None
  let mut requested_action = "unknown"
  let mut protocol_error : String? = None

  // Validate the outer command envelope here so malformed requests still
  // produce the same session-shaped error payload as runtime failures.
  match runtime_parse_json_object(command_json) {
    Some(command_root) => {
      origin = runtime_json_optional_string(command_root, "origin")
      command_id = runtime_json_optional_string(command_root, "command_id")
      requested_action = runtime_json_string_or(
        command_root,
        "action",
        requested_action,
      )
      match runtime_json_optional_string(command_root, "protocol") {
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
    Some(message) => runtime_dispatch_error_output(requested_action, message)
    None => self.dispatch_json_safe(command_json)
  }

  let mut ok = false
  let mut action = requested_action
  let mut result : Json = Json::null()
  let mut error : String? = Some("dispatch output parse failed")
  match runtime_parse_json_object(dispatch_output) {
    Some(dispatch_root) => {
      ok = runtime_json_bool_or(dispatch_root, "ok", false)
      action = runtime_json_string_or(dispatch_root, "action", action)
      match dispatch_root.get("result") {
        Some(runtime_result) => result = runtime_result
        None => ()
      }
      error = runtime_json_optional_string(dispatch_root, "error")
    }
    None => ()
  }

  let after_payload = self.payload()
  let after_selection = self.selection()
  let after_cell_ids = self.all_cell_ids()
  let changed = before_payload != after_payload ||
    !runtime_int_arrays_equal(before_selection, after_selection) ||
    !runtime_int_arrays_equal(before_cell_ids, after_cell_ids)

  // Read-only commands still get a full envelope, but only material state
  // changes should create undo/redo checkpoints.
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
    "origin": runtime_optional_string_json(origin),
    "command_id": runtime_optional_string_json(command_id),
    "result": result,
    "error": runtime_optional_string_json(error),
    "changed": Json::boolean(changed),
    "undo_checkpoint": runtime_optional_string_json(undo_checkpoint),
    "redo_checkpoint": runtime_optional_string_json(redo_checkpoint),
    "before": runtime_state_json(
      before_payload,
      before_selection,
      before_cell_ids,
    ),
    "after": runtime_state_json(
      after_payload,
      after_selection,
      after_cell_ids,
    ),
  }).stringify()
}

///|
pub fn ffi_runtime_command_protocol() -> String {
  runtime_command_protocol()
}

///|
pub fn ffi_runtime_session_new() -> BrowserDemoSession {
  BrowserDemoSession::new()
}

///|
pub fn ffi_runtime_session_dispatch_command_json(
  session : BrowserDemoSession,
  command_json : String,
) -> String {
  session.dispatch_command_json(command_json)
}
