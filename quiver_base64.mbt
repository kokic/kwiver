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
) -> String {
  let payload = self.export_base64_v0()
  match share_base_url {
    Some(base_url) => {
      if self.is_empty() {
        base_url
      } else {
        let macro_part = match macro_url {
          Some(value) => ["&macro_url=", base64_percent_encode_component(value)].join("")
          None => ""
        }
        [base_url, "#q=", payload, macro_part].join("")
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
