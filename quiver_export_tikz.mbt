pub struct TikzCdExportSettings {
  centre_diagram : Bool
  ampersand_replacement : Bool
  cramped : Bool
  standalone : Bool
}

pub fn TikzCdExportSettings::default() -> TikzCdExportSettings {
  {
    centre_diagram: false,
    ampersand_replacement: false,
    cramped: false,
    standalone: false,
  }
}

pub fn TikzCdExportSettings::with_centre_diagram(
  self : TikzCdExportSettings,
  value~ : Bool = true,
) -> TikzCdExportSettings {
  {
    centre_diagram: value,
    ampersand_replacement: self.ampersand_replacement,
    cramped: self.cramped,
    standalone: self.standalone,
  }
}

pub fn TikzCdExportSettings::with_ampersand_replacement(
  self : TikzCdExportSettings,
  value~ : Bool = true,
) -> TikzCdExportSettings {
  {
    centre_diagram: self.centre_diagram,
    ampersand_replacement: value,
    cramped: self.cramped,
    standalone: self.standalone,
  }
}

pub fn TikzCdExportSettings::with_cramped(
  self : TikzCdExportSettings,
  value~ : Bool = true,
) -> TikzCdExportSettings {
  {
    centre_diagram: self.centre_diagram,
    ampersand_replacement: self.ampersand_replacement,
    cramped: value,
    standalone: self.standalone,
  }
}

pub fn TikzCdExportSettings::with_standalone(
  self : TikzCdExportSettings,
  value~ : Bool = true,
) -> TikzCdExportSettings {
  {
    centre_diagram: self.centre_diagram,
    ampersand_replacement: self.ampersand_replacement,
    cramped: self.cramped,
    standalone: value,
  }
}

fn tikz_coord_key(x : Int, y : Int) -> String {
  [x.to_string(), ",", y.to_string()].join("")
}

fn tikz_escape_label(label : String) -> String {
  label.replace_all(old="\"", new="\\\"")
}

fn tikz_begin_line(settings : TikzCdExportSettings) -> String {
  let options : Array[String] = []
  if settings.ampersand_replacement {
    options.push("ampersand replacement=\\&")
  }
  if settings.cramped {
    options.push("cramped")
  }

  if options.is_empty() {
    "\\begin{tikzcd}"
  } else {
    ["\\begin{tikzcd}[", options.join(","), "]"].join("")
  }
}

fn tikz_wrap_output(settings : TikzCdExportSettings, tikzcd : String) -> String {
  if settings.standalone {
    [
      "\\documentclass[tikz]{standalone}\n\\usepackage{quiver}\n\\begin{document}\n",
      tikzcd,
      "\n\\end{document}",
    ].join("")
  } else if settings.centre_diagram {
    ["\\[", tikzcd, "\\]"].join("")
  } else {
    tikzcd
  }
}

fn tikz_repeat(token : String, count : Int) -> String {
  if count <= 0 {
    return ""
  }
  let out : Array[String] = []
  for _ in 0..<count {
    out.push(token)
  }
  out.join("")
}

fn tikz_mod(x : Double, y : Double) -> Double {
  let r = x - y * @math.floor(x / y)
  if r < 0.0 { r + y } else { r }
}

fn tikz_round_to_int(x : Double) -> Int {
  if x >= 0.0 {
    @math.floor(x + 0.5).to_int()
  } else {
    -@math.floor(-x + 0.5).to_int()
  }
}

fn tikz_direction_option(source : Vertex, target : Vertex) -> String? {
  let dx = target.x - source.x
  let dy = target.y - source.y
  let parts : Array[String] = []

  if dy < 0 {
    parts.push(tikz_repeat("u", Int::abs(dy)))
  } else if dy > 0 {
    parts.push(tikz_repeat("d", dy))
  }

  if dx < 0 {
    parts.push(tikz_repeat("l", Int::abs(dx)))
  } else if dx > 0 {
    parts.push(tikz_repeat("r", dx))
  }

  let direction = parts.join("")
  if direction == "" { None } else { Some(direction) }
}

fn tikz_max_double(a : Double, b : Double) -> Double {
  if a > b { a } else { b }
}

fn tikz_min_double(a : Double, b : Double) -> Double {
  if a < b { a } else { b }
}

fn tikz_min3_double(a : Double, b : Double, c : Double) -> Double {
  tikz_min_double(a, tikz_min_double(b, c))
}

fn tikz_colour_channel(colour : Colour, n : Int) -> Int {
  let h = colour.h.to_double()
  let s = colour.s.to_double() / 100.0
  let l = colour.l.to_double() / 100.0
  let a = s * tikz_min_double(l, 1.0 - l)
  let k_raw = n.to_double() + h / 30.0
  let k = k_raw - 12.0 * @math.floor(k_raw / 12.0)
  let f = l - a * tikz_max_double(-1.0, tikz_min3_double(k - 3.0, 9.0 - k, 1.0))
  let rounded = @math.floor(f * 255.0 + 0.5).to_int()
  if rounded < 0 {
    0
  } else if rounded > 255 {
    255
  } else {
    rounded
  }
}

fn tikz_colour_spec(colour : Colour) -> String {
  let r = tikz_colour_channel(colour, 0)
  let g = tikz_colour_channel(colour, 8)
  let b = tikz_colour_channel(colour, 4)
  [
    "{rgb,255:red,",
    r.to_string(),
    ";green,",
    g.to_string(),
    ";blue,",
    b.to_string(),
    "}",
  ].join("")
}

fn tikz_coloured_text(label : String, colour : Colour) -> String {
  [
    "\\textcolor",
    tikz_colour_spec(colour),
    "{",
    tikz_escape_label(label),
    "}",
  ].join("")
}

fn tikz_colour_eq(a : Colour, b : Colour) -> Bool {
  let exact = a.h == b.h && a.s == b.s && a.l == b.l && a.a == b.a
  exact || (a.l == 0 && b.l == 0) || (a.l == 100 && b.l == 100)
}

fn tikz_edge_is_empty(edge : Edge) -> Bool {
  let is_arrow = edge.options.style.name == "arrow"
  let no_head = edge.options.style.head.name == "none"
  let no_body = edge.options.style.body.name == "none"
  let no_tail = edge.options.style.tail.name == "none"
  is_arrow && no_head && no_body && no_tail
}

fn tikz_shared_colour(edge : Edge) -> Bool {
  tikz_colour_eq(edge.options.colour, edge.cell.label_colour) && edge.cell.label_colour.is_not_black()
}

fn tikz_append_colour_options(
  options : Array[String],
  edge : Edge,
  edge_is_empty : Bool,
) -> Bool {
  if tikz_shared_colour(edge) {
    options.push(["color=", tikz_colour_spec(edge.cell.label_colour)].join(""))
    false
  } else {
    if !edge_is_empty && edge.options.style.name == "arrow" && edge.options.colour.is_not_black() {
      options.push(["draw=", tikz_colour_spec(edge.options.colour)].join(""))
    }
    edge.cell.label_colour.is_not_black()
  }
}

fn tikz_edge_label_content(edge : Edge, explicit_colour : Bool) -> String {
  if edge.cell.label == "" {
    return ""
  }
  if explicit_colour && edge.cell.label_colour.is_not_black() {
    tikz_coloured_text(edge.cell.label, edge.cell.label_colour)
  } else {
    tikz_escape_label(edge.cell.label)
  }
}

fn tikz_vertex_label(vertex : Vertex) -> String {
  if vertex.cell.label == "" {
    ""
  } else if vertex.cell.label_colour.is_not_black() {
    tikz_coloured_text(vertex.cell.label, vertex.cell.label_colour)
  } else {
    vertex.cell.label
  }
}

fn tikz_edge_coord_part(vertex : Vertex?) -> (Int, Int) {
  match vertex {
    Some(v) => (v.y, v.x)
    None => (2147483647, 2147483647)
  }
}

fn tikz_resolve_vertex(
  start_id : Int,
  vertices_by_id : @hashmap.HashMap[Int, Vertex],
  edges_by_id : @hashmap.HashMap[Int, Edge],
  pick_source : Bool,
) -> Vertex? {
  let mut current = start_id
  let mut i = 0
  let limit = edges_by_id.length() + 1
  while i <= limit {
    match vertices_by_id.get(current) {
      Some(vertex) => return Some(vertex)
      None => ()
    }

    match edges_by_id.get(current) {
      Some(edge) => current = if pick_source { edge.source } else { edge.target }
      None => return None
    }
    i = i + 1
  }
  None
}

fn tikz_edge_name(edge_id : Int) -> String {
  ["e", edge_id.to_string()].join("")
}

fn tikz_edge_reference_name(edge_id : Int, phantom : Bool) -> String {
  let base = tikz_edge_name(edge_id)
  if phantom { [base, "p"].join("") } else { base }
}

fn tikz_named_placeholder(name : String) -> String {
  ["\"\"{name=", name, ", anchor=center, inner sep=0}"].join("")
}

fn tikz_vertex_reference(vertex : Vertex, min_x : Int, min_y : Int) -> String {
  [(vertex.y - min_y + 1).to_string(), "-", (vertex.x - min_x + 1).to_string()].join("")
}

fn tikz_cell_reference(
  cell_id : Int,
  min_x : Int,
  min_y : Int,
  phantom : Bool,
  vertices_by_id : @hashmap.HashMap[Int, Vertex],
  edges_by_id : @hashmap.HashMap[Int, Edge],
) -> String? {
  match vertices_by_id.get(cell_id) {
    Some(vertex) => Some(tikz_vertex_reference(vertex, min_x, min_y))
    None => match edges_by_id.get(cell_id) {
      Some(edge) => Some(tikz_edge_reference_name(edge.cell.id, phantom))
      None => None
    }
  }
}

fn tikz_edge_angle_deg(source : Vertex, target : Vertex) -> Double {
  let dx = target.x - source.x
  let dy = target.y - source.y
  @math.atan2(dy.to_double(), dx.to_double()) * 180.0 / @math.PI
}

fn tikz_compare_edges(
  vertices_by_id : @hashmap.HashMap[Int, Vertex],
  edges_by_id : @hashmap.HashMap[Int, Edge],
  a : Edge,
  b : Edge,
) -> Int {
  if a.options.level != b.options.level {
    return a.options.level - b.options.level
  }

  let (a_source_y, a_source_x) = tikz_edge_coord_part(
    tikz_resolve_vertex(a.source, vertices_by_id, edges_by_id, true),
  )
  let (b_source_y, b_source_x) = tikz_edge_coord_part(
    tikz_resolve_vertex(b.source, vertices_by_id, edges_by_id, true),
  )
  if a_source_y != b_source_y {
    return a_source_y - b_source_y
  }
  if a_source_x != b_source_x {
    return a_source_x - b_source_x
  }

  let (a_target_y, a_target_x) = tikz_edge_coord_part(
    tikz_resolve_vertex(a.target, vertices_by_id, edges_by_id, false),
  )
  let (b_target_y, b_target_x) = tikz_edge_coord_part(
    tikz_resolve_vertex(b.target, vertices_by_id, edges_by_id, false),
  )
  if a_target_y != b_target_y {
    return a_target_y - b_target_y
  }
  if a_target_x != b_target_x {
    return a_target_x - b_target_x
  }
  a.cell.id - b.cell.id
}

fn tikz_is_arrow_body_decoration(style_body : String) -> Bool {
  match style_body {
    "barred" => true
    "double barred" => true
    "bullet solid" => true
    "bullet hollow" => true
    _ => false
  }
}

fn tikz_append_label_options(options : Array[String], edge : Edge, label_content : String) -> Unit {
  if label_content != "" {
    options.push(["\"", label_content, "\""].join(""))

    match edge.options.label_alignment {
      LabelAlignment::Right => options.push("swap")
      LabelAlignment::Centre => options.push("description")
      LabelAlignment::Over => {
        options.push("marking")
        options.push("allow upside down")
      }
      LabelAlignment::Left => ()
    }

    if edge.options.label_position != 50 {
      options.push(
        ["pos=", (edge.options.label_position.to_double() / 100.0).to_string()].join(""),
      )
    }

    if edge.options.style.name == "arrow" && tikz_is_arrow_body_decoration(edge.options.style.body.name) {
      match edge.options.label_alignment {
        LabelAlignment::Left => options.push("inner sep=.8ex")
        LabelAlignment::Right => options.push("inner sep=.8ex")
        _ => ()
      }
    }
  }
}

fn tikz_append_style_options(options : Array[String], edge : Edge, edge_is_empty : Bool) -> Unit {
  if edge.options.style.name != "arrow" {
    return
  }

  if edge_is_empty {
    options.push("draw=none")
    return
  }

  if edge.options.level == 2 {
    if edge.options.style.head.name == "none" {
      options.push("equals")
    } else {
      options.push("Rightarrow")
    }
  } else if edge.options.level > 2 {
    options.push("Rightarrow")
    options.push(["scaling nfold=", edge.options.level.to_string()].join(""))
  }

  match edge.options.style.body.name {
    "dashed" => options.push("dashed")
    "dotted" => options.push("dotted")
    "squiggly" => options.push("squiggly")
    "none" => options.push("no body")
    _ => ()
  }

  match edge.options.style.tail.name {
    "maps to" => options.push("maps to")
    "mono" => {
      if edge.options.level == 2 {
        options.push("2tail")
      } else {
        options.push("tail")
      }
    }
    "hook" => {
      let suffix = if edge.options.style.tail.side == "top" { "" } else { "'" }
      options.push(["hook", suffix].join(""))
    }
    "arrowhead" => {
      if edge.options.level == 2 {
        options.push("2tail reversed")
      } else {
        options.push("tail reversed")
      }
    }
    _ => ()
  }

  match edge.options.style.head.name {
    "none" => if edge.options.level != 2 { options.push("no head") }
    "epi" => options.push("two heads")
    "harpoon" => {
      let suffix = if edge.options.style.head.side == "top" { "" } else { "'" }
      options.push(["harpoon", suffix].join(""))
    }
    _ => ()
  }
}

fn tikz_append_shift_and_curve_options(options : Array[String], edge : Edge) -> Unit {
  if edge.options.offset != 0 {
    let side = if edge.options.offset > 0 { "right" } else { "left" }
    let abs_offset = Int::abs(edge.options.offset)
    if abs_offset == 1 {
      options.push(["shift ", side].join(""))
    } else {
      options.push(["shift ", side, "=", abs_offset.to_string()].join(""))
    }
  }

  if edge.options.curve != 0 {
    // Keep a compact fixed mapping in pt for minimum viable parity.
    let curve_height_pt = edge.options.curve.to_double() * 6.0
    options.push(["curve={height=", curve_height_pt.to_string(), "pt}"].join(""))
  }
}

fn tikz_append_geometry_options(options : Array[String], edge : Edge) -> Unit {
  tikz_append_shift_and_curve_options(options, edge)

  if edge.options.shorten.source != 0 || edge.options.shorten.target != 0 {
    let source = edge.options.shorten.source.to_double() / 100.0
    let target = (100 - edge.options.shorten.target).to_double() / 100.0
    options.push(["between={", source.to_string(), "}{", target.to_string(), "}"].join(""))
  }
}

fn tikz_append_phantom_geometry_options(options : Array[String], edge : Edge) -> Unit {
  tikz_append_shift_and_curve_options(options, edge)
}

fn tikz_append_arrow_body_decorations(options : Array[String], edge : Edge) -> Unit {
  if edge.options.style.name != "arrow" {
    return
  }

  let midpoint_numerator = edge.options.shorten.source + (100 - edge.options.shorten.target)
  let has_custom_midpoint = midpoint_numerator != 100
  let midpoint = midpoint_numerator.to_double() / 200.0

  let with_midpoint = (parameters : Array[String]) => {
    if has_custom_midpoint {
      parameters.push(["pos=", midpoint.to_string()].join(""))
    }
  }

  let with_edge_colour = (parameters : Array[String]) => {
    if edge.options.colour.is_not_black() {
      parameters.push(["text=", tikz_colour_spec(edge.options.colour)].join(""))
    }
  }

  match edge.options.style.body.name {
    "barred" => {
      let parameters : Array[String] = ["marking"]
      with_midpoint(parameters)
      with_edge_colour(parameters)
      options.push(tikz_decoration_option("\\shortmid", parameters))
    }
    "double barred" => {
      let parameters : Array[String] = ["marking"]
      with_midpoint(parameters)
      with_edge_colour(parameters)
      options.push(tikz_decoration_option("\\shortmid\\shortmid", parameters))
    }
    "bullet solid" => {
      let parameters : Array[String] = ["marking"]
      with_midpoint(parameters)
      with_edge_colour(parameters)
      options.push(tikz_decoration_option("\\bullet", parameters))
    }
    "bullet hollow" => {
      let background_parameters : Array[String] = [
        "marking",
        "text=\\pgfkeysvalueof{/tikz/commutative diagrams/background color}",
      ]
      with_midpoint(background_parameters)
      options.push(tikz_decoration_option("\\bullet", background_parameters))

      let outline_parameters : Array[String] = ["marking"]
      with_midpoint(outline_parameters)
      with_edge_colour(outline_parameters)
      options.push(tikz_decoration_option("\\circ", outline_parameters))
    }
    _ => ()
  }
}

fn tikz_append_loop_options(
  options : Array[String],
  edge : Edge,
  source_vertex : Vertex?,
  target_vertex : Vertex?,
) -> Unit {
  if edge.source != edge.target {
    return
  }

  match (source_vertex, target_vertex) {
    (Some(_), Some(_)) => ()
    _ => return
  }

  options.push("loop")
  let clockwise = if edge.options.radius >= 0 { 1.0 } else { -1.0 }
  let loop_angle = 180.0 - 90.0 * clockwise - edge.options.angle.to_double()
  let angle_spread = 30.0 + 5.0 * (Int::abs(edge.options.radius).to_double() - 1.0) / 2.0
  let in_angle = tikz_mod(loop_angle - angle_spread * clockwise, 360.0)
  let out_angle = tikz_mod(loop_angle + angle_spread * clockwise, 360.0)
  let distance = 5.0 + 5.0 * (Int::abs(edge.options.radius).to_double() - 1.0) / 2.0

  options.push(["in=", in_angle.to_string()].join(""))
  options.push(["out=", out_angle.to_string()].join(""))
  options.push(["distance=", distance.to_string(), "mm"].join(""))
}

fn tikz_decoration_option(content : String, parameters : Array[String]) -> String {
  if parameters.is_empty() {
    ["\"", content, "\""].join("")
  } else {
    ["\"", content, "\"{", parameters.join(", "), "}"].join("")
  }
}

fn tikz_append_non_arrow_style_options(
  options : Array[String],
  edge : Edge,
  shared_colour : Bool,
  source : Vertex?,
  target : Vertex?,
) -> Unit {
  let angle_deg = match (source, target) {
    (Some(source_vertex), Some(target_vertex)) => tikz_edge_angle_deg(source_vertex, target_vertex)
    _ => 0.0
  }
  let decoration_text = !shared_colour && edge.options.style.name != "arrow" &&
    edge.options.colour.is_not_black()

  match edge.options.style.name {
    "adjunction" => {
      let rotate = -tikz_round_to_int(angle_deg)
      let parameters : Array[String] = ["anchor=center"]
      if decoration_text {
        parameters.push(["text=", tikz_colour_spec(edge.options.colour)].join(""))
      }
      if rotate != 0 {
        parameters.push(["rotate=", rotate.to_string()].join(""))
      }
      options.push("draw=none")
      options.push(tikz_decoration_option("\\dashv", parameters))
    }
    "corner" => {
      let rotate = 45 - 45 * tikz_round_to_int(angle_deg / 45.0)
      let parameters : Array[String] = ["anchor=center", "pos=0.125"]
      if decoration_text {
        parameters.push(["text=", tikz_colour_spec(edge.options.colour)].join(""))
      }
      if rotate != 0 {
        parameters.push(["rotate=", rotate.to_string()].join(""))
      }
      options.push("draw=none")
      options.push(tikz_decoration_option("\\lrcorner", parameters))
    }
    "corner-inverse" => {
      let rotate = 45 - 45 * tikz_round_to_int(angle_deg / 45.0)
      let parameters : Array[String] = ["anchor=center", "pos=0.125"]
      if decoration_text {
        parameters.push(["text=", tikz_colour_spec(edge.options.colour)].join(""))
      }
      if rotate != 0 {
        parameters.push(["rotate=", rotate.to_string()].join(""))
      }
      options.push("draw=none")
      options.push(tikz_decoration_option("\\ulcorner", parameters))
    }
    _ => ()
  }
}

pub fn Quiver::export_tikz_cd(
  self : Quiver,
  settings~ : TikzCdExportSettings = TikzCdExportSettings::default(),
) -> String {
  let vertices_by_id : @hashmap.HashMap[Int, Vertex] = @hashmap.new()
  let edges_by_id : @hashmap.HashMap[Int, Edge] = @hashmap.new()
  let edges : Array[Edge] = []

  let mut has_vertex = false
  let mut min_x = 0
  let mut max_x = 0
  let mut min_y = 0
  let mut max_y = 0

  for cell in self.all_cells() {
    match cell {
      CellData::Vertex(vertex) => {
        vertices_by_id.set(vertex.cell.id, vertex)
        if !has_vertex {
          has_vertex = true
          min_x = vertex.x
          max_x = vertex.x
          min_y = vertex.y
          max_y = vertex.y
        } else {
          min_x = Int::min(min_x, vertex.x)
          max_x = Int::max(max_x, vertex.x)
          min_y = Int::min(min_y, vertex.y)
          max_y = Int::max(max_y, vertex.y)
        }
      }
      CellData::Edge(edge) => {
        edges_by_id.set(edge.cell.id, edge)
        edges.push(edge)
      }
    }
  }

  let begin_line = tikz_begin_line(settings)
  if !has_vertex {
    let empty = [begin_line, "\n\\end{tikzcd}"].join("")
    return tikz_wrap_output(settings, empty)
  }

  let vertex_id_by_coord : @hashmap.HashMap[String, Int] = @hashmap.new()
  vertices_by_id.each((id, vertex) => {
    vertex_id_by_coord.set(tikz_coord_key(vertex.x, vertex.y), id)
  })

  edges.sort_by((a, b) => tikz_compare_edges(vertices_by_id, edges_by_id, a, b))

  let referenced_edges : @hashmap.HashMap[Int, Bool] = @hashmap.new()
  let phantom_referenced_edges : @hashmap.HashMap[Int, Bool] = @hashmap.new()
  for edge in edges {
    if edges_by_id.contains(edge.source) {
      referenced_edges.set(edge.source, true)
      if !edge.options.edge_alignment.source {
        phantom_referenced_edges.set(edge.source, true)
      }
    }
    if edges_by_id.contains(edge.target) {
      referenced_edges.set(edge.target, true)
      if !edge.options.edge_alignment.target {
        phantom_referenced_edges.set(edge.target, true)
      }
    }
  }

  let outgoing_arrows : @hashmap.HashMap[Int, Array[String]] = @hashmap.new()
  for edge in edges {
    match (
      tikz_cell_reference(
        edge.source,
        min_x,
        min_y,
        !edge.options.edge_alignment.source,
        vertices_by_id,
        edges_by_id,
      ),
      tikz_cell_reference(
        edge.target,
        min_x,
        min_y,
        !edge.options.edge_alignment.target,
        vertices_by_id,
        edges_by_id,
      ),
    ) {
      (Some(source_ref), Some(target_ref)) => {
        let source_vertex = vertices_by_id.get(edge.source)
        let target_vertex = vertices_by_id.get(edge.target)
        let source_anchor = tikz_resolve_vertex(edge.source, vertices_by_id, edges_by_id, true)
        let target_anchor = tikz_resolve_vertex(edge.target, vertices_by_id, edges_by_id, false)

        let arrow_options : Array[String] = []
        if referenced_edges.contains(edge.cell.id) {
          arrow_options.push(tikz_named_placeholder(tikz_edge_name(edge.cell.id)))
        }

        match (source_vertex, target_vertex) {
          (Some(source), Some(target)) => {
            match tikz_direction_option(source, target) {
              Some(direction) => arrow_options.push(direction)
              None => {
                arrow_options.push(["from=", source_ref].join(""))
                arrow_options.push(["to=", target_ref].join(""))
              }
            }
          }
          _ => {
            arrow_options.push(["from=", source_ref].join(""))
            arrow_options.push(["to=", target_ref].join(""))
          }
        }

        let edge_is_empty = tikz_edge_is_empty(edge)
        let shared_colour = tikz_shared_colour(edge)
        let explicit_label_colour = tikz_append_colour_options(
          arrow_options,
          edge,
          edge_is_empty,
        )
        let label_content = tikz_edge_label_content(edge, explicit_label_colour)
        tikz_append_label_options(arrow_options, edge, label_content)
        tikz_append_arrow_body_decorations(arrow_options, edge)
        tikz_append_geometry_options(arrow_options, edge)
        tikz_append_loop_options(
          arrow_options,
          edge,
          source_vertex,
          target_vertex,
        )
        tikz_append_non_arrow_style_options(
          arrow_options,
          edge,
          shared_colour,
          source_anchor,
          target_anchor,
        )
        tikz_append_style_options(arrow_options, edge, edge_is_empty)

        let arrow = ["\\arrow[", arrow_options.join(", "), "]"].join("")
        match source_anchor {
          Some(anchor) => {
            let list = outgoing_arrows.get_or_init(anchor.cell.id, () => [])
            list.push(arrow)
            if phantom_referenced_edges.contains(edge.cell.id) {
              let phantom_options : Array[String] = []
              phantom_options.push(
                tikz_named_placeholder(tikz_edge_reference_name(edge.cell.id, true)),
              )
              phantom_options.push("phantom")
              phantom_options.push(["from=", source_ref].join(""))
              phantom_options.push(["to=", target_ref].join(""))
              phantom_options.push("start anchor=center")
              phantom_options.push("end anchor=center")
              tikz_append_phantom_geometry_options(phantom_options, edge)
              list.push(["\\arrow[", phantom_options.join(", "), "]"].join(""))
            }
          }
          None => ()
        }
      }
      _ => ()
    }
  }

  let column_separator = if settings.ampersand_replacement {
    " \\& "
  } else {
    " & "
  }
  let rows : Array[String] = []
  for y in min_y..=max_y {
    let columns : Array[String] = []
    for x in min_x..=max_x {
      let content = match vertex_id_by_coord.get(tikz_coord_key(x, y)) {
        Some(vertex_id) => {
          let label = match vertices_by_id.get(vertex_id) {
            Some(vertex) => tikz_vertex_label(vertex)
            None => ""
          }
          let arrows = match outgoing_arrows.get(vertex_id) {
            Some(list) => list
            None => []
          }
          let arrow_text = arrows.join(" ")
          if label == "" {
            arrow_text
          } else if arrow_text == "" {
            label
          } else {
            [label, " ", arrow_text].join("")
          }
        }
        None => ""
      }
      columns.push(content)
    }
    rows.push(columns.join(column_separator))
  }

  let body = rows.join(" \\\\\n")
  let tikzcd = [begin_line, "\n", body, "\n\\end{tikzcd}"].join("")
  tikz_wrap_output(settings, tikzcd)
}
