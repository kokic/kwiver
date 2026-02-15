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

fn colour_to_tuple(colour : Colour) -> ColourTuple {
  (colour.h, colour.s, colour.l, colour.a)
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

fn edge_shape_to_int(shape : EdgeShape) -> Int {
  match shape {
    EdgeShape::Bezier => 0
    EdgeShape::Arc => 1
  }
}

fn int_to_edge_shape(value : Int) -> EdgeShape {
  match value {
    0 => EdgeShape::Bezier
    1 => EdgeShape::Arc
    _ => EdgeShape::Bezier
  }
}

fn edge_options_to_encoded(options : EdgeOptions) -> EncodedEdgeOptions {
  (
    (
      options.label_position,
      options.offset,
      options.curve,
      options.radius,
      options.angle,
    ),
    (options.shorten.source, options.shorten.target),
    (options.level, edge_shape_to_int(options.shape)),
    colour_to_tuple(options.colour),
    (options.edge_alignment.source, options.edge_alignment.target),
    (
      options.style.name,
      (options.style.tail.name, options.style.tail.side),
      (options.style.body.name, options.style.body.side),
      (options.style.head.name, options.style.head.side),
    ),
  )
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
  let fragment_raw = if has_hash {
    base64_share_url_fragment(input)
  } else if is_url {
    match input.find("?") {
      Some(index) => input.unsafe_substring(start=index + 1, end=input.length())
      None => ""
    }
  } else {
    input
  }
  let fragment_amp = fragment_raw.replace_all(old="&amp;", new="&")
  let fragment = if fragment_amp.has_prefix("?") {
    fragment_amp.unsafe_substring(start=1, end=fragment_amp.length())
  } else {
    fragment_amp
  }

  if fragment == "" {
    return { payload: None, macro_url: None, renderer: None, embed: false }
  }

  if !fragment.contains("=") {
    if fragment == "embed" {
      return { payload: None, macro_url: None, renderer: None, embed: true }
    }
    if is_url {
      return { payload: None, macro_url: None, renderer: None, embed: false }
    }
    return { payload: Some(fragment), macro_url: None, renderer: None, embed: false }
  }

  let mut payload : String? = None
  let mut macro_url : String? = None
  let mut renderer_raw : String? = None
  let mut embed = false

  for pair_view in fragment.split("&") {
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
  let vertices : Array[EncodedVertex] = []
  let edges : Array[EncodedEdge] = []

  for cell in self.all_cells() {
    match cell {
      CellData::Vertex(vertex) => vertices.push(
        (
          vertex.cell.id,
          vertex.x,
          vertex.y,
          vertex.cell.label,
          colour_to_tuple(vertex.cell.label_colour),
        ),
      )
      CellData::Edge(edge) => edges.push(
        (
          edge.cell.id,
          edge.source,
          edge.target,
          edge.cell.label,
          label_alignment_to_int(edge.options.label_alignment),
          colour_to_tuple(edge.cell.label_colour),
          edge_options_to_encoded(edge.options),
        ),
      )
    }
  }

  let payload : EncodedQuiver = (0, vertices, edges)
  let json_string = payload.to_json().stringify()
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
    }
    None => ()
  }
  match options_map.get("radius") {
    Some(value) => {
      let radius : Int = @json.from_json(value)
      out = out.with_radius(radius)
    }
    None => ()
  }
  match options_map.get("angle") {
    Some(value) => {
      let angle : Int = @json.from_json(value)
      out = out.with_angle(angle)
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
    None => ()
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
