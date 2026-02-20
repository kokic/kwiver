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
fn browser_demo_parse_json_object_or_empty(input : String) -> Json {
  match browser_demo_parse_json_object(input) {
    Some(root) => Json::object(root)
    None => Json::object({})
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
fn browser_demo_json_bool_array_or(
  root : Map[String, Json],
  key : String,
  fallback : Array[Bool],
) -> Array[Bool] {
  match root.get(key) {
    Some(raw) => {
      let parsed : Result[Array[Bool], Error] = try? @json.from_json(raw)
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
fn browser_demo_dispatch_result_json(output_json : String) -> Json? {
  match browser_demo_parse_json_object(output_json) {
    Some(root) => root.get("result")
    None => None
  }
}

///|
fn browser_demo_dispatch_result_int_array(output_json : String) -> Array[Int]? {
  match browser_demo_dispatch_result_json(output_json) {
    Some(raw) => {
      let parsed : Result[Array[Int], Error] = try? @json.from_json(raw)
      match parsed {
        Ok(values) => Some(values)
        Err(_) => None
      }
    }
    None => None
  }
}

///|
fn browser_demo_dispatch_ok(output_json : String) -> Bool {
  match browser_demo_parse_json_object(output_json) {
    Some(root) => browser_demo_json_bool_or(root, "ok", false)
    None => false
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
pub struct BrowserDemoImportResult {
  ok : Bool
  payload : String
  macro_url : String?
  renderer : String?
  embed : Bool
}

///|
pub struct BrowserDemoIdRemap {
  old_id : Int
  new_id : Int
}

///|
pub struct BrowserDemoSelectionImportResult {
  ok : Bool
  payload : String
  imported_ids : Array[Int]
  id_remap : Array[BrowserDemoIdRemap]
}

///|
pub struct BrowserDemoMutationBatchResult {
  payload : String
  label_results : Array[Bool]
  label_colour_results : Array[Bool]
  vertex_position_results : Array[Bool]
  edge_option_results : Array[Bool]
  edge_connection_results : Array[Bool]
}

///|
pub struct BrowserDemoTikzRenderResult {
  data : String
  metadata : Json
}

///|
fn browser_demo_optional_string_json(value : String?) -> Json {
  match value {
    Some(raw) => Json::string(raw)
    None => Json::null()
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
fn browser_demo_id_remap_json(entry : BrowserDemoIdRemap) -> Json {
  Json::object({
    "old_id": Json::number(entry.old_id.to_double()),
    "new_id": Json::number(entry.new_id.to_double()),
  })
}

///|
fn browser_demo_import_result_json(result : BrowserDemoImportResult) -> Json {
  Json::object({
    "ok": Json::boolean(result.ok),
    "payload": Json::string(result.payload),
    "macro_url": browser_demo_optional_string_json(result.macro_url),
    "renderer": browser_demo_optional_string_json(result.renderer),
    "embed": Json::boolean(result.embed),
  })
}

///|
fn browser_demo_selection_import_result_json(
  result : BrowserDemoSelectionImportResult,
) -> Json {
  let remap : Array[Json] = []
  for entry in result.id_remap {
    remap.push(browser_demo_id_remap_json(entry))
  }
  Json::object({
    "ok": Json::boolean(result.ok),
    "payload": Json::string(result.payload),
    "imported_ids": browser_demo_int_array_json(result.imported_ids),
    "id_remap": Json::array(remap),
  })
}

///|
fn browser_demo_bool_array_json(values : Array[Bool]) -> Json {
  let out : Array[Json] = []
  for value in values {
    out.push(Json::boolean(value))
  }
  Json::array(out)
}

///|
fn browser_demo_mutation_batch_result_json(
  result : BrowserDemoMutationBatchResult,
) -> Json {
  Json::object({
    "payload": Json::string(result.payload),
    "label_results": browser_demo_bool_array_json(result.label_results),
    "label_colour_results": browser_demo_bool_array_json(
      result.label_colour_results,
    ),
    "vertex_position_results": browser_demo_bool_array_json(
      result.vertex_position_results,
    ),
    "edge_option_results": browser_demo_bool_array_json(result.edge_option_results),
    "edge_connection_results": browser_demo_bool_array_json(
      result.edge_connection_results,
    ),
  })
}

///|
fn browser_demo_tikz_render_result_json(result : BrowserDemoTikzRenderResult) -> Json {
  Json::object({
    "data": Json::string(result.data),
    "metadata": result.metadata,
  })
}

///|
pub fn BrowserDemoImportResult::to_json_string(self : BrowserDemoImportResult) -> String {
  browser_demo_import_result_json(self).stringify()
}

///|
pub fn BrowserDemoSelectionImportResult::to_json_string(
  self : BrowserDemoSelectionImportResult,
) -> String {
  browser_demo_selection_import_result_json(self).stringify()
}

///|
pub fn BrowserDemoMutationBatchResult::to_json_string(
  self : BrowserDemoMutationBatchResult,
) -> String {
  browser_demo_mutation_batch_result_json(self).stringify()
}

///|
pub fn BrowserDemoTikzRenderResult::to_json_string(
  self : BrowserDemoTikzRenderResult,
) -> String {
  browser_demo_tikz_render_result_json(self).stringify()
}

///|
fn browser_demo_import_result_from_output(
  output_json : String,
  fallback_payload : String,
) -> BrowserDemoImportResult {
  match browser_demo_parse_json_object(output_json) {
    Some(root) => {
      let ok = browser_demo_json_bool_or(root, "ok", false)
      match browser_demo_dispatch_result_object(output_json) {
        Some(result) => {
          let payload = browser_demo_json_string_or(
            result,
            "payload",
            browser_demo_json_string_or(root, "payload", fallback_payload),
          )
          {
            ok,
            payload,
            macro_url: browser_demo_json_optional_string(result, "macro_url"),
            renderer: browser_demo_json_optional_string(result, "renderer"),
            embed: browser_demo_json_bool_or(result, "embed", false),
          }
        }
        None => {
          ok,
          payload: browser_demo_json_string_or(root, "payload", fallback_payload),
          macro_url: None,
          renderer: None,
          embed: false,
        }
      }
    }
    None => {
      ok: false,
      payload: fallback_payload,
      macro_url: None,
      renderer: None,
      embed: false,
    }
  }
}

///|
fn browser_demo_mutation_batch_result_from_engine(
  result : @engine.QuiverUiMutationBatchResult,
) -> BrowserDemoMutationBatchResult {
  {
    payload: result.payload,
    label_results: result.label_results,
    label_colour_results: result.label_colour_results,
    vertex_position_results: result.vertex_position_results,
    edge_option_results: result.edge_option_results,
    edge_connection_results: result.edge_connection_results,
  }
}

///|
fn browser_demo_mutation_batch_result_from_output(
  output_json : String,
  fallback_payload : String,
) -> BrowserDemoMutationBatchResult {
  match browser_demo_dispatch_result_object(output_json) {
    Some(result) => {
      payload: browser_demo_json_string_or(result, "payload", fallback_payload),
      label_results: browser_demo_json_bool_array_or(result, "label_results", []),
      label_colour_results: browser_demo_json_bool_array_or(
        result,
        "label_colour_results",
        [],
      ),
      vertex_position_results: browser_demo_json_bool_array_or(
        result,
        "vertex_position_results",
        [],
      ),
      edge_option_results: browser_demo_json_bool_array_or(
        result,
        "edge_option_results",
        [],
      ),
      edge_connection_results: browser_demo_json_bool_array_or(
        result,
        "edge_connection_results",
        [],
      ),
    }
    None => {
      payload: fallback_payload,
      label_results: [],
      label_colour_results: [],
      vertex_position_results: [],
      edge_option_results: [],
      edge_connection_results: [],
    }
  }
}

///|
fn browser_demo_tikz_render_result_from_output(
  output_json : String,
) -> BrowserDemoTikzRenderResult {
  match browser_demo_dispatch_result_object(output_json) {
    Some(result) => {
      data: browser_demo_json_string_or(result, "data", ""),
      metadata: match result.get("metadata") {
        Some(value) => value
        None => Json::object({})
      },
    }
    None => {
      data: "",
      metadata: Json::object({}),
    }
  }
}

///|
fn browser_demo_selection_import_result_from_output(
  output_json : String,
  fallback_payload : String,
) -> BrowserDemoSelectionImportResult {
  match browser_demo_parse_json_object(output_json) {
    Some(root) => {
      let ok = browser_demo_json_bool_or(root, "ok", false)
      match browser_demo_dispatch_result_object(output_json) {
        Some(result) => {
          let id_remap : Array[BrowserDemoIdRemap] = []
          match result.get("id_remap") {
            Some(raw_remap) => {
              let parsed : Result[Array[Map[String, Json]], Error] = try? @json.from_json(
                raw_remap,
              )
              match parsed {
                Ok(entries) => {
                  for entry in entries {
                    id_remap.push({
                      old_id: browser_demo_json_int_or(entry, "old_id", -1),
                      new_id: browser_demo_json_int_or(entry, "new_id", -1),
                    })
                  }
                }
                Err(_) => ()
              }
            }
            None => ()
          }
          {
            ok,
            payload: browser_demo_json_string_or(
              result,
              "payload",
              browser_demo_json_string_or(root, "payload", fallback_payload),
            ),
            imported_ids: browser_demo_json_int_array_or(result, "imported_ids", []),
            id_remap,
          }
        }
        None => {
          ok,
          payload: browser_demo_json_string_or(root, "payload", fallback_payload),
          imported_ids: [],
          id_remap: [],
        }
      }
    }
    None => {
      ok: false,
      payload: fallback_payload,
      imported_ids: [],
      id_remap: [],
    }
  }
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
pub fn BrowserDemoSession::dispatch_json_safe(
  self : BrowserDemoSession,
  action_json : String,
) -> String {
  let output = @browser_adapter.ffi_browser_runtime_dispatch_json_safe(
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
pub fn BrowserDemoSession::dispatch_many_json_safe(
  self : BrowserDemoSession,
  batch_json : String,
) -> String {
  let output = @browser_adapter.ffi_browser_runtime_dispatch_many_json_safe(
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
pub fn BrowserDemoSession::set_label(
  self : BrowserDemoSession,
  cell_id : Int,
  label : String,
) -> Bool {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "set_label_json",
      Json::object({
        "cell_id": Json::number(cell_id.to_double()),
        "label": Json::string(label),
      }),
    ),
  )
  match browser_demo_dispatch_result_object(output) {
    Some(result) => browser_demo_json_bool_or(result, "ok", false)
    None => false
  }
}

///|
pub fn BrowserDemoSession::set_label_colour(
  self : BrowserDemoSession,
  cell_id : Int,
  label_colour : @engine.Colour,
) -> Bool {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "set_label_colour_json",
      Json::object({
        "cell_id": Json::number(cell_id.to_double()),
        "label_colour": Json::object({
          "h": Json::number(label_colour.h.to_double()),
          "s": Json::number(label_colour.s.to_double()),
          "l": Json::number(label_colour.l.to_double()),
          "a": Json::number(label_colour.a),
        }),
      }),
    ),
  )
  match browser_demo_dispatch_result_object(output) {
    Some(result) => browser_demo_json_bool_or(result, "ok", false)
    None => false
  }
}

///|
pub fn BrowserDemoSession::set_label_colour_hsla(
  self : BrowserDemoSession,
  cell_id : Int,
  h : Int,
  s : Int,
  l : Int,
  a : Double,
) -> Bool {
  self.set_label_colour(cell_id, @engine.Colour::new(h, s, l, a))
}

///|
pub fn BrowserDemoSession::move_vertex(
  self : BrowserDemoSession,
  vertex_id : Int,
  x : Int,
  y : Int,
) -> Bool {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "move_vertex_json",
      Json::object({
        "vertex_id": Json::number(vertex_id.to_double()),
        "x": Json::number(x.to_double()),
        "y": Json::number(y.to_double()),
      }),
    ),
  )
  match browser_demo_dispatch_result_object(output) {
    Some(result) => browser_demo_json_bool_or(result, "ok", false)
    None => false
  }
}

///|
pub fn BrowserDemoSession::set_edge_options_json(
  self : BrowserDemoSession,
  edge_id : Int,
  options_json : String,
) -> Bool {
  let options_result : Result[Json, Error] = try? @json.parse(options_json)
  let options_object = match options_result {
    Ok(Json::Object(value)) => value
    _ => return false
  }

  let required_fields = [
    "label_alignment",
    "label_position",
    "offset",
    "curve",
    "radius",
    "angle",
    "shorten_source",
    "shorten_target",
    "level",
    "shape",
    "colour",
    "edge_alignment_source",
    "edge_alignment_target",
    "style",
  ]
  for required in required_fields {
    if options_object.get(required) is None {
      return false
    }
  }

  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "set_edge_options_json",
      Json::object({
        "edge_id": Json::number(edge_id.to_double()),
        "options": Json::object(options_object),
      }),
    ),
  )
  match browser_demo_dispatch_result_object(output) {
    Some(result) => browser_demo_json_bool_or(result, "ok", false)
    None => false
  }
}

///|
pub fn BrowserDemoSession::patch_edge_options_json(
  self : BrowserDemoSession,
  edge_id : Int,
  patch_json : String,
) -> Bool {
  let patch_result : Result[Json, Error] = try? @json.parse(patch_json)
  let patch = match patch_result {
    Ok(value) => value
    Err(_) => return false
  }

  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "patch_edge_options_json",
      Json::object({
        "edge_id": Json::number(edge_id.to_double()),
        "patch": patch,
      }),
    ),
  )
  match browser_demo_dispatch_result_object(output) {
    Some(result) => browser_demo_json_bool_or(result, "ok", false)
    None => false
  }
}

///|
pub fn BrowserDemoSession::set_edge_label_alignment(
  self : BrowserDemoSession,
  edge_id : Int,
  label_alignment : String,
) -> Bool {
  let alignment = label_alignment.trim().to_string()
  if alignment != "left" &&
    alignment != "centre" &&
    alignment != "center" &&
    alignment != "right" &&
    alignment != "over" {
    return false
  }

  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "set_edge_label_alignment_json",
      Json::object({
        "edge_id": Json::number(edge_id.to_double()),
        "label_alignment": Json::string(alignment),
      }),
    ),
  )
  match browser_demo_dispatch_result_object(output) {
    Some(result) => browser_demo_json_bool_or(result, "ok", false)
    None => false
  }
}

///|
pub fn BrowserDemoSession::set_edge_label_position(
  self : BrowserDemoSession,
  edge_id : Int,
  label_position : Int,
) -> Bool {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "set_edge_label_position_json",
      Json::object({
        "edge_id": Json::number(edge_id.to_double()),
        "label_position": Json::number(label_position.to_double()),
      }),
    ),
  )
  match browser_demo_dispatch_result_object(output) {
    Some(result) => browser_demo_json_bool_or(result, "ok", false)
    None => false
  }
}

///|
pub fn BrowserDemoSession::set_edge_offset(
  self : BrowserDemoSession,
  edge_id : Int,
  offset : Int,
) -> Bool {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "set_edge_offset_json",
      Json::object({
        "edge_id": Json::number(edge_id.to_double()),
        "offset": Json::number(offset.to_double()),
      }),
    ),
  )
  match browser_demo_dispatch_result_object(output) {
    Some(result) => browser_demo_json_bool_or(result, "ok", false)
    None => false
  }
}

///|
pub fn BrowserDemoSession::set_edge_curve(
  self : BrowserDemoSession,
  edge_id : Int,
  curve : Int,
) -> Bool {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "set_edge_curve_json",
      Json::object({
        "edge_id": Json::number(edge_id.to_double()),
        "curve": Json::number(curve.to_double()),
      }),
    ),
  )
  match browser_demo_dispatch_result_object(output) {
    Some(result) => browser_demo_json_bool_or(result, "ok", false)
    None => false
  }
}

///|
pub fn BrowserDemoSession::set_edge_shorten(
  self : BrowserDemoSession,
  edge_id : Int,
  shorten_source : Int,
  shorten_target : Int,
) -> Bool {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "set_edge_shorten_json",
      Json::object({
        "edge_id": Json::number(edge_id.to_double()),
        "shorten_source": Json::number(shorten_source.to_double()),
        "shorten_target": Json::number(shorten_target.to_double()),
      }),
    ),
  )
  match browser_demo_dispatch_result_object(output) {
    Some(result) => browser_demo_json_bool_or(result, "ok", false)
    None => false
  }
}

///|
pub fn BrowserDemoSession::reconnect_edge(
  self : BrowserDemoSession,
  edge_id : Int,
  source_id : Int,
  target_id : Int,
) -> Bool {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "reconnect_edge_json",
      Json::object({
        "edge_id": Json::number(edge_id.to_double()),
        "source_id": Json::number(source_id.to_double()),
        "target_id": Json::number(target_id.to_double()),
      }),
    ),
  )
  match browser_demo_dispatch_result_object(output) {
    Some(result) => browser_demo_json_bool_or(result, "ok", false)
    None => false
  }
}

///|
pub fn BrowserDemoSession::remove(
  self : BrowserDemoSession,
  cell_id : Int,
  when? : Int = 0,
) -> Array[Int] {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "remove_json",
      Json::object({
        "cell_id": Json::number(cell_id.to_double()),
        "when": Json::number(when.to_double()),
      }),
    ),
  )
  match browser_demo_dispatch_result_object(output) {
    Some(result) => browser_demo_json_int_array_or(result, "removed_ids", [])
    None => []
  }
}

///|
pub fn BrowserDemoSession::flush(self : BrowserDemoSession, when : Int) -> Bool {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "flush_json",
      Json::object({ "when": Json::number(when.to_double()) }),
    ),
  )
  browser_demo_dispatch_ok(output)
}

///|
pub fn BrowserDemoSession::apply_mutation_batch_json(
  self : BrowserDemoSession,
  batch_json : String,
) -> BrowserDemoMutationBatchResult {
  let parsed : Result[Json, Error] = try? @json.parse(batch_json)
  let input = match parsed {
    Ok(Json::Object(value)) => Json::object(value)
    _ =>
      return {
        payload: self.payload,
        label_results: [],
        label_colour_results: [],
        vertex_position_results: [],
        edge_option_results: [],
        edge_connection_results: [],
      }
  }

  let output = self.dispatch_json(
    browser_demo_action_with_input("apply_mutation_batch_json", input),
  )
  browser_demo_mutation_batch_result_from_output(output, self.payload)
}

///|
pub fn BrowserDemoSession::apply_mutation_batch(
  self : BrowserDemoSession,
  batch : @engine.QuiverUiMutationBatch,
) -> BrowserDemoMutationBatchResult {
  let result = self.runtime.apply_mutation_batch(batch)
  self.sync_from_runtime()
  browser_demo_mutation_batch_result_from_engine(result)
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
pub fn BrowserDemoSession::export_selection(
  self : BrowserDemoSession,
  include_dependencies? : Bool = true,
) -> String {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "export_selection",
      Json::object({
        "include_dependencies": Json::boolean(include_dependencies),
      }),
    ),
  )
  match browser_demo_dispatch_result_string(output) {
    Some(payload) => payload
    None => ""
  }
}

///|
pub fn BrowserDemoSession::paste_selection(
  self : BrowserDemoSession,
  payload : String,
  origin_x : Int,
  origin_y : Int,
  start_id? : Int = 1,
) -> Array[Int] {
  self.paste_selection_result(payload, origin_x, origin_y, start_id~).imported_ids
}

///|
pub fn BrowserDemoSession::paste_selection_result(
  self : BrowserDemoSession,
  payload : String,
  origin_x : Int,
  origin_y : Int,
  start_id? : Int = 1,
) -> BrowserDemoSelectionImportResult {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "paste_selection_json",
      Json::object({
        "payload": Json::string(payload),
        "origin_x": Json::number(origin_x.to_double()),
        "origin_y": Json::number(origin_y.to_double()),
        "start_id": Json::number(start_id.to_double()),
      }),
    ),
  )
  browser_demo_selection_import_result_from_output(output, self.payload)
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
pub fn BrowserDemoSession::reset(self : BrowserDemoSession) -> Unit {
  @browser_adapter.ffi_browser_runtime_reset(self.runtime)
  self.sync_from_runtime()
}

///|
pub fn BrowserDemoSession::render_tikz(self : BrowserDemoSession) -> String {
  self.render_tikz_result().data
}

///|
pub fn BrowserDemoSession::render_tikz_result_with_input(
  self : BrowserDemoSession,
  input_json : String,
) -> BrowserDemoTikzRenderResult {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "render_tikz_json",
      browser_demo_parse_json_object_or_empty(input_json),
    ),
  )
  browser_demo_tikz_render_result_from_output(output)
}

///|
pub fn BrowserDemoSession::render_tikz_result(
  self : BrowserDemoSession,
) -> BrowserDemoTikzRenderResult {
  self.render_tikz_result_with_input("{}")
}

///|
pub fn BrowserDemoSession::render_tikz_json(self : BrowserDemoSession) -> String {
  self.render_tikz_result().data
}

///|
pub fn BrowserDemoSession::render_tikz_result_json(self : BrowserDemoSession) -> String {
  self.render_tikz_result().to_json_string()
}

///|
pub fn BrowserDemoSession::render_fletcher_with_input(
  self : BrowserDemoSession,
  input_json : String,
) -> String {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "render_fletcher",
      browser_demo_parse_json_object_or_empty(input_json),
    ),
  )
  match browser_demo_dispatch_result_string(output) {
    Some(result) => result
    None => ""
  }
}

///|
pub fn BrowserDemoSession::render_fletcher(self : BrowserDemoSession) -> String {
  self.render_fletcher_with_input("{}")
}

///|
pub fn BrowserDemoSession::render_html_embed_with_input(
  self : BrowserDemoSession,
  input_json : String,
) -> String {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "render_html_embed",
      browser_demo_parse_json_object_or_empty(input_json),
    ),
  )
  match browser_demo_dispatch_result_string(output) {
    Some(result) => result
    None => ""
  }
}

///|
pub fn BrowserDemoSession::render_html_embed(self : BrowserDemoSession) -> String {
  self.render_html_embed_with_input("{}")
}

///|
fn BrowserDemoSession::import_action_result(
  self : BrowserDemoSession,
  action : String,
  input : String,
  default_renderer? : String = "canvas",
) -> BrowserDemoImportResult {
  let output = self.dispatch_json(
    Json::object({
      "action": Json::string(action),
      "input": Json::string(input),
      "default_renderer": Json::string(default_renderer),
    }).stringify(),
  )
  browser_demo_import_result_from_output(output, self.payload)
}

///|
pub fn BrowserDemoSession::import_text_auto_result(
  self : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> BrowserDemoImportResult {
  self.import_action_result("import_text_auto_json", input, default_renderer~)
}

///|
pub fn BrowserDemoSession::import_text_auto(
  self : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> Bool {
  self.import_text_auto_result(input, default_renderer~).ok
}

///|
pub fn BrowserDemoSession::import_share_url_result(
  self : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> BrowserDemoImportResult {
  self.import_action_result("import_share_url_json", input, default_renderer~)
}

///|
pub fn BrowserDemoSession::import_share_url(
  self : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> Bool {
  self.import_share_url_result(input, default_renderer~).ok
}

///|
pub fn BrowserDemoSession::import_tikz_cd_result(
  self : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> BrowserDemoImportResult {
  self.import_action_result("import_tikz_cd_json", input, default_renderer~)
}

///|
pub fn BrowserDemoSession::import_tikz_cd(
  self : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> Bool {
  self.import_tikz_cd_result(input, default_renderer~).ok
}

///|
pub fn BrowserDemoSession::import_fletcher_result(
  self : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> BrowserDemoImportResult {
  self.import_action_result("import_fletcher_json", input, default_renderer~)
}

///|
pub fn BrowserDemoSession::import_fletcher(
  self : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> Bool {
  self.import_fletcher_result(input, default_renderer~).ok
}

///|
pub fn BrowserDemoSession::import_html_embed_result(
  self : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> BrowserDemoImportResult {
  self.import_action_result("import_html_embed_json", input, default_renderer~)
}

///|
pub fn BrowserDemoSession::import_html_embed(
  self : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> Bool {
  self.import_html_embed_result(input, default_renderer~).ok
}

///|
pub fn BrowserDemoSession::import_share_text_result(
  self : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> BrowserDemoImportResult {
  self.import_action_result("import_share_text_json", input, default_renderer~)
}

///|
pub fn BrowserDemoSession::import_share_text(
  self : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> Bool {
  self.import_share_text_result(input, default_renderer~).ok
}

///|
pub fn BrowserDemoSession::dependencies_of(
  self : BrowserDemoSession,
  cell_id : Int,
) -> Array[Int] {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "dependencies_of_json",
      Json::object({ "cell_id": Json::number(cell_id.to_double()) }),
    ),
  )
  match browser_demo_dispatch_result_int_array(output) {
    Some(values) => values
    None => []
  }
}

///|
pub fn BrowserDemoSession::reverse_dependencies_of(
  self : BrowserDemoSession,
  cell_id : Int,
) -> Array[Int] {
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "reverse_dependencies_of_json",
      Json::object({ "cell_id": Json::number(cell_id.to_double()) }),
    ),
  )
  match browser_demo_dispatch_result_int_array(output) {
    Some(values) => values
    None => []
  }
}

///|
pub fn BrowserDemoSession::transitive_dependencies(
  self : BrowserDemoSession,
  roots : Array[Int],
  exclude_roots? : Bool = false,
) -> Array[Int] {
  let roots_json : Array[Json] = []
  for root in roots {
    roots_json.push(Json::number(root.to_double()))
  }
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "transitive_dependencies_json",
      Json::object({
        "roots": Json::array(roots_json),
        "exclude_roots": Json::boolean(exclude_roots),
      }),
    ),
  )
  match browser_demo_dispatch_result_int_array(output) {
    Some(values) => values
    None => []
  }
}

///|
pub fn BrowserDemoSession::transitive_reverse_dependencies(
  self : BrowserDemoSession,
  roots : Array[Int],
) -> Array[Int] {
  let roots_json : Array[Json] = []
  for root in roots {
    roots_json.push(Json::number(root.to_double()))
  }
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "transitive_reverse_dependencies_json",
      Json::object({ "roots": Json::array(roots_json) }),
    ),
  )
  match browser_demo_dispatch_result_int_array(output) {
    Some(values) => values
    None => []
  }
}

///|
pub fn BrowserDemoSession::connected_components(
  self : BrowserDemoSession,
  roots : Array[Int],
) -> Array[Int] {
  let roots_json : Array[Json] = []
  for root in roots {
    roots_json.push(Json::number(root.to_double()))
  }
  let output = self.dispatch_json(
    browser_demo_action_with_input(
      "connected_components_json",
      Json::object({ "roots": Json::array(roots_json) }),
    ),
  )
  match browser_demo_dispatch_result_int_array(output) {
    Some(values) => values
    None => []
  }
}

///|
pub fn BrowserDemoSession::snapshot_json(self : BrowserDemoSession) -> String {
  let output = self.dispatch_json(browser_demo_action("snapshot_json"))
  match browser_demo_dispatch_result_json(output) {
    Some(snapshot) => snapshot.stringify()
    None => "{}"
  }
}

///|
pub fn BrowserDemoSession::snapshot(self : BrowserDemoSession) -> @engine.QuiverUiSnapshot {
  self.runtime.snapshot()
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
pub fn BrowserDemoSession::all_cells(self : BrowserDemoSession) -> Array[@engine.CellData] {
  @browser_adapter.ffi_browser_runtime_all_cells(self.runtime)
}

///|
pub fn BrowserDemoSession::all_cells_json(self : BrowserDemoSession) -> String {
  let output = self.dispatch_json(browser_demo_action("all_cells_json"))
  match browser_demo_dispatch_result_json(output) {
    Some(cells) => cells.stringify()
    None => "[]"
  }
}

///|
pub fn BrowserDemoSession::all_cell_ids(self : BrowserDemoSession) -> Array[Int] {
  @browser_adapter.ffi_browser_runtime_all_cell_ids(self.runtime)
}

///|
pub fn BrowserDemoSession::cell_ids(self : BrowserDemoSession) -> Array[Int] {
  self.all_cell_ids()
}

///|
pub fn BrowserDemoSession::state_json(self : BrowserDemoSession) -> String {
  Json::object({
    "payload": Json::string(self.payload),
    "selection": browser_demo_int_array_json(self.selection),
    "cell_ids": browser_demo_int_array_json(self.all_cell_ids()),
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
pub fn ffi_browser_demo_session_dispatch_json_safe(
  session : BrowserDemoSession,
  action_json : String,
) -> String {
  session.dispatch_json_safe(action_json)
}

///|
pub fn ffi_browser_demo_session_dispatch_many_json(
  session : BrowserDemoSession,
  batch_json : String,
) -> String {
  session.dispatch_many_json(batch_json)
}

///|
pub fn ffi_browser_demo_session_dispatch_many_json_safe(
  session : BrowserDemoSession,
  batch_json : String,
) -> String {
  session.dispatch_many_json_safe(batch_json)
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
pub fn ffi_browser_demo_session_set_label(
  session : BrowserDemoSession,
  cell_id : Int,
  label : String,
) -> Bool {
  session.set_label(cell_id, label)
}

///|
pub fn ffi_browser_demo_session_set_label_colour_hsla(
  session : BrowserDemoSession,
  cell_id : Int,
  h : Int,
  s : Int,
  l : Int,
  a : Double,
) -> Bool {
  session.set_label_colour_hsla(cell_id, h, s, l, a)
}

///|
pub fn ffi_browser_demo_session_set_edge_options_json(
  session : BrowserDemoSession,
  edge_id : Int,
  options_json : String,
) -> Bool {
  session.set_edge_options_json(edge_id, options_json)
}

///|
pub fn ffi_browser_demo_session_set_edge_label_alignment(
  session : BrowserDemoSession,
  edge_id : Int,
  label_alignment : String,
) -> Bool {
  session.set_edge_label_alignment(edge_id, label_alignment)
}

///|
pub fn ffi_browser_demo_session_set_edge_label_position(
  session : BrowserDemoSession,
  edge_id : Int,
  label_position : Int,
) -> Bool {
  session.set_edge_label_position(edge_id, label_position)
}

///|
pub fn ffi_browser_demo_session_set_edge_offset(
  session : BrowserDemoSession,
  edge_id : Int,
  offset : Int,
) -> Bool {
  session.set_edge_offset(edge_id, offset)
}

///|
pub fn ffi_browser_demo_session_set_edge_curve(
  session : BrowserDemoSession,
  edge_id : Int,
  curve : Int,
) -> Bool {
  session.set_edge_curve(edge_id, curve)
}

///|
pub fn ffi_browser_demo_session_set_edge_shorten(
  session : BrowserDemoSession,
  edge_id : Int,
  shorten_source : Int,
  shorten_target : Int,
) -> Bool {
  session.set_edge_shorten(edge_id, shorten_source, shorten_target)
}

///|
pub fn ffi_browser_demo_session_reconnect_edge(
  session : BrowserDemoSession,
  edge_id : Int,
  source_id : Int,
  target_id : Int,
) -> Bool {
  session.reconnect_edge(edge_id, source_id, target_id)
}

///|
pub fn ffi_browser_demo_session_move_vertex(
  session : BrowserDemoSession,
  vertex_id : Int,
  x : Int,
  y : Int,
) -> Bool {
  session.move_vertex(vertex_id, x, y)
}

///|
pub fn ffi_browser_demo_session_patch_edge_options_json(
  session : BrowserDemoSession,
  edge_id : Int,
  patch_json : String,
) -> Bool {
  session.patch_edge_options_json(edge_id, patch_json)
}

///|
pub fn ffi_browser_demo_session_remove(
  session : BrowserDemoSession,
  cell_id : Int,
  when? : Int = 0,
) -> Array[Int] {
  session.remove(cell_id, when~)
}

///|
pub fn ffi_browser_demo_session_flush(session : BrowserDemoSession, when : Int) -> Bool {
  session.flush(when)
}

///|
pub fn ffi_browser_demo_session_apply_mutation_batch_demo_json() -> String {
  let session = BrowserDemoSession::new()
  let source_id = session.add_vertex("A", 0, 0)
  let target_id = session.add_vertex("B", 1, 0)
  let edge_id = session.add_edge(source_id, target_id, label="f")
  let batch = @engine.QuiverUiMutationBatch::new(
    [@engine.QuiverUiSetLabelPatch::new(source_id, "A-demo")],
    [
      @engine.QuiverUiSetLabelColourPatch::new(
        source_id,
        @engine.Colour::new(210, 80, 40, 1.0),
      ),
    ],
    [@engine.QuiverUiMoveVertexPatch::new(source_id, 4, 5)],
    [
      @engine.QuiverUiSetEdgeOptionsPatch::new(
        edge_id,
        @engine.EdgeOptions::default()
          .with_label_alignment_right()
          .with_label_position(70)
          .with_curve(-2),
      ),
    ],
    [@engine.QuiverUiReconnectEdgePatch::new(edge_id, target_id, source_id)],
  )
  session.apply_mutation_batch(batch).to_json_string()
}

///|
pub fn ffi_browser_demo_session_apply_mutation_batch_json(
  session : BrowserDemoSession,
  batch_json : String,
) -> String {
  session.apply_mutation_batch_json(batch_json).to_json_string()
}

///|
pub fn ffi_browser_demo_session_set_selection(
  session : BrowserDemoSession,
  selected_ids : Array[Int],
) -> Array[Int] {
  session.apply_selection(selected_ids)
}

///|
pub fn ffi_browser_demo_session_export_selection(
  session : BrowserDemoSession,
  include_dependencies? : Bool = true,
) -> String {
  session.export_selection(include_dependencies~)
}

///|
pub fn ffi_browser_demo_session_paste_selection(
  session : BrowserDemoSession,
  payload : String,
  origin_x : Int,
  origin_y : Int,
  start_id? : Int = 1,
) -> Array[Int] {
  session.paste_selection(payload, origin_x, origin_y, start_id~)
}

///|
pub fn ffi_browser_demo_session_paste_selection_result_json(
  session : BrowserDemoSession,
  payload : String,
  origin_x : Int,
  origin_y : Int,
  start_id? : Int = 1,
) -> String {
  session.paste_selection_result(payload, origin_x, origin_y, start_id~)
    .to_json_string()
}

///|
pub fn ffi_browser_demo_session_import_payload(
  session : BrowserDemoSession,
  payload : String,
) -> Bool {
  session.import_payload(payload)
}

///|
pub fn ffi_browser_demo_session_reset(session : BrowserDemoSession) -> Unit {
  session.reset()
}

///|
pub fn ffi_browser_demo_session_all_cells(
  session : BrowserDemoSession,
) -> Array[@engine.CellData] {
  session.all_cells()
}

///|
pub fn ffi_browser_demo_session_all_cells_json(
  session : BrowserDemoSession,
) -> String {
  session.all_cells_json()
}

///|
pub fn ffi_browser_demo_session_all_cell_ids(
  session : BrowserDemoSession,
) -> Array[Int] {
  session.all_cell_ids()
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
pub fn ffi_browser_demo_session_render_tikz_result_json(
  session : BrowserDemoSession,
) -> String {
  session.render_tikz_result_json()
}

///|
pub fn ffi_browser_demo_session_render_tikz_result_with_input_json(
  session : BrowserDemoSession,
  input_json : String,
) -> String {
  session.render_tikz_result_with_input(input_json).to_json_string()
}

///|
pub fn ffi_browser_demo_session_render_fletcher(session : BrowserDemoSession) -> String {
  session.render_fletcher()
}

///|
pub fn ffi_browser_demo_session_render_fletcher_with_input(
  session : BrowserDemoSession,
  input_json : String,
) -> String {
  session.render_fletcher_with_input(input_json)
}

///|
pub fn ffi_browser_demo_session_render_html_embed(session : BrowserDemoSession) -> String {
  session.render_html_embed()
}

///|
pub fn ffi_browser_demo_session_render_html_embed_with_input(
  session : BrowserDemoSession,
  input_json : String,
) -> String {
  session.render_html_embed_with_input(input_json)
}

///|
pub fn ffi_browser_demo_session_import_text_auto(
  session : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> Bool {
  session.import_text_auto(input, default_renderer~)
}

///|
pub fn ffi_browser_demo_session_import_text_auto_result_json(
  session : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> String {
  session.import_text_auto_result(input, default_renderer~).to_json_string()
}

///|
pub fn ffi_browser_demo_session_import_share_url(
  session : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> Bool {
  session.import_share_url(input, default_renderer~)
}

///|
pub fn ffi_browser_demo_session_import_share_url_result_json(
  session : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> String {
  session.import_share_url_result(input, default_renderer~).to_json_string()
}

///|
pub fn ffi_browser_demo_session_import_tikz_cd(
  session : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> Bool {
  session.import_tikz_cd(input, default_renderer~)
}

///|
pub fn ffi_browser_demo_session_import_tikz_cd_result_json(
  session : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> String {
  session.import_tikz_cd_result(input, default_renderer~).to_json_string()
}

///|
pub fn ffi_browser_demo_session_import_fletcher(
  session : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> Bool {
  session.import_fletcher(input, default_renderer~)
}

///|
pub fn ffi_browser_demo_session_import_fletcher_result_json(
  session : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> String {
  session.import_fletcher_result(input, default_renderer~).to_json_string()
}

///|
pub fn ffi_browser_demo_session_import_html_embed(
  session : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> Bool {
  session.import_html_embed(input, default_renderer~)
}

///|
pub fn ffi_browser_demo_session_import_html_embed_result_json(
  session : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> String {
  session.import_html_embed_result(input, default_renderer~).to_json_string()
}

///|
pub fn ffi_browser_demo_session_import_share_text(
  session : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> Bool {
  session.import_share_text(input, default_renderer~)
}

///|
pub fn ffi_browser_demo_session_import_share_text_result_json(
  session : BrowserDemoSession,
  input : String,
  default_renderer? : String = "canvas",
) -> String {
  session.import_share_text_result(input, default_renderer~).to_json_string()
}

///|
pub fn ffi_browser_demo_session_dependencies_of(
  session : BrowserDemoSession,
  cell_id : Int,
) -> Array[Int] {
  session.dependencies_of(cell_id)
}

///|
pub fn ffi_browser_demo_session_reverse_dependencies_of(
  session : BrowserDemoSession,
  cell_id : Int,
) -> Array[Int] {
  session.reverse_dependencies_of(cell_id)
}

///|
pub fn ffi_browser_demo_session_transitive_dependencies(
  session : BrowserDemoSession,
  roots : Array[Int],
  exclude_roots? : Bool = false,
) -> Array[Int] {
  session.transitive_dependencies(roots, exclude_roots~)
}

///|
pub fn ffi_browser_demo_session_transitive_reverse_dependencies(
  session : BrowserDemoSession,
  roots : Array[Int],
) -> Array[Int] {
  session.transitive_reverse_dependencies(roots)
}

///|
pub fn ffi_browser_demo_session_connected_components(
  session : BrowserDemoSession,
  roots : Array[Int],
) -> Array[Int] {
  session.connected_components(roots)
}

///|
pub fn ffi_browser_demo_session_snapshot_json(session : BrowserDemoSession) -> String {
  session.snapshot_json()
}

///|
pub fn ffi_browser_demo_session_state_json(session : BrowserDemoSession) -> String {
  session.state_json()
}

///|
pub fn ffi_browser_demo_roundtrip_demo_json() -> String {
  browser_demo_roundtrip_demo_json()
}
