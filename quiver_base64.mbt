type ColourTuple = (Int, Int, Int, Double)

type EncodedVertex = (Int, Int, Int, String, ColourTuple)

type EncodedEdgeStyles = (
  String,
  (String, String),
  (String, String),
  (String, String),
)

type EncodedEdgeOptions = (
  (Int, Int, Int, Int, Int),
  (Int, Int),
  (Int, Int),
  ColourTuple,
  (Bool, Bool),
  EncodedEdgeStyles,
)

type EncodedEdge = (Int, Int, Int, String, Int, ColourTuple, EncodedEdgeOptions)

type EncodedQuiver = (Int, Array[EncodedVertex], Array[EncodedEdge])

pub struct Base64ShareUrlParts {
  payload : String?
  macro_url : String?
  renderer : String?
  embed : Bool
}

pub struct Base64ShareImportResult {
  quiver : Quiver
  macro_url : String?
  renderer : String?
  embed : Bool
}

fn colour_from_tuple(tuple : ColourTuple) -> Colour {
  let (h, s, l, a) = tuple
  Colour::new(h, s, l, a)
}

fn label_alignment_to_int(alignment : LabelAlignment) -> Int {
  match alignment {
    LabelAlignment::Left => 0
    LabelAlignment::Centre => 1
    LabelAlignment::Right => 2
    LabelAlignment::Over => 3
  }
}

fn int_to_label_alignment(value : Int) -> LabelAlignment {
  match value {
    0 => LabelAlignment::Left
    1 => LabelAlignment::Centre
    2 => LabelAlignment::Right
    3 => LabelAlignment::Over
    _ => LabelAlignment::Left
  }
}

fn int_to_edge_shape(value : Int) -> EdgeShape {
  match value {
    0 => EdgeShape::Bezier
    1 => EdgeShape::Arc
    _ => EdgeShape::Bezier
  }
}

fn edge_options_from_encoded(
  alignment : Int,
  encoded : EncodedEdgeOptions,
) -> EdgeOptions {
  let (
    core,
    shorten,
    level_shape,
    colour,
    edge_alignment,
    style,
  ) = encoded
  let (label_position, offset, curve, radius, angle) = core
  let (shorten_source, shorten_target) = shorten
  let (level, shape) = level_shape
  let (edge_alignment_source, edge_alignment_target) = edge_alignment
  let (style_name, tail, body, head) = style
  let (tail_name, tail_side) = tail
  let (body_name, body_side) = body
  let (head_name, head_side) = head
  {
    label_alignment: int_to_label_alignment(alignment),
    label_position,
    offset,
    curve,
    radius,
    angle,
    shorten: { source: shorten_source, target: shorten_target },
    level: if level < 1 { 1 } else { level },
    shape: int_to_edge_shape(shape),
    colour: colour_from_tuple(colour),
    edge_alignment: {
      source: edge_alignment_source,
      target: edge_alignment_target,
    },
    style: {
      name: style_name,
      tail: { name: tail_name, side: tail_side },
      body: { name: body_name, side: body_side },
      head: { name: head_name, side: head_side },
    },
  }
}

fn base64_is_url_unreserved(code : Int) -> Bool {
  let is_digit = code >= 48 && code <= 57
  let is_upper = code >= 65 && code <= 90
  let is_lower = code >= 97 && code <= 122
  is_digit || is_upper || is_lower || code == 45 || code == 46 || code == 95 || code == 126
}

fn base64_hex_upper(n : Int) -> Char {
  if n < 10 {
    (48 + n).unsafe_to_char()
  } else {
    (55 + n).unsafe_to_char()
  }
}

fn base64_percent_encode_component(value : String) -> String {
  let bytes = @utf8.encode(value)
  let out : Array[String] = []
  for byte in bytes {
    let code = byte.to_int()
    if base64_is_url_unreserved(code) {
      out.push(code.unsafe_to_char().to_string())
    } else {
      out.push("%")
      out.push(base64_hex_upper(code / 16).to_string())
      out.push(base64_hex_upper(code % 16).to_string())
    }
  }
  out.join("")
}

fn base64_hex_to_int(code : Int) -> Int {
  if code >= 48 && code <= 57 {
    code - 48
  } else if code >= 65 && code <= 70 {
    code - 55
  } else if code >= 97 && code <= 102 {
    code - 87
  } else {
    -1
  }
}

fn base64_percent_decode_component(value : String) -> String {
  let bytes = @utf8.encode(value)
  let decoded : Array[Byte] = []
  let mut i = 0
  while i < bytes.length() {
    let byte = bytes.unsafe_get(i)
    if byte == b'+' {
      decoded.push(b' ')
      i = i + 1
      continue
    }
    if byte == b'%' && i + 2 < bytes.length() {
      let high = base64_hex_to_int(bytes.unsafe_get(i + 1).to_int())
      let low = base64_hex_to_int(bytes.unsafe_get(i + 2).to_int())
      if high >= 0 && low >= 0 {
        decoded.push((high * 16 + low).to_byte())
        i = i + 3
        continue
      }
    }
    decoded.push(byte)
    i = i + 1
  }
  @utf8.decode_lossy(Bytes::from_array(decoded))
}

fn base64_share_url_fragment(input : String) -> String {
  match input.find("#") {
    Some(index) => input.unsafe_substring(start=index + 1, end=input.length())
    None => input
  }
}

fn base64_share_url_query(input : String) -> String {
  match input.find("?") {
    Some(query_start) => {
      let end = match input.find("#") {
        Some(hash_start) =>
          if hash_start > query_start {
            hash_start
          } else {
            input.length()
          }
        None => input.length()
      }
      input.unsafe_substring(start=query_start + 1, end=end)
    }
    None => ""
  }
}

fn base64_normalise_fragment(value : String) -> String {
  let amp = value.replace_all(old="&amp;", new="&")
  if amp.has_prefix("?") {
    amp.unsafe_substring(start=1, end=amp.length())
  } else {
    amp
  }
}

fn base64_trimmed(line : String) -> String {
  line.trim().to_string()
}

fn base64_extract_html_comment_reference(line : String) -> String? {
  match line.find("<!--") {
    Some(start) => {
      let after = line.unsafe_substring(start=start + 4, end=line.length())
      match after.find("-->") {
        Some(end) => Some(base64_trimmed(after.unsafe_substring(start=0, end=end)))
        None => None
      }
    }
    None => None
  }
}

fn base64_extract_iframe_src_reference(line : String) -> String? {
  let single_quote = Int::to_byte(39)
  let is_space = (byte : Byte) => byte == b' ' || byte == b'\t'
  let bytes = @utf8.encode(line)
  let mut i = 0
  while i + 2 < bytes.length() {
    if bytes.unsafe_get(i) == b's' &&
      bytes.unsafe_get(i + 1) == b'r' &&
      bytes.unsafe_get(i + 2) == b'c' {
      let mut j = i + 3
      while j < bytes.length() && is_space(bytes.unsafe_get(j)) {
        j = j + 1
      }
      if j >= bytes.length() || bytes.unsafe_get(j) != b'=' {
        i = i + 1
        continue
      }
      j = j + 1
      while j < bytes.length() && is_space(bytes.unsafe_get(j)) {
        j = j + 1
      }
      if j >= bytes.length() {
        i = i + 1
        continue
      }
      let quote = bytes.unsafe_get(j)
      if quote != b'"' && quote != single_quote {
        i = i + 1
        continue
      }
      j = j + 1
      let value_start = j
      while j < bytes.length() && bytes.unsafe_get(j) != quote {
        j = j + 1
      }
      if j < bytes.length() {
        return Some(line.unsafe_substring(start=value_start, end=j))
      }
    }
    i = i + 1
  }
  None
}

pub fn Quiver::extract_base64_share_reference(input : String) -> String? {
  if input == "" {
    return None
  }

  let mut fallback : String? = None
  for raw_line_view in input.split("\n") {
    let line = base64_trimmed(raw_line_view.to_string())
    if line == "" {
      continue
    }
    if fallback is None {
      fallback = Some(line)
    }

    if line.has_prefix("% ") {
      return Some(base64_trimmed(line.unsafe_substring(start=2, end=line.length())))
    }
    if line.has_prefix("// ") {
      return Some(base64_trimmed(line.unsafe_substring(start=3, end=line.length())))
    }
    match base64_extract_html_comment_reference(line) {
      Some(reference) =>
        if reference != "" {
          return Some(reference)
        }
      None => ()
    }
    match base64_extract_iframe_src_reference(line) {
      Some(reference) =>
        if reference != "" {
          return Some(reference)
        }
      None => ()
    }
  }

  fallback
}

fn base64_parse_share_segment(
  segment : String,
  allow_bare_payload : Bool,
  payload : String?,
  macro_url : String?,
  renderer_raw : String?,
  embed : Bool,
) -> (String?, String?, String?, Bool) {
  if segment == "" {
    return (payload, macro_url, renderer_raw, embed)
  }

  let mut payload = payload
  let mut macro_url = macro_url
  let mut renderer_raw = renderer_raw
  let mut embed = embed

  if !segment.contains("=") {
    if segment == "embed" {
      embed = true
    } else if allow_bare_payload {
      payload = Some(segment)
    }
    return (payload, macro_url, renderer_raw, embed)
  }

  for pair_view in segment.split("&") {
    let pair = pair_view.to_string()
    if pair == "" {
      continue
    }
    if pair == "embed" {
      embed = true
      continue
    }

    match pair.find("=") {
      Some(index) => {
        let key = pair.unsafe_substring(start=0, end=index)
        let value = pair.unsafe_substring(start=index + 1, end=pair.length())
        if key == "q" {
          payload = Some(value)
        } else if key == "macro_url" {
          macro_url = Some(base64_percent_decode_component(value))
        } else if key == "r" {
          renderer_raw = Some(base64_percent_decode_component(value))
        } else if key == "embed" {
          embed = true
        }
      }
      None => ()
    }
  }

  (payload, macro_url, renderer_raw, embed)
}

pub fn Quiver::parse_base64_share_url(
  input : String,
  default_renderer? : String = "canvas",
) -> Base64ShareUrlParts {
  let is_url = input.contains("://")
  let has_hash = input.contains("#")
  if !has_hash && !is_url {
    let is_fragment_query = input.has_prefix("q=") ||
      input.has_prefix("r=") ||
      input.has_prefix("macro_url=") ||
      input.has_prefix("embed") ||
      input.contains("&")
    if !is_fragment_query {
      return { payload: Some(input), macro_url: None, renderer: None, embed: false }
    }
  }

  let mut payload : String? = None
  let mut macro_url : String? = None
  let mut renderer_raw : String? = None
  let mut embed = false

  if is_url {
    let fragment = if has_hash {
      base64_normalise_fragment(base64_share_url_fragment(input))
    } else {
      ""
    }
    let query = base64_normalise_fragment(base64_share_url_query(input))
    if fragment == "" && query == "" {
      return { payload: None, macro_url: None, renderer: None, embed: false }
    }

    let parsed_fragment = base64_parse_share_segment(
      fragment,
      false,
      payload,
      macro_url,
      renderer_raw,
      embed,
    )
    let (payload_after_fragment, macro_after_fragment, renderer_after_fragment, embed_after_fragment) =
      parsed_fragment

    let parsed_query = base64_parse_share_segment(
      query,
      false,
      payload_after_fragment,
      macro_after_fragment,
      renderer_after_fragment,
      embed_after_fragment,
    )
    let (payload_after_query, macro_after_query, renderer_after_query, embed_after_query) =
      parsed_query

    payload = payload_after_query
    macro_url = macro_after_query
    renderer_raw = renderer_after_query
    embed = embed_after_query
  } else {
    let fragment_raw = if has_hash {
      base64_share_url_fragment(input)
    } else {
      input
    }
    let fragment = base64_normalise_fragment(fragment_raw)
    if fragment == "" {
      return { payload: None, macro_url: None, renderer: None, embed: false }
    }

    let parsed = base64_parse_share_segment(
      fragment,
      true,
      payload,
      macro_url,
      renderer_raw,
      embed,
    )
    let (payload_after_fragment, macro_after_fragment, renderer_after_fragment, embed_after_fragment) =
      parsed
    payload = payload_after_fragment
    macro_url = macro_after_fragment
    renderer_raw = renderer_after_fragment
    embed = embed_after_fragment
  }

  let renderer = match renderer_raw {
    Some(value) =>
      if value == default_renderer {
        None
      } else {
        Some(value)
      }
    None => None
  }

  { payload, macro_url, renderer, embed }
}

pub fn Quiver::export_base64_v0(self : Quiver) -> String {
  let cells = self.all_cells()
  let vertices : Array[Vertex] = []
  let edges : Array[Edge] = []

  for cell in cells {
    match cell {
      CellData::Vertex(vertex) => vertices.push(vertex)
      CellData::Edge(edge) => edges.push(edge)
    }
  }

  if vertices.is_empty() {
    return @base64.encode(@utf8.encode("[0,0]"))
  }

  let mut min_x = vertices.unsafe_get(0).x
  let mut min_y = vertices.unsafe_get(0).y
  for vertex in vertices {
    if vertex.x < min_x {
      min_x = vertex.x
    }
    if vertex.y < min_y {
      min_y = vertex.y
    }
  }

  let json_int = (value : Int) => Json::number(value.to_double())
  let json_colour = (colour : Colour) => {
    let values : Array[Json] = [
      Json::number(colour.h.to_double()),
      Json::number(colour.s.to_double()),
      Json::number(colour.l.to_double()),
    ]
    // Match quiver JS Colour.toJSON(): omit alpha when it is fully opaque.
    if colour.a != 1.0 {
      values.push(Json::number(colour.a))
    }
    Json::array(values)
  }

  let equal_colour = (a : Colour, b : Colour) =>
    (a.h == b.h && a.s == b.s && a.l == b.l && a.a == b.a) ||
    (a.l == 0 && b.l == 0) ||
    (a.l == 100 && b.l == 100)

  let options_delta = (options : EdgeOptions) => {
    let defaults = EdgeOptions::at_level(options.level)
    let delta : Map[String, Json] = Map::new()

    if options.label_position != defaults.label_position {
      delta.set("label_position", json_int(options.label_position))
    }
    if options.offset != defaults.offset {
      delta.set("offset", json_int(options.offset))
    }
    if options.curve != defaults.curve {
      delta.set("curve", json_int(options.curve))
    }
    if options.radius != defaults.radius {
      delta.set("radius", json_int(options.radius))
    }
    if options.angle != defaults.angle {
      delta.set("angle", json_int(options.angle))
    }

    if options.shorten.source != defaults.shorten.source ||
      options.shorten.target != defaults.shorten.target {
      let shorten_delta : Map[String, Json] = Map::new()
      if options.shorten.source != defaults.shorten.source {
        shorten_delta.set("source", json_int(options.shorten.source))
      }
      if options.shorten.target != defaults.shorten.target {
        shorten_delta.set("target", json_int(options.shorten.target))
      }
      if !shorten_delta.is_empty() {
        delta.set("shorten", Json::object(shorten_delta))
      }
    }

    if !equal_colour(options.colour, defaults.colour) {
      delta.set("colour", json_colour(options.colour))
    }

    if options.edge_alignment.source != defaults.edge_alignment.source ||
      options.edge_alignment.target != defaults.edge_alignment.target {
      let alignment_delta : Map[String, Json] = Map::new()
      if options.edge_alignment.source != defaults.edge_alignment.source {
        alignment_delta.set("source", Json::boolean(options.edge_alignment.source))
      }
      if options.edge_alignment.target != defaults.edge_alignment.target {
        alignment_delta.set("target", Json::boolean(options.edge_alignment.target))
      }
      if !alignment_delta.is_empty() {
        delta.set("edge_alignment", Json::object(alignment_delta))
      }
    }

    let style_delta : Map[String, Json] = Map::new()
    if options.style.name != defaults.style.name {
      style_delta.set("name", Json::string(options.style.name))
    }

    let tail_delta : Map[String, Json] = Map::new()
    if options.style.tail.name != defaults.style.tail.name {
      tail_delta.set("name", Json::string(options.style.tail.name))
    }
    if options.style.tail.side != defaults.style.tail.side {
      tail_delta.set("side", Json::string(options.style.tail.side))
    }
    if !tail_delta.is_empty() {
      style_delta.set("tail", Json::object(tail_delta))
    }

    let body_delta : Map[String, Json] = Map::new()
    if options.style.body.name != defaults.style.body.name {
      body_delta.set("name", Json::string(options.style.body.name))
    }
    if options.style.body.side != defaults.style.body.side {
      body_delta.set("side", Json::string(options.style.body.side))
    }
    if !body_delta.is_empty() {
      style_delta.set("body", Json::object(body_delta))
    }

    let head_delta : Map[String, Json] = Map::new()
    if options.style.head.name != defaults.style.head.name {
      head_delta.set("name", Json::string(options.style.head.name))
    }
    if options.style.head.side != defaults.style.head.side {
      head_delta.set("side", Json::string(options.style.head.side))
    }
    if !head_delta.is_empty() {
      style_delta.set("head", Json::object(head_delta))
    }

    if !style_delta.is_empty() {
      delta.set("style", Json::object(style_delta))
    }

    match options.shape {
      EdgeShape::Bezier => {
        delta.remove("radius")
        delta.remove("angle")
      }
      EdgeShape::Arc => delta.remove("curve")
    }

    delta
  }

  let encoded_cells : Array[Json] = []
  let indices : @hashmap.HashMap[Int, Int] = @hashmap.new()

  for vertex in vertices {
    let cell : Array[Json] = [
      json_int(vertex.x - min_x),
      json_int(vertex.y - min_y),
    ]
    if vertex.cell.label != "" {
      cell.push(Json::string(vertex.cell.label))
    }
    if vertex.cell.label != "" && vertex.cell.label_colour.is_not_black() {
      cell.push(json_colour(vertex.cell.label_colour))
    }
    indices.set(vertex.cell.id, encoded_cells.length())
    encoded_cells.push(Json::array(cell))
  }

  for edge in edges {
    let source_index = match indices.get(edge.source) {
      Some(value) => value
      None => abort("invalid source index in quiver encoding")
    }
    let target_index = match indices.get(edge.target) {
      Some(value) => value
      None => abort("invalid target index in quiver encoding")
    }

    let cell : Array[Json] = [
      json_int(source_index),
      json_int(target_index),
    ]
    let end : Array[Json] = []

    if edge.cell.label != "" && edge.cell.label_colour.is_not_black() {
      end.push(json_colour(edge.cell.label_colour))
    }

    let delta = options_delta(edge.options)
    if !end.is_empty() || !delta.is_empty() {
      end.push(Json::object(delta))
    }

    let alignment = label_alignment_to_int(edge.options.label_alignment)
    if !end.is_empty() || (alignment != 0 && edge.cell.label != "") {
      end.push(json_int(alignment))
    }
    if !end.is_empty() || edge.cell.label != "" {
      end.push(Json::string(edge.cell.label))
    }

    end.rev_each((value) => cell.push(value))

    indices.set(edge.cell.id, encoded_cells.length())
    encoded_cells.push(Json::array(cell))
  }

  let payload : Array[Json] = [json_int(0), json_int(vertices.length())]
  payload.append(encoded_cells)
  let json_string = Json::array(payload).stringify()
  @base64.encode(@utf8.encode(json_string))
}

pub fn Quiver::export_base64_share_url(
  self : Quiver,
  share_base_url : String?,
  macro_url : String?,
  renderer? : String,
  default_renderer? : String = "canvas",
) -> String {
  let payload = self.export_base64_v0()
  match share_base_url {
    Some(base_url) => {
      if self.is_empty() {
        base_url
      } else {
        let renderer_part = match renderer {
          Some(value) =>
            if value == default_renderer {
              ""
            } else {
              ["r=", base64_percent_encode_component(value), "&"].join("")
            }
          None => ""
        }
        let macro_part = match macro_url {
          Some(value) => ["&macro_url=", base64_percent_encode_component(value)].join("")
          None => ""
        }
        [base_url, "#", renderer_part, "q=", payload, macro_part].join("")
      }
    }
    None => payload
  }
}

fn base64_import_assert(condition : Bool, message : String) -> Unit {
  if !condition {
    abort(message + " in quiver encoding")
  }
}

fn base64_import_colour(raw : Json) -> Colour raise {
  let values : Array[Double] = @json.from_json(raw)
  base64_import_assert(
    values.length() >= 3 && values.length() <= 4,
    "invalid colour format",
  )
  let h = values.unsafe_get(0).to_int()
  let s = values.unsafe_get(1).to_int()
  let l = values.unsafe_get(2).to_int()
  let a = if values.length() >= 4 {
    values.unsafe_get(3)
  } else {
    1.0
  }
  base64_import_assert(h >= 0 && h <= 360, "invalid hue")
  base64_import_assert(s >= 0 && s <= 100, "invalid saturation")
  base64_import_assert(l >= 0 && l <= 100, "invalid lightness")
  base64_import_assert(a >= 0.0 && a <= 1.0, "invalid alpha")
  Colour::new(h, s, l, a)
}

fn base64_import_endpoint_style(
  raw : Json,
  fallback : EdgeEndpointStyle,
) -> EdgeEndpointStyle raise {
  match raw {
    Json::String(name) => { name, side: fallback.side }
    Json::Object(value_map) => {
      let name = match value_map.get("name") {
        Some(value) => @json.from_json(value)
        None => fallback.name
      }
      let side = match value_map.get("side") {
        Some(value) => @json.from_json(value)
        None => fallback.side
      }
      { name, side }
    }
    _ => fallback
  }
}

fn base64_import_apply_style_delta(
  options : EdgeOptions,
  style_raw : Json,
) -> (EdgeOptions, Int?) raise {
  match style_raw {
    Json::Object(style_map) => {
      let mut out = options
      let mut level_override : Int? = None

      match style_map.get("name") {
        Some(value) => {
          let name : String = @json.from_json(value)
          out = out.with_style_name(name)
        }
        None => ()
      }
      match style_map.get("tail") {
        Some(value) => {
          let tail = base64_import_endpoint_style(value, out.style.tail)
          out = out.with_style_tail(tail.name, side=tail.side)
        }
        None => ()
      }
      match style_map.get("body") {
        Some(value) => {
          let body = base64_import_endpoint_style(value, out.style.body)
          out = out.with_style_body(body.name, side=body.side)
          match value {
            Json::Object(body_map) => match body_map.get("level") {
              Some(level_value) => {
                let level : Int = @json.from_json(level_value)
                base64_import_assert(level >= 1, "invalid level")
                level_override = Some(level)
              }
              None => ()
            }
            _ => ()
          }
        }
        None => ()
      }
      match style_map.get("head") {
        Some(value) => {
          let head = base64_import_endpoint_style(value, out.style.head)
          out = out.with_style_head(head.name, side=head.side)
        }
        None => ()
      }

      (out, level_override)
    }
    _ => (options, None)
  }
}

fn base64_import_apply_options_delta(
  options : EdgeOptions,
  options_map : Map[String, Json],
) -> EdgeOptions raise {
  let mut out = options
  let mut has_shorten = false
  let mut has_curve = false
  let mut has_radius_or_angle = false

  match options_map.get("label_position") {
    Some(value) => {
      let label_position : Int = @json.from_json(value)
      base64_import_assert(label_position >= 0 && label_position <= 100, "invalid label position")
      out = out.with_label_position(label_position)
    }
    None => ()
  }
  match options_map.get("offset") {
    Some(value) => {
      let offset : Int = @json.from_json(value)
      out = out.with_offset(offset)
    }
    None => ()
  }
  match options_map.get("curve") {
    Some(value) => {
      let curve : Int = @json.from_json(value)
      out = out.with_curve(curve)
      has_curve = true
    }
    None => ()
  }
  match options_map.get("radius") {
    Some(value) => {
      let radius : Int = @json.from_json(value)
      out = out.with_radius(radius)
      has_radius_or_angle = true
    }
    None => ()
  }
  match options_map.get("angle") {
    Some(value) => {
      let angle : Int = @json.from_json(value)
      out = out.with_angle(angle)
      has_radius_or_angle = true
    }
    None => ()
  }
  match options_map.get("shorten") {
    Some(value) => {
      let shorten_map : Map[String, Json] = @json.from_json(value)
      let mut source = out.shorten.source
      let mut target = out.shorten.target
      match shorten_map.get("source") {
        Some(raw) => {
          source = @json.from_json(raw)
          base64_import_assert(source >= 0, "invalid shorten")
        }
        None => ()
      }
      match shorten_map.get("target") {
        Some(raw) => {
          target = @json.from_json(raw)
          base64_import_assert(target >= 0, "invalid shorten")
        }
        None => ()
      }
      base64_import_assert(source + target <= 100, "invalid shorten")
      out = out.with_shorten(source, target)
      has_shorten = true
    }
    None => ()
  }
  if !has_shorten {
    match options_map.get("length") {
      Some(value) => {
        let length : Int = @json.from_json(value)
        base64_import_assert(length >= 0 && length <= 100, "invalid length")
        let shorten = (100 - length) / 2
        out = out.with_shorten(shorten, shorten)
      }
      None => ()
    }
  }
  match options_map.get("colour") {
    Some(value) => out = out.with_colour(base64_import_colour(value))
    None => ()
  }
  match options_map.get("edge_alignment") {
    Some(value) => {
      let alignment_map : Map[String, Json] = @json.from_json(value)
      let mut source = out.edge_alignment.source
      let mut target = out.edge_alignment.target
      match alignment_map.get("source") {
        Some(raw) => source = @json.from_json(raw)
        None => ()
      }
      match alignment_map.get("target") {
        Some(raw) => target = @json.from_json(raw)
        None => ()
      }
      out = out.with_edge_alignment(source, target)
    }
    None => ()
  }
  match options_map.get("shape") {
    Some(value) => {
      let shape : String = @json.from_json(value)
      if shape == "arc" {
        out = out.with_shape_arc()
      } else if shape == "bezier" {
        out = out.with_shape_bezier()
      }
    }
    None => {
      // JS canonical payload omits `shape`; infer it from which curve parameters were encoded.
      if has_radius_or_angle && !has_curve {
        out = out.with_shape_arc()
      } else if has_curve && !has_radius_or_angle {
        out = out.with_shape_bezier()
      }
    }
  }
  match options_map.get("level") {
    Some(value) => {
      let level : Int = @json.from_json(value)
      if level >= 1 {
        out = out.with_level(level)
      }
    }
    None => ()
  }

  out
}

fn base64_import_quiver_from_legacy(parsed : EncodedQuiver) -> Quiver {
  let (version, vertices, edges) = parsed
  if version != 0 {
    abort("unsupported base64 quiver version")
  }

  let quiver = Quiver::new()

  for encoded_vertex in vertices {
    let (id, x, y, label, label_colour) = encoded_vertex
    quiver.add(
      CellData::from_vertex(
        Vertex::new(id, label, x, y, colour_from_tuple(label_colour)),
      ),
    )
  }

  let pending_connections : Array[(Int, Int, Int)] = []
  for encoded_edge in edges {
    let (id, source, target, label, alignment, label_colour, edge_options) = encoded_edge
    let options = edge_options_from_encoded(alignment, edge_options)
    quiver.add(
      CellData::from_edge(
        Edge::new(id, label, source, target, options, colour_from_tuple(label_colour)),
      ),
    )
    pending_connections.push((id, source, target))
  }

  for pending in pending_connections {
    let (id, source, target) = pending
    quiver.connect(source, target, id)
  }

  quiver
}

fn base64_import_quiver_from_js(root : Array[Json]) -> Quiver raise {
  base64_import_assert(root.length() >= 2, "invalid quiver format")

  let version : Int = @json.from_json(root.unsafe_get(0))
  base64_import_assert(version == 0, "unsupported base64 quiver version")

  let vertices : Int = @json.from_json(root.unsafe_get(1))
  let cells_count = root.length() - 2
  base64_import_assert(vertices >= 0, "invalid number of vertices")
  base64_import_assert(vertices <= cells_count, "invalid number of vertices")

  let quiver = Quiver::new()
  let index_to_id : Array[Int] = []
  let index_to_level : Array[Int] = []
  let mut i = 0
  while i < cells_count {
    let cell_raw = root.unsafe_get(i + 2)
    let cell : Array[Json] = @json.from_json(cell_raw)
    if i < vertices {
      base64_import_assert(cell.length() >= 2 && cell.length() <= 4, "invalid vertex format")
      let x : Int = @json.from_json(cell.unsafe_get(0))
      let y : Int = @json.from_json(cell.unsafe_get(1))
      base64_import_assert(x >= 0, "invalid x position")
      base64_import_assert(y >= 0, "invalid y position")
      let label = if cell.length() >= 3 {
        @json.from_json(cell.unsafe_get(2))
      } else {
        ""
      }
      let label_colour = if cell.length() >= 4 {
        base64_import_colour(cell.unsafe_get(3))
      } else {
        Colour::black()
      }
      let id = i + 1
      quiver.add(
        CellData::from_vertex(
          Vertex::new(id, label, x, y, label_colour),
        ),
      )
      index_to_id.push(id)
      index_to_level.push(0)
    } else {
      base64_import_assert(cell.length() >= 2 && cell.length() <= 6, "invalid edge format")
      let source_index : Int = @json.from_json(cell.unsafe_get(0))
      let target_index : Int = @json.from_json(cell.unsafe_get(1))
      base64_import_assert(source_index >= 0, "invalid source index")
      base64_import_assert(target_index >= 0, "invalid target index")
      base64_import_assert(source_index < index_to_id.length(), "invalid source index")
      base64_import_assert(target_index < index_to_id.length(), "invalid target index")

      let source_id = index_to_id.unsafe_get(source_index)
      let target_id = index_to_id.unsafe_get(target_index)
      let label = if cell.length() >= 3 {
        @json.from_json(cell.unsafe_get(2))
      } else {
        ""
      }
      let alignment = if cell.length() >= 4 {
        let value : Int = @json.from_json(cell.unsafe_get(3))
        base64_import_assert(value >= 0 && value <= 3, "invalid label alignment")
        value
      } else {
        0
      }
      let mut level = Int::max(
        index_to_level.unsafe_get(source_index),
        index_to_level.unsafe_get(target_index),
      ) + 1

      let options_map : Map[String, Json] = if cell.length() >= 5 {
        match cell.unsafe_get(4) {
          Json::Object(map) => map
          Json::Null => Map::new()
          _ => abort("expected object in quiver encoding")
        }
      } else {
        Map::new()
      }

      let mut options = EdgeOptions::at_level(level)
      options = match alignment {
        0 => options.with_label_alignment_left()
        1 => options.with_label_alignment_centre()
        2 => options.with_label_alignment_right()
        _ => options.with_label_alignment_over()
      }

      match options_map.get("style") {
        Some(style_raw) => {
          let (styled, level_override) = base64_import_apply_style_delta(options, style_raw)
          options = styled
          match level_override {
            Some(value) => level = value
            None => ()
          }
        }
        None => ()
      }
      options = base64_import_apply_options_delta(options, options_map)
      options = options.with_level(level)

      let label_colour = if cell.length() >= 6 {
        base64_import_colour(cell.unsafe_get(5))
      } else {
        Colour::black()
      }
      let id = i + 1
      quiver.add(
        CellData::from_edge(
          Edge::new(id, label, source_id, target_id, options, label_colour),
        ),
      )
      quiver.connect(source_id, target_id, id)
      index_to_id.push(id)
      index_to_level.push(quiver.cell_level_or_default(id))
    }
    i = i + 1
  }

  quiver
}

pub fn Quiver::import_base64_v0(encoded : String) -> Quiver raise {
  let decoded = @utf8.decode(@base64.decode(encoded))
  let json = @json.parse(decoded)
  let root : Array[Json] = @json.from_json(json)

  if root.length() == 3 {
    match (root.unsafe_get(1), root.unsafe_get(2)) {
      (Json::Array(_), Json::Array(_)) => {
        let parsed : EncodedQuiver = @json.from_json(json)
        return base64_import_quiver_from_legacy(parsed)
      }
      _ => ()
    }
  }

  base64_import_quiver_from_js(root)
}

pub fn Quiver::import_base64_share_url(
  input : String,
  default_renderer? : String = "canvas",
) -> Quiver raise {
  Quiver::import_base64_share_url_result(
    input,
    default_renderer=default_renderer,
  ).quiver
}

pub fn Quiver::import_base64_share_url_result(
  input : String,
  default_renderer? : String = "canvas",
) -> Base64ShareImportResult raise {
  let parsed = Quiver::parse_base64_share_url(input, default_renderer=default_renderer)
  match parsed.payload {
    Some(payload) =>
      {
        quiver: Quiver::import_base64_v0(payload),
        macro_url: parsed.macro_url,
        renderer: parsed.renderer,
        embed: parsed.embed,
      }
    None => abort("missing base64 payload in share URL")
  }
}

pub fn Quiver::import_base64_share_text(
  input : String,
  default_renderer? : String = "canvas",
) -> Base64ShareImportResult raise {
  let reference = match Quiver::extract_base64_share_reference(input) {
    Some(value) => value
    None => input
  }
  Quiver::import_base64_share_url_result(reference, default_renderer=default_renderer)
}
