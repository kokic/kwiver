///|
pub struct TikzCdExportSettings {
  centre_diagram : Bool
  ampersand_replacement : Bool
  cramped : Bool
  standalone : Bool
}

///|
pub struct TikzCdSepOptions {
  column_hundredths : Int
  row_hundredths : Int
}

///|
pub struct TikzCdExportOptions {
  sep : TikzCdSepOptions
  share_base_url : String?
  macro_url : String?
  renderer : String?
}

///|
pub struct TikzCdExportDefinitions {
  colours : @hashmap.HashMap[String, Colour]
}

///|
pub struct TikzCdExportMetadata {
  tikz_incompatibilities : Array[String]
  dependencies : @hashmap.HashMap[String, @hashmap.HashMap[String, Bool]]
}

///|
pub struct TikzCdExportResult {
  data : String
  metadata : TikzCdExportMetadata
}

///|
pub fn TikzCdExportSettings::default() -> TikzCdExportSettings {
  {
    centre_diagram: false,
    ampersand_replacement: false,
    cramped: false,
    standalone: false,
  }
}

///|
pub fn TikzCdExportSettings::with_centre_diagram(
  self : TikzCdExportSettings,
  value? : Bool = true,
) -> TikzCdExportSettings {
  {
    centre_diagram: value,
    ampersand_replacement: self.ampersand_replacement,
    cramped: self.cramped,
    standalone: self.standalone,
  }
}

///|
pub fn TikzCdExportSettings::with_ampersand_replacement(
  self : TikzCdExportSettings,
  value? : Bool = true,
) -> TikzCdExportSettings {
  {
    centre_diagram: self.centre_diagram,
    ampersand_replacement: value,
    cramped: self.cramped,
    standalone: self.standalone,
  }
}

///|
pub fn TikzCdExportSettings::with_cramped(
  self : TikzCdExportSettings,
  value? : Bool = true,
) -> TikzCdExportSettings {
  {
    centre_diagram: self.centre_diagram,
    ampersand_replacement: self.ampersand_replacement,
    cramped: value,
    standalone: self.standalone,
  }
}

///|
pub fn TikzCdExportSettings::with_standalone(
  self : TikzCdExportSettings,
  value? : Bool = true,
) -> TikzCdExportSettings {
  {
    centre_diagram: self.centre_diagram,
    ampersand_replacement: self.ampersand_replacement,
    cramped: self.cramped,
    standalone: value,
  }
}

///|
pub fn TikzCdSepOptions::default() -> TikzCdSepOptions {
  { column_hundredths: 180, row_hundredths: 180 }
}

///|
pub fn TikzCdSepOptions::with_column_em(
  self : TikzCdSepOptions,
  value : Double,
) -> TikzCdSepOptions {
  {
    column_hundredths: tikz_round_to_int(value * 100.0),
    row_hundredths: self.row_hundredths,
  }
}

///|
pub fn TikzCdSepOptions::with_row_em(
  self : TikzCdSepOptions,
  value : Double,
) -> TikzCdSepOptions {
  {
    column_hundredths: self.column_hundredths,
    row_hundredths: tikz_round_to_int(value * 100.0),
  }
}

///|
pub fn TikzCdSepOptions::with_em(
  _self : TikzCdSepOptions,
  value : Double,
) -> TikzCdSepOptions {
  let hundredths = tikz_round_to_int(value * 100.0)
  { column_hundredths: hundredths, row_hundredths: hundredths }
}

///|
pub fn TikzCdExportOptions::default() -> TikzCdExportOptions {
  {
    sep: TikzCdSepOptions::default(),
    share_base_url: None,
    macro_url: None,
    renderer: None,
  }
}

///|
pub fn TikzCdExportOptions::with_sep(
  self : TikzCdExportOptions,
  sep : TikzCdSepOptions,
) -> TikzCdExportOptions {
  {
    sep,
    share_base_url: self.share_base_url,
    macro_url: self.macro_url,
    renderer: self.renderer,
  }
}

///|
pub fn TikzCdExportOptions::with_column_sep_em(
  self : TikzCdExportOptions,
  value : Double,
) -> TikzCdExportOptions {
  {
    sep: self.sep.with_column_em(value),
    share_base_url: self.share_base_url,
    macro_url: self.macro_url,
    renderer: self.renderer,
  }
}

///|
pub fn TikzCdExportOptions::with_row_sep_em(
  self : TikzCdExportOptions,
  value : Double,
) -> TikzCdExportOptions {
  {
    sep: self.sep.with_row_em(value),
    share_base_url: self.share_base_url,
    macro_url: self.macro_url,
    renderer: self.renderer,
  }
}

///|
pub fn TikzCdExportOptions::with_sep_em(
  self : TikzCdExportOptions,
  value : Double,
) -> TikzCdExportOptions {
  {
    sep: TikzCdSepOptions::default().with_em(value),
    share_base_url: self.share_base_url,
    macro_url: self.macro_url,
    renderer: self.renderer,
  }
}

///|
pub fn TikzCdExportOptions::with_share_base_url(
  self : TikzCdExportOptions,
  base_url : String,
) -> TikzCdExportOptions {
  {
    sep: self.sep,
    share_base_url: Some(base_url),
    macro_url: self.macro_url,
    renderer: self.renderer,
  }
}

///|
pub fn TikzCdExportOptions::without_share_base_url(
  self : TikzCdExportOptions,
) -> TikzCdExportOptions {
  {
    sep: self.sep,
    share_base_url: None,
    macro_url: self.macro_url,
    renderer: self.renderer,
  }
}

///|
pub fn TikzCdExportOptions::with_macro_url(
  self : TikzCdExportOptions,
  macro_url : String,
) -> TikzCdExportOptions {
  {
    sep: self.sep,
    share_base_url: self.share_base_url,
    macro_url: Some(macro_url),
    renderer: self.renderer,
  }
}

///|
pub fn TikzCdExportOptions::without_macro_url(
  self : TikzCdExportOptions,
) -> TikzCdExportOptions {
  {
    sep: self.sep,
    share_base_url: self.share_base_url,
    macro_url: None,
    renderer: self.renderer,
  }
}

///|
pub fn TikzCdExportOptions::with_renderer(
  self : TikzCdExportOptions,
  renderer : String,
) -> TikzCdExportOptions {
  {
    sep: self.sep,
    share_base_url: self.share_base_url,
    macro_url: self.macro_url,
    renderer: Some(renderer),
  }
}

///|
pub fn TikzCdExportOptions::without_renderer(
  self : TikzCdExportOptions,
) -> TikzCdExportOptions {
  {
    sep: self.sep,
    share_base_url: self.share_base_url,
    macro_url: self.macro_url,
    renderer: None,
  }
}

///|
pub fn TikzCdExportDefinitions::default() -> TikzCdExportDefinitions {
  { colours: @hashmap.new() }
}

///|
pub fn TikzCdExportDefinitions::with_colour(
  self : TikzCdExportDefinitions,
  name : String,
  colour : Colour,
) -> TikzCdExportDefinitions {
  self.colours.set(name, colour)
  self
}

///|
fn tikz_escape_label(label : String) -> String {
  label.replace_all(old="\"", new="\\\"")
}

///|
fn tikz_is_simple_label(label : String) -> Bool {
  let bytes = @utf8.encode(label)
  if bytes.length() == 0 {
    return false
  }

  let mut i = 0
  if bytes.unsafe_get(0) == b'\\' {
    if bytes.length() == 1 {
      return false
    }
    i = 1
  }

  while i < bytes.length() {
    let code = bytes.unsafe_get(i).to_int()
    let is_digit = code >= 48 && code <= 57
    let is_upper = code >= 65 && code <= 90
    let is_lower = code >= 97 && code <= 122
    if !(is_digit || is_upper || is_lower) {
      return false
    }
    i = i + 1
  }
  true
}

///|
fn tikz_format_label(label : String) -> String {
  let escaped = tikz_escape_label(label)
  if escaped.contains("\\\\") {
    return ["\\begin{array}{c} ", escaped, " \\end{array}"].join("")
  }
  if !tikz_is_simple_label(escaped) {
    ["{", escaped, "}"].join("")
  } else {
    escaped
  }
}

///|
fn tikz_begin_line(
  settings : TikzCdExportSettings,
  options_config : TikzCdExportOptions,
) -> String {
  let options : Array[String] = []
  if settings.ampersand_replacement {
    options.push("ampersand replacement=\\&")
  }
  if settings.cramped {
    options.push("cramped")
  }
  let column_sep = tikz_sep_option_name(options_config.sep.column_hundredths)
  let row_sep = tikz_sep_option_name(options_config.sep.row_hundredths)
  if column_sep == row_sep {
    if column_sep != "normal" {
      options.push(["sep=", column_sep].join(""))
    }
  } else {
    if column_sep != "normal" {
      options.push(["column sep=", column_sep].join(""))
    }
    if row_sep != "normal" {
      options.push(["row sep=", row_sep].join(""))
    }
  }

  if options.is_empty() {
    "\\begin{tikzcd}"
  } else {
    ["\\begin{tikzcd}[", options.join(","), "]"].join("")
  }
}

///|
fn tikz_fixed_2(value : Int) -> String {
  let sign = if value < 0 { "-" } else { "" }
  let abs_value = Int::abs(value)
  let whole = abs_value / 100
  let frac = abs_value % 100
  let frac_string = if frac < 10 {
    ["0", frac.to_string()].join("")
  } else {
    frac.to_string()
  }
  [sign, whole.to_string(), ".", frac_string].join("")
}

///|
fn tikz_sep_option_name(value : Int) -> String {
  match value {
    45 => "tiny"
    90 => "small"
    135 => "scriptsize"
    180 => "normal"
    270 => "large"
    360 => "huge"
    _ => [tikz_fixed_2(value), "em"].join("")
  }
}

///|
fn tikz_wrap_output(
  quiver : Quiver,
  settings : TikzCdExportSettings,
  options_config : TikzCdExportOptions,
  tikzcd : String,
) -> String {
  let wrapped = if settings.standalone {
    [
      "\\documentclass[tikz]{standalone}\n\\usepackage{quiver}\n\\begin{document}\n",
      tikzcd, "\n\\end{document}",
    ].join("")
  } else if settings.centre_diagram {
    ["\\[", tikzcd, "\\]"].join("")
  } else {
    tikzcd
  }
  [
    "% ",
    quiver.export_base64_share_url(
      options_config.share_base_url,
      options_config.macro_url,
      renderer?=options_config.renderer,
    ),
    "\n",
    wrapped,
  ].join("")
}

///|
fn tikz_indent_lines(content : String) -> String {
  if content == "" {
    ""
  } else {
    ["\t", content.replace_all(old="\n", new="\n\t")].join("")
  }
}

///|
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

///|
fn tikz_mod(x : Double, y : Double) -> Double {
  let r = x - y * @math.floor(x / y)
  if r < 0.0 {
    r + y
  } else {
    r
  }
}

///|
fn tikz_round_to_int(x : Double) -> Int {
  if x >= 0.0 {
    @math.floor(x + 0.5).to_int()
  } else {
    -@math.floor(-x + 0.5).to_int()
  }
}

///|
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
  if direction == "" {
    None
  } else {
    Some(direction)
  }
}

///|
fn tikz_max_double(a : Double, b : Double) -> Double {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn tikz_min_double(a : Double, b : Double) -> Double {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn tikz_min3_double(a : Double, b : Double, c : Double) -> Double {
  tikz_min_double(a, tikz_min_double(b, c))
}

///|
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

///|
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

///|
fn tikz_builtin_colour_name(colour : Colour) -> String? {
  if colour.l == 0 {
    return Some("black")
  }
  if colour.l == 100 {
    return Some("white")
  }
  if colour.a != 1.0 {
    return None
  }

  if colour.h == 0 && colour.s == 100 && colour.l == 50 {
    return Some("red")
  }
  if colour.h == 120 && colour.s == 100 && colour.l == 25 {
    return Some("green")
  }
  if colour.h == 240 && colour.s == 100 && colour.l == 50 {
    return Some("blue")
  }
  None
}

///|
fn tikz_wrap_colour_name(name : String, parenthesise : Bool) -> String {
  if parenthesise {
    ["{", name, "}"].join("")
  } else {
    name
  }
}

///|
fn tikz_colour_latex(
  colour : Colour,
  definitions : TikzCdExportDefinitions,
  parenthesise : Bool,
) -> String {
  match tikz_builtin_colour_name(colour) {
    Some(name) => return tikz_wrap_colour_name(name, parenthesise)
    None => ()
  }

  let colour_names = Array::from_iter(definitions.colours.keys())
  colour_names.sort()
  for name in colour_names {
    match definitions.colours.get(name) {
      Some(defined_colour) =>
        if tikz_colour_eq(defined_colour, colour) {
          return tikz_wrap_colour_name(name, parenthesise)
        }
      None => ()
    }
  }

  tikz_colour_spec(colour)
}

///|
fn tikz_coloured_text(
  label : String,
  colour : Colour,
  definitions : TikzCdExportDefinitions,
) -> String {
  [
    "\\textcolor",
    tikz_colour_latex(colour, definitions, true),
    "{",
    tikz_format_label(label),
    "}",
  ].join("")
}

///|
fn tikz_colour_eq(a : Colour, b : Colour) -> Bool {
  let exact = a.h == b.h && a.s == b.s && a.l == b.l && a.a == b.a
  exact || (a.l == 0 && b.l == 0) || (a.l == 100 && b.l == 100)
}

///|
fn tikz_edge_is_empty(edge : Edge) -> Bool {
  let is_arrow = edge.options.style.name == "arrow"
  let no_head = edge.options.style.head.name == "none"
  let no_body = edge.options.style.body.name == "none"
  let no_tail = edge.options.style.tail.name == "none"
  is_arrow && no_head && no_body && no_tail
}

///|
fn tikz_shared_colour(edge : Edge) -> Bool {
  tikz_colour_eq(edge.options.colour, edge.cell.label_colour) &&
  edge.cell.label_colour.is_not_black()
}

///|
fn tikz_append_colour_options(
  options : Array[String],
  edge : Edge,
  edge_is_empty : Bool,
  definitions : TikzCdExportDefinitions,
) -> Bool {
  if tikz_shared_colour(edge) {
    options.push(
      ["color=", tikz_colour_latex(edge.cell.label_colour, definitions, false)].join(
        "",
      ),
    )
    false
  } else {
    if !edge_is_empty &&
      edge.options.style.name == "arrow" &&
      edge.options.colour.is_not_black() {
      options.push(
        ["draw=", tikz_colour_latex(edge.options.colour, definitions, false)].join(
          "",
        ),
      )
    }
    edge.cell.label_colour.is_not_black()
  }
}

///|
fn tikz_edge_label_content(edge : Edge, _explicit_colour : Bool) -> String {
  if edge.cell.label == "" {
    return ""
  }
  tikz_format_label(edge.cell.label)
}

///|
fn tikz_vertex_label(
  vertex : Vertex,
  definitions : TikzCdExportDefinitions,
) -> String {
  if vertex.cell.label == "" {
    ""
  } else if vertex.cell.label_colour.is_not_black() {
    tikz_coloured_text(vertex.cell.label, vertex.cell.label_colour, definitions)
  } else {
    tikz_format_label(vertex.cell.label)
  }
}

///|
fn tikz_edge_coord_part(vertex : Vertex?) -> (Int, Int) {
  match vertex {
    Some(v) => (v.y, v.x)
    None => (2147483647, 2147483647)
  }
}

///|
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
      Some(edge) =>
        current = if pick_source { edge.source } else { edge.target }
      None => return None
    }
    i = i + 1
  }
  None
}

///|
fn tikz_edge_reference_name(base_name : String, phantom : Bool) -> String {
  if phantom {
    [base_name, "p"].join("")
  } else {
    base_name
  }
}

///|
fn tikz_named_placeholder(name : String) -> String {
  ["\"\"{name=", name, ", anchor=center, inner sep=0}"].join("")
}

///|
fn tikz_vertex_reference(vertex : Vertex, min_x : Int, min_y : Int) -> String {
  [(vertex.y - min_y + 1).to_string(), "-", (vertex.x - min_x + 1).to_string()].join(
    "",
  )
}

///|
fn tikz_cell_reference(
  cell_id : Int,
  min_x : Int,
  min_y : Int,
  phantom : Bool,
  vertices_by_id : @hashmap.HashMap[Int, Vertex],
  edge_export_name_by_id : @hashmap.HashMap[Int, String],
) -> String? {
  match vertices_by_id.get(cell_id) {
    Some(vertex) => Some(tikz_vertex_reference(vertex, min_x, min_y))
    None =>
      match edge_export_name_by_id.get(cell_id) {
        Some(edge_name) => Some(tikz_edge_reference_name(edge_name, phantom))
        None => None
      }
  }
}

///|
fn tikz_vertex_origin(vertex : Vertex) -> Point {
  Point::new(vertex.x.to_double(), vertex.y.to_double())
}

///|
fn tikz_cell_origin(
  cell_id : Int,
  use_phantom : Bool,
  vertices_by_id : @hashmap.HashMap[Int, Vertex],
  edges_by_id : @hashmap.HashMap[Int, Edge],
  depth : Int,
) -> Point? {
  if depth > edges_by_id.length() + 1 {
    return None
  }

  match vertices_by_id.get(cell_id) {
    Some(vertex) => Some(tikz_vertex_origin(vertex))
    None =>
      match edges_by_id.get(cell_id) {
        Some(edge) => {
          let source_origin = tikz_cell_origin(
            edge.source,
            !edge.options.edge_alignment.source,
            vertices_by_id,
            edges_by_id,
            depth + 1,
          )
          let target_origin = tikz_cell_origin(
            edge.target,
            !edge.options.edge_alignment.target,
            vertices_by_id,
            edges_by_id,
            depth + 1,
          )
          match (source_origin, target_origin) {
            (Some(source_point), Some(target_point)) => {
              let t = if use_phantom {
                0.5
              } else {
                let midpoint_numerator = edge.options.shorten.source +
                  (100 - edge.options.shorten.target)
                midpoint_numerator.to_double() / 200.0
              }
              Some(source_point.lerp(target_point, t))
            }
            _ => None
          }
        }
        None => None
      }
  }
}

///|
fn tikz_edge_angle_deg(source : Point, target : Point) -> Double {
  @math.atan2(target.y - source.y, target.x - source.x) * 180.0 / @math.PI
}

///|
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

///|
fn tikz_is_arrow_body_decoration(style_body : String) -> Bool {
  match style_body {
    "barred" => true
    "double barred" => true
    "bullet solid" => true
    "bullet hollow" => true
    _ => false
  }
}

///|
fn tikz_label_option(
  content : String,
  swap : Bool,
  parameters : Array[String],
) -> String {
  let base = if swap {
    ["\"", content, "\"'"].join("")
  } else {
    ["\"", content, "\""].join("")
  }
  if parameters.is_empty() {
    base
  } else {
    [base, "{", parameters.join(", "), "}"].join("")
  }
}

///|
fn tikz_append_label_options(
  options : Array[String],
  edge : Edge,
  label_content : String,
  explicit_label_colour : Bool,
  definitions : TikzCdExportDefinitions,
) -> Unit {
  if label_content != "" {
    let label_parameters : Array[String] = []
    let swap = match edge.options.label_alignment {
      LabelAlignment::Right => true
      _ => false
    }
    match edge.options.label_alignment {
      LabelAlignment::Right => ()
      LabelAlignment::Centre => label_parameters.push("description")
      LabelAlignment::Over => {
        label_parameters.push("marking")
        label_parameters.push("allow upside down")
      }
      LabelAlignment::Left => ()
    }

    if edge.options.label_position != 50 {
      label_parameters.push(
        ["pos=", (edge.options.label_position.to_double() / 100.0).to_string()].join(
          "",
        ),
      )
    }

    if edge.options.style.name == "arrow" &&
      tikz_is_arrow_body_decoration(edge.options.style.body.name) {
      match edge.options.label_alignment {
        LabelAlignment::Left => label_parameters.push("inner sep=.8ex")
        LabelAlignment::Right => label_parameters.push("inner sep=.8ex")
        _ => ()
      }
    }

    if explicit_label_colour && edge.cell.label_colour.is_not_black() {
      label_parameters.push(
        ["text=", tikz_colour_latex(edge.cell.label_colour, definitions, false)].join(
          "",
        ),
      )
    }

    options.push(tikz_label_option(label_content, swap, label_parameters))
  }
}

///|
fn tikz_append_style_options(
  options : Array[String],
  edge : Edge,
  edge_is_empty : Bool,
) -> Unit {
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
    "mono" =>
      if edge.options.level == 2 {
        options.push("2tail")
      } else {
        options.push("tail")
      }
    "hook" => {
      let suffix = if edge.options.style.tail.side == "top" { "" } else { "'" }
      options.push(["hook", suffix].join(""))
    }
    "arrowhead" =>
      if edge.options.level == 2 {
        options.push("2tail reversed")
      } else {
        options.push("tail reversed")
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

///|
fn tikz_append_shift_and_curve_options(
  options : Array[String],
  edge : Edge,
) -> Unit {
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
    options.push(
      ["curve={height=", curve_height_pt.to_string(), "pt}"].join(""),
    )
  }
}

///|
fn tikz_append_geometry_options(options : Array[String], edge : Edge) -> Unit {
  tikz_append_shift_and_curve_options(options, edge)

  if edge.options.shorten.source != 0 || edge.options.shorten.target != 0 {
    let source = edge.options.shorten.source.to_double() / 100.0
    let target = (100 - edge.options.shorten.target).to_double() / 100.0
    options.push(
      ["between={", source.to_string(), "}{", target.to_string(), "}"].join(""),
    )
  }
}

///|
fn tikz_append_phantom_geometry_options(
  options : Array[String],
  edge : Edge,
) -> Unit {
  tikz_append_shift_and_curve_options(options, edge)
}

///|
fn tikz_append_arrow_body_decorations(
  options : Array[String],
  edge : Edge,
  definitions : TikzCdExportDefinitions,
) -> Unit {
  if edge.options.style.name != "arrow" {
    return
  }

  let midpoint_numerator = edge.options.shorten.source +
    (100 - edge.options.shorten.target)
  let has_custom_midpoint = midpoint_numerator != 100
  let midpoint = midpoint_numerator.to_double() / 200.0

  let with_midpoint = (parameters : Array[String]) => {
    if has_custom_midpoint {
      parameters.push(["pos=", midpoint.to_string()].join(""))
    }
  }

  let with_edge_colour = (parameters : Array[String]) => {
    if edge.options.colour.is_not_black() {
      parameters.push(
        ["text=", tikz_colour_latex(edge.options.colour, definitions, false)].join(
          "",
        ),
      )
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
        "marking", "text=\\pgfkeysvalueof{/tikz/commutative diagrams/background color}",
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

///|
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
  let angle_spread = 30.0 +
    5.0 * (Int::abs(edge.options.radius).to_double() - 1.0) / 2.0
  let in_angle = tikz_mod(loop_angle - angle_spread * clockwise, 360.0)
  let out_angle = tikz_mod(loop_angle + angle_spread * clockwise, 360.0)
  let distance = 5.0 +
    5.0 * (Int::abs(edge.options.radius).to_double() - 1.0) / 2.0

  options.push(["in=", in_angle.to_string()].join(""))
  options.push(["out=", out_angle.to_string()].join(""))
  options.push(["distance=", distance.to_string(), "mm"].join(""))
}

///|
fn tikz_decoration_option(
  content : String,
  parameters : Array[String],
) -> String {
  if parameters.is_empty() {
    ["\"", content, "\""].join("")
  } else {
    ["\"", content, "\"{", parameters.join(", "), "}"].join("")
  }
}

///|
fn tikz_append_non_arrow_style_options(
  options : Array[String],
  edge : Edge,
  shared_colour : Bool,
  source : Point?,
  target : Point?,
  definitions : TikzCdExportDefinitions,
) -> Unit {
  let angle_deg = if edge.source == edge.target {
    edge.options.angle.to_double()
  } else {
    match (source, target) {
      (Some(source_point), Some(target_point)) =>
        tikz_edge_angle_deg(source_point, target_point)
      _ => 0.0
    }
  }
  let decoration_text = !shared_colour &&
    edge.options.style.name != "arrow" &&
    edge.options.colour.is_not_black()

  match edge.options.style.name {
    "adjunction" => {
      let rotate = -tikz_round_to_int(angle_deg)
      let parameters : Array[String] = ["anchor=center"]
      if decoration_text {
        parameters.push(
          ["text=", tikz_colour_latex(edge.options.colour, definitions, false)].join(
            "",
          ),
        )
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
        parameters.push(
          ["text=", tikz_colour_latex(edge.options.colour, definitions, false)].join(
            "",
          ),
        )
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
        parameters.push(
          ["text=", tikz_colour_latex(edge.options.colour, definitions, false)].join(
            "",
          ),
        )
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

///|
fn tikz_sorted_keys(values : @hashmap.HashMap[String, Bool]) -> Array[String] {
  let keys = Array::from_iter(values.keys())
  keys.sort()
  keys
}

///|
fn tikz_add_dependency(
  dependencies : @hashmap.HashMap[String, @hashmap.HashMap[String, Bool]],
  package_name : String,
  reason : String,
) -> Unit {
  let reasons = dependencies.get_or_init(package_name, () => @hashmap.new())
  reasons.set(reason, true)
}

///|
fn tikz_add_incompatibility(
  incompatibilities : @hashmap.HashMap[String, Bool],
  warning : String,
) -> Unit {
  incompatibilities.set(warning, true)
}

///|
fn tikz_finalize_metadata(
  incompatibilities : @hashmap.HashMap[String, Bool],
  dependencies : @hashmap.HashMap[String, @hashmap.HashMap[String, Bool]],
) -> TikzCdExportMetadata {
  let dependencies_copy : @hashmap.HashMap[
    String,
    @hashmap.HashMap[String, Bool],
  ] = @hashmap.new()
  dependencies.each((package_name, reasons_set) => {
    let reasons_copy : @hashmap.HashMap[String, Bool] = @hashmap.new()
    reasons_set.each((reason, _) => reasons_copy.set(reason, true))
    dependencies_copy.set(package_name, reasons_copy)
  })

  {
    tikz_incompatibilities: tikz_sorted_keys(incompatibilities),
    dependencies: dependencies_copy,
  }
}

///|
pub fn Quiver::export_tikz_cd_result(
  self : Quiver,
  settings? : TikzCdExportSettings = TikzCdExportSettings::default(),
  options? : TikzCdExportOptions = TikzCdExportOptions::default(),
  definitions? : TikzCdExportDefinitions = TikzCdExportDefinitions::default(),
) -> TikzCdExportResult {
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

  let begin_line = tikz_begin_line(settings, options)
  let tikz_incompatibilities : @hashmap.HashMap[String, Bool] = @hashmap.new()
  let dependencies : @hashmap.HashMap[String, @hashmap.HashMap[String, Bool]] = @hashmap.new()
  if !has_vertex {
    let empty = [begin_line, "\n\\end{tikzcd}"].join("")
    return {
      data: tikz_wrap_output(self, settings, options, empty),
      metadata: tikz_finalize_metadata(tikz_incompatibilities, dependencies),
    }
  }

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

  let edge_export_name_by_id : @hashmap.HashMap[Int, String] = @hashmap.new()
  let mut edge_name_index = 0
  for edge in edges {
    if referenced_edges.contains(edge.cell.id) {
      edge_export_name_by_id.set(edge.cell.id, edge_name_index.to_string())
      edge_name_index = edge_name_index + 1
    }
  }

  let arrow_lines : Array[String] = []
  for edge in edges {
    match
      (
        tikz_cell_reference(
          edge.source,
          min_x,
          min_y,
          !edge.options.edge_alignment.source,
          vertices_by_id,
          edge_export_name_by_id,
        ),
        tikz_cell_reference(
          edge.target,
          min_x,
          min_y,
          !edge.options.edge_alignment.target,
          vertices_by_id,
          edge_export_name_by_id,
        ),
      ) {
      (Some(source_ref), Some(target_ref)) => {
        let source_vertex = vertices_by_id.get(edge.source)
        let target_vertex = vertices_by_id.get(edge.target)
        let source_origin = tikz_cell_origin(
          edge.source,
          !edge.options.edge_alignment.source,
          vertices_by_id,
          edges_by_id,
          0,
        )
        let target_origin = tikz_cell_origin(
          edge.target,
          !edge.options.edge_alignment.target,
          vertices_by_id,
          edges_by_id,
          0,
        )

        let arrow_options : Array[String] = []
        if referenced_edges.contains(edge.cell.id) {
          match edge_export_name_by_id.get(edge.cell.id) {
            Some(edge_name) =>
              arrow_options.push(tikz_named_placeholder(edge_name))
            None => ()
          }
        }

        match (source_vertex, target_vertex) {
          (Some(source), Some(target)) =>
            match tikz_direction_option(source, target) {
              Some(direction) => arrow_options.push(direction)
              None => {
                arrow_options.push(["from=", source_ref].join(""))
                arrow_options.push(["to=", target_ref].join(""))
              }
            }
          _ => {
            arrow_options.push(["from=", source_ref].join(""))
            arrow_options.push(["to=", target_ref].join(""))
          }
        }

        let edge_is_empty = tikz_edge_is_empty(edge)
        let shared_colour = tikz_shared_colour(edge)
        if !edge_is_empty &&
          (edge.options.shorten.source != 0 || edge.options.shorten.target != 0) {
          tikz_add_dependency(dependencies, "quiver", "shortened arrows")
        }
        let explicit_label_colour = tikz_append_colour_options(
          arrow_options, edge, edge_is_empty, definitions,
        )
        let label_content = tikz_edge_label_content(edge, explicit_label_colour)
        tikz_append_label_options(
          arrow_options, edge, label_content, explicit_label_colour, definitions,
        )
        tikz_append_arrow_body_decorations(arrow_options, edge, definitions)
        tikz_append_geometry_options(arrow_options, edge)
        tikz_append_loop_options(
          arrow_options, edge, source_vertex, target_vertex,
        )
        tikz_append_non_arrow_style_options(
          arrow_options, edge, shared_colour, source_origin, target_origin, definitions,
        )
        tikz_append_style_options(arrow_options, edge, edge_is_empty)

        if edge.options.style.name == "arrow" && edge.options.level > 2 {
          tikz_add_dependency(
            dependencies, "tikz-nfold", "triple arrows or higher",
          )
        }

        if edge.options.level > 1 {
          match edge.options.style.body.name {
            "bullet hollow" =>
              tikz_add_incompatibility(
                tikz_incompatibilities, "double arrows or higher with decorations",
              )
            "bullet solid" =>
              tikz_add_incompatibility(
                tikz_incompatibilities, "double arrows or higher with decorations",
              )
            _ => ()
          }

          if edge.options.style.tail.name == "hook" {
            tikz_add_incompatibility(
              tikz_incompatibilities, "double arrows or higher with hook tails",
            )
          }

          if edge.options.style.head.name == "epi" {
            tikz_add_incompatibility(
              tikz_incompatibilities, "double arrows or higher with multiple heads",
            )
          }
          if edge.options.style.head.name == "harpoon" {
            tikz_add_incompatibility(
              tikz_incompatibilities, "double arrows or higher with harpoon heads",
            )
          }
        }

        let arrow = ["\\arrow[", arrow_options.join(", "), "]"].join("")
        arrow_lines.push(arrow)
        if phantom_referenced_edges.contains(edge.cell.id) {
          match edge_export_name_by_id.get(edge.cell.id) {
            Some(edge_name) => {
              let phantom_options : Array[String] = []
              phantom_options.push(
                tikz_named_placeholder(
                  tikz_edge_reference_name(edge_name, true),
                ),
              )
              phantom_options.push("phantom")
              phantom_options.push(["from=", source_ref].join(""))
              phantom_options.push(["to=", target_ref].join(""))
              phantom_options.push("start anchor=center")
              phantom_options.push("end anchor=center")
              tikz_append_phantom_geometry_options(phantom_options, edge)
              arrow_lines.push(
                ["\\arrow[", phantom_options.join(", "), "]"].join(""),
              )
            }
            None => ()
          }
        }
      }
      _ => ()
    }
  }

  let ampersand = if settings.ampersand_replacement { "\\&" } else { "&" }
  let rows_by_y : @hashmap.HashMap[Int, Array[(Int, Vertex)]] = @hashmap.new()
  let row_indices : Array[Int] = []
  vertices_by_id.each((_, vertex) => {
    if !rows_by_y.contains(vertex.y) {
      row_indices.push(vertex.y)
    }
    let row = rows_by_y.get_or_init(vertex.y, () => [])
    row.push((vertex.x, vertex))
  })
  row_indices.sort()

  let matrix_parts : Array[String] = []
  let mut prev_x = min_x
  let mut prev_y = min_y
  for y in row_indices {
    if y - prev_y > 0 {
      matrix_parts.push(" ")
      matrix_parts.push(tikz_repeat("\\\\\n", y - prev_y))
    }

    let row = rows_by_y.get_or_init(y, () => [])
    row.sort_by((a, b) => a.0 - b.0)

    let mut first_in_row = true
    for entry in row {
      let (x, vertex) = entry
      if x - prev_x > 0 {
        if !first_in_row {
          matrix_parts.push(" ")
        }
        matrix_parts.push(tikz_repeat(ampersand, x - prev_x))
        matrix_parts.push(" ")
      }
      matrix_parts.push(tikz_vertex_label(vertex, definitions))
      prev_x = x
      first_in_row = false
    }

    prev_x = min_x
    prev_y = y
  }

  let matrix_body = matrix_parts.join("")
  let body = if arrow_lines.is_empty() {
    matrix_body
  } else {
    [matrix_body, "\n", arrow_lines.join("\n")].join("")
  }
  let indented_body = tikz_indent_lines(body)
  let tikzcd = if indented_body == "" {
    [begin_line, "\n\\end{tikzcd}"].join("")
  } else {
    [begin_line, "\n", indented_body, "\n\\end{tikzcd}"].join("")
  }
  {
    data: tikz_wrap_output(self, settings, options, tikzcd),
    metadata: tikz_finalize_metadata(tikz_incompatibilities, dependencies),
  }
}

///|
pub fn Quiver::export_tikz_cd(
  self : Quiver,
  settings? : TikzCdExportSettings = TikzCdExportSettings::default(),
  options? : TikzCdExportOptions = TikzCdExportOptions::default(),
  definitions? : TikzCdExportDefinitions = TikzCdExportDefinitions::default(),
) -> String {
  self.export_tikz_cd_result(settings~, options~, definitions~).data
}

///|
fn tikz_trim_left(input : String) -> String {
  let mut start = 0
  while start < input.length() {
    let ch = input.unsafe_get(start)
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
      start = start + 1
      continue
    }
    break
  }
  if start == 0 {
    input
  } else {
    input.unsafe_substring(start~, end=input.length())
  }
}

///|
fn tikz_is_whitespace(ch : UInt16) -> Bool {
  ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r'
}

///|
priv struct TikzEnvironmentBody {
  body : String
  ampersand_replacement : String?
}

///|
priv struct TikzArrowMatch {
  start : Int
  options_start : Int
  open_delimiter : UInt16
  close_delimiter : UInt16
}

///|
priv struct TikzParsedArrow {
  direction : String?
  reverse : Bool
  is_loop : Bool
  is_phantom : Bool
  name : String?
  source_center_anchor : Bool
  target_center_anchor : Bool
  label : String
  from_x : Int?
  from_y : Int?
  from_ref : String?
  to_x : Int?
  to_y : Int?
  to_ref : String?
  options : EdgeOptions
  label_colour : Colour
}

///|
priv struct TikzParsedVertexLabel {
  label : String
  label_colour : Colour
}

///|
priv struct TikzPendingArrow {
  default_source_x : Int
  default_source_y : Int
  reverse : Bool
  is_loop : Bool
  source_x : Int?
  source_y : Int?
  source_ref : String?
  source_center_anchor : Bool
  target_x : Int?
  target_y : Int?
  target_ref : String?
  target_center_anchor : Bool
  is_phantom : Bool
  name : String?
  label : String
  options : EdgeOptions
  label_colour : Colour
}

///|
priv struct TikzNamedCellRef {
  id : Int
  center_anchor : Bool
}

///|
priv struct TikzResolvedEndpoint {
  id : Int
  center_anchor : Bool
}

///|
priv struct TikzParsedLabelOptions {
  swap : Bool
  description : Bool
  marking : Bool
  pos : Int?
  colour : Colour?
}

///|
priv struct TikzParsedDecorationOption {
  style_name : String
  colour : Colour?
  rotate : Int?
}

///|
priv struct TikzParsedArrowBodyDecorationOption {
  style_body : String
  colour : Colour?
}

///|
priv struct TikzParsedLoopOptions {
  is_loop : Bool
  clockwise_hint : Int?
  in_angle : Double?
  out_angle : Double?
  distance_mm : Double?
}

///|
fn tikz_parse_ampersand_replacement(options : String) -> String? {
  for option in tikz_split_arrow_options(options) {
    match tikz_option_key_value(option) {
      Some((key, value)) => {
        let key_token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(key))
          .replace_all(old=" ", new="")
          .replace_all(old="\t", new="")
        if key_token == "ampersandreplacement" {
          let token = tikz_unwrap_braced_text(value).trim().to_string()
          if token != "" {
            return Some(token)
          }
        }
      }
      None => ()
    }
  }
  None
}

///|
fn tikz_extract_environment_body(input : String) -> TikzEnvironmentBody? {
  let begin_token = "\\begin{tikzcd}"
  let end_token = "\\end{tikzcd}"
  match input.find(begin_token) {
    Some(begin_index) => {
      let after_begin = input.unsafe_substring(
        start=begin_index + begin_token.length(),
        end=input.length(),
      )
      let mut rest = tikz_trim_left(after_begin)
      let mut ampersand_replacement : String? = None
      if rest.has_prefix("[") {
        let mut depth = 0
        let mut i = 0
        while i < rest.length() {
          let ch = rest.unsafe_get(i)
          if ch == '[' {
            depth = depth + 1
          } else if ch == ']' {
            depth = depth - 1
            if depth == 0 {
              let options = rest.unsafe_substring(start=1, end=i)
              ampersand_replacement = tikz_parse_ampersand_replacement(options)
              rest = rest.unsafe_substring(start=i + 1, end=rest.length())
              break
            }
          }
          i = i + 1
        }
      }
      match rest.find(end_token) {
        Some(end_index) =>
          Some({
            body: rest.unsafe_substring(start=0, end=end_index),
            ampersand_replacement,
          })
        None => None
      }
    }
    None => None
  }
}

///|
fn tikz_split_rows(body : String) -> Array[String] {
  let rows : Array[String] = []
  let mut segment_start = 0
  let mut i = 0
  while i + 1 < body.length() {
    if body.unsafe_get(i) == '\\' && body.unsafe_get(i + 1) == '\\' {
      rows.push(body.unsafe_substring(start=segment_start, end=i))
      i = i + 2
      while i < body.length() && tikz_is_whitespace(body.unsafe_get(i)) {
        i = i + 1
      }
      if i < body.length() && body.unsafe_get(i) == '*' {
        // Support starred row breaks (e.g. "\\*" and "\\* [0.6em]").
        i = i + 1
        while i < body.length() && tikz_is_whitespace(body.unsafe_get(i)) {
          i = i + 1
        }
      }
      if i < body.length() && body.unsafe_get(i) == '[' {
        let mut depth = 1
        i = i + 1
        while i < body.length() && depth > 0 {
          let ch = body.unsafe_get(i)
          if ch == '[' {
            depth = depth + 1
          } else if ch == ']' {
            depth = depth - 1
          }
          i = i + 1
        }
      }
      segment_start = i
      continue
    }
    i = i + 1
  }
  rows.push(body.unsafe_substring(start=segment_start, end=body.length()))
  rows
}

///|
fn tikz_find_unescaped_percent(line : String) -> Int? {
  let mut i = 0
  while i < line.length() {
    if line.unsafe_get(i) == '%' {
      let mut slash_count = 0
      let mut j = i
      while j > 0 && line.unsafe_get(j - 1) == '\\' {
        slash_count = slash_count + 1
        j = j - 1
      }
      if slash_count % 2 == 0 {
        return Some(i)
      }
    }
    i = i + 1
  }
  None
}

///|
fn tikz_strip_line_comments(body : String) -> String {
  let rows : Array[String] = []
  for line_view in body.split("\n") {
    let line = line_view.to_string()
    match tikz_find_unescaped_percent(line) {
      Some(index) => rows.push(line.unsafe_substring(start=0, end=index))
      None => rows.push(line)
    }
  }
  rows.join("\n")
}

///|
fn tikz_split_cells(
  row : String,
  ampersand_replacement : String?,
) -> Array[String] {
  let cells : Array[String] = []
  let mut segment_start = 0
  let mut i = 0
  let mut brace_depth = 0
  let mut bracket_depth = 0
  let mut paren_depth = 0
  let mut in_quotes = false
  while i < row.length() {
    if !in_quotes &&
      brace_depth == 0 &&
      bracket_depth == 0 &&
      paren_depth == 0 {
      match ampersand_replacement {
        Some(token) =>
          if token != "" &&
            i + token.length() <= row.length() &&
            row.unsafe_substring(start=i, end=i + token.length()) == token {
            cells.push(row.unsafe_substring(start=segment_start, end=i))
            i = i + token.length()
            segment_start = i
            continue
          }
        None => ()
      }
    }

    let ch = row.unsafe_get(i)
    if ch == '\\' {
      if i + 1 < row.length() {
        // Skip escaped next char so it cannot act as a delimiter.
        i = i + 2
        continue
      }
      i = i + 1
      continue
    }

    if ch == '"' {
      in_quotes = !in_quotes
      i = i + 1
      continue
    }

    if !in_quotes {
      if ch == '{' {
        brace_depth = brace_depth + 1
      } else if ch == '}' && brace_depth > 0 {
        brace_depth = brace_depth - 1
      } else if ch == '[' {
        bracket_depth = bracket_depth + 1
      } else if ch == ']' && bracket_depth > 0 {
        bracket_depth = bracket_depth - 1
      } else if ch == '(' {
        paren_depth = paren_depth + 1
      } else if ch == ')' && paren_depth > 0 {
        paren_depth = paren_depth - 1
      } else if ampersand_replacement is None &&
        ch == '&' &&
        brace_depth == 0 &&
        bracket_depth == 0 &&
        paren_depth == 0 {
        cells.push(row.unsafe_substring(start=segment_start, end=i))
        i = i + 1
        segment_start = i
        continue
      }
    }

    i = i + 1
  }
  cells.push(row.unsafe_substring(start=segment_start, end=row.length()))
  cells
}

///|
fn tikz_unwrap_braced_text(input : String) -> String {
  let trimmed = input.trim().to_string()
  if trimmed.length() >= 2 && trimmed.has_prefix("{") && trimmed.has_suffix("}") {
    trimmed
    .unsafe_substring(start=1, end=trimmed.length() - 1)
    .trim()
    .to_string()
  } else {
    trimmed
  }
}

///|
fn tikz_strip_math_wrapper(input : String) -> String {
  let trimmed = input.trim().to_string()
  if trimmed.length() >= 2 && trimmed.has_prefix("$") && trimmed.has_suffix("$") {
    trimmed
    .unsafe_substring(start=1, end=trimmed.length() - 1)
    .trim()
    .to_string()
  } else {
    trimmed
  }
}

///|
fn tikz_parse_positive_int(input : String) -> Int? {
  let value = input.trim().to_string()
  if value == "" {
    return None
  }

  let bytes = @utf8.encode(value)
  let mut out = 0
  for byte in bytes {
    let code = byte.to_int()
    if code < 48 || code > 57 {
      return None
    }
    out = out * 10 + (code - 48)
  }
  Some(out)
}

///|
fn tikz_parse_grid_reference(value : String) -> (Int, Int)? {
  let raw = tikz_unwrap_braced_text(value)
  let compact = raw.replace_all(old=" ", new="").replace_all(old="\t", new="")
  match compact.find("-") {
    Some(split_at) => {
      let row_text = compact.unsafe_substring(start=0, end=split_at)
      let col_text = compact.unsafe_substring(
        start=split_at + 1,
        end=compact.length(),
      )
      if row_text == "" || col_text == "" || col_text.contains("-") {
        return None
      }
      match
        (tikz_parse_positive_int(row_text), tikz_parse_positive_int(col_text)) {
        (Some(row), Some(col)) =>
          if row >= 1 && col >= 1 {
            Some((col - 1, row - 1))
          } else {
            None
          }
        _ => None
      }
    }
    None => None
  }
}

///|
fn tikz_parse_reference_name(value : String) -> String? {
  let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  if token == "" {
    None
  } else {
    Some(token)
  }
}

///|
fn tikz_is_direction_token(token : String) -> Bool {
  if token == "" {
    return false
  }
  for ch in token {
    if ch != 'r' && ch != 'l' && ch != 'u' && ch != 'd' {
      return false
    }
  }
  true
}

///|
fn tikz_is_escaped_at(value : String, index : Int) -> Bool {
  let mut slash_count = 0
  let mut i = index
  while i > 0 && value.unsafe_get(i - 1) == '\\' {
    slash_count = slash_count + 1
    i = i - 1
  }
  slash_count % 2 == 1
}

///|
fn tikz_find_unescaped_quote(value : String, start : Int) -> Int? {
  let mut i = start
  while i < value.length() {
    if value.unsafe_get(i) == '"' && !tikz_is_escaped_at(value, i) {
      return Some(i)
    }
    i = i + 1
  }
  None
}

///|
fn tikz_extract_first_quoted(value : String) -> String? {
  match tikz_find_unescaped_quote(value, 0) {
    Some(start) => {
      let content_start = start + 1
      match tikz_find_unescaped_quote(value, content_start) {
        Some(end) =>
          Some(
            value
            .unsafe_substring(start=content_start, end=end)
            .replace_all(old="\\\"", new="\""),
          )
        None => None
      }
    }
    None => None
  }
}

///|
fn tikz_option_key_value(option : String) -> (String, String)? {
  match option.find("=") {
    Some(index) =>
      Some(
        (
          option.unsafe_substring(start=0, end=index).trim().to_string(),
          option
          .unsafe_substring(start=index + 1, end=option.length())
          .trim()
          .to_string(),
        ),
      )
    None => None
  }
}

///|
fn tikz_is_label_modifier(option : String) -> Bool {
  match option {
    "'" => true
    "swap" => true
    "description" => true
    "marking" => true
    "allow upside down" => true
    "at start" => true
    "at end" => true
    "near start" => true
    "near end" => true
    "very near start" => true
    "very near end" => true
    "midway" => true
    _ => false
  }
}

///|
fn tikz_is_arrow_flag_token(option : String) -> Bool {
  match option {
    "Rightarrow" => true
    "Leftarrow" => true
    "Leftrightarrow" => true
    "mapsto" => true
    "mapsfrom" => true
    "Mapsto" => true
    "Mapsfrom" => true
    "hookrightarrow" => true
    "hookleftarrow" => true
    "rightarrowtail" => true
    "leftarrowtail" => true
    "rightarrow" => true
    "leftarrow" => true
    "leftrightarrow" => true
    "twoheadrightarrow" => true
    "twoheadleftarrow" => true
    "rightharpoonup" => true
    "rightharpoondown" => true
    "leftharpoonup" => true
    "leftharpoondown" => true
    "dashrightarrow" => true
    "dashleftarrow" => true
    "rightsquigarrow" => true
    "leftsquigarrow" => true
    "leftrightsquigarrow" => true
    "dash" => true
    "equal" => true
    "double line" => true
    "dashed" => true
    "dotted" => true
    "squiggly" => true
    "no body" => true
    "no head" => true
    "no tail" => true
    "maps to" => true
    "tail" => true
    "2tail" => true
    "tail reversed" => true
    "2tail reversed" => true
    "hook" => true
    "hook'" => true
    "harpoon" => true
    "harpoon'" => true
    "shift right" => true
    "shift left" => true
    "bend left" => true
    "bend right" => true
    "to head" => true
    "two heads" => true
    "equals" => true
    "loop" => true
    "loop left" => true
    "loop right" => true
    "phantom" => true
    _ => false
  }
}

///|
fn tikz_arrow_flag_reverse(option : String) -> Bool? {
  let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(option))
  match token {
    "Rightarrow" => Some(false)
    "Leftarrow" => Some(true)
    "mapsto" => Some(false)
    "mapsfrom" => Some(true)
    "Mapsto" => Some(false)
    "Mapsfrom" => Some(true)
    "hookrightarrow" => Some(false)
    "hookleftarrow" => Some(true)
    "rightarrowtail" => Some(false)
    "leftarrowtail" => Some(true)
    "rightarrow" => Some(false)
    "leftarrow" => Some(true)
    "twoheadrightarrow" => Some(false)
    "twoheadleftarrow" => Some(true)
    "rightharpoonup" => Some(false)
    "rightharpoondown" => Some(false)
    "leftharpoonup" => Some(true)
    "leftharpoondown" => Some(true)
    "dashrightarrow" => Some(false)
    "dashleftarrow" => Some(true)
    "rightsquigarrow" => Some(false)
    "leftsquigarrow" => Some(true)
    _ => None
  }
}

///|
fn tikz_apply_empty_arrow_style(options : EdgeOptions) -> EdgeOptions {
  options
  .with_style_tail("none")
  .with_style_body("none")
  .with_style_head("none")
}

///|
fn tikz_parse_level_option_value(value : String) -> Int? {
  let text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
  tikz_parse_positive_int(text)
}

///|
fn tikz_parse_signed_double(value : String) -> Double? {
  let text = value.trim().to_string()
  if text == "" {
    return None
  }

  let mut index = 0
  let mut sign = 1.0
  if text.unsafe_get(0) == '-' {
    sign = -1.0
    index = 1
  } else if text.unsafe_get(0) == '+' {
    index = 1
  }
  if index >= text.length() {
    return None
  }

  let mut seen_digit = false
  let mut seen_dot = false
  let mut int_part = 0
  let mut frac_part = 0
  let mut frac_scale = 1
  while index < text.length() {
    let ch = text.unsafe_get(index)
    if ch == '.' {
      if seen_dot {
        return None
      }
      seen_dot = true
      index = index + 1
      continue
    }

    if ch < '0' || ch > '9' {
      return None
    }
    seen_digit = true
    let digit = (ch - '0').to_int()
    if !seen_dot {
      int_part = int_part * 10 + digit
    } else {
      frac_part = frac_part * 10 + digit
      frac_scale = frac_scale * 10
    }
    index = index + 1
  }

  if !seen_digit {
    return None
  }

  Some(
    sign * (int_part.to_double() + frac_part.to_double() / frac_scale.to_double()),
  )
}

///|
fn tikz_parse_shift_magnitude(value : String) -> Int? {
  let mut text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  if text.has_suffix("pt") {
    text = text.unsafe_substring(start=0, end=text.length() - 2)
  } else if text.has_suffix("ex") {
    text = text.unsafe_substring(start=0, end=text.length() - 2)
  } else if text.has_suffix("em") {
    text = text.unsafe_substring(start=0, end=text.length() - 2)
  }
  match tikz_parse_signed_double(text) {
    Some(shift_value) => {
      let shift_abs = tikz_abs_double(shift_value)
      if shift_abs == 0.0 {
        return Some(0)
      }
      let rounded = tikz_round_to_int(shift_abs)
      if rounded < 1 {
        Some(1)
      } else {
        Some(rounded)
      }
    }
    None => None
  }
}

///|
fn tikz_parse_bend_curve_magnitude(value : String) -> Int? {
  let mut text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  if text.has_suffix("deg") {
    text = text.unsafe_substring(start=0, end=text.length() - 3)
  }
  match tikz_parse_signed_double(text) {
    Some(angle_value) => {
      let angle_abs = tikz_abs_double(angle_value)
      if angle_abs == 0.0 {
        return None
      }
      let curve = tikz_round_to_int(angle_abs / 30.0)
      if curve < 1 {
        Some(1)
      } else {
        Some(curve)
      }
    }
    None => None
  }
}

///|
fn tikz_take_braced_group(input : String) -> (String, String)? {
  let text = input.trim().to_string()
  if !text.has_prefix("{") {
    return None
  }

  let mut depth = 0
  let mut i = 0
  while i < text.length() {
    let ch = text.unsafe_get(i)
    if ch == '{' {
      depth = depth + 1
    } else if ch == '}' {
      depth = depth - 1
      if depth == 0 {
        let inner = text.unsafe_substring(start=1, end=i)
        let rest = text.unsafe_substring(start=i + 1, end=text.length())
        return Some((inner, rest))
      }
    }
    i = i + 1
  }
  None
}

///|
fn tikz_parse_between_option(value : String) -> (Int, Int)? {
  match tikz_take_braced_group(value) {
    Some((source_text, rest)) =>
      match tikz_take_braced_group(rest) {
        Some((target_text, _)) =>
          match
            (
              tikz_parse_label_pos_percent(source_text),
              tikz_parse_label_pos_percent(target_text),
            ) {
            (Some(source), Some(target_end)) =>
              if source >= 0 && source <= 100 && target_end >= 0 &&
                target_end <= 100 {
                Some((source, 100 - target_end))
              } else {
                None
              }
            _ => None
          }
        None => None
      }
    None => None
  }
}

///|
fn tikz_parse_curve_height_option(value : String) -> Int? {
  let text = value.trim().to_string()
  let inner = if text.has_prefix("{") && text.has_suffix("}") {
    text.unsafe_substring(start=1, end=text.length() - 1).trim().to_string()
  } else {
    text
  }

  let compact = inner.replace_all(old=" ", new="")
  if !compact.has_prefix("height=") {
    return None
  }
  let mut height_text = compact.unsafe_substring(start=7, end=compact.length())
  if height_text.has_suffix("pt") {
    height_text = height_text.unsafe_substring(
      start=0,
      end=height_text.length() - 2,
    )
  }

  match tikz_parse_signed_double(height_text) {
    Some(height_pt) => Some(tikz_round_to_int(height_pt / 6.0))
    None => None
  }
}

///|
fn tikz_ascii_lower(value : String) -> String {
  let out : Array[String] = []
  for byte in @utf8.encode(value) {
    let code = byte.to_int()
    if code >= 65 && code <= 90 {
      out.push((code + 32).unsafe_to_char().to_string())
    } else {
      out.push(code.unsafe_to_char().to_string())
    }
  }
  out.join("")
}

///|
fn tikz_normalise_colour_name(value : String) -> String {
  let mut text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  if text.has_prefix("(") && text.has_suffix(")") && text.length() >= 2 {
    text = text
      .unsafe_substring(start=1, end=text.length() - 1)
      .trim()
      .to_string()
  }
  if text.has_prefix("\\") {
    text = text.unsafe_substring(start=1, end=text.length())
  }
  match text.find("!") {
    Some(index) =>
      text = text.unsafe_substring(start=0, end=index).trim().to_string()
    None => ()
  }
  tikz_ascii_lower(text)
}

///|
fn tikz_named_colour(name : String) -> Colour? {
  match name {
    "black" => Some(Colour::black())
    "white" => Some(Colour::new(0, 0, 100, 1.0))
    "red" => Some(Colour::new(0, 100, 50, 1.0))
    "green" => Some(Colour::new(120, 100, 25, 1.0))
    "blue" => Some(Colour::new(240, 100, 50, 1.0))
    "yellow" => Some(Colour::new(60, 100, 50, 1.0))
    "cyan" => Some(Colour::new(180, 100, 50, 1.0))
    "magenta" => Some(Colour::new(300, 100, 50, 1.0))
    "gray" => Some(Colour::new(0, 0, 50, 1.0))
    "grey" => Some(Colour::new(0, 0, 50, 1.0))
    "orange" => Some(Colour::new(30, 100, 50, 1.0))
    "purple" => Some(Colour::new(300, 100, 25, 1.0))
    _ => None
  }
}

///|
fn tikz_parse_rgb_255_component(value : String) -> Int? {
  match tikz_parse_positive_int(value.trim().to_string()) {
    Some(component) =>
      if component >= 0 && component <= 255 {
        Some(component)
      } else {
        None
      }
    None => None
  }
}

///|
fn tikz_parse_rgb_255_colour(value : String) -> Colour? {
  let compact = value.replace_all(old=" ", new="")
  if !compact.has_prefix("rgb,255:red,") {
    return None
  }

  let after_red = compact.unsafe_substring(start=12, end=compact.length())
  match after_red.find(";green,") {
    Some(green_index) => {
      let red_text = after_red.unsafe_substring(start=0, end=green_index)
      let after_green = after_red.unsafe_substring(
        start=green_index + 7,
        end=after_red.length(),
      )
      match after_green.find(";blue,") {
        Some(blue_index) => {
          let green_text = after_green.unsafe_substring(start=0, end=blue_index)
          let blue_text = after_green.unsafe_substring(
            start=blue_index + 6,
            end=after_green.length(),
          )
          match
            (
              tikz_parse_rgb_255_component(red_text),
              tikz_parse_rgb_255_component(green_text),
              tikz_parse_rgb_255_component(blue_text),
            ) {
            (Some(r_int), Some(g_int), Some(b_int)) => {
              let r = r_int.to_double() / 255.0
              let g = g_int.to_double() / 255.0
              let b = b_int.to_double() / 255.0
              let max_channel = tikz_max_double(r, tikz_max_double(g, b))
              let min_channel = tikz_min_double(r, tikz_min_double(g, b))
              let delta = max_channel - min_channel
              let l = (max_channel + min_channel) / 2.0
              if delta == 0.0 {
                return Some(Colour::new(0, 0, tikz_round_to_int(l * 100.0), 1.0))
              }

              let abs_l = if 2.0 * l - 1.0 >= 0.0 {
                2.0 * l - 1.0
              } else {
                -(2.0 * l - 1.0)
              }
              let s = delta / (1.0 - abs_l)
              let h = if max_channel == r {
                60.0 * tikz_mod((g - b) / delta, 6.0)
              } else if max_channel == g {
                60.0 * (((b - r) / delta) + 2.0)
              } else {
                60.0 * (((r - g) / delta) + 4.0)
              }
              Some(
                Colour::new(
                  tikz_round_to_int(h),
                  tikz_round_to_int(s * 100.0),
                  tikz_round_to_int(l * 100.0),
                  1.0,
                ),
              )
            }
            _ => None
          }
        }
        None => None
      }
    }
    None => None
  }
}

///|
fn tikz_parse_colour_option(value : String) -> Colour? {
  let inner = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  match tikz_parse_rgb_255_colour(inner) {
    Some(colour) => Some(colour)
    None => tikz_named_colour(tikz_normalise_colour_name(inner))
  }
}

///|
fn tikz_parse_rotate_option(value : String) -> Int? {
  let text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  match tikz_parse_signed_double(text) {
    Some(value_double) => Some(tikz_round_to_int(value_double))
    None => None
  }
}

///|
fn tikz_decoration_style_name(content : String) -> String? {
  let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(content))
    .trim()
    .to_string()
  if token == "\\dashv" {
    return Some("adjunction")
  }
  if token == "\\lrcorner" {
    return Some("corner")
  }
  if token == "\\ulcorner" {
    return Some("corner-inverse")
  }
  None
}

///|
fn tikz_parse_decoration_option(option : String) -> TikzParsedDecorationOption? {
  match tikz_extract_first_quoted(option) {
    Some(content) =>
      match tikz_decoration_style_name(content) {
        Some(style_name) => {
          let mut colour : Colour? = None
          let mut rotate : Int? = None
          for suffix_option in tikz_label_suffix_options(option) {
            match tikz_option_key_value(suffix_option) {
              Some((key, value)) => {
                let key_token = tikz_strip_math_wrapper(
                  tikz_unwrap_braced_text(key),
                )
                if key_token == "text" {
                  match tikz_parse_colour_option(value) {
                    Some(parsed_colour) => colour = Some(parsed_colour)
                    None => ()
                  }
                } else if key_token == "rotate" {
                  match tikz_parse_rotate_option(value) {
                    Some(parsed_rotate) => rotate = Some(parsed_rotate)
                    None => ()
                  }
                }
              }
              None => ()
            }
          }
          Some({ style_name, colour, rotate })
        }
        None => None
      }
    None => None
  }
}

///|
fn tikz_apply_decoration_rotation(
  options : EdgeOptions,
  style_name : String,
  rotate : Int,
) -> EdgeOptions {
  match style_name {
    "adjunction" => options.with_angle(-rotate)
    "corner" => options.with_angle(45 - rotate)
    "corner-inverse" => options.with_angle(45 - rotate)
    _ => options
  }
}

///|
fn tikz_is_background_colour_expression(value : String) -> Bool {
  let compact = tikz_ascii_lower(
    tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
      .replace_all(old=" ", new="")
      .replace_all(old="\t", new=""),
  )
  compact.contains("/tikz/commutativediagrams/backgroundcolor")
}

///|
fn tikz_arrow_body_decoration_style(content : String) -> String? {
  let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(content))
    .trim()
    .to_string()
  if token == "\\shortmid" {
    return Some("barred")
  }
  if token == "\\shortmid\\shortmid" {
    return Some("double barred")
  }
  if token == "\\bullet" {
    return Some("bullet solid")
  }
  if token == "\\circ" {
    return Some("bullet hollow")
  }
  None
}

///|
fn tikz_parse_arrow_body_decoration_option(
  option : String,
) -> TikzParsedArrowBodyDecorationOption? {
  match tikz_extract_first_quoted(option) {
    Some(content) =>
      match tikz_arrow_body_decoration_style(content) {
        Some(base_style_body) => {
          let mut style_body = base_style_body
          let mut colour : Colour? = None
          for suffix_option in tikz_label_suffix_options(option) {
            match tikz_option_key_value(suffix_option) {
              Some((key, value)) => {
                let key_token = tikz_strip_math_wrapper(
                  tikz_unwrap_braced_text(key),
                )
                if key_token == "text" {
                  if style_body == "bullet solid" &&
                    tikz_is_background_colour_expression(value) {
                    style_body = "bullet hollow"
                  } else {
                    match tikz_parse_colour_option(value) {
                      Some(parsed_colour) => colour = Some(parsed_colour)
                      None => ()
                    }
                  }
                }
              }
              None => ()
            }
          }
          Some({ style_body, colour })
        }
        None => None
      }
    None => None
  }
}

///|
fn tikz_loop_options_default() -> TikzParsedLoopOptions {
  {
    is_loop: false,
    clockwise_hint: None,
    in_angle: None,
    out_angle: None,
    distance_mm: None,
  }
}

///|
fn tikz_abs_double(value : Double) -> Double {
  if value >= 0.0 {
    value
  } else {
    -value
  }
}

///|
fn tikz_signed_angle_delta(from : Double, to : Double) -> Double {
  let raw = tikz_mod(to - from + 180.0, 360.0) - 180.0
  if raw == -180.0 {
    180.0
  } else {
    raw
  }
}

///|
fn tikz_parse_angle_option(value : String) -> Double? {
  let mut text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  if text.has_suffix("deg") {
    text = text.unsafe_substring(start=0, end=text.length() - 3)
  }
  tikz_parse_signed_double(text)
}

///|
fn tikz_parse_distance_option(value : String) -> Double? {
  let mut text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  if text.has_suffix("mm") || text.has_suffix("pt") || text.has_suffix("em") {
    text = text.unsafe_substring(start=0, end=text.length() - 2)
  }
  match tikz_parse_signed_double(text) {
    Some(distance_mm) => if distance_mm > 0.0 { Some(distance_mm) } else { None }
    None => None
  }
}

///|
fn tikz_apply_loop_flag_option(
  loop_options : TikzParsedLoopOptions,
  option : String,
) -> TikzParsedLoopOptions {
  let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(option))
    .trim()
    .to_string()
  if token == "loop left" {
    return { ..loop_options, is_loop: true, clockwise_hint: Some(-1) }
  }
  if token == "loop right" {
    return { ..loop_options, is_loop: true, clockwise_hint: Some(1) }
  }
  if token == "loop" {
    return { ..loop_options, is_loop: true }
  }
  loop_options
}

///|
fn tikz_apply_loop_key_value_option(
  loop_options : TikzParsedLoopOptions,
  key : String,
  value : String,
) -> TikzParsedLoopOptions {
  let key_token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(key))
  if key_token == "in" {
    match tikz_parse_angle_option(value) {
      Some(in_angle) => return { ..loop_options, in_angle: Some(in_angle) }
      None => ()
    }
  }
  if key_token == "out" {
    match tikz_parse_angle_option(value) {
      Some(out_angle) => return { ..loop_options, out_angle: Some(out_angle) }
      None => ()
    }
  }
  if key_token == "distance" {
    match tikz_parse_distance_option(value) {
      Some(distance_mm) => return { ..loop_options, distance_mm: Some(distance_mm) }
      None => ()
    }
  }
  loop_options
}

///|
fn tikz_apply_loop_geometry_options(
  options : EdgeOptions,
  loop_options : TikzParsedLoopOptions,
) -> EdgeOptions {
  if !loop_options.is_loop {
    return options
  }

  let mut clockwise = match loop_options.clockwise_hint {
    Some(value) => if value < 0 { -1 } else { 1 }
    None =>
      if options.radius < 0 {
        -1
      } else {
        1
      }
  }

  let mut abs_radius = Int::abs(options.radius)
  if abs_radius < 1 {
    abs_radius = 1
  }

  let mut angle = options.angle
  match (loop_options.in_angle, loop_options.out_angle) {
    (Some(in_angle), Some(out_angle)) => {
      let delta = tikz_signed_angle_delta(in_angle, out_angle)
      if delta > 0.0 {
        clockwise = 1
      } else if delta < 0.0 {
        clockwise = -1
      }

      let spread = tikz_abs_double(delta) / 2.0
      let loop_angle = tikz_mod(in_angle + delta / 2.0, 360.0)
      angle = tikz_round_to_int(
        180.0 - 90.0 * clockwise.to_double() - loop_angle,
      )

      let radius_from_spread = 1.0 + (spread - 30.0) / 2.5
      if radius_from_spread >= 1.0 {
        abs_radius = tikz_round_to_int(radius_from_spread)
      }
    }
    _ => ()
  }

  match loop_options.distance_mm {
    Some(distance_mm) => {
      let radius_from_distance = 1.0 + (distance_mm - 5.0) / 2.5
      if radius_from_distance >= 1.0 {
        abs_radius = tikz_round_to_int(radius_from_distance)
      }
    }
    None => ()
  }

  if abs_radius < 1 {
    abs_radius = 1
  }
  options.with_radius(abs_radius * clockwise).with_angle(angle)
}

///|
fn tikz_parse_label_pos_percent(value : String) -> Int? {
  let text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  if text == "" {
    return None
  }

  match text.find(".") {
    Some(dot_index) => {
      let whole_text = text.unsafe_substring(start=0, end=dot_index)
      let frac_text = text.unsafe_substring(start=dot_index + 1, end=text.length())
      if frac_text == "" {
        return None
      }

      let whole_value = if whole_text == "" {
        0
      } else {
        match tikz_parse_positive_int(whole_text) {
          Some(value) => value
          None => return None
        }
      }

      if whole_value > 1 {
        return None
      }

      let mut frac_value = 0
      let mut frac_scale = 1
      for byte in @utf8.encode(frac_text) {
        let code = byte.to_int()
        if code < 48 || code > 57 {
          return None
        }
        frac_value = frac_value * 10 + (code - 48)
        frac_scale = frac_scale * 10
      }

      if whole_value == 1 && frac_value != 0 {
        return None
      }

      let numerator = whole_value * frac_scale + frac_value
      let percent_numerator = numerator * 100
      let rounded = (percent_numerator + frac_scale / 2) / frac_scale
      if rounded >= 0 && rounded <= 100 {
        Some(rounded)
      } else {
        None
      }
    }
    None =>
      match tikz_parse_positive_int(text) {
        Some(value) =>
          if value <= 1 {
            Some(value * 100)
          } else if value <= 100 {
            Some(value)
          } else {
            None
          }
        None => None
      }
  }
}

///|
fn tikz_apply_arrow_flag_option(
  options : EdgeOptions,
  option : String,
) -> EdgeOptions {
  let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(option))
  match token {
    "Rightarrow" =>
      options
      .with_level(2)
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "Leftarrow" =>
      options
      .with_level(2)
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "Leftrightarrow" =>
      options
      .with_level(2)
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("arrowhead")
      .with_style_head("arrowhead")
    "mapsto" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("maps to")
      .with_style_head("arrowhead")
    "mapsfrom" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("maps to")
      .with_style_head("arrowhead")
    "Mapsto" =>
      options
      .with_level(2)
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("maps to")
      .with_style_head("arrowhead")
    "Mapsfrom" =>
      options
      .with_level(2)
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("maps to")
      .with_style_head("arrowhead")
    "hookrightarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("hook", side="top")
      .with_style_head("arrowhead")
    "hookleftarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("hook", side="top")
      .with_style_head("arrowhead")
    "rightarrowtail" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("mono")
      .with_style_head("arrowhead")
    "leftarrowtail" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("mono")
      .with_style_head("arrowhead")
    "rightarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "leftarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "leftrightarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("arrowhead")
      .with_style_head("arrowhead")
    "twoheadrightarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("epi")
    "twoheadleftarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("epi")
    "rightharpoonup" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("harpoon", side="top")
    "rightharpoondown" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("harpoon", side="bottom")
    "leftharpoonup" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("harpoon", side="top")
    "leftharpoondown" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("harpoon", side="bottom")
    "dashrightarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("dashed")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "dashleftarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("dashed")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "rightsquigarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("squiggly")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "leftsquigarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("squiggly")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "leftrightsquigarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("squiggly")
      .with_style_tail("arrowhead")
      .with_style_head("arrowhead")
    "dash" =>
      options
      .with_level(1)
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("none")
    "equal" =>
      options
      .with_level(2)
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("none")
    "double line" => options.with_level(2)
    "dashed" => options.with_style_body("dashed")
    "dotted" => options.with_style_body("dotted")
    "squiggly" => options.with_style_body("squiggly")
    "no body" => options.with_style_body("none")
    "no head" => options.with_style_head("none")
    "no tail" => options.with_style_tail("none")
    "maps to" => options.with_style_tail("maps to")
    "tail" => options.with_style_tail("mono")
    "2tail" => options.with_level(2).with_style_tail("mono")
    "tail reversed" => options.with_style_tail("arrowhead")
    "2tail reversed" => options.with_level(2).with_style_tail("arrowhead")
    "hook" => options.with_style_tail("hook", side="top")
    "hook'" => options.with_style_tail("hook", side="bottom")
    "harpoon" => options.with_style_head("harpoon", side="top")
    "harpoon'" => options.with_style_head("harpoon", side="bottom")
    "shift right" => options.with_offset(1)
    "shift left" => options.with_offset(-1)
    "bend left" => options.with_curve(1)
    "bend right" => options.with_curve(-1)
    "to head" => options.with_style_head("cell")
    "two heads" => options.with_style_head("epi")
    "equals" =>
      options
      .with_level(2)
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("none")
    _ => options
  }
}

///|
fn tikz_apply_arrow_key_value_option(
  options : EdgeOptions,
  key : String,
  value : String,
) -> EdgeOptions {
  let key_token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(key))
  let value_raw = value.trim().to_string()
  let value_token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
  if key_token == "draw" && value_token == "none" {
    return tikz_apply_empty_arrow_style(options)
  }

  if key_token == "scaling nfold" {
    match tikz_parse_level_option_value(value_token) {
      Some(level) => {
        let clamped = if level < 2 {
          2
        } else if level > 4 {
          4
        } else {
          level
        }
        return options.with_level(clamped)
      }
      None => ()
    }
  }

  if key_token == "shift right" {
    match tikz_parse_shift_magnitude(value_raw) {
      Some(magnitude) => return options.with_offset(magnitude)
      None => ()
    }
  }

  if key_token == "shift left" {
    match tikz_parse_shift_magnitude(value_raw) {
      Some(magnitude) => return options.with_offset(-magnitude)
      None => ()
    }
  }

  if key_token == "curve" {
    match tikz_parse_curve_height_option(value_raw) {
      Some(curve) => return options.with_curve(curve)
      None => ()
    }
  }

  if key_token == "bend left" {
    match tikz_parse_bend_curve_magnitude(value_raw) {
      Some(curve) => return options.with_curve(curve)
      None => ()
    }
  }

  if key_token == "bend right" {
    match tikz_parse_bend_curve_magnitude(value_raw) {
      Some(curve) => return options.with_curve(-curve)
      None => ()
    }
  }

  let key_compact = key_token
    .replace_all(old=" ", new="")
    .replace_all(old="\t", new="")
  if key_compact == "shorten<" {
    match tikz_parse_shorten_magnitude(value_raw) {
      Some(source) => return options.with_shorten(source, options.shorten.target)
      None => ()
    }
  }
  if key_compact == "shorten>" {
    match tikz_parse_shorten_magnitude(value_raw) {
      Some(target) => return options.with_shorten(options.shorten.source, target)
      None => ()
    }
  }

  if key_token == "between" {
    match tikz_parse_between_option(value_raw) {
      Some((source, target)) => return options.with_shorten(source, target)
      None => ()
    }
  }

  options
}

///|
fn tikz_label_options_default() -> TikzParsedLabelOptions {
  {
    swap: false,
    description: false,
    marking: false,
    pos: None,
    colour: None,
  }
}

///|
fn tikz_apply_label_flag_option(
  label_options : TikzParsedLabelOptions,
  option : String,
) -> TikzParsedLabelOptions {
  let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(option))
  match token {
    "'" => { ..label_options, swap: !label_options.swap }
    "swap" => { ..label_options, swap: !label_options.swap }
    "description" => { ..label_options, description: true }
    "marking" => { ..label_options, marking: true }
    "allow upside down" => label_options
    "at start" => { ..label_options, pos: Some(0) }
    "very near start" => { ..label_options, pos: Some(10) }
    "near start" => { ..label_options, pos: Some(20) }
    "midway" => { ..label_options, pos: Some(50) }
    "near end" => { ..label_options, pos: Some(80) }
    "very near end" => { ..label_options, pos: Some(90) }
    "at end" => { ..label_options, pos: Some(1) }
    _ => label_options
  }
}

///|
fn tikz_apply_label_key_value_option(
  label_options : TikzParsedLabelOptions,
  key : String,
  value : String,
) -> TikzParsedLabelOptions {
  let key_token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(key))
  if key_token == "pos" {
    match tikz_parse_label_pos_percent(value) {
      Some(pos) => { ..label_options, pos: Some(pos) }
      None => label_options
    }
  } else if key_token == "text" {
    match tikz_parse_colour_option(value) {
      Some(colour) => { ..label_options, colour: Some(colour) }
      None => label_options
    }
  } else {
    tikz_apply_label_flag_option(label_options, key_token)
  }
}

///|
fn tikz_label_suffix_options(option : String) -> Array[String] {
  let suffix_options : Array[String] = []
  match option.find("\"") {
    Some(start) => {
      let rest = option.unsafe_substring(start=start + 1, end=option.length())
      match rest.find("\"") {
        Some(end) => {
          let mut suffix = rest
            .unsafe_substring(start=end + 1, end=rest.length())
            .trim()
            .to_string()

          if suffix.has_prefix("'") {
            suffix_options.push("'")
            suffix = suffix
              .unsafe_substring(start=1, end=suffix.length())
              .trim()
              .to_string()
          }

          if suffix == "" {
            return suffix_options
          }

          if suffix.has_prefix("{") && suffix.has_suffix("}") {
            let inner = suffix.unsafe_substring(start=1, end=suffix.length() - 1)
            for opt in tikz_split_arrow_options(inner) {
              suffix_options.push(opt)
            }
          } else {
            suffix_options.push(suffix)
          }
        }
        None => ()
      }
    }
    None => ()
  }
  suffix_options
}

///|
fn tikz_apply_label_options_to_edge_options(
  options : EdgeOptions,
  label_options : TikzParsedLabelOptions,
) -> EdgeOptions {
  let aligned = if label_options.marking {
    options.with_label_alignment_over()
  } else if label_options.description {
    options.with_label_alignment_centre()
  } else if label_options.swap {
    options.with_label_alignment_right()
  } else {
    options.with_label_alignment_left()
  }

  match label_options.pos {
    Some(pos) => aligned.with_label_position(pos)
    None => aligned
  }
}

///|
fn tikz_parse_shorten_magnitude(value : String) -> Int? {
  let mut text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  if text.has_suffix("pt") {
    text = text.unsafe_substring(start=0, end=text.length() - 2)
  } else {
    return None
  }

  match tikz_parse_signed_double(text) {
    Some(raw_value) => {
      let rounded = tikz_round_to_int(raw_value)
      if rounded < 0 {
        None
      } else if rounded > 100 {
        Some(100)
      } else {
        Some(rounded)
      }
    }
    None => None
  }
}

///|
fn tikz_extract_arrow_label_option(option : String) -> String? {
  match tikz_extract_first_quoted(option) {
    Some(value) => return Some(value)
    None => ()
  }

  if option.contains("=") {
    return None
  }

  let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(option))
  if token == "" ||
    tikz_is_direction_token(token) ||
    tikz_is_label_modifier(token) ||
    tikz_is_arrow_flag_token(token) {
    None
  } else {
    Some(token)
  }
}

///|
fn tikz_take_leading_positional_label(input : String) -> (String, String)? {
  let mut i = 0
  while i < input.length() && tikz_is_whitespace(input.unsafe_get(i)) {
    i = i + 1
  }
  if i >= input.length() {
    return None
  }

  let marker = input.unsafe_get(i)
  if marker != '^' && marker != '_' && marker != '|' {
    return None
  }
  let alignment = if marker == '_' {
    "right"
  } else if marker == '|' {
    "centre"
  } else {
    "left"
  }
  i = i + 1
  if marker == '|' &&
    i < input.length() &&
    input.unsafe_get(i) == '-' {
    i = i + 1
  }
  while i < input.length() && tikz_is_whitespace(input.unsafe_get(i)) {
    i = i + 1
  }
  if i >= input.length() {
    return None
  }

  let start = i
  let first = input.unsafe_get(i)
  if first == '{' {
    let mut depth = 1
    let mut j = i + 1
    while j < input.length() && depth > 0 {
      let ch = input.unsafe_get(j)
      if ch == '\\' {
        if j + 1 < input.length() {
          j = j + 2
          continue
        } else {
          break
        }
      }
      if ch == '{' {
        depth = depth + 1
      } else if ch == '}' {
        depth = depth - 1
      }
      j = j + 1
    }
    if depth != 0 || j <= start + 1 {
      return None
    }

    let label = input
      .unsafe_substring(start=start + 1, end=j - 1)
      .trim()
      .to_string()
    let normalised = tikz_strip_math_wrapper(label).trim().to_string()
    if normalised == "" {
      None
    } else {
      Some((normalised, alignment))
    }
  } else if first == '"' {
    match tikz_find_unescaped_quote(input, i + 1) {
      Some(end_quote) =>
        if end_quote <= i + 1 {
          None
        } else {
          let label = input
            .unsafe_substring(start=i + 1, end=end_quote)
            .replace_all(old="\\\"", new="\"")
          let normalised = tikz_strip_math_wrapper(label).trim().to_string()
          if normalised == "" {
            None
          } else {
            Some((normalised, alignment))
          }
        }
      None => None
    }
  } else {
    let mut j = i
    while j < input.length() {
      let ch = input.unsafe_get(j)
      if tikz_is_whitespace(ch) ||
        ch == '\\' ||
        ch == '&' ||
        ch == '[' ||
        ch == ']' ||
        ch == ',' {
        break
      }
      j = j + 1
    }
    if j == i {
      return None
    }

    let label = input.unsafe_substring(start=i, end=j).trim().to_string()
    let normalised = tikz_strip_math_wrapper(label).trim().to_string()
    if normalised == "" {
      None
    } else {
      Some((normalised, alignment))
    }
  }
}

fn tikz_next_arrow_match(input : String) -> TikzArrowMatch? {
  let mut i = 0
  while i < input.length() {
    if input.unsafe_get(i) != '\\' {
      i = i + 1
      continue
    }

    let rest = input.unsafe_substring(start=i, end=input.length())
    let command_len = if rest.has_prefix("\\arrow") {
      6
    } else if rest.has_prefix("\\ar") {
      3
    } else {
      0
    }

    if command_len == 0 {
      i = i + 1
      continue
    }

    let mut options_start = i + command_len
    while options_start < input.length() &&
      tikz_is_whitespace(input.unsafe_get(options_start)) {
      options_start = options_start + 1
    }
    if options_start < input.length() {
      let open = input.unsafe_get(options_start)
      if open == '[' {
        return Some({
          start: i,
          options_start: options_start + 1,
          open_delimiter: '[',
          close_delimiter: ']',
        })
      }
      if open == '{' {
        return Some({
          start: i,
          options_start: options_start + 1,
          open_delimiter: '{',
          close_delimiter: '}',
        })
      }
    }
    i = i + 1
  }

  None
}

///|
fn tikz_split_arrow_options(raw_options : String) -> Array[String] {
  let options : Array[String] = []
  let mut segment_start = 0
  let mut i = 0
  let mut brace_depth = 0
  let mut bracket_depth = 0
  let mut paren_depth = 0
  let mut in_quotes = false

  while i < raw_options.length() {
    let ch = raw_options.unsafe_get(i)
    if ch == '\\' {
      if i + 1 < raw_options.length() {
        i = i + 2
      } else {
        i = i + 1
      }
      continue
    }

    if ch == '"' {
      in_quotes = !in_quotes
      i = i + 1
      continue
    }

    if !in_quotes {
      if ch == '{' {
        brace_depth = brace_depth + 1
      } else if ch == '}' && brace_depth > 0 {
        brace_depth = brace_depth - 1
      } else if ch == '[' {
        bracket_depth = bracket_depth + 1
      } else if ch == ']' && bracket_depth > 0 {
        bracket_depth = bracket_depth - 1
      } else if ch == '(' {
        paren_depth = paren_depth + 1
      } else if ch == ')' && paren_depth > 0 {
        paren_depth = paren_depth - 1
      } else if ch == ',' &&
        brace_depth == 0 &&
        bracket_depth == 0 &&
        paren_depth == 0 {
        let option = raw_options
          .unsafe_substring(start=segment_start, end=i)
          .trim()
          .to_string()
        if option != "" {
          options.push(option)
        }
        i = i + 1
        segment_start = i
        continue
      }
    }

    i = i + 1
  }

  let option = raw_options
    .unsafe_substring(start=segment_start, end=raw_options.length())
    .trim()
    .to_string()
  if option != "" {
    options.push(option)
  }
  options
}

///|
fn tikz_find_closing_delimiter(
  input : String,
  open_delimiter : UInt16,
  close_delimiter : UInt16,
) -> Int? {
  let mut in_quotes = false
  let mut brace_depth = 0
  let mut bracket_depth = 0
  let mut paren_depth = 0
  let mut i = 0
  while i < input.length() {
    let ch = input.unsafe_get(i)

    if ch == '\\' {
      if i + 1 < input.length() {
        i = i + 2
      } else {
        i = i + 1
      }
      continue
    }

    if ch == '"' {
      in_quotes = !in_quotes
      i = i + 1
      continue
    }

    if in_quotes {
      i = i + 1
      continue
    }

    if ch == '{' {
      brace_depth = brace_depth + 1
      i = i + 1
      continue
    }
    if ch == '[' {
      bracket_depth = bracket_depth + 1
      i = i + 1
      continue
    }
    if ch == '(' {
      paren_depth = paren_depth + 1
      i = i + 1
      continue
    }
    if ch == '}' {
      if open_delimiter == '{' &&
        close_delimiter == '}' &&
        brace_depth == 0 &&
        bracket_depth == 0 &&
        paren_depth == 0 {
        return Some(i)
      }
      if brace_depth > 0 {
        brace_depth = brace_depth - 1
      }
      i = i + 1
      continue
    }
    if ch == ']' {
      if open_delimiter == '[' &&
        close_delimiter == ']' &&
        bracket_depth == 0 &&
        brace_depth == 0 &&
        paren_depth == 0 {
        return Some(i)
      }
      if bracket_depth > 0 {
        bracket_depth = bracket_depth - 1
      }
      i = i + 1
      continue
    }
    if ch == ')' {
      if paren_depth > 0 {
        paren_depth = paren_depth - 1
      }
      i = i + 1
      continue
    }

    i = i + 1
  }
  None
}

///|
fn tikz_cell_label_raw(cell : String) -> String {
  let trimmed = cell.trim().to_string()
  match tikz_next_arrow_match(trimmed) {
    Some(matched) =>
      trimmed
      .unsafe_substring(start=0, end=matched.start)
      .trim()
      .to_string()
    None => trimmed
  }
}

///|
fn tikz_take_leading_braced_group(input : String) -> (String, String)? {
  let trimmed = tikz_trim_left(input)
  if trimmed == "" || trimmed.unsafe_get(0) != '{' {
    return None
  }

  let after_open = trimmed.unsafe_substring(start=1, end=trimmed.length())
  match tikz_find_closing_delimiter(after_open, '{', '}') {
    Some(close_index) =>
      Some(
        (
          after_open.unsafe_substring(start=0, end=close_index),
          after_open.unsafe_substring(start=close_index + 1, end=after_open.length()),
        ),
      )
    None => None
  }
}

///|
fn tikz_parse_textcolor_vertex_label(label_raw : String) -> TikzParsedVertexLabel? {
  let mut trimmed = label_raw.trim().to_string()
  while true {
    match tikz_take_leading_braced_group(trimmed) {
      Some((inner, rest)) =>
        if tikz_trim_left(rest) == "" {
          trimmed = inner.trim().to_string()
          continue
        } else {
          break
        }
      None => break
    }
  }
  if !trimmed.has_prefix("\\textcolor") {
    return None
  }
  let rest = trimmed.unsafe_substring(start=10, end=trimmed.length())
  match tikz_take_leading_braced_group(rest) {
    Some((colour_text, after_colour)) =>
      match tikz_parse_colour_option(colour_text) {
        Some(label_colour) =>
          match tikz_take_leading_braced_group(after_colour) {
            Some((label_text, _)) =>
              Some({
                label: tikz_unwrap_braced_text(label_text),
                label_colour,
              })
            None => None
          }
        None => None
      }
    None => None
  }
}

///|
fn tikz_parse_vertex_label(label_raw : String) -> TikzParsedVertexLabel {
  match tikz_parse_textcolor_vertex_label(label_raw) {
    Some(parsed) => parsed
    None => {
      label: tikz_unwrap_braced_text(label_raw),
      label_colour: Colour::black(),
    }
  }
}

///|
fn tikz_collect_cell_arrows(cell : String) -> Array[TikzParsedArrow] {
  let arrows : Array[TikzParsedArrow] = []
  let mut rest = cell
  while true {
    match tikz_next_arrow_match(rest) {
      Some(matched) => {
        let after_arrow = rest.unsafe_substring(
          start=matched.options_start,
          end=rest.length(),
        )
        match
          tikz_find_closing_delimiter(
            after_arrow,
            matched.open_delimiter,
            matched.close_delimiter,
          ) {
          Some(end) => {
            let raw_options = after_arrow.unsafe_substring(start=0, end~)
            let options = tikz_split_arrow_options(raw_options)

            let mut direction : String? = None
            let mut label = ""
            let mut from_x : Int? = None
            let mut from_y : Int? = None
            let mut from_ref : String? = None
            let mut to_x : Int? = None
            let mut to_y : Int? = None
            let mut to_ref : String? = None
            let mut is_phantom = false
            let mut name : String? = None
            let mut source_center_anchor = false
            let mut target_center_anchor = false
            let mut parsed_options = EdgeOptions::at_level(1)
            let mut parsed_reverse = false
            let mut parsed_label_options = tikz_label_options_default()
            let mut parsed_label_colour = Colour::black()
            let mut parsed_loop_options = tikz_loop_options_default()

            for option in options {
              match tikz_parse_decoration_option(option) {
                Some(parsed_decoration) => {
                  parsed_options = parsed_options.with_style_name(
                    parsed_decoration.style_name,
                  )
                  match parsed_decoration.colour {
                    Some(colour) => parsed_options = parsed_options.with_colour(colour)
                    None => ()
                  }
                  match parsed_decoration.rotate {
                    Some(rotate) =>
                      parsed_options = tikz_apply_decoration_rotation(
                        parsed_options,
                        parsed_decoration.style_name,
                        rotate,
                      )
                    None => ()
                  }
                  continue
                }
                None => ()
              }

              match tikz_parse_arrow_body_decoration_option(option) {
                Some(parsed_decoration) => {
                  parsed_options = parsed_options.with_style_body(
                    parsed_decoration.style_body,
                  )
                  match parsed_decoration.colour {
                    Some(colour) => parsed_options = parsed_options.with_colour(colour)
                    None => ()
                  }
                  continue
                }
                None => ()
              }

              if label == "" {
                match tikz_extract_arrow_label_option(option) {
                  Some(value) => label = value
                  None => ()
                }
              }

              match tikz_option_key_value(option) {
                Some((key, value)) =>
                  if key == "from" {
                    match tikz_parse_grid_reference(value) {
                      Some((x, y)) => {
                        from_x = Some(x)
                        from_y = Some(y)
                      }
                      None =>
                        match tikz_parse_reference_name(value) {
                          Some(reference_name) => from_ref = Some(reference_name)
                          None => ()
                        }
                    }
                  } else if key == "to" {
                    match tikz_parse_grid_reference(value) {
                      Some((x, y)) => {
                        to_x = Some(x)
                        to_y = Some(y)
                      }
                      None =>
                        match tikz_parse_reference_name(value) {
                          Some(reference_name) => to_ref = Some(reference_name)
                          None => ()
                        }
                    }
                  } else {
                    let key_token = tikz_strip_math_wrapper(
                      tikz_unwrap_braced_text(key),
                    )
                    let value_token = tikz_strip_math_wrapper(
                      tikz_unwrap_braced_text(value),
                    )
                    if key_token == "name" {
                      match tikz_parse_reference_name(value) {
                        Some(reference_name) => name = Some(reference_name)
                        None => ()
                      }
                    }
                    if key_token == "draw" || key_token == "color" {
                      match tikz_parse_colour_option(value) {
                        Some(colour) => {
                          parsed_options = parsed_options.with_colour(colour)
                          if key_token == "color" {
                            parsed_label_colour = colour
                          }
                        }
                        None => ()
                      }
                    } else if key_token == "start anchor" {
                      if value_token == "center" {
                        source_center_anchor = true
                      }
                    } else if key_token == "end anchor" {
                      if value_token == "center" {
                        target_center_anchor = true
                      }
                    } else if key_token == "text" {
                      match tikz_parse_colour_option(value) {
                        Some(colour) => parsed_label_colour = colour
                        None => ()
                      }
                    }
                    parsed_loop_options = tikz_apply_loop_key_value_option(
                      parsed_loop_options,
                      key,
                      value,
                    )
                    parsed_options = tikz_apply_arrow_key_value_option(
                      parsed_options,
                      key,
                      value,
                    )
                    parsed_label_options = tikz_apply_label_key_value_option(
                      parsed_label_options,
                      key,
                      value,
                    )
                  }
                None => {
                  let direction_candidate = tikz_unwrap_braced_text(option)
                  let option_token = tikz_strip_math_wrapper(direction_candidate)
                  if option_token == "phantom" {
                    is_phantom = true
                    parsed_options = tikz_apply_empty_arrow_style(
                      parsed_options,
                    )
                    parsed_label_options = {
                      ..parsed_label_options,
                      description: true,
                    }
                  }
                  if direction is None &&
                    tikz_is_direction_token(option_token) {
                    direction = Some(option_token)
                  }
                  if label == "" {
                    match tikz_extract_arrow_label_option(option) {
                      Some(value) => label = value
                      None => ()
                    }
                  }
                  match tikz_arrow_flag_reverse(option) {
                    Some(reverse) => parsed_reverse = reverse
                    None => ()
                  }
                  parsed_options = tikz_apply_arrow_flag_option(
                      parsed_options,
                      option,
                    )
                  parsed_loop_options = tikz_apply_loop_flag_option(
                    parsed_loop_options,
                    option,
                  )
                  parsed_label_options = tikz_apply_label_flag_option(
                    parsed_label_options,
                    option,
                  )
                }
              }

              for suffix_option in tikz_label_suffix_options(option) {
                match tikz_option_key_value(suffix_option) {
                  Some((key, value)) => {
                    let key_token = tikz_strip_math_wrapper(
                      tikz_unwrap_braced_text(key),
                    )
                    if key_token == "name" {
                      match tikz_parse_reference_name(value) {
                        Some(reference_name) => name = Some(reference_name)
                        None => ()
                      }
                    }
                    parsed_label_options = tikz_apply_label_key_value_option(
                      parsed_label_options,
                      key,
                      value,
                    )
                  }
                  None =>
                    parsed_label_options = tikz_apply_label_flag_option(
                      parsed_label_options,
                      suffix_option,
                    )
                }
              }
            }

            parsed_options = tikz_apply_label_options_to_edge_options(
              parsed_options,
              parsed_label_options,
            )
            parsed_options = tikz_apply_loop_geometry_options(
              parsed_options,
              parsed_loop_options,
            )
            let label_colour = match parsed_label_options.colour {
              Some(colour) => colour
              None => parsed_label_colour
            }

            let remaining_after_arrow = after_arrow.unsafe_substring(
              start=end + 1,
              end=after_arrow.length(),
            )
            if label == "" {
              match tikz_take_leading_positional_label(remaining_after_arrow) {
                Some((suffix_label, alignment)) => {
                  label = suffix_label
                  parsed_options = match alignment {
                    "right" => parsed_options.with_label_alignment_right()
                    "centre" => parsed_options.with_label_alignment_centre()
                    _ => parsed_options
                  }
                }
                None => ()
              }
            }

            arrows.push({
              direction,
              reverse: parsed_reverse,
              is_loop: parsed_loop_options.is_loop,
              is_phantom,
              name,
              source_center_anchor,
              target_center_anchor,
              label,
              from_x,
              from_y,
              from_ref,
              to_x,
              to_y,
              to_ref,
              options: parsed_options,
              label_colour,
            })

            rest = remaining_after_arrow
          }
          None => break
        }
      }
      None => break
    }
  }
  arrows
}

///|
fn tikz_direction_delta(direction : String) -> (Int, Int) {
  let mut dx = 0
  let mut dy = 0
  for ch in direction {
    if ch == 'r' {
      dx = dx + 1
    } else if ch == 'l' {
      dx = dx - 1
    } else if ch == 'd' {
      dy = dy + 1
    } else if ch == 'u' {
      dy = dy - 1
    }
  }
  (dx, dy)
}

///|
fn tikz_grid_key(x : Int, y : Int) -> String {
  ["x=", x.to_string(), ",y=", y.to_string()].join("")
}

///|
fn tikz_resolve_pending_endpoint_id(
  grid_x : Int?,
  grid_y : Int?,
  reference_name : String?,
  default_x : Int,
  default_y : Int,
  use_default : Bool,
  vertex_by_key : Map[String, Int],
  named_cell_ids : Map[String, TikzNamedCellRef],
) -> TikzResolvedEndpoint? {
  match reference_name {
    Some(name) =>
      match named_cell_ids.get(name) {
        Some(named) => Some({ id: named.id, center_anchor: named.center_anchor })
        None =>
          match tikz_parse_grid_reference(name) {
            Some((x, y)) =>
              match vertex_by_key.get(tikz_grid_key(x, y)) {
                Some(id) => Some({ id, center_anchor: false })
                None => None
              }
            None => None
          }
      }
    None => {
      let resolved_grid = match (grid_x, grid_y) {
        (Some(x), Some(y)) => Some((x, y))
        _ =>
          if use_default {
            Some((default_x, default_y))
          } else {
            None
          }
      }
      match resolved_grid {
        Some((x, y)) =>
          match vertex_by_key.get(tikz_grid_key(x, y)) {
            Some(id) => Some({ id, center_anchor: false })
            None => None
          }
        None => None
      }
    }
  }
}

///|
fn tikz_edge_matches_phantom_anchor(
  edge : Edge,
  source_id : Int,
  target_id : Int,
  options : EdgeOptions,
) -> Bool {
  edge.source == source_id &&
  edge.target == target_id &&
  edge.options.offset == options.offset &&
  edge.options.curve == options.curve
}

///|
fn tikz_find_phantom_anchor_edge_id(
  quiver : Quiver,
  source_id : Int,
  target_id : Int,
  options : EdgeOptions,
) -> Int? {
  let mut matched : Int? = None
  for cell in quiver.all_cells() {
    match cell {
      CellData::Edge(edge) =>
        if tikz_edge_matches_phantom_anchor(edge, source_id, target_id, options) {
          matched = Some(edge.cell.id)
        }
      _ => ()
    }
  }
  matched
}

///|
fn tikz_is_phantom_helper_name(reference_name : String) -> Bool {
  let name = reference_name.trim().to_string()
  if name.length() < 2 || !name.has_suffix("p") {
    return false
  }

  let prefix = name.unsafe_substring(start=0, end=name.length() - 1)
  if prefix == "" {
    return false
  }

  for byte in @utf8.encode(prefix) {
    let code = byte.to_int()
    if code < 48 || code > 57 {
      return false
    }
  }
  true
}

///|
fn tikz_has_wrapper_marker(input : String) -> Bool {
  for raw_line in input.split("\n") {
    let line = raw_line.to_string().trim().to_string()
    if line == "" {
      continue
    }
    if line.has_prefix("% ") ||
      line.has_prefix("// ") ||
      line.contains("<!--") ||
      line.contains("src=") {
      return true
    }
  }
  false
}

///|
fn tikz_is_share_reference_candidate(reference : String) -> Bool {
  if reference == "" {
    return false
  }

  let has_share_markers = reference.contains("q.uiver.app") ||
    reference.contains("#q=") ||
    reference.contains("?q=") ||
    reference.contains("&q=") ||
    reference.has_prefix("q=") ||
    reference.has_prefix("r=") ||
    reference.has_prefix("macro_url=") ||
    reference.has_prefix("embed")

  if has_share_markers {
    let parsed = Quiver::parse_base64_share_url(reference)
    match parsed.payload {
      Some(payload) => {
        let payload_result : Result[Quiver, Error] = try? Quiver::import_base64_v0(
          payload,
        )
        return payload_result is Ok(_)
      }
      None => return false
    }
  }

  let parsed : Result[Quiver, Error] = try? Quiver::import_base64_v0(reference)
  parsed is Ok(_)
}

///|
fn tikz_promote_imported_edge_level(
  quiver : Quiver,
  edge_id : Int,
  minimum_level : Int,
) -> Unit {
  if minimum_level < 1 {
    return
  }

  match quiver.cells.get(edge_id) {
    Some(CellData::Edge(edge)) => {
      if edge.cell.level >= minimum_level {
        return
      }
      let old_level = edge.cell.level
      quiver.remove_from_level(old_level, edge_id)
      quiver.ensure_level(minimum_level)
      quiver.cells_by_level[minimum_level].set(edge_id, true)
      quiver.cells.set(
        edge_id,
        CellData::Edge(edge.reconnected(edge.source, edge.target, minimum_level)),
      )
    }
    _ => ()
  }
}

///|
fn tikz_ensure_implicit_vertex_at(
  quiver : Quiver,
  vertex_by_key : Map[String, Int],
  x : Int,
  y : Int,
  next_id : Int,
) -> Int {
  let key = tikz_grid_key(x, y)
  match vertex_by_key.get(key) {
    Some(_) => next_id
    None => {
      let vertex_id = next_id
      quiver.add(CellData::from_vertex(Vertex::new_black(vertex_id, "", x, y)))
      vertex_by_key.set(key, vertex_id)
      vertex_id + 1
    }
  }
}

///|
fn Quiver::import_tikz_cd_minimal(input : String) -> Quiver {
  let environment = match tikz_extract_environment_body(input) {
    Some(value) => value
    None => abort("missing tikzcd environment")
  }

  let body_without_comments = tikz_strip_line_comments(environment.body)
  let rows = tikz_split_rows(body_without_comments)
  let quiver = Quiver::new()
  let vertex_by_key : Map[String, Int] = Map::new()
  let pending_arrows : Array[TikzPendingArrow] = []
  let mut next_id = 1

  let mut y = 0
  for row_raw in rows {
    let row = row_raw.trim().to_string()
    if row == "" {
      continue
    }
    let cells = tikz_split_cells(row, environment.ampersand_replacement)
    let mut x = 0
    for cell_raw in cells {
      let cell = cell_raw.trim().to_string()
      let label_raw = tikz_cell_label_raw(cell)
      if label_raw != "" {
        let parsed_vertex = tikz_parse_vertex_label(label_raw)
        let vertex_id = next_id
        next_id = next_id + 1
        quiver.add(
          CellData::from_vertex(
            Vertex::new(
              vertex_id,
              parsed_vertex.label,
              x,
              y,
              parsed_vertex.label_colour,
            ),
          ),
        )
        vertex_by_key.set(tikz_grid_key(x, y), vertex_id)
      }

      for parsed_arrow in tikz_collect_cell_arrows(cell) {
        let default_source_x = match parsed_arrow.from_x {
          Some(value) => value
          None => x
        }
        let default_source_y = match parsed_arrow.from_y {
          Some(value) => value
          None => y
        }

        let target_coords = if parsed_arrow.to_ref is Some(_) {
          None
        } else {
          match (parsed_arrow.to_x, parsed_arrow.to_y) {
            (Some(tx), Some(ty)) => Some((tx, ty))
            _ =>
              match parsed_arrow.direction {
                Some(direction) => {
                  let (dx, dy) = tikz_direction_delta(direction)
                  Some((default_source_x + dx, default_source_y + dy))
                }
                None =>
                  if parsed_arrow.is_loop {
                    Some((default_source_x, default_source_y))
                  } else {
                    None
                  }
              }
          }
        }

        let (target_x, target_y) = match target_coords {
          Some((tx, ty)) => (Some(tx), Some(ty))
          None => (None, None)
        }

        pending_arrows.push({
          default_source_x,
          default_source_y,
          reverse: parsed_arrow.reverse,
          is_loop: parsed_arrow.is_loop,
          source_x: parsed_arrow.from_x,
          source_y: parsed_arrow.from_y,
          source_ref: parsed_arrow.from_ref,
          source_center_anchor: parsed_arrow.source_center_anchor,
          target_x,
          target_y,
          target_ref: parsed_arrow.to_ref,
          target_center_anchor: parsed_arrow.target_center_anchor,
          is_phantom: parsed_arrow.is_phantom,
          name: parsed_arrow.name,
          label: parsed_arrow.label,
          options: parsed_arrow.options,
          label_colour: parsed_arrow.label_colour,
        })
      }

      x = x + 1
    }
    y = y + 1
  }

  for pending in pending_arrows {
    if pending.source_ref is None {
      let (source_x, source_y) = match (pending.source_x, pending.source_y) {
        (Some(x), Some(y)) => (x, y)
        _ => (pending.default_source_x, pending.default_source_y)
      }
      next_id = tikz_ensure_implicit_vertex_at(
        quiver,
        vertex_by_key,
        source_x,
        source_y,
        next_id,
      )
    }

    if pending.target_ref is None {
      match (pending.target_x, pending.target_y) {
        (Some(x), Some(y)) =>
          next_id = tikz_ensure_implicit_vertex_at(
            quiver,
            vertex_by_key,
            x,
            y,
            next_id,
          )
        _ => ()
      }
    }
  }

  let named_cell_ids : Map[String, TikzNamedCellRef] = Map::new()
  let mut pending_round = pending_arrows.copy()
  let mut made_progress = true
  while pending_round.length() > 0 && made_progress {
    made_progress = false
    let next_round : Array[TikzPendingArrow] = []
    for pending in pending_round {
      let source_endpoint = match
        tikz_resolve_pending_endpoint_id(
          pending.source_x,
          pending.source_y,
          pending.source_ref,
          pending.default_source_x,
          pending.default_source_y,
          true,
          vertex_by_key,
          named_cell_ids,
        ) {
        Some(value) => value
        None => {
          next_round.push(pending)
          continue
        }
      }
      let target_endpoint = match
        tikz_resolve_pending_endpoint_id(
          pending.target_x,
          pending.target_y,
          pending.target_ref,
          pending.default_source_x,
          pending.default_source_y,
          false,
          vertex_by_key,
          named_cell_ids,
        ) {
        Some(value) => value
        None => {
          next_round.push(pending)
          continue
        }
      }

      let source_id = source_endpoint.id
      let target_id = target_endpoint.id
      let source_center_anchor = pending.source_center_anchor ||
        source_endpoint.center_anchor
      let target_center_anchor = pending.target_center_anchor ||
        target_endpoint.center_anchor
      let (
        resolved_source_id,
        resolved_target_id,
        resolved_source_center_anchor,
        resolved_target_center_anchor,
      ) = if pending.reverse {
        (target_id, source_id, target_center_anchor, source_center_anchor)
      } else {
        (source_id, target_id, source_center_anchor, target_center_anchor)
      }

      if pending.is_loop {
        if resolved_source_id != resolved_target_id {
          continue
        }
      } else if resolved_source_id == resolved_target_id {
        continue
      }

      if pending.is_phantom {
        let matched_helper_edge_id = tikz_find_phantom_anchor_edge_id(
          quiver,
          resolved_source_id,
          resolved_target_id,
          pending.options,
        )
        let helper_reference = match pending.name {
          Some(reference_name) =>
            if tikz_is_phantom_helper_name(reference_name) {
              Some(reference_name)
            } else {
              None
            }
          None => None
        }
        match helper_reference {
          Some(reference_name) =>
            match matched_helper_edge_id {
              Some(edge_id) => {
                named_cell_ids.set(reference_name, {
                  id: edge_id,
                  center_anchor: resolved_source_center_anchor ||
                    resolved_target_center_anchor,
                })
                made_progress = true
              }
              None => next_round.push(pending)
            }
          None => ()
        }
        if helper_reference is Some(_) {
          continue
        }

        if pending.name is None {
          if matched_helper_edge_id is Some(_) {
            made_progress = true
            continue
          }
        }
      }

      let edge_id = next_id
      next_id = next_id + 1
      let edge_options = pending.options
        .with_edge_alignment_source(!resolved_source_center_anchor)
        .with_edge_alignment_target(!resolved_target_center_anchor)
      quiver.add(
        CellData::from_edge(
          Edge::new(
            edge_id,
            pending.label,
            resolved_source_id,
            resolved_target_id,
            edge_options,
            pending.label_colour,
          ),
        ),
      )
      quiver.connect(resolved_source_id, resolved_target_id, edge_id)
      tikz_promote_imported_edge_level(quiver, edge_id, pending.options.level)
      match pending.name {
        Some(reference_name) =>
          named_cell_ids.set(reference_name, {
            id: edge_id,
            center_anchor: false,
          })
        None => ()
      }
      made_progress = true
    }
    pending_round = next_round
  }

  quiver
}

///|
fn tikz_has_share_reference_hint(input : String) -> Bool {
  if !tikz_has_wrapper_marker(input) {
    return false
  }

  match Quiver::extract_base64_share_reference(input) {
    Some(reference) => tikz_is_share_reference_candidate(reference)
    None => false
  }
}

///|
pub fn Quiver::import_tikz_cd_result(
  input : String,
  default_renderer? : String = "canvas",
) -> Base64ShareImportResult raise {
  let looks_like_tikz = input.contains("\\begin{tikzcd}") &&
    input.contains("\\end{tikzcd}")
  if looks_like_tikz {
    if !tikz_has_share_reference_hint(input) {
      return {
        quiver: Quiver::import_tikz_cd_minimal(input),
        macro_url: None,
        renderer: None,
        embed: false,
      }
    }

    // Prefer wrapper import when a share reference is detected, but keep
    // handwritten diagrams robust when the wrapper marker is malformed.
    let imported : Result[Base64ShareImportResult, Error] = try? Quiver::import_base64_share_text(
      input,
      default_renderer~,
    )
    match imported {
      Ok(result) => result
      Err(_) => {
        quiver: Quiver::import_tikz_cd_minimal(input),
        macro_url: None,
        renderer: None,
        embed: false,
      }
    }
  } else {
    Quiver::import_base64_share_text(input, default_renderer~)
  }
}

///|
pub fn Quiver::import_tikz_cd(
  input : String,
  default_renderer? : String = "canvas",
) -> Quiver raise {
  Quiver::import_tikz_cd_result(input, default_renderer~).quiver
}
