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
}

pub struct Base64ShareImportResult {
  quiver : Quiver
  macro_url : String?
  renderer : String?
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
  match line.find("src=\"") {
    Some(start) => {
      let after = line.unsafe_substring(start=start + 5, end=line.length())
      match after.find("\"") {
        Some(end) => Some(after.unsafe_substring(start=0, end=end))
        None => None
      }
    }
    None => None
  }
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
  let has_hash = input.contains("#")
  if !has_hash {
    if input.contains("://") {
      return { payload: None, macro_url: None, renderer: None }
    }
    let is_fragment_query = input.has_prefix("q=") ||
      input.has_prefix("r=") ||
      input.has_prefix("macro_url=") ||
      input.contains("&")
    if !is_fragment_query {
      return { payload: Some(input), macro_url: None, renderer: None }
    }
  }

  let fragment = base64_share_url_fragment(input)
  if fragment == "" {
    return { payload: None, macro_url: None, renderer: None }
  }

  if !fragment.contains("=") {
    if input.contains("://") {
      return { payload: None, macro_url: None, renderer: None }
    }
    return { payload: Some(fragment), macro_url: None, renderer: None }
  }

  let mut payload : String? = None
  let mut macro_url : String? = None
  let mut renderer_raw : String? = None

  for pair_view in fragment.split("&") {
    let pair = pair_view.to_string()
    if pair == "" {
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

  { payload, macro_url, renderer }
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

pub fn Quiver::import_base64_v0(encoded : String) -> Quiver raise {
  let decoded = @utf8.decode(@base64.decode(encoded))
  let json = @json.parse(decoded)
  let parsed : EncodedQuiver = @json.from_json(json)
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
