///|
fn browser_contains_id(ids : Array[Int], target : Int) -> Bool {
  for id in ids {
    if id == target {
      return true
    }
  }
  false
}

///|
fn browser_json_required_field(root : Map[String, Json], key : String) -> Json {
  match root.get(key) {
    Some(value) => value
    None => abort("missing runtime json field: " + key)
  }
}

///|
fn browser_parse_added_id(result_json : String) -> Int raise {
  let root : Map[String, Json] = @json.from_json(@json.parse(result_json))
  @json.from_json(browser_json_required_field(root, "id"))
}

///|
fn browser_parse_removed_ids(result_json : String) -> Array[Int] raise {
  let root : Map[String, Json] = @json.from_json(@json.parse(result_json))
  @json.from_json(browser_json_required_field(root, "removed_ids"))
}

///|
fn browser_int_array_json_string(values : Array[Int]) -> String {
  browser_int_array_json(values).stringify()
}

///|
fn browser_int_array_json(values : Array[Int]) -> Json {
  let out : Array[Json] = []
  for value in values {
    out.push(Json::number(value.to_double()))
  }
  Json::array(out)
}

///|
fn browser_runtime_dispatch_action_name(root : Map[String, Json]) -> String raise {
  match root.get("action") {
    Some(action_json) => @json.from_json(action_json)
    None =>
      match root.get("type") {
        Some(action_json) => @json.from_json(action_json)
        None => abort("missing runtime dispatch action")
      }
  }
}

///|
fn browser_runtime_dispatch_input_json(root : Map[String, Json]) -> String {
  match root.get("input") {
    Some(input) => input.stringify()
    None => "{}"
  }
}

///|
fn browser_runtime_dispatch_optional_string(
  root : Map[String, Json],
  key : String,
) -> String? {
  match root.get(key) {
    Some(Json::String(value)) => Some(value)
    _ => None
  }
}

///|
fn browser_runtime_dispatch_optional_bool(
  root : Map[String, Json],
  key : String,
) -> Bool? {
  match root.get(key) {
    Some(Json::True) => Some(true)
    Some(Json::False) => Some(false)
    _ => None
  }
}

///|
fn browser_runtime_dispatch_raw_input(root : Map[String, Json]) -> String {
  match root.get("input") {
    Some(Json::String(value)) => value
    Some(value) => value.stringify()
    None => ""
  }
}

///|
fn browser_runtime_dispatch_input_object(
  root : Map[String, Json],
) -> Map[String, Json] raise {
  @json.from_json(browser_json_required_field(root, "input"))
}

///|
fn browser_runtime_dispatch_input_object_or_empty(
  root : Map[String, Json],
) -> Map[String, Json] {
  match root.get("input") {
    Some(Json::Object(input)) => input
    _ => Map::new()
  }
}

///|
fn browser_runtime_dispatch_bool_from_object(
  input : Map[String, Json],
  key : String,
  default_value : Bool,
) -> Bool {
  match browser_runtime_dispatch_optional_bool(input, key) {
    Some(value) => value
    None => default_value
  }
}

///|
fn browser_runtime_dispatch_optional_int(
  input : Map[String, Json],
  key : String,
) -> Int? raise {
  match input.get(key) {
    Some(Json::Null) => None
    Some(value) => Some(@json.from_json(value))
    None => None
  }
}

///|
fn browser_runtime_dispatch_optional_double(
  input : Map[String, Json],
  key : String,
) -> Double? raise {
  match input.get(key) {
    Some(Json::Null) => None
    Some(value) => Some(@json.from_json(value))
    None => None
  }
}

///|
fn browser_runtime_dispatch_payload_input(root : Map[String, Json]) -> String raise {
  match root.get("input") {
    Some(Json::String(payload)) => payload
    Some(Json::Object(input)) =>
      @json.from_json(browser_json_required_field(input, "payload"))
    Some(value) => @json.from_json(value)
    None => abort("missing payload input")
  }
}

///|
fn browser_runtime_dispatch_action_json_string(action : Json) -> String {
  match action {
    Json::String(raw_action_json) => raw_action_json
    _ => action.stringify()
  }
}

///|
fn browser_runtime_dispatch_many_input(
  batch_json : String,
) -> (Array[Json], Bool) raise {
  let root = @json.parse(batch_json)
  match root {
    Json::Array(actions) => (actions, false)
    Json::Object(config) => {
      let actions : Array[Json] = @json.from_json(
        browser_json_required_field(config, "actions"),
      )
      let stop_on_error = browser_runtime_dispatch_bool_from_object(
        config,
        "stop_on_error",
        false,
      )
      (actions, stop_on_error)
    }
    _ => abort("dispatch_many_json expects array or object with actions")
  }
}

///|
fn browser_runtime_dispatch_result_ok(result : Json) -> Bool {
  match result {
    Json::Object(root) =>
      match root.get("ok") {
        Some(Json::True) => true
        _ => false
      }
    _ => false
  }
}

///|
fn browser_runtime_dispatch_action_hint(action_json : String) -> String {
  let parsed : Result[Json, Error] = try? @json.parse(action_json)
  match parsed {
    Ok(Json::Object(root)) =>
      match root.get("action") {
        Some(Json::String(action)) => action
        _ =>
          match root.get("type") {
            Some(Json::String(action)) => action
            _ => "unknown"
          }
      }
    _ => "unknown"
  }
}

///|
fn browser_runtime_dispatch_safe_error_json(
  action : String,
  error : String,
  payload : String,
  selection : Array[Int],
) -> String {
  Json::object({
    "ok": Json::boolean(false),
    "action": Json::string(action),
    "result": Json::null(),
    "payload": Json::string(payload),
    "selection": browser_int_array_json(selection),
    "error": Json::string(error),
  }).stringify()
}

///|
fn browser_runtime_dispatch_many_safe_error_json(
  error : String,
  payload : String,
  selection : Array[Int],
) -> String {
  Json::object({
    "ok": Json::boolean(false),
    "processed": Json::number(0.0),
    "results": Json::array([]),
    "payload": Json::string(payload),
    "selection": browser_int_array_json(selection),
    "error": Json::string(error),
  }).stringify()
}

///|
fn browser_runtime_dispatch_optional_object(
  root : Map[String, Json],
  key : String,
) -> Map[String, Json]? {
  match root.get(key) {
    Some(Json::Object(value)) => Some(value)
    _ => None
  }
}

///|
fn browser_runtime_dispatch_object_field_or_self(
  input : Map[String, Json],
  key : String,
) -> Map[String, Json] {
  match browser_runtime_dispatch_optional_object(input, key) {
    Some(value) => value
    None => input
  }
}

///|
fn browser_runtime_dispatch_colour_from_json(raw : Json) -> @engine.Colour raise {
  let root : Map[String, Json] = @json.from_json(raw)
  let h : Int = @json.from_json(browser_json_required_field(root, "h"))
  let s : Int = @json.from_json(browser_json_required_field(root, "s"))
  let l : Int = @json.from_json(browser_json_required_field(root, "l"))
  let a : Double = @json.from_json(browser_json_required_field(root, "a"))
  @engine.Colour::new(h, s, l, a)
}

///|
fn browser_runtime_dispatch_tikz_settings_from_input(
  input : Map[String, Json],
) -> @engine.TikzCdExportSettings {
  let settings_input = browser_runtime_dispatch_object_field_or_self(
    input,
    "settings",
  )
  let defaults = @engine.TikzCdExportSettings::default()
  defaults
    .with_centre_diagram(
      value=
      browser_runtime_dispatch_bool_from_object(
        settings_input,
        "centre_diagram",
        defaults.centre_diagram,
      ),
    )
    .with_ampersand_replacement(
      value=
      browser_runtime_dispatch_bool_from_object(
        settings_input,
        "ampersand_replacement",
        defaults.ampersand_replacement,
      ),
    )
    .with_cramped(
      value=
      browser_runtime_dispatch_bool_from_object(
        settings_input,
        "cramped",
        defaults.cramped,
      ),
    )
    .with_standalone(
      value=
      browser_runtime_dispatch_bool_from_object(
        settings_input,
        "standalone",
        defaults.standalone,
      ),
    )
}

///|
fn browser_runtime_dispatch_tikz_options_from_input(
  input : Map[String, Json],
) -> @engine.TikzCdExportOptions raise {
  let options_input = browser_runtime_dispatch_object_field_or_self(input, "options")
  let mut options = @engine.TikzCdExportOptions::default()

  match browser_runtime_dispatch_optional_string(options_input, "share_base_url") {
    Some(value) => options = options.with_share_base_url(value)
    None => ()
  }
  match browser_runtime_dispatch_optional_string(options_input, "macro_url") {
    Some(value) => options = options.with_macro_url(value)
    None => ()
  }
  match browser_runtime_dispatch_optional_string(options_input, "renderer") {
    Some(value) => options = options.with_renderer(value)
    None => ()
  }

  match options_input.get("sep") {
    Some(Json::Number(value, ..)) => options = options.with_sep_em(value)
    Some(Json::Object(sep_input)) => {
      let mut sep = @engine.TikzCdSepOptions::default()
      let mut has_sep_override = false

      match browser_runtime_dispatch_optional_double(sep_input, "em") {
        Some(value) => {
          sep = sep.with_em(value)
          has_sep_override = true
        }
        None => ()
      }
      match browser_runtime_dispatch_optional_int(sep_input, "column_hundredths") {
        Some(value) => {
          sep = sep.with_column_em(value.to_double() / 100.0)
          has_sep_override = true
        }
        None => ()
      }
      match browser_runtime_dispatch_optional_int(sep_input, "row_hundredths") {
        Some(value) => {
          sep = sep.with_row_em(value.to_double() / 100.0)
          has_sep_override = true
        }
        None => ()
      }
      match browser_runtime_dispatch_optional_double(sep_input, "column_em") {
        Some(value) => {
          sep = sep.with_column_em(value)
          has_sep_override = true
        }
        None => ()
      }
      match browser_runtime_dispatch_optional_double(sep_input, "row_em") {
        Some(value) => {
          sep = sep.with_row_em(value)
          has_sep_override = true
        }
        None => ()
      }

      if has_sep_override {
        options = options.with_sep(sep)
      }
    }
    _ => ()
  }

  match browser_runtime_dispatch_optional_double(options_input, "sep_em") {
    Some(value) => options = options.with_sep_em(value)
    None => ()
  }
  match browser_runtime_dispatch_optional_double(options_input, "column_sep_em") {
    Some(value) => options = options.with_column_sep_em(value)
    None => ()
  }
  match browser_runtime_dispatch_optional_double(options_input, "row_sep_em") {
    Some(value) => options = options.with_row_sep_em(value)
    None => ()
  }

  options
}

///|
fn browser_runtime_dispatch_tikz_definitions_from_input(
  input : Map[String, Json],
) -> @engine.TikzCdExportDefinitions raise {
  let mut definitions = @engine.TikzCdExportDefinitions::default()
  let definitions_input = match browser_runtime_dispatch_optional_object(
    input,
    "definitions",
  ) {
    Some(value) => value
    None => return definitions
  }
  let colours_input = match browser_runtime_dispatch_optional_object(
    definitions_input,
    "colours",
  ) {
    Some(value) => value
    None => return definitions
  }

  let colour_names : Array[String] = []
  colours_input.each((name, _) => colour_names.push(name))
  colour_names.sort()
  for name in colour_names {
    match colours_input.get(name) {
      Some(value) =>
        definitions = definitions.with_colour(
          name,
          browser_runtime_dispatch_colour_from_json(value),
        )
      None => ()
    }
  }
  definitions
}

///|
fn browser_runtime_dispatch_fletcher_settings_from_input(
  input : Map[String, Json],
) -> @engine.FletcherExportSettings {
  let settings_input = browser_runtime_dispatch_object_field_or_self(
    input,
    "settings",
  )
  let defaults = @engine.FletcherExportSettings::default()
  defaults.with_centre_diagram(
    value=
    browser_runtime_dispatch_bool_from_object(
      settings_input,
      "centre_diagram",
      defaults.centre_diagram,
    ),
  )
}

///|
fn browser_runtime_dispatch_fletcher_options_from_input(
  input : Map[String, Json],
) -> @engine.FletcherExportOptions {
  let options_input = browser_runtime_dispatch_object_field_or_self(input, "options")
  let mut options = @engine.FletcherExportOptions::default()

  match browser_runtime_dispatch_optional_string(options_input, "share_base_url") {
    Some(value) => options = options.with_share_base_url(value)
    None => ()
  }
  match browser_runtime_dispatch_optional_string(options_input, "macro_url") {
    Some(value) => options = options.with_macro_url(value)
    None => ()
  }
  match browser_runtime_dispatch_optional_string(options_input, "renderer") {
    Some(value) => options = options.with_renderer(value)
    None => ()
  }

  options
}

///|
fn browser_runtime_dispatch_html_options_from_input(
  input : Map[String, Json],
) -> @engine.HtmlEmbedExportOptions {
  let options_input = browser_runtime_dispatch_object_field_or_self(input, "options")
  let mut options = @engine.HtmlEmbedExportOptions::default()

  match browser_runtime_dispatch_optional_string(options_input, "share_base_url") {
    Some(value) => options = options.with_share_base_url(value)
    None => ()
  }
  match browser_runtime_dispatch_optional_string(options_input, "macro_url") {
    Some(value) => options = options.with_macro_url(value)
    None => ()
  }
  match browser_runtime_dispatch_optional_string(options_input, "renderer") {
    Some(value) => options = options.with_renderer(value)
    None => ()
  }

  options
}

///|
fn browser_runtime_dispatch_html_settings_from_input(
  input : Map[String, Json],
  options : @engine.HtmlEmbedExportOptions,
) -> @engine.HtmlEmbedExportSettings raise {
  let settings_input = browser_runtime_dispatch_object_field_or_self(
    input,
    "settings",
  )
  let base_url = match browser_runtime_dispatch_optional_string(
    settings_input,
    "base_url",
  ) {
    Some(value) => value
    None =>
      match options.share_base_url {
        Some(value) => value
        None => "https://q.uiver.app"
      }
  }

  let defaults = @engine.HtmlEmbedExportSettings::default(base_url)
  let mut settings = defaults
  let width = browser_runtime_dispatch_optional_int(settings_input, "width")
  let height = browser_runtime_dispatch_optional_int(settings_input, "height")
  let diagram_width = browser_runtime_dispatch_optional_int(
    settings_input,
    "diagram_width",
  )
  let diagram_height = browser_runtime_dispatch_optional_int(
    settings_input,
    "diagram_height",
  )
  let embed_padding = browser_runtime_dispatch_optional_int(
    settings_input,
    "embed_padding",
  )

  let use_fixed_size = match browser_runtime_dispatch_optional_bool(
    settings_input,
    "fixed_size",
  ) {
    Some(value) => value
    None =>
      match width {
        Some(_) => true
        None =>
          match height {
            Some(_) => true
            None => false
          }
      }
  }

  if use_fixed_size {
    settings = settings.with_fixed_size(
      match width {
        Some(value) => value
        None => defaults.width
      },
      match height {
        Some(value) => value
        None => defaults.height
      },
    )
  } else {
    settings = settings.with_dynamic_size(
      match diagram_width {
        Some(value) => value
        None => defaults.diagram_width
      },
      match diagram_height {
        Some(value) => value
        None => defaults.diagram_height
      },
      embed_padding=
        match embed_padding {
          Some(value) => value
          None => defaults.embed_padding
        },
    )
  }

  settings
}

///|
fn browser_runtime_label_alignment_name(
  alignment : @engine.LabelAlignment,
) -> String {
  match alignment {
    @engine.LabelAlignment::Left => "left"
    @engine.LabelAlignment::Centre => "centre"
    @engine.LabelAlignment::Right => "right"
    @engine.LabelAlignment::Over => "over"
  }
}

///|
fn browser_runtime_shape_name(shape : @engine.EdgeShape) -> String {
  match shape {
    @engine.EdgeShape::Bezier => "bezier"
    @engine.EdgeShape::Arc => "arc"
  }
}

///|
fn browser_runtime_colour_json(colour : @engine.Colour) -> Json {
  Json::object({
    "h": Json::number(colour.h.to_double()),
    "s": Json::number(colour.s.to_double()),
    "l": Json::number(colour.l.to_double()),
    "a": Json::number(colour.a),
  })
}

///|
fn browser_runtime_endpoint_style_json(style : @engine.EdgeEndpointStyle) -> Json {
  Json::object({
    "name": Json::string(style.name),
    "side": Json::string(style.side),
  })
}

///|
fn browser_runtime_style_json(style : @engine.EdgeStyle) -> Json {
  Json::object({
    "name": Json::string(style.name),
    "tail": browser_runtime_endpoint_style_json(style.tail),
    "body": browser_runtime_endpoint_style_json(style.body),
    "head": browser_runtime_endpoint_style_json(style.head),
  })
}

///|
fn browser_runtime_edge_options_json(options : @engine.EdgeOptions) -> Json {
  Json::object({
    "label_alignment": Json::string(
      browser_runtime_label_alignment_name(options.label_alignment),
    ),
    "label_position": Json::number(options.label_position.to_double()),
    "offset": Json::number(options.offset.to_double()),
    "curve": Json::number(options.curve.to_double()),
    "radius": Json::number(options.radius.to_double()),
    "angle": Json::number(options.angle.to_double()),
    "shorten_source": Json::number(options.shorten.source.to_double()),
    "shorten_target": Json::number(options.shorten.target.to_double()),
    "level": Json::number(options.level.to_double()),
    "shape": Json::string(browser_runtime_shape_name(options.shape)),
    "colour": browser_runtime_colour_json(options.colour),
    "edge_alignment_source": Json::boolean(options.edge_alignment.source),
    "edge_alignment_target": Json::boolean(options.edge_alignment.target),
    "style": browser_runtime_style_json(options.style),
  })
}

///|
fn browser_runtime_cell_data_json(cell_data : @engine.CellData) -> Json {
  match cell_data {
    @engine.CellData::Vertex(vertex) =>
      Json::object({
        "kind": Json::string("vertex"),
        "id": Json::number(vertex.cell.id.to_double()),
        "level": Json::number(vertex.cell.level.to_double()),
        "label": Json::string(vertex.cell.label),
        "label_colour": browser_runtime_colour_json(vertex.cell.label_colour),
        "x": Json::number(vertex.x.to_double()),
        "y": Json::number(vertex.y.to_double()),
      })
    @engine.CellData::Edge(edge) =>
      Json::object({
        "kind": Json::string("edge"),
        "id": Json::number(edge.cell.id.to_double()),
        "level": Json::number(edge.cell.level.to_double()),
        "label": Json::string(edge.cell.label),
        "label_colour": browser_runtime_colour_json(edge.cell.label_colour),
        "source_id": Json::number(edge.source.to_double()),
        "target_id": Json::number(edge.target.to_double()),
        "options": browser_runtime_edge_options_json(edge.options),
      })
  }
}

///|
fn browser_runtime_cell_data_array_json_string(
  cell_data : Array[@engine.CellData],
) -> String {
  let out : Array[Json] = []
  for cell in cell_data {
    out.push(browser_runtime_cell_data_json(cell))
  }
  Json::array(out).stringify()
}

///|
fn browser_runtime_edge_options_with_label_alignment(
  options : @engine.EdgeOptions,
  label_alignment : String,
) -> @engine.EdgeOptions {
  if label_alignment == "left" {
    return options.with_label_alignment_left()
  }
  if label_alignment == "centre" || label_alignment == "center" {
    return options.with_label_alignment_centre()
  }
  if label_alignment == "right" {
    return options.with_label_alignment_right()
  }
  if label_alignment == "over" {
    return options.with_label_alignment_over()
  }
  abort("invalid label_alignment in edge options patch: " + label_alignment)
}

///|
fn browser_runtime_edge_options_with_shape(
  options : @engine.EdgeOptions,
  shape : String,
) -> @engine.EdgeOptions {
  if shape == "bezier" {
    return options.with_shape_bezier()
  }
  if shape == "arc" {
    return options.with_shape_arc()
  }
  abort("invalid shape in edge options patch: " + shape)
}

///|
fn browser_runtime_patch_edge_options_from_map(
  options : @engine.EdgeOptions,
  patch : Map[String, Json],
) -> @engine.EdgeOptions raise {
  let mut out = options

  match browser_runtime_dispatch_optional_string(patch, "label_alignment") {
    Some(value) => out = browser_runtime_edge_options_with_label_alignment(out, value)
    None => ()
  }
  match browser_runtime_dispatch_optional_int(patch, "label_position") {
    Some(value) => out = out.with_label_position(value)
    None => ()
  }
  match browser_runtime_dispatch_optional_int(patch, "offset") {
    Some(value) => out = out.with_offset(value)
    None => ()
  }
  match browser_runtime_dispatch_optional_int(patch, "curve") {
    Some(value) => out = out.with_curve(value)
    None => ()
  }
  match browser_runtime_dispatch_optional_int(patch, "radius") {
    Some(value) => out = out.with_radius(value)
    None => ()
  }
  match browser_runtime_dispatch_optional_int(patch, "angle") {
    Some(value) => out = out.with_angle(value)
    None => ()
  }
  match browser_runtime_dispatch_optional_int(patch, "level") {
    Some(value) => out = out.with_level(value)
    None => ()
  }
  match browser_runtime_dispatch_optional_string(patch, "shape") {
    Some(value) => out = browser_runtime_edge_options_with_shape(out, value)
    None => ()
  }
  match browser_runtime_dispatch_optional_object(patch, "colour") {
    Some(value) =>
      out = out.with_colour(
        browser_runtime_dispatch_colour_from_json(Json::object(value)),
      )
    None => ()
  }

  match browser_runtime_dispatch_optional_object(patch, "shorten") {
    Some(value) => {
      let source = match browser_runtime_dispatch_optional_int(value, "source") {
        Some(raw) => raw
        None => out.shorten.source
      }
      let target = match browser_runtime_dispatch_optional_int(value, "target") {
        Some(raw) => raw
        None => out.shorten.target
      }
      out = out.with_shorten(source, target)
    }
    None => ()
  }
  match browser_runtime_dispatch_optional_int(patch, "shorten_source") {
    Some(value) => out = out.with_shorten(value, out.shorten.target)
    None => ()
  }
  match browser_runtime_dispatch_optional_int(patch, "shorten_target") {
    Some(value) => out = out.with_shorten(out.shorten.source, value)
    None => ()
  }

  match browser_runtime_dispatch_optional_object(patch, "edge_alignment") {
    Some(value) => {
      let source = match browser_runtime_dispatch_optional_bool(value, "source") {
        Some(raw) => raw
        None => out.edge_alignment.source
      }
      let target = match browser_runtime_dispatch_optional_bool(value, "target") {
        Some(raw) => raw
        None => out.edge_alignment.target
      }
      out = out.with_edge_alignment(source, target)
    }
    None => ()
  }
  match browser_runtime_dispatch_optional_bool(patch, "edge_alignment_source") {
    Some(value) => out = out.with_edge_alignment_source(value)
    None => ()
  }
  match browser_runtime_dispatch_optional_bool(patch, "edge_alignment_target") {
    Some(value) => out = out.with_edge_alignment_target(value)
    None => ()
  }

  match browser_runtime_dispatch_optional_string(patch, "style_name") {
    Some(value) => out = out.with_style_name(value)
    None => ()
  }
  let tail_name = browser_runtime_dispatch_optional_string(patch, "style_tail_name")
  let tail_side = browser_runtime_dispatch_optional_string(patch, "style_tail_side")
  if tail_name is Some(_) || tail_side is Some(_) {
    out = out.with_style_tail(
      match tail_name {
        Some(value) => value
        None => out.style.tail.name
      },
      side=
        match tail_side {
          Some(value) => value
          None => out.style.tail.side
        },
    )
  }
  let body_name = browser_runtime_dispatch_optional_string(patch, "style_body_name")
  let body_side = browser_runtime_dispatch_optional_string(patch, "style_body_side")
  if body_name is Some(_) || body_side is Some(_) {
    out = out.with_style_body(
      match body_name {
        Some(value) => value
        None => out.style.body.name
      },
      side=
        match body_side {
          Some(value) => value
          None => out.style.body.side
        },
    )
  }
  let head_name = browser_runtime_dispatch_optional_string(patch, "style_head_name")
  let head_side = browser_runtime_dispatch_optional_string(patch, "style_head_side")
  if head_name is Some(_) || head_side is Some(_) {
    out = out.with_style_head(
      match head_name {
        Some(value) => value
        None => out.style.head.name
      },
      side=
        match head_side {
          Some(value) => value
          None => out.style.head.side
        },
    )
  }

  match browser_runtime_dispatch_optional_object(patch, "style") {
    Some(style_patch) => {
      match browser_runtime_dispatch_optional_string(style_patch, "name") {
        Some(value) => out = out.with_style_name(value)
        None => ()
      }
      match browser_runtime_dispatch_optional_object(style_patch, "tail") {
        Some(tail_patch) => {
          let tail_name = match browser_runtime_dispatch_optional_string(
            tail_patch,
            "name",
          ) {
            Some(value) => value
            None => out.style.tail.name
          }
          let tail_side = match browser_runtime_dispatch_optional_string(
            tail_patch,
            "side",
          ) {
            Some(value) => value
            None => out.style.tail.side
          }
          out = out.with_style_tail(tail_name, side=tail_side)
        }
        None => ()
      }
      match browser_runtime_dispatch_optional_object(style_patch, "body") {
        Some(body_patch) => {
          let body_name = match browser_runtime_dispatch_optional_string(
            body_patch,
            "name",
          ) {
            Some(value) => value
            None => out.style.body.name
          }
          let body_side = match browser_runtime_dispatch_optional_string(
            body_patch,
            "side",
          ) {
            Some(value) => value
            None => out.style.body.side
          }
          out = out.with_style_body(body_name, side=body_side)
        }
        None => ()
      }
      match browser_runtime_dispatch_optional_object(style_patch, "head") {
        Some(head_patch) => {
          let head_name = match browser_runtime_dispatch_optional_string(
            head_patch,
            "name",
          ) {
            Some(value) => value
            None => out.style.head.name
          }
          let head_side = match browser_runtime_dispatch_optional_string(
            head_patch,
            "side",
          ) {
            Some(value) => value
            None => out.style.head.side
          }
          out = out.with_style_head(head_name, side=head_side)
        }
        None => ()
      }
    }
    None => ()
  }

  out
}

///|
fn browser_runtime_patch_edge_options_input_from_json(
  input_json : String,
) -> (Int, Map[String, Json]) raise {
  let root : Map[String, Json] = @json.from_json(@json.parse(input_json))
  let edge_id : Int = @json.from_json(browser_json_required_field(root, "edge_id"))

  let patch = match browser_runtime_dispatch_optional_object(root, "patch") {
    Some(value) => value
    None => root
  }
  let options_patch = match browser_runtime_dispatch_optional_object(
    patch,
    "options",
  ) {
    Some(value) => value
    None => patch
  }
  (edge_id, options_patch)
}

///|
pub struct BrowserRuntime {
  adapter : @engine.QuiverUiAdapter
  mut selected_ids : Array[Int]
}

///|
pub fn BrowserRuntime::new() -> BrowserRuntime {
  { adapter: @engine.ffi_adapter_new(), selected_ids: [] }
}

///|
pub fn BrowserRuntime::reset(self : BrowserRuntime) -> Unit {
  @engine.ffi_adapter_reset(self.adapter)
  self.selected_ids = []
}

///|
pub fn BrowserRuntime::set_selection(
  self : BrowserRuntime,
  selected_ids : Array[Int],
) -> Unit {
  self.selected_ids = selected_ids.copy()
}

///|
pub fn BrowserRuntime::selection(self : BrowserRuntime) -> Array[Int] {
  self.selected_ids.copy()
}

///|
pub fn BrowserRuntime::add_vertex(
  self : BrowserRuntime,
  label : String,
  x : Int,
  y : Int,
  label_colour? : @engine.Colour = @engine.Colour::black(),
) -> Int {
  let id = @engine.ffi_adapter_add_vertex(
    self.adapter,
    label,
    x,
    y,
    label_colour~,
  )
  self.selected_ids = [id]
  id
}

///|
pub fn BrowserRuntime::add_edge(
  self : BrowserRuntime,
  source_id : Int,
  target_id : Int,
  label? : String = "",
  options? : @engine.EdgeOptions = @engine.EdgeOptions::at_level(1),
  label_colour? : @engine.Colour = @engine.Colour::black(),
) -> Int {
  let id = @engine.ffi_adapter_add_edge(
    self.adapter,
    source_id,
    target_id,
    label~,
    options~,
    label_colour~,
  )
  self.selected_ids = [id]
  id
}

///|
pub fn BrowserRuntime::add_vertex_json(
  self : BrowserRuntime,
  input_json : String,
) -> String raise {
  let result_json = @engine.ffi_adapter_add_vertex_json(self.adapter, input_json)
  self.selected_ids = [browser_parse_added_id(result_json)]
  result_json
}

///|
pub fn BrowserRuntime::add_edge_json(
  self : BrowserRuntime,
  input_json : String,
) -> String raise {
  let result_json = @engine.ffi_adapter_add_edge_json(self.adapter, input_json)
  self.selected_ids = [browser_parse_added_id(result_json)]
  result_json
}

///|
pub fn BrowserRuntime::set_label(
  self : BrowserRuntime,
  cell_id : Int,
  label : String,
) -> Bool {
  @engine.ffi_adapter_set_cell_label(self.adapter, cell_id, label)
}

///|
pub fn BrowserRuntime::set_label_json(
  self : BrowserRuntime,
  input_json : String,
) -> String raise {
  @engine.ffi_adapter_set_cell_label_json(self.adapter, input_json)
}

///|
pub fn BrowserRuntime::set_label_colour(
  self : BrowserRuntime,
  cell_id : Int,
  label_colour : @engine.Colour,
) -> Bool {
  @engine.ffi_adapter_set_cell_label_colour(self.adapter, cell_id, label_colour)
}

///|
pub fn BrowserRuntime::set_label_colour_json(
  self : BrowserRuntime,
  input_json : String,
) -> String raise {
  @engine.ffi_adapter_set_cell_label_colour_json(self.adapter, input_json)
}

///|
pub fn BrowserRuntime::move_vertex(
  self : BrowserRuntime,
  vertex_id : Int,
  x : Int,
  y : Int,
) -> Bool {
  @engine.ffi_adapter_move_vertex(self.adapter, vertex_id, x, y)
}

///|
pub fn BrowserRuntime::move_vertex_json(
  self : BrowserRuntime,
  input_json : String,
) -> String raise {
  @engine.ffi_adapter_move_vertex_json(self.adapter, input_json)
}

///|
pub fn BrowserRuntime::set_edge_options(
  self : BrowserRuntime,
  edge_id : Int,
  options : @engine.EdgeOptions,
) -> Bool {
  @engine.ffi_adapter_set_edge_options(self.adapter, edge_id, options)
}

///|
pub fn BrowserRuntime::set_edge_options_json(
  self : BrowserRuntime,
  input_json : String,
) -> String raise {
  @engine.ffi_adapter_set_edge_options_json(self.adapter, input_json)
}

///|
pub fn BrowserRuntime::patch_edge_options(
  self : BrowserRuntime,
  edge_id : Int,
  options_patch : Map[String, Json],
) -> Bool raise {
  let mut current : @engine.Edge? = None
  for cell in self.all_cells() {
    match cell {
      @engine.CellData::Edge(edge) =>
        if edge.cell.id == edge_id {
          current = Some(edge)
        }
      _ => ()
    }
  }

  match current {
    Some(edge) => {
      let patched_options = browser_runtime_patch_edge_options_from_map(
        edge.options,
        options_patch,
      )
      self.set_edge_options(edge_id, patched_options)
    }
    None => false
  }
}

///|
pub fn BrowserRuntime::patch_edge_options_json(
  self : BrowserRuntime,
  input_json : String,
) -> String raise {
  let (edge_id, options_patch) = browser_runtime_patch_edge_options_input_from_json(
    input_json,
  )
  Json::object({
    "ok": Json::boolean(self.patch_edge_options(edge_id, options_patch)),
    "payload": Json::string(self.export_payload()),
  }).stringify()
}

///|
pub fn BrowserRuntime::set_edge_label_alignment(
  self : BrowserRuntime,
  edge_id : Int,
  label_alignment : String,
) -> Bool {
  @engine.ffi_adapter_set_edge_label_alignment(
    self.adapter,
    edge_id,
    label_alignment,
  )
}

///|
pub fn BrowserRuntime::set_edge_label_alignment_json(
  self : BrowserRuntime,
  input_json : String,
) -> String raise {
  @engine.ffi_adapter_set_edge_label_alignment_json(self.adapter, input_json)
}

///|
pub fn BrowserRuntime::set_edge_label_position(
  self : BrowserRuntime,
  edge_id : Int,
  label_position : Int,
) -> Bool {
  @engine.ffi_adapter_set_edge_label_position(
    self.adapter,
    edge_id,
    label_position,
  )
}

///|
pub fn BrowserRuntime::set_edge_label_position_json(
  self : BrowserRuntime,
  input_json : String,
) -> String raise {
  @engine.ffi_adapter_set_edge_label_position_json(self.adapter, input_json)
}

///|
pub fn BrowserRuntime::set_edge_offset(
  self : BrowserRuntime,
  edge_id : Int,
  offset : Int,
) -> Bool {
  @engine.ffi_adapter_set_edge_offset(
    self.adapter,
    edge_id,
    offset,
  )
}

///|
pub fn BrowserRuntime::set_edge_offset_json(
  self : BrowserRuntime,
  input_json : String,
) -> String raise {
  @engine.ffi_adapter_set_edge_offset_json(self.adapter, input_json)
}

///|
pub fn BrowserRuntime::set_edge_curve(
  self : BrowserRuntime,
  edge_id : Int,
  curve : Int,
) -> Bool {
  @engine.ffi_adapter_set_edge_curve(
    self.adapter,
    edge_id,
    curve,
  )
}

///|
pub fn BrowserRuntime::set_edge_curve_json(
  self : BrowserRuntime,
  input_json : String,
) -> String raise {
  @engine.ffi_adapter_set_edge_curve_json(self.adapter, input_json)
}

///|
pub fn BrowserRuntime::set_edge_shorten(
  self : BrowserRuntime,
  edge_id : Int,
  shorten_source : Int,
  shorten_target : Int,
) -> Bool {
  @engine.ffi_adapter_set_edge_shorten(
    self.adapter,
    edge_id,
    shorten_source,
    shorten_target,
  )
}

///|
pub fn BrowserRuntime::set_edge_shorten_json(
  self : BrowserRuntime,
  input_json : String,
) -> String raise {
  @engine.ffi_adapter_set_edge_shorten_json(self.adapter, input_json)
}

///|
pub fn BrowserRuntime::reconnect_edge(
  self : BrowserRuntime,
  edge_id : Int,
  source_id : Int,
  target_id : Int,
) -> Bool {
  @engine.ffi_adapter_reconnect_edge(
    self.adapter,
    edge_id,
    source_id,
    target_id,
  )
}

///|
pub fn BrowserRuntime::reconnect_edge_json(
  self : BrowserRuntime,
  input_json : String,
) -> String raise {
  @engine.ffi_adapter_reconnect_edge_json(self.adapter, input_json)
}

///|
pub fn BrowserRuntime::apply_mutation_batch(
  self : BrowserRuntime,
  batch : @engine.QuiverUiMutationBatch,
) -> @engine.QuiverUiMutationBatchResult {
  @engine.ffi_adapter_apply_mutation_batch(self.adapter, batch)
}

///|
pub fn BrowserRuntime::apply_mutation_batch_json(
  self : BrowserRuntime,
  batch_json : String,
) -> String raise {
  @engine.ffi_adapter_apply_mutation_batch_json(self.adapter, batch_json)
}

///|
pub fn BrowserRuntime::remove(
  self : BrowserRuntime,
  cell_id : Int,
  when : Int,
) -> Array[Int] {
  let removed = @engine.ffi_adapter_remove(self.adapter, cell_id, when)
  self.selected_ids.retain(id => !browser_contains_id(removed, id))
  removed
}

///|
pub fn BrowserRuntime::remove_json(
  self : BrowserRuntime,
  input_json : String,
) -> String raise {
  let result_json = @engine.ffi_adapter_remove_json(self.adapter, input_json)
  let removed_ids = browser_parse_removed_ids(result_json)
  self.selected_ids.retain(id => !browser_contains_id(removed_ids, id))
  result_json
}

///|
pub fn BrowserRuntime::flush(self : BrowserRuntime, when : Int) -> Unit {
  @engine.ffi_adapter_flush(self.adapter, when)
}

///|
pub fn BrowserRuntime::flush_json(
  self : BrowserRuntime,
  input_json : String,
) -> String raise {
  @engine.ffi_adapter_flush_json(self.adapter, input_json)
}

///|
pub fn BrowserRuntime::all_cell_ids(self : BrowserRuntime) -> Array[Int] {
  @engine.ffi_adapter_all_cell_ids(self.adapter)
}

///|
pub fn BrowserRuntime::all_cells(self : BrowserRuntime) -> Array[@engine.CellData] {
  @engine.ffi_adapter_all_cells(self.adapter)
}

///|
pub fn BrowserRuntime::snapshot(self : BrowserRuntime) -> @engine.QuiverUiSnapshot {
  @engine.ffi_adapter_snapshot(self.adapter)
}

///|
pub fn BrowserRuntime::snapshot_json(self : BrowserRuntime) -> String {
  @engine.ffi_adapter_snapshot_json(self.adapter)
}

///|
pub fn BrowserRuntime::dependencies_of(
  self : BrowserRuntime,
  cell_id : Int,
) -> Array[Int] {
  @engine.ffi_adapter_dependencies_of(self.adapter, cell_id)
}

///|
pub fn BrowserRuntime::reverse_dependencies_of(
  self : BrowserRuntime,
  cell_id : Int,
) -> Array[Int] {
  @engine.ffi_adapter_reverse_dependencies_of(self.adapter, cell_id)
}

///|
pub fn BrowserRuntime::transitive_dependencies(
  self : BrowserRuntime,
  roots : Array[Int],
  exclude_roots? : Bool = false,
) -> Array[Int] {
  @engine.ffi_adapter_transitive_dependencies(
    self.adapter,
    roots,
    exclude_roots~,
  )
}

///|
pub fn BrowserRuntime::transitive_reverse_dependencies(
  self : BrowserRuntime,
  roots : Array[Int],
) -> Array[Int] {
  @engine.ffi_adapter_transitive_reverse_dependencies(self.adapter, roots)
}

///|
pub fn BrowserRuntime::connected_components(
  self : BrowserRuntime,
  roots : Array[Int],
) -> Array[Int] {
  @engine.ffi_adapter_connected_components(self.adapter, roots)
}

///|
pub fn BrowserRuntime::export_payload(self : BrowserRuntime) -> String {
  @engine.ffi_adapter_export_base64(self.adapter)
}

///|
pub fn BrowserRuntime::export_selection(
  self : BrowserRuntime,
  include_dependencies? : Bool = true,
) -> String {
  @engine.ffi_adapter_export_base64_selection(
    self.adapter,
    self.selected_ids,
    include_dependencies~,
  )
}

///|
pub fn BrowserRuntime::render_tikz(self : BrowserRuntime) -> String {
  @engine.ffi_adapter_export_tikz_cd(self.adapter).data
}

///|
pub fn BrowserRuntime::render_tikz_json(
  self : BrowserRuntime,
  settings? : @engine.TikzCdExportSettings = @engine.TikzCdExportSettings::default(),
  options? : @engine.TikzCdExportOptions = @engine.TikzCdExportOptions::default(),
  definitions? : @engine.TikzCdExportDefinitions = @engine.TikzCdExportDefinitions::default(),
) -> String {
  @engine.ffi_adapter_export_tikz_cd_json(
    self.adapter,
    settings~,
    options~,
    definitions~,
  )
}

///|
pub fn BrowserRuntime::render_fletcher(
  self : BrowserRuntime,
  settings? : @engine.FletcherExportSettings = @engine.FletcherExportSettings::default(),
  options? : @engine.FletcherExportOptions = @engine.FletcherExportOptions::default(),
) -> String {
  @engine.ffi_adapter_export_fletcher(self.adapter, settings~, options~)
}

///|
pub fn BrowserRuntime::render_html_embed(
  self : BrowserRuntime,
  settings : @engine.HtmlEmbedExportSettings,
  options? : @engine.HtmlEmbedExportOptions = @engine.HtmlEmbedExportOptions::default(),
) -> String {
  @engine.ffi_adapter_export_html_embed(self.adapter, settings, options~)
}

///|
pub fn BrowserRuntime::import_payload(
  self : BrowserRuntime,
  payload : String,
) -> String raise {
  let normalised = @engine.ffi_adapter_import_base64(self.adapter, payload)
  self.selected_ids = []
  normalised
}

///|
pub fn BrowserRuntime::import_share_url(
  self : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> @engine.QuiverUiImportResult raise {
  let imported = @engine.ffi_adapter_import_share_url(
    self.adapter,
    input,
    default_renderer~,
  )
  self.selected_ids = []
  imported
}

///|
pub fn BrowserRuntime::import_share_url_json(
  self : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  self.import_share_url(input, default_renderer~).to_json_string()
}

///|
pub fn BrowserRuntime::import_share_text(
  self : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> @engine.QuiverUiImportResult raise {
  let imported = @engine.ffi_adapter_import_share_text(
    self.adapter,
    input,
    default_renderer~,
  )
  self.selected_ids = []
  imported
}

///|
pub fn BrowserRuntime::import_share_text_json(
  self : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  self.import_share_text(input, default_renderer~).to_json_string()
}

///|
pub fn BrowserRuntime::import_text_auto(
  self : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> @engine.QuiverUiImportResult raise {
  let imported = @engine.ffi_adapter_import_text_auto(
    self.adapter,
    input,
    default_renderer~,
  )
  self.selected_ids = []
  imported
}

///|
pub fn BrowserRuntime::import_text_auto_json(
  self : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  self.import_text_auto(input, default_renderer~).to_json_string()
}

///|
pub fn BrowserRuntime::import_tikz_cd(
  self : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> @engine.QuiverUiImportResult raise {
  let imported = @engine.ffi_adapter_import_tikz_cd(
    self.adapter,
    input,
    default_renderer~,
  )
  self.selected_ids = []
  imported
}

///|
pub fn BrowserRuntime::import_tikz_cd_json(
  self : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  self.import_tikz_cd(input, default_renderer~).to_json_string()
}

///|
pub fn BrowserRuntime::import_fletcher(
  self : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> @engine.QuiverUiImportResult raise {
  let imported = @engine.ffi_adapter_import_fletcher(
    self.adapter,
    input,
    default_renderer~,
  )
  self.selected_ids = []
  imported
}

///|
pub fn BrowserRuntime::import_fletcher_json(
  self : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  self.import_fletcher(input, default_renderer~).to_json_string()
}

///|
pub fn BrowserRuntime::import_html_embed(
  self : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> @engine.QuiverUiImportResult raise {
  let imported = @engine.ffi_adapter_import_html_embed(
    self.adapter,
    input,
    default_renderer~,
  )
  self.selected_ids = []
  imported
}

///|
pub fn BrowserRuntime::import_html_embed_json(
  self : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  self.import_html_embed(input, default_renderer~).to_json_string()
}

///|
pub fn BrowserRuntime::paste_selection(
  self : BrowserRuntime,
  payload : String,
  origin_x : Int,
  origin_y : Int,
  start_id? : Int = 1,
) -> @engine.QuiverUiSelectionImportResult raise {
  let imported = @engine.ffi_adapter_paste_base64_selection(
    self.adapter,
    payload,
    origin_x,
    origin_y,
    start_id~,
  )
  self.selected_ids = imported.imported_ids.copy()
  imported
}

///|
pub fn BrowserRuntime::paste_selection_json(
  self : BrowserRuntime,
  payload : String,
  origin_x : Int,
  origin_y : Int,
  start_id? : Int = 1,
) -> String raise {
  self.paste_selection(payload, origin_x, origin_y, start_id~).to_json_string()
}

///|
pub fn BrowserRuntime::dispatch_json(
  self : BrowserRuntime,
  action_json : String,
) -> String raise {
  let root : Map[String, Json] = @json.from_json(@json.parse(action_json))
  let action = browser_runtime_dispatch_action_name(root)
  let input_json = browser_runtime_dispatch_input_json(root)

  let mut ok = true
  let mut result : Json = Json::null()
  let mut error : String? = None

  match action {
    "add_vertex_json" => result = @json.parse(self.add_vertex_json(input_json))
    "add_edge_json" => result = @json.parse(self.add_edge_json(input_json))
    "set_label_json" => result = @json.parse(self.set_label_json(input_json))
    "set_label_colour_json" =>
      result = @json.parse(self.set_label_colour_json(input_json))
    "move_vertex_json" => result = @json.parse(self.move_vertex_json(input_json))
    "set_edge_options_json" =>
      result = @json.parse(self.set_edge_options_json(input_json))
    "patch_edge_options_json" =>
      result = @json.parse(self.patch_edge_options_json(input_json))
    "set_edge_label_alignment_json" =>
      result = @json.parse(self.set_edge_label_alignment_json(input_json))
    "set_edge_label_position_json" =>
      result = @json.parse(self.set_edge_label_position_json(input_json))
    "set_edge_offset_json" =>
      result = @json.parse(self.set_edge_offset_json(input_json))
    "set_edge_curve_json" =>
      result = @json.parse(self.set_edge_curve_json(input_json))
    "set_edge_shorten_json" =>
      result = @json.parse(self.set_edge_shorten_json(input_json))
    "reconnect_edge_json" =>
      result = @json.parse(self.reconnect_edge_json(input_json))
    "remove_json" => result = @json.parse(self.remove_json(input_json))
    "flush_json" => result = @json.parse(self.flush_json(input_json))
    "reset" => {
      self.reset()
      result = Json::object({})
    }
    "apply_mutation_batch_json" =>
      result = @json.parse(self.apply_mutation_batch_json(input_json))
    "import_payload" => {
      let payload = browser_runtime_dispatch_payload_input(root)
      result = Json::string(self.import_payload(payload))
    }
    "import_text_auto_json" => {
      let raw_input = browser_runtime_dispatch_raw_input(root)
      let default_renderer = match
        browser_runtime_dispatch_optional_string(root, "default_renderer") {
        Some(value) => value
        None => "canvas"
      }
      result = @json.parse(self.import_text_auto_json(raw_input, default_renderer~))
    }
    "import_share_url_json" => {
      let raw_input = browser_runtime_dispatch_raw_input(root)
      let default_renderer = match
        browser_runtime_dispatch_optional_string(root, "default_renderer") {
        Some(value) => value
        None => "canvas"
      }
      result = @json.parse(self.import_share_url_json(raw_input, default_renderer~))
    }
    "import_share_text_json" => {
      let raw_input = browser_runtime_dispatch_raw_input(root)
      let default_renderer = match
        browser_runtime_dispatch_optional_string(root, "default_renderer") {
        Some(value) => value
        None => "canvas"
      }
      result = @json.parse(self.import_share_text_json(raw_input, default_renderer~))
    }
    "import_tikz_cd_json" => {
      let raw_input = browser_runtime_dispatch_raw_input(root)
      let default_renderer = match
        browser_runtime_dispatch_optional_string(root, "default_renderer") {
        Some(value) => value
        None => "canvas"
      }
      result = @json.parse(self.import_tikz_cd_json(raw_input, default_renderer~))
    }
    "import_fletcher_json" => {
      let raw_input = browser_runtime_dispatch_raw_input(root)
      let default_renderer = match
        browser_runtime_dispatch_optional_string(root, "default_renderer") {
        Some(value) => value
        None => "canvas"
      }
      result = @json.parse(self.import_fletcher_json(raw_input, default_renderer~))
    }
    "import_html_embed_json" => {
      let raw_input = browser_runtime_dispatch_raw_input(root)
      let default_renderer = match
        browser_runtime_dispatch_optional_string(root, "default_renderer") {
        Some(value) => value
        None => "canvas"
      }
      result = @json.parse(self.import_html_embed_json(raw_input, default_renderer~))
    }
    "paste_selection_json" => {
      let input : Map[String, Json] = @json.from_json(
        browser_json_required_field(root, "input"),
      )
      let payload : String = @json.from_json(
        browser_json_required_field(input, "payload"),
      )
      let origin_x : Int = @json.from_json(
        browser_json_required_field(input, "origin_x"),
      )
      let origin_y : Int = @json.from_json(
        browser_json_required_field(input, "origin_y"),
      )
      let start_id : Int = match input.get("start_id") {
        Some(value) => @json.from_json(value)
        None => 1
      }
      result = @json.parse(
        self.paste_selection_json(payload, origin_x, origin_y, start_id~),
      )
    }
    "set_selection" => {
      let selected_ids : Array[Int] = match root.get("input") {
        Some(value) => @json.from_json(value)
        None => []
      }
      self.set_selection(selected_ids)
      result = browser_int_array_json(self.selection())
    }
    "selection" => result = browser_int_array_json(self.selection())
    "snapshot_json" => result = @json.parse(self.snapshot_json())
    "all_cells_json" => result = @json.parse(browser_runtime_cell_data_array_json_string(self.all_cells()))
    "all_cell_ids_json" => result = @json.parse(browser_int_array_json_string(self.all_cell_ids()))
    "dependencies_of_json" => {
      let input = browser_runtime_dispatch_input_object(root)
      let cell_id : Int = @json.from_json(
        browser_json_required_field(input, "cell_id"),
      )
      result = browser_int_array_json(self.dependencies_of(cell_id))
    }
    "reverse_dependencies_of_json" => {
      let input = browser_runtime_dispatch_input_object(root)
      let cell_id : Int = @json.from_json(
        browser_json_required_field(input, "cell_id"),
      )
      result = browser_int_array_json(self.reverse_dependencies_of(cell_id))
    }
    "transitive_dependencies_json" => {
      let input = browser_runtime_dispatch_input_object(root)
      let roots : Array[Int] = @json.from_json(
        browser_json_required_field(input, "roots"),
      )
      let exclude_roots = browser_runtime_dispatch_bool_from_object(
        input,
        "exclude_roots",
        false,
      )
      result = browser_int_array_json(
        self.transitive_dependencies(roots, exclude_roots~),
      )
    }
    "transitive_reverse_dependencies_json" => {
      let input = browser_runtime_dispatch_input_object(root)
      let roots : Array[Int] = @json.from_json(
        browser_json_required_field(input, "roots"),
      )
      result = browser_int_array_json(self.transitive_reverse_dependencies(roots))
    }
    "connected_components_json" => {
      let input = browser_runtime_dispatch_input_object(root)
      let roots : Array[Int] = @json.from_json(
        browser_json_required_field(input, "roots"),
      )
      result = browser_int_array_json(self.connected_components(roots))
    }
    "render_tikz_json" => {
      let input = browser_runtime_dispatch_input_object_or_empty(root)
      let settings = browser_runtime_dispatch_tikz_settings_from_input(input)
      let options = browser_runtime_dispatch_tikz_options_from_input(input)
      let definitions = browser_runtime_dispatch_tikz_definitions_from_input(input)
      result = @json.parse(self.render_tikz_json(settings~, options~, definitions~))
    }
    "render_fletcher" => {
      let input = browser_runtime_dispatch_input_object_or_empty(root)
      let settings = browser_runtime_dispatch_fletcher_settings_from_input(input)
      let options = browser_runtime_dispatch_fletcher_options_from_input(input)
      result = Json::string(self.render_fletcher(settings~, options~))
    }
    "render_html_embed" => {
      let input = browser_runtime_dispatch_input_object_or_empty(root)
      let options = browser_runtime_dispatch_html_options_from_input(input)
      let settings = browser_runtime_dispatch_html_settings_from_input(
        input,
        options,
      )
      result = Json::string(self.render_html_embed(settings, options~))
    }
    "render_tikz" => result = Json::string(self.render_tikz())
    "export_payload" => result = Json::string(self.export_payload())
    "export_selection" => {
      let input = browser_runtime_dispatch_input_object_or_empty(root)
      let include_dependencies = match browser_runtime_dispatch_optional_bool(
        input,
        "include_dependencies",
      ) {
        Some(value) => value
        None =>
          match browser_runtime_dispatch_optional_bool(
            root,
            "include_dependencies",
          ) {
            Some(value) => value
            None => true
          }
      }
      result = Json::string(self.export_selection(include_dependencies~))
    }
    _ => {
      ok = false
      error = Some(["unknown runtime dispatch action: ", action].join(""))
    }
  }

  Json::object({
    "ok": Json::boolean(ok),
    "action": Json::string(action),
    "result": result,
    "payload": Json::string(self.export_payload()),
    "selection": browser_int_array_json(self.selection()),
    "error": match error {
      Some(message) => Json::string(message)
      None => Json::null()
    },
  }).stringify()
}

///|
pub fn BrowserRuntime::dispatch_many_json(
  self : BrowserRuntime,
  batch_json : String,
) -> String raise {
  let (actions, stop_on_error) = browser_runtime_dispatch_many_input(batch_json)
  let results : Array[Json] = []
  let mut ok = true
  let mut processed = 0

  for action in actions {
    let result_json = self.dispatch_json(
      browser_runtime_dispatch_action_json_string(action),
    )
    let result = @json.parse(result_json)
    let result_ok = browser_runtime_dispatch_result_ok(result)
    if !result_ok {
      ok = false
    }
    results.push(result)
    processed = processed + 1
    if stop_on_error && !result_ok {
      break
    }
  }

  Json::object({
    "ok": Json::boolean(ok),
    "processed": Json::number(processed.to_double()),
    "results": Json::array(results),
    "payload": Json::string(self.export_payload()),
    "selection": browser_int_array_json(self.selection()),
    "error": Json::null(),
  }).stringify()
}

///|
pub fn BrowserRuntime::dispatch_json_safe(
  self : BrowserRuntime,
  action_json : String,
) -> String {
  let dispatched : Result[String, Error] = try? self.dispatch_json(action_json)
  match dispatched {
    Ok(result) => result
    Err(error) =>
      browser_runtime_dispatch_safe_error_json(
        browser_runtime_dispatch_action_hint(action_json),
        error.to_string(),
        self.export_payload(),
        self.selection(),
      )
  }
}

///|
pub fn BrowserRuntime::dispatch_many_json_safe(
  self : BrowserRuntime,
  batch_json : String,
) -> String {
  let dispatched : Result[String, Error] = try? self.dispatch_many_json(batch_json)
  match dispatched {
    Ok(result) => result
    Err(error) =>
      browser_runtime_dispatch_many_safe_error_json(
        error.to_string(),
        self.export_payload(),
        self.selection(),
      )
  }
}

///|
pub fn ffi_browser_runtime_new() -> BrowserRuntime {
  BrowserRuntime::new()
}

///|
pub fn ffi_browser_runtime_reset(runtime : BrowserRuntime) -> Unit {
  runtime.reset()
}

///|
pub fn ffi_browser_runtime_set_selection(
  runtime : BrowserRuntime,
  selected_ids : Array[Int],
) -> Unit {
  runtime.set_selection(selected_ids)
}

///|
pub fn ffi_browser_runtime_selection(runtime : BrowserRuntime) -> Array[Int] {
  runtime.selection()
}

///|
pub fn ffi_browser_runtime_all_cell_ids(runtime : BrowserRuntime) -> Array[Int] {
  runtime.all_cell_ids()
}

///|
pub fn ffi_browser_runtime_all_cells(
  runtime : BrowserRuntime,
) -> Array[@engine.CellData] {
  runtime.all_cells()
}

///|
pub fn ffi_browser_runtime_all_cells_json(runtime : BrowserRuntime) -> String {
  browser_runtime_cell_data_array_json_string(runtime.all_cells())
}

///|
pub fn ffi_browser_runtime_all_cell_ids_json(runtime : BrowserRuntime) -> String {
  browser_int_array_json_string(runtime.all_cell_ids())
}

///|
pub fn ffi_browser_runtime_dependencies_of(
  runtime : BrowserRuntime,
  cell_id : Int,
) -> Array[Int] {
  runtime.dependencies_of(cell_id)
}

///|
pub fn ffi_browser_runtime_dependencies_of_json(
  runtime : BrowserRuntime,
  cell_id : Int,
) -> String {
  browser_int_array_json_string(runtime.dependencies_of(cell_id))
}

///|
pub fn ffi_browser_runtime_reverse_dependencies_of(
  runtime : BrowserRuntime,
  cell_id : Int,
) -> Array[Int] {
  runtime.reverse_dependencies_of(cell_id)
}

///|
pub fn ffi_browser_runtime_reverse_dependencies_of_json(
  runtime : BrowserRuntime,
  cell_id : Int,
) -> String {
  browser_int_array_json_string(runtime.reverse_dependencies_of(cell_id))
}

///|
pub fn ffi_browser_runtime_transitive_dependencies(
  runtime : BrowserRuntime,
  roots : Array[Int],
  exclude_roots? : Bool = false,
) -> Array[Int] {
  runtime.transitive_dependencies(roots, exclude_roots~)
}

///|
pub fn ffi_browser_runtime_transitive_dependencies_json(
  runtime : BrowserRuntime,
  roots : Array[Int],
  exclude_roots? : Bool = false,
) -> String {
  browser_int_array_json_string(
    runtime.transitive_dependencies(roots, exclude_roots~),
  )
}

///|
pub fn ffi_browser_runtime_transitive_reverse_dependencies(
  runtime : BrowserRuntime,
  roots : Array[Int],
) -> Array[Int] {
  runtime.transitive_reverse_dependencies(roots)
}

///|
pub fn ffi_browser_runtime_transitive_reverse_dependencies_json(
  runtime : BrowserRuntime,
  roots : Array[Int],
) -> String {
  browser_int_array_json_string(runtime.transitive_reverse_dependencies(roots))
}

///|
pub fn ffi_browser_runtime_connected_components(
  runtime : BrowserRuntime,
  roots : Array[Int],
) -> Array[Int] {
  runtime.connected_components(roots)
}

///|
pub fn ffi_browser_runtime_connected_components_json(
  runtime : BrowserRuntime,
  roots : Array[Int],
) -> String {
  browser_int_array_json_string(runtime.connected_components(roots))
}

///|
pub fn ffi_browser_runtime_add_vertex_json(
  runtime : BrowserRuntime,
  input_json : String,
) -> String raise {
  runtime.add_vertex_json(input_json)
}

///|
pub fn ffi_browser_runtime_add_edge_json(
  runtime : BrowserRuntime,
  input_json : String,
) -> String raise {
  runtime.add_edge_json(input_json)
}

///|
pub fn ffi_browser_runtime_set_label_json(
  runtime : BrowserRuntime,
  input_json : String,
) -> String raise {
  runtime.set_label_json(input_json)
}

///|
pub fn ffi_browser_runtime_set_label_colour_json(
  runtime : BrowserRuntime,
  input_json : String,
) -> String raise {
  runtime.set_label_colour_json(input_json)
}

///|
pub fn ffi_browser_runtime_move_vertex_json(
  runtime : BrowserRuntime,
  input_json : String,
) -> String raise {
  runtime.move_vertex_json(input_json)
}

///|
pub fn ffi_browser_runtime_set_edge_options_json(
  runtime : BrowserRuntime,
  input_json : String,
) -> String raise {
  runtime.set_edge_options_json(input_json)
}

///|
pub fn ffi_browser_runtime_patch_edge_options_json(
  runtime : BrowserRuntime,
  input_json : String,
) -> String raise {
  runtime.patch_edge_options_json(input_json)
}

///|
pub fn ffi_browser_runtime_set_edge_label_alignment_json(
  runtime : BrowserRuntime,
  input_json : String,
) -> String raise {
  runtime.set_edge_label_alignment_json(input_json)
}

///|
pub fn ffi_browser_runtime_set_edge_label_position_json(
  runtime : BrowserRuntime,
  input_json : String,
) -> String raise {
  runtime.set_edge_label_position_json(input_json)
}

///|
pub fn ffi_browser_runtime_set_edge_offset_json(
  runtime : BrowserRuntime,
  input_json : String,
) -> String raise {
  runtime.set_edge_offset_json(input_json)
}

///|
pub fn ffi_browser_runtime_set_edge_curve_json(
  runtime : BrowserRuntime,
  input_json : String,
) -> String raise {
  runtime.set_edge_curve_json(input_json)
}

///|
pub fn ffi_browser_runtime_set_edge_shorten_json(
  runtime : BrowserRuntime,
  input_json : String,
) -> String raise {
  runtime.set_edge_shorten_json(input_json)
}

///|
pub fn ffi_browser_runtime_reconnect_edge_json(
  runtime : BrowserRuntime,
  input_json : String,
) -> String raise {
  runtime.reconnect_edge_json(input_json)
}

///|
pub fn ffi_browser_runtime_remove_json(
  runtime : BrowserRuntime,
  input_json : String,
) -> String raise {
  runtime.remove_json(input_json)
}

///|
pub fn ffi_browser_runtime_flush_json(
  runtime : BrowserRuntime,
  input_json : String,
) -> String raise {
  runtime.flush_json(input_json)
}

///|
pub fn ffi_browser_runtime_apply_mutation_batch_json(
  runtime : BrowserRuntime,
  batch_json : String,
) -> String raise {
  runtime.apply_mutation_batch_json(batch_json)
}

///|
pub fn ffi_browser_runtime_dispatch_json_safe(
  runtime : BrowserRuntime,
  action_json : String,
) -> String {
  runtime.dispatch_json_safe(action_json)
}

///|
pub fn ffi_browser_runtime_dispatch_many_json_safe(
  runtime : BrowserRuntime,
  batch_json : String,
) -> String {
  runtime.dispatch_many_json_safe(batch_json)
}

///|
pub fn ffi_browser_runtime_dispatch_json(
  runtime : BrowserRuntime,
  action_json : String,
) -> String {
  ffi_browser_runtime_dispatch_json_safe(runtime, action_json)
}

///|
pub fn ffi_browser_runtime_dispatch_many_json(
  runtime : BrowserRuntime,
  batch_json : String,
) -> String {
  ffi_browser_runtime_dispatch_many_json_safe(runtime, batch_json)
}

///|
pub fn ffi_browser_runtime_export_payload(runtime : BrowserRuntime) -> String {
  runtime.export_payload()
}

///|
pub fn ffi_browser_runtime_export_selection(
  runtime : BrowserRuntime,
  include_dependencies? : Bool = true,
) -> String {
  runtime.export_selection(include_dependencies~)
}

///|
pub fn ffi_browser_runtime_snapshot_json(runtime : BrowserRuntime) -> String {
  runtime.snapshot_json()
}

///|
pub fn ffi_browser_runtime_render_tikz_json(
  runtime : BrowserRuntime,
  settings? : @engine.TikzCdExportSettings = @engine.TikzCdExportSettings::default(),
  options? : @engine.TikzCdExportOptions = @engine.TikzCdExportOptions::default(),
  definitions? : @engine.TikzCdExportDefinitions = @engine.TikzCdExportDefinitions::default(),
) -> String {
  runtime.render_tikz_json(settings~, options~, definitions~)
}

///|
pub fn ffi_browser_runtime_render_tikz(runtime : BrowserRuntime) -> String {
  runtime.render_tikz()
}

///|
pub fn ffi_browser_runtime_render_fletcher(
  runtime : BrowserRuntime,
  settings? : @engine.FletcherExportSettings = @engine.FletcherExportSettings::default(),
  options? : @engine.FletcherExportOptions = @engine.FletcherExportOptions::default(),
) -> String {
  runtime.render_fletcher(settings~, options~)
}

///|
pub fn ffi_browser_runtime_render_html_embed(
  runtime : BrowserRuntime,
  settings : @engine.HtmlEmbedExportSettings,
  options? : @engine.HtmlEmbedExportOptions = @engine.HtmlEmbedExportOptions::default(),
) -> String {
  runtime.render_html_embed(settings, options~)
}

///|
pub fn ffi_browser_runtime_import_text_auto_json(
  runtime : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  runtime.import_text_auto_json(input, default_renderer~)
}

///|
pub fn ffi_browser_runtime_import_payload(
  runtime : BrowserRuntime,
  payload : String,
) -> String raise {
  runtime.import_payload(payload)
}

///|
pub fn ffi_browser_runtime_import_share_url_json(
  runtime : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  runtime.import_share_url_json(input, default_renderer~)
}

///|
pub fn ffi_browser_runtime_import_share_text_json(
  runtime : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  runtime.import_share_text_json(input, default_renderer~)
}

///|
pub fn ffi_browser_runtime_import_tikz_cd_json(
  runtime : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  runtime.import_tikz_cd_json(input, default_renderer~)
}

///|
pub fn ffi_browser_runtime_import_fletcher_json(
  runtime : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  runtime.import_fletcher_json(input, default_renderer~)
}

///|
pub fn ffi_browser_runtime_import_html_embed_json(
  runtime : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  runtime.import_html_embed_json(input, default_renderer~)
}

///|
pub fn ffi_browser_runtime_paste_selection_json(
  runtime : BrowserRuntime,
  payload : String,
  origin_x : Int,
  origin_y : Int,
  start_id? : Int = 1,
) -> String raise {
  runtime.paste_selection_json(payload, origin_x, origin_y, start_id~)
}
