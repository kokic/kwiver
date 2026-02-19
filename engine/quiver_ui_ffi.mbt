///|
pub struct QuiverUiAdapter {
  mut quiver : Quiver
}

///|
pub struct QuiverUiImportResult {
  payload : String
  macro_url : String?
  renderer : String?
  embed : Bool
}

///|
pub struct QuiverUiIdRemap {
  old_id : Int
  new_id : Int
}

///|
pub struct QuiverUiSelectionImportResult {
  payload : String
  imported_ids : Array[Int]
  id_remap : Array[QuiverUiIdRemap]
}

///|
pub struct QuiverUiSetLabelPatch {
  cell_id : Int
  label : String
}

///|
pub struct QuiverUiSetLabelColourPatch {
  cell_id : Int
  label_colour : Colour
}

///|
pub struct QuiverUiMoveVertexPatch {
  vertex_id : Int
  x : Int
  y : Int
}

///|
pub struct QuiverUiSetEdgeOptionsPatch {
  edge_id : Int
  options : EdgeOptions
}

///|
pub struct QuiverUiReconnectEdgePatch {
  edge_id : Int
  source_id : Int
  target_id : Int
}

///|
pub struct QuiverUiMutationBatch {
  labels : Array[QuiverUiSetLabelPatch]
  label_colours : Array[QuiverUiSetLabelColourPatch]
  vertex_positions : Array[QuiverUiMoveVertexPatch]
  edge_options : Array[QuiverUiSetEdgeOptionsPatch]
  edge_connections : Array[QuiverUiReconnectEdgePatch]
}

///|
pub struct QuiverUiMutationBatchResult {
  payload : String
  label_results : Array[Bool]
  label_colour_results : Array[Bool]
  vertex_position_results : Array[Bool]
  edge_option_results : Array[Bool]
  edge_connection_results : Array[Bool]
}

///|
pub struct QuiverUiAddResult {
  id : Int
  payload : String
}

///|
pub struct QuiverUiRemoveResult {
  removed_ids : Array[Int]
  payload : String
}

///|
pub struct QuiverUiColourData {
  h : Int
  s : Int
  l : Int
  a : Double
}

///|
pub struct QuiverUiEdgeEndpointStyleData {
  name : String
  side : String
}

///|
pub struct QuiverUiEdgeStyleData {
  name : String
  tail : QuiverUiEdgeEndpointStyleData
  body : QuiverUiEdgeEndpointStyleData
  head : QuiverUiEdgeEndpointStyleData
}

///|
pub struct QuiverUiEdgeOptionsData {
  label_alignment : String
  label_position : Int
  offset : Int
  curve : Int
  radius : Int
  angle : Int
  shorten_source : Int
  shorten_target : Int
  level : Int
  shape : String
  colour : QuiverUiColourData
  edge_alignment_source : Bool
  edge_alignment_target : Bool
  style : QuiverUiEdgeStyleData
}

///|
pub struct QuiverUiVertexData {
  id : Int
  level : Int
  label : String
  label_colour : QuiverUiColourData
  x : Int
  y : Int
}

///|
pub struct QuiverUiEdgeData {
  id : Int
  level : Int
  label : String
  label_colour : QuiverUiColourData
  source_id : Int
  target_id : Int
  options : QuiverUiEdgeOptionsData
}

///|
pub struct QuiverUiCellDependenciesData {
  cell_id : Int
  dependencies : Array[Int]
  reverse_dependencies : Array[Int]
}

///|
pub struct QuiverUiSnapshot {
  payload : String
  cell_ids : Array[Int]
  vertices : Array[QuiverUiVertexData]
  edges : Array[QuiverUiEdgeData]
  dependencies : Array[QuiverUiCellDependenciesData]
}

///|
pub fn QuiverUiAdapter::new() -> QuiverUiAdapter {
  { quiver: Quiver::new() }
}

///|
pub fn QuiverUiSetLabelPatch::new(
  cell_id : Int,
  label : String,
) -> QuiverUiSetLabelPatch {
  { cell_id, label }
}

///|
pub fn QuiverUiSetLabelColourPatch::new(
  cell_id : Int,
  label_colour : Colour,
) -> QuiverUiSetLabelColourPatch {
  { cell_id, label_colour }
}

///|
pub fn QuiverUiMoveVertexPatch::new(
  vertex_id : Int,
  x : Int,
  y : Int,
) -> QuiverUiMoveVertexPatch {
  { vertex_id, x, y }
}

///|
pub fn QuiverUiSetEdgeOptionsPatch::new(
  edge_id : Int,
  options : EdgeOptions,
) -> QuiverUiSetEdgeOptionsPatch {
  { edge_id, options }
}

///|
pub fn QuiverUiReconnectEdgePatch::new(
  edge_id : Int,
  source_id : Int,
  target_id : Int,
) -> QuiverUiReconnectEdgePatch {
  { edge_id, source_id, target_id }
}

///|
pub fn QuiverUiMutationBatch::default() -> QuiverUiMutationBatch {
  {
    labels: [],
    label_colours: [],
    vertex_positions: [],
    edge_options: [],
    edge_connections: [],
  }
}

///|
pub fn QuiverUiMutationBatch::new(
  labels : Array[QuiverUiSetLabelPatch],
  label_colours : Array[QuiverUiSetLabelColourPatch],
  vertex_positions : Array[QuiverUiMoveVertexPatch],
  edge_options : Array[QuiverUiSetEdgeOptionsPatch],
  edge_connections : Array[QuiverUiReconnectEdgePatch],
) -> QuiverUiMutationBatch {
  { labels, label_colours, vertex_positions, edge_options, edge_connections }
}

///|
fn quiver_ui_import_result(
  quiver : Quiver,
  macro_url : String?,
  renderer : String?,
  embed : Bool,
) -> QuiverUiImportResult {
  { payload: quiver.export_base64_v0(), macro_url, renderer, embed }
}

///|
fn quiver_ui_sorted_id_remap(remap : Map[Int, Int]) -> Array[QuiverUiIdRemap] {
  let out : Array[QuiverUiIdRemap] = []
  remap.each((old_id, new_id) => out.push({ old_id, new_id }))
  out.sort_by((a, b) => a.old_id - b.old_id)
  out
}

///|
fn quiver_ui_order_dependency_ids(
  quiver : Quiver,
  dependencies : @hashmap.HashMap[Int, DependencyRole],
) -> Array[Int] {
  let ordered : Array[Int] = []
  for cell_id in quiver.all_cell_ids() {
    if dependencies.contains(cell_id) {
      ordered.push(cell_id)
    }
  }
  ordered
}

///|
fn quiver_ui_order_reverse_dependency_ids(
  quiver : Quiver,
  reverse_dependencies : @hashmap.HashMap[Int, Bool],
) -> Array[Int] {
  let ordered : Array[Int] = []
  for cell_id in quiver.all_cell_ids() {
    if reverse_dependencies.contains(cell_id) {
      ordered.push(cell_id)
    }
  }
  ordered
}

///|
fn quiver_ui_colour_data(colour : Colour) -> QuiverUiColourData {
  { h: colour.h, s: colour.s, l: colour.l, a: colour.a }
}

///|
fn quiver_ui_edge_endpoint_style_data(
  endpoint : EdgeEndpointStyle,
) -> QuiverUiEdgeEndpointStyleData {
  { name: endpoint.name, side: endpoint.side }
}

///|
fn quiver_ui_edge_style_data(style : EdgeStyle) -> QuiverUiEdgeStyleData {
  {
    name: style.name,
    tail: quiver_ui_edge_endpoint_style_data(style.tail),
    body: quiver_ui_edge_endpoint_style_data(style.body),
    head: quiver_ui_edge_endpoint_style_data(style.head),
  }
}

///|
fn quiver_ui_label_alignment_name(alignment : LabelAlignment) -> String {
  match alignment {
    LabelAlignment::Left => "left"
    LabelAlignment::Centre => "centre"
    LabelAlignment::Right => "right"
    LabelAlignment::Over => "over"
  }
}

///|
fn quiver_ui_edge_shape_name(shape : EdgeShape) -> String {
  match shape {
    EdgeShape::Bezier => "bezier"
    EdgeShape::Arc => "arc"
  }
}

///|
fn quiver_ui_edge_options_data(options : EdgeOptions) -> QuiverUiEdgeOptionsData {
  {
    label_alignment: quiver_ui_label_alignment_name(options.label_alignment),
    label_position: options.label_position,
    offset: options.offset,
    curve: options.curve,
    radius: options.radius,
    angle: options.angle,
    shorten_source: options.shorten.source,
    shorten_target: options.shorten.target,
    level: options.level,
    shape: quiver_ui_edge_shape_name(options.shape),
    colour: quiver_ui_colour_data(options.colour),
    edge_alignment_source: options.edge_alignment.source,
    edge_alignment_target: options.edge_alignment.target,
    style: quiver_ui_edge_style_data(options.style),
  }
}

///|
fn quiver_ui_vertex_data(vertex : Vertex) -> QuiverUiVertexData {
  {
    id: vertex.cell.id,
    level: vertex.cell.level,
    label: vertex.cell.label,
    label_colour: quiver_ui_colour_data(vertex.cell.label_colour),
    x: vertex.x,
    y: vertex.y,
  }
}

///|
fn quiver_ui_edge_data(edge : Edge) -> QuiverUiEdgeData {
  {
    id: edge.cell.id,
    level: edge.cell.level,
    label: edge.cell.label,
    label_colour: quiver_ui_colour_data(edge.cell.label_colour),
    source_id: edge.source,
    target_id: edge.target,
    options: quiver_ui_edge_options_data(edge.options),
  }
}

///|
fn quiver_ui_cell_dependencies_data(
  quiver : Quiver,
  cell_id : Int,
) -> QuiverUiCellDependenciesData {
  {
    cell_id,
    dependencies: quiver_ui_order_dependency_ids(quiver, quiver.dependencies_of(cell_id)),
    reverse_dependencies: quiver_ui_order_reverse_dependency_ids(
      quiver,
      quiver.reverse_dependencies_of(cell_id),
    ),
  }
}

///|
fn quiver_ui_int_array_json(values : Array[Int]) -> Json {
  let out : Array[Json] = []
  for value in values {
    out.push(Json::number(value.to_double()))
  }
  Json::array(out)
}

///|
fn quiver_ui_colour_json(data : QuiverUiColourData) -> Json {
  let out : Map[String, Json] = Map::new()
  out.set("h", Json::number(data.h.to_double()))
  out.set("s", Json::number(data.s.to_double()))
  out.set("l", Json::number(data.l.to_double()))
  out.set("a", Json::number(data.a))
  Json::object(out)
}

///|
fn quiver_ui_endpoint_style_json(data : QuiverUiEdgeEndpointStyleData) -> Json {
  let out : Map[String, Json] = Map::new()
  out.set("name", Json::string(data.name))
  out.set("side", Json::string(data.side))
  Json::object(out)
}

///|
fn quiver_ui_edge_style_json(data : QuiverUiEdgeStyleData) -> Json {
  let out : Map[String, Json] = Map::new()
  out.set("name", Json::string(data.name))
  out.set("tail", quiver_ui_endpoint_style_json(data.tail))
  out.set("body", quiver_ui_endpoint_style_json(data.body))
  out.set("head", quiver_ui_endpoint_style_json(data.head))
  Json::object(out)
}

///|
fn quiver_ui_edge_options_json(data : QuiverUiEdgeOptionsData) -> Json {
  let out : Map[String, Json] = Map::new()
  out.set("label_alignment", Json::string(data.label_alignment))
  out.set("label_position", Json::number(data.label_position.to_double()))
  out.set("offset", Json::number(data.offset.to_double()))
  out.set("curve", Json::number(data.curve.to_double()))
  out.set("radius", Json::number(data.radius.to_double()))
  out.set("angle", Json::number(data.angle.to_double()))
  out.set("shorten_source", Json::number(data.shorten_source.to_double()))
  out.set("shorten_target", Json::number(data.shorten_target.to_double()))
  out.set("level", Json::number(data.level.to_double()))
  out.set("shape", Json::string(data.shape))
  out.set("colour", quiver_ui_colour_json(data.colour))
  out.set("edge_alignment_source", Json::boolean(data.edge_alignment_source))
  out.set("edge_alignment_target", Json::boolean(data.edge_alignment_target))
  out.set("style", quiver_ui_edge_style_json(data.style))
  Json::object(out)
}

///|
fn quiver_ui_vertex_json(data : QuiverUiVertexData) -> Json {
  let out : Map[String, Json] = Map::new()
  out.set("id", Json::number(data.id.to_double()))
  out.set("level", Json::number(data.level.to_double()))
  out.set("label", Json::string(data.label))
  out.set("label_colour", quiver_ui_colour_json(data.label_colour))
  out.set("x", Json::number(data.x.to_double()))
  out.set("y", Json::number(data.y.to_double()))
  Json::object(out)
}

///|
fn quiver_ui_edge_json(data : QuiverUiEdgeData) -> Json {
  let out : Map[String, Json] = Map::new()
  out.set("id", Json::number(data.id.to_double()))
  out.set("level", Json::number(data.level.to_double()))
  out.set("label", Json::string(data.label))
  out.set("label_colour", quiver_ui_colour_json(data.label_colour))
  out.set("source_id", Json::number(data.source_id.to_double()))
  out.set("target_id", Json::number(data.target_id.to_double()))
  out.set("options", quiver_ui_edge_options_json(data.options))
  Json::object(out)
}

///|
fn quiver_ui_dependencies_json(data : QuiverUiCellDependenciesData) -> Json {
  let out : Map[String, Json] = Map::new()
  out.set("cell_id", Json::number(data.cell_id.to_double()))
  out.set("dependencies", quiver_ui_int_array_json(data.dependencies))
  out.set(
    "reverse_dependencies",
    quiver_ui_int_array_json(data.reverse_dependencies),
  )
  Json::object(out)
}

///|
fn quiver_ui_snapshot_json(snapshot : QuiverUiSnapshot) -> Json {
  let vertices : Array[Json] = []
  for vertex in snapshot.vertices {
    vertices.push(quiver_ui_vertex_json(vertex))
  }

  let edges : Array[Json] = []
  for edge in snapshot.edges {
    edges.push(quiver_ui_edge_json(edge))
  }

  let dependencies : Array[Json] = []
  for dependency in snapshot.dependencies {
    dependencies.push(quiver_ui_dependencies_json(dependency))
  }

  let out : Map[String, Json] = Map::new()
  out.set("payload", Json::string(snapshot.payload))
  out.set("cell_ids", quiver_ui_int_array_json(snapshot.cell_ids))
  out.set("vertices", Json::array(vertices))
  out.set("edges", Json::array(edges))
  out.set("dependencies", Json::array(dependencies))
  Json::object(out)
}

///|
fn quiver_ui_option_string_json(value : String?) -> Json {
  match value {
    Some(text) => Json::string(text)
    None => Json::null()
  }
}

///|
fn quiver_ui_id_remap_json(data : QuiverUiIdRemap) -> Json {
  let out : Map[String, Json] = Map::new()
  out.set("old_id", Json::number(data.old_id.to_double()))
  out.set("new_id", Json::number(data.new_id.to_double()))
  Json::object(out)
}

///|
fn quiver_ui_import_result_json(result : QuiverUiImportResult) -> Json {
  let out : Map[String, Json] = Map::new()
  out.set("payload", Json::string(result.payload))
  out.set("macro_url", quiver_ui_option_string_json(result.macro_url))
  out.set("renderer", quiver_ui_option_string_json(result.renderer))
  out.set("embed", Json::boolean(result.embed))
  Json::object(out)
}

///|
fn quiver_ui_selection_import_result_json(
  result : QuiverUiSelectionImportResult,
) -> Json {
  let remap : Array[Json] = []
  for entry in result.id_remap {
    remap.push(quiver_ui_id_remap_json(entry))
  }

  let out : Map[String, Json] = Map::new()
  out.set("payload", Json::string(result.payload))
  out.set("imported_ids", quiver_ui_int_array_json(result.imported_ids))
  out.set("id_remap", Json::array(remap))
  Json::object(out)
}

///|
fn quiver_ui_string_array_json(values : Array[String]) -> Json {
  let out : Array[Json] = []
  for value in values {
    out.push(Json::string(value))
  }
  Json::array(out)
}

///|
fn quiver_ui_sorted_string_keys(
  values : @hashmap.HashMap[String, Bool],
) -> Array[String] {
  let out : Array[String] = []
  values.each((value, _) => out.push(value))
  out.sort()
  out
}

///|
fn quiver_ui_tikz_dependencies_json(
  dependencies : @hashmap.HashMap[String, @hashmap.HashMap[String, Bool]],
) -> Json {
  let package_names : Array[String] = []
  dependencies.each((package_name, _) => package_names.push(package_name))
  package_names.sort()

  let out : Map[String, Json] = Map::new()
  for package_name in package_names {
    match dependencies.get(package_name) {
      Some(reasons_set) => {
        let reasons_json : Map[String, Json] = Map::new()
        for reason in quiver_ui_sorted_string_keys(reasons_set) {
          reasons_json.set(reason, Json::boolean(true))
        }
        out.set(package_name, Json::object(reasons_json))
      }
      None => ()
    }
  }
  Json::object(out)
}

///|
fn quiver_ui_tikz_export_result_json(result : TikzCdExportResult) -> Json {
  let metadata : Map[String, Json] = Map::new()
  metadata.set(
    "tikz_incompatibilities",
    quiver_ui_string_array_json(result.metadata.tikz_incompatibilities),
  )
  metadata.set(
    "dependencies",
    quiver_ui_tikz_dependencies_json(result.metadata.dependencies),
  )

  let out : Map[String, Json] = Map::new()
  out.set("data", Json::string(result.data))
  out.set("metadata", Json::object(metadata))
  Json::object(out)
}

///|
fn quiver_ui_bool_array_json(values : Array[Bool]) -> Json {
  let out : Array[Json] = []
  for value in values {
    out.push(Json::boolean(value))
  }
  Json::array(out)
}

///|
fn quiver_ui_mutation_batch_result_json(
  result : QuiverUiMutationBatchResult,
) -> Json {
  let out : Map[String, Json] = Map::new()
  out.set("payload", Json::string(result.payload))
  out.set("label_results", quiver_ui_bool_array_json(result.label_results))
  out.set(
    "label_colour_results",
    quiver_ui_bool_array_json(result.label_colour_results),
  )
  out.set(
    "vertex_position_results",
    quiver_ui_bool_array_json(result.vertex_position_results),
  )
  out.set(
    "edge_option_results",
    quiver_ui_bool_array_json(result.edge_option_results),
  )
  out.set(
    "edge_connection_results",
    quiver_ui_bool_array_json(result.edge_connection_results),
  )
  Json::object(out)
}

///|
fn quiver_ui_add_result_json(result : QuiverUiAddResult) -> Json {
  let out : Map[String, Json] = Map::new()
  out.set("id", Json::number(result.id.to_double()))
  out.set("payload", Json::string(result.payload))
  Json::object(out)
}

///|
fn quiver_ui_remove_result_json(result : QuiverUiRemoveResult) -> Json {
  let out : Map[String, Json] = Map::new()
  out.set("removed_ids", quiver_ui_int_array_json(result.removed_ids))
  out.set("payload", Json::string(result.payload))
  Json::object(out)
}

///|
fn quiver_ui_payload_result_json(payload : String) -> Json {
  let out : Map[String, Json] = Map::new()
  out.set("payload", Json::string(payload))
  Json::object(out)
}

///|
fn quiver_ui_ok_payload_result_json(ok : Bool, payload : String) -> Json {
  let out : Map[String, Json] = Map::new()
  out.set("ok", Json::boolean(ok))
  out.set("payload", Json::string(payload))
  Json::object(out)
}

///|
fn quiver_ui_json_required_field(root : Map[String, Json], key : String) -> Json {
  match root.get(key) {
    Some(value) => value
    None => abort("missing required field in mutation batch json: " + key)
  }
}

///|
fn quiver_ui_json_optional_field(root : Map[String, Json], key : String) -> Json? {
  root.get(key)
}

///|
fn quiver_ui_json_array_field_or_empty(
  root : Map[String, Json],
  key : String,
) -> Array[Json] raise {
  match root.get(key) {
    Some(value) => @json.from_json(value)
    None => []
  }
}

///|
fn quiver_ui_colour_from_json(raw : Json) -> Colour raise {
  let root : Map[String, Json] = @json.from_json(raw)
  let h : Int = @json.from_json(quiver_ui_json_required_field(root, "h"))
  let s : Int = @json.from_json(quiver_ui_json_required_field(root, "s"))
  let l : Int = @json.from_json(quiver_ui_json_required_field(root, "l"))
  let a : Double = @json.from_json(quiver_ui_json_required_field(root, "a"))
  Colour::new(h, s, l, a)
}

///|
fn quiver_ui_label_alignment_from_json(raw : Json) -> LabelAlignment raise {
  let value : String = @json.from_json(raw)
  if value == "left" {
    return LabelAlignment::Left
  }
  if value == "centre" || value == "center" {
    return LabelAlignment::Centre
  }
  if value == "right" {
    return LabelAlignment::Right
  }
  if value == "over" {
    return LabelAlignment::Over
  }
  abort("invalid label_alignment in mutation batch json: " + value)
}

///|
fn quiver_ui_edge_shape_from_json(raw : Json) -> EdgeShape raise {
  let value : String = @json.from_json(raw)
  if value == "bezier" {
    return EdgeShape::Bezier
  }
  if value == "arc" {
    return EdgeShape::Arc
  }
  abort("invalid shape in mutation batch json: " + value)
}

///|
fn quiver_ui_edge_endpoint_style_from_json(raw : Json) -> EdgeEndpointStyle raise {
  let root : Map[String, Json] = @json.from_json(raw)
  {
    name: @json.from_json(quiver_ui_json_required_field(root, "name")),
    side: @json.from_json(quiver_ui_json_required_field(root, "side")),
  }
}

///|
fn quiver_ui_edge_style_from_json(raw : Json) -> EdgeStyle raise {
  let root : Map[String, Json] = @json.from_json(raw)
  {
    name: @json.from_json(quiver_ui_json_required_field(root, "name")),
    tail: quiver_ui_edge_endpoint_style_from_json(
      quiver_ui_json_required_field(root, "tail"),
    ),
    body: quiver_ui_edge_endpoint_style_from_json(
      quiver_ui_json_required_field(root, "body"),
    ),
    head: quiver_ui_edge_endpoint_style_from_json(
      quiver_ui_json_required_field(root, "head"),
    ),
  }
}

///|
fn quiver_ui_edge_options_from_json(raw : Json) -> EdgeOptions raise {
  let root : Map[String, Json] = @json.from_json(raw)
  let label_alignment = quiver_ui_label_alignment_from_json(
    quiver_ui_json_required_field(root, "label_alignment"),
  )
  let label_position : Int = @json.from_json(
    quiver_ui_json_required_field(root, "label_position"),
  )
  let offset : Int = @json.from_json(quiver_ui_json_required_field(root, "offset"))
  let curve : Int = @json.from_json(quiver_ui_json_required_field(root, "curve"))
  let radius : Int = @json.from_json(quiver_ui_json_required_field(root, "radius"))
  let angle : Int = @json.from_json(quiver_ui_json_required_field(root, "angle"))
  let shorten_source : Int = @json.from_json(
    quiver_ui_json_required_field(root, "shorten_source"),
  )
  let shorten_target : Int = @json.from_json(
    quiver_ui_json_required_field(root, "shorten_target"),
  )
  let level : Int = @json.from_json(quiver_ui_json_required_field(root, "level"))
  let shape = quiver_ui_edge_shape_from_json(
    quiver_ui_json_required_field(root, "shape"),
  )
  let colour = quiver_ui_colour_from_json(
    quiver_ui_json_required_field(root, "colour"),
  )
  let edge_alignment_source : Bool = @json.from_json(
    quiver_ui_json_required_field(root, "edge_alignment_source"),
  )
  let edge_alignment_target : Bool = @json.from_json(
    quiver_ui_json_required_field(root, "edge_alignment_target"),
  )
  let style = quiver_ui_edge_style_from_json(
    quiver_ui_json_required_field(root, "style"),
  )

  let mut options = EdgeOptions::at_level(level)
  options = match label_alignment {
    LabelAlignment::Left => options.with_label_alignment_left()
    LabelAlignment::Centre => options.with_label_alignment_centre()
    LabelAlignment::Right => options.with_label_alignment_right()
    LabelAlignment::Over => options.with_label_alignment_over()
  }
  options = options
    .with_label_position(label_position)
    .with_offset(offset)
    .with_curve(curve)
    .with_radius(radius)
    .with_angle(angle)
    .with_shorten(shorten_source, shorten_target)
  options = match shape {
    EdgeShape::Bezier => options.with_shape_bezier()
    EdgeShape::Arc => options.with_shape_arc()
  }
  options = options
    .with_colour(colour)
    .with_edge_alignment(edge_alignment_source, edge_alignment_target)
    .with_style_name(style.name)
    .with_style_tail(style.tail.name, side=style.tail.side)
    .with_style_body(style.body.name, side=style.body.side)
    .with_style_head(style.head.name, side=style.head.side)
  options
}

///|
fn quiver_ui_set_label_patch_from_json(
  raw : Json,
) -> QuiverUiSetLabelPatch raise {
  let root : Map[String, Json] = @json.from_json(raw)
  {
    cell_id: @json.from_json(quiver_ui_json_required_field(root, "cell_id")),
    label: @json.from_json(quiver_ui_json_required_field(root, "label")),
  }
}

///|
fn quiver_ui_set_label_colour_patch_from_json(
  raw : Json,
) -> QuiverUiSetLabelColourPatch raise {
  let root : Map[String, Json] = @json.from_json(raw)
  {
    cell_id: @json.from_json(quiver_ui_json_required_field(root, "cell_id")),
    label_colour: quiver_ui_colour_from_json(
      quiver_ui_json_required_field(root, "label_colour"),
    ),
  }
}

///|
fn quiver_ui_move_vertex_patch_from_json(
  raw : Json,
) -> QuiverUiMoveVertexPatch raise {
  let root : Map[String, Json] = @json.from_json(raw)
  {
    vertex_id: @json.from_json(quiver_ui_json_required_field(root, "vertex_id")),
    x: @json.from_json(quiver_ui_json_required_field(root, "x")),
    y: @json.from_json(quiver_ui_json_required_field(root, "y")),
  }
}

///|
fn quiver_ui_set_edge_options_patch_from_json(
  raw : Json,
) -> QuiverUiSetEdgeOptionsPatch raise {
  let root : Map[String, Json] = @json.from_json(raw)
  {
    edge_id: @json.from_json(quiver_ui_json_required_field(root, "edge_id")),
    options: quiver_ui_edge_options_from_json(
      quiver_ui_json_required_field(root, "options"),
    ),
  }
}

///|
fn quiver_ui_reconnect_edge_patch_from_json(
  raw : Json,
) -> QuiverUiReconnectEdgePatch raise {
  let root : Map[String, Json] = @json.from_json(raw)
  {
    edge_id: @json.from_json(quiver_ui_json_required_field(root, "edge_id")),
    source_id: @json.from_json(quiver_ui_json_required_field(root, "source_id")),
    target_id: @json.from_json(quiver_ui_json_required_field(root, "target_id")),
  }
}

///|
fn quiver_ui_mutation_batch_from_json(
  input : String,
) -> QuiverUiMutationBatch raise {
  let root : Map[String, Json] = @json.from_json(@json.parse(input))

  let labels : Array[QuiverUiSetLabelPatch] = []
  for raw in quiver_ui_json_array_field_or_empty(root, "labels") {
    labels.push(quiver_ui_set_label_patch_from_json(raw))
  }

  let label_colours : Array[QuiverUiSetLabelColourPatch] = []
  for raw in quiver_ui_json_array_field_or_empty(root, "label_colours") {
    label_colours.push(quiver_ui_set_label_colour_patch_from_json(raw))
  }

  let vertex_positions : Array[QuiverUiMoveVertexPatch] = []
  for raw in quiver_ui_json_array_field_or_empty(root, "vertex_positions") {
    vertex_positions.push(quiver_ui_move_vertex_patch_from_json(raw))
  }

  let edge_options : Array[QuiverUiSetEdgeOptionsPatch] = []
  for raw in quiver_ui_json_array_field_or_empty(root, "edge_options") {
    edge_options.push(quiver_ui_set_edge_options_patch_from_json(raw))
  }

  let edge_connections : Array[QuiverUiReconnectEdgePatch] = []
  for raw in quiver_ui_json_array_field_or_empty(root, "edge_connections") {
    edge_connections.push(quiver_ui_reconnect_edge_patch_from_json(raw))
  }

  QuiverUiMutationBatch::new(
    labels,
    label_colours,
    vertex_positions,
    edge_options,
    edge_connections,
  )
}

///|
fn quiver_ui_add_vertex_from_json(
  input : String,
) -> (String, Int, Int, Colour) raise {
  let root : Map[String, Json] = @json.from_json(@json.parse(input))
  let label : String = @json.from_json(quiver_ui_json_required_field(root, "label"))
  let x : Int = @json.from_json(quiver_ui_json_required_field(root, "x"))
  let y : Int = @json.from_json(quiver_ui_json_required_field(root, "y"))
  let label_colour = match quiver_ui_json_optional_field(root, "label_colour") {
    Some(raw) => quiver_ui_colour_from_json(raw)
    None => Colour::black()
  }
  (label, x, y, label_colour)
}

///|
fn quiver_ui_add_edge_from_json(
  input : String,
) -> (Int, Int, String, EdgeOptions, Colour) raise {
  let root : Map[String, Json] = @json.from_json(@json.parse(input))
  let source_id : Int = @json.from_json(
    quiver_ui_json_required_field(root, "source_id"),
  )
  let target_id : Int = @json.from_json(
    quiver_ui_json_required_field(root, "target_id"),
  )
  let label = match quiver_ui_json_optional_field(root, "label") {
    Some(raw) => @json.from_json(raw)
    None => ""
  }
  let options = match quiver_ui_json_optional_field(root, "options") {
    Some(raw) => quiver_ui_edge_options_from_json(raw)
    None => EdgeOptions::at_level(1)
  }
  let label_colour = match quiver_ui_json_optional_field(root, "label_colour") {
    Some(raw) => quiver_ui_colour_from_json(raw)
    None => Colour::black()
  }
  (source_id, target_id, label, options, label_colour)
}

///|
fn quiver_ui_set_cell_label_from_json(input : String) -> (Int, String) raise {
  let root : Map[String, Json] = @json.from_json(@json.parse(input))
  let cell_id : Int = @json.from_json(quiver_ui_json_required_field(root, "cell_id"))
  let label : String = @json.from_json(quiver_ui_json_required_field(root, "label"))
  (cell_id, label)
}

///|
fn quiver_ui_set_cell_label_colour_from_json(
  input : String,
) -> (Int, Colour) raise {
  let root : Map[String, Json] = @json.from_json(@json.parse(input))
  let cell_id : Int = @json.from_json(quiver_ui_json_required_field(root, "cell_id"))
  let label_colour = quiver_ui_colour_from_json(
    quiver_ui_json_required_field(root, "label_colour"),
  )
  (cell_id, label_colour)
}

///|
fn quiver_ui_move_vertex_from_json(input : String) -> (Int, Int, Int) raise {
  let root : Map[String, Json] = @json.from_json(@json.parse(input))
  let vertex_id : Int = @json.from_json(
    quiver_ui_json_required_field(root, "vertex_id"),
  )
  let x : Int = @json.from_json(quiver_ui_json_required_field(root, "x"))
  let y : Int = @json.from_json(quiver_ui_json_required_field(root, "y"))
  (vertex_id, x, y)
}

///|
fn quiver_ui_set_edge_options_from_json(
  input : String,
) -> (Int, EdgeOptions) raise {
  let root : Map[String, Json] = @json.from_json(@json.parse(input))
  let edge_id : Int = @json.from_json(quiver_ui_json_required_field(root, "edge_id"))
  let options = quiver_ui_edge_options_from_json(
    quiver_ui_json_required_field(root, "options"),
  )
  (edge_id, options)
}

///|
fn quiver_ui_set_edge_label_alignment_from_json(
  input : String,
) -> (Int, LabelAlignment) raise {
  let root : Map[String, Json] = @json.from_json(@json.parse(input))
  let edge_id : Int = @json.from_json(quiver_ui_json_required_field(root, "edge_id"))
  let label_alignment = quiver_ui_label_alignment_from_json(
    quiver_ui_json_required_field(root, "label_alignment"),
  )
  (edge_id, label_alignment)
}

///|
fn quiver_ui_set_edge_label_position_from_json(
  input : String,
) -> (Int, Int) raise {
  let root : Map[String, Json] = @json.from_json(@json.parse(input))
  let edge_id : Int = @json.from_json(quiver_ui_json_required_field(root, "edge_id"))
  let label_position : Int = @json.from_json(
    quiver_ui_json_required_field(root, "label_position"),
  )
  (edge_id, label_position)
}

///|
fn quiver_ui_reconnect_edge_from_json(input : String) -> (Int, Int, Int) raise {
  let root : Map[String, Json] = @json.from_json(@json.parse(input))
  let edge_id : Int = @json.from_json(quiver_ui_json_required_field(root, "edge_id"))
  let source_id : Int = @json.from_json(
    quiver_ui_json_required_field(root, "source_id"),
  )
  let target_id : Int = @json.from_json(
    quiver_ui_json_required_field(root, "target_id"),
  )
  (edge_id, source_id, target_id)
}

///|
fn quiver_ui_remove_from_json(input : String) -> (Int, Int) raise {
  let root : Map[String, Json] = @json.from_json(@json.parse(input))
  let cell_id : Int = @json.from_json(quiver_ui_json_required_field(root, "cell_id"))
  let when : Int = @json.from_json(quiver_ui_json_required_field(root, "when"))
  (cell_id, when)
}

///|
fn quiver_ui_flush_from_json(input : String) -> Int raise {
  let root : Map[String, Json] = @json.from_json(@json.parse(input))
  @json.from_json(quiver_ui_json_required_field(root, "when"))
}

///|
fn quiver_ui_looks_like_share_reference(input : String) -> Bool {
  input.contains("#q=") ||
  input.contains("?q=") ||
  input.contains("&q=") ||
  input.contains("q.uiver.app")
}

///|
fn quiver_ui_looks_like_tikz(input : String) -> Bool {
  input.contains("\\begin{tikzcd}") && input.contains("\\end{tikzcd}")
}

///|
fn quiver_ui_looks_like_fletcher(input : String) -> Bool {
  input.contains("#diagram({") || input.contains("diagram({")
}

///|
fn quiver_ui_looks_like_html(input : String) -> Bool {
  input.contains("<iframe") || input.contains("<!--") || input.contains("src=")
}

///|
pub fn QuiverUiAdapter::reset(self : QuiverUiAdapter) -> Unit {
  self.quiver = Quiver::new()
}

///|
pub fn QuiverUiAdapter::import_base64_state(
  self : QuiverUiAdapter,
  payload : String,
) -> String raise {
  self.quiver = Quiver::import_base64_v0(payload)
  self.quiver.export_base64_v0()
}

///|
pub fn QuiverUiAdapter::import_share_url(
  self : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  let imported = Quiver::import_base64_share_url_result(
    input,
    default_renderer~,
  )
  self.quiver = imported.quiver
  quiver_ui_import_result(
    self.quiver,
    imported.macro_url,
    imported.renderer,
    imported.embed,
  )
}

///|
pub fn QuiverUiAdapter::import_share_text(
  self : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  let imported = Quiver::import_base64_share_text(input, default_renderer~)
  self.quiver = imported.quiver
  quiver_ui_import_result(
    self.quiver,
    imported.macro_url,
    imported.renderer,
    imported.embed,
  )
}

///|
pub fn QuiverUiAdapter::import_text_auto(
  self : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  if quiver_ui_looks_like_share_reference(input) {
    return self.import_share_text(input, default_renderer~)
  }
  if quiver_ui_looks_like_tikz(input) {
    return self.import_tikz_cd(input, default_renderer~)
  }
  if quiver_ui_looks_like_fletcher(input) {
    return self.import_fletcher(input, default_renderer~)
  }
  if quiver_ui_looks_like_html(input) {
    return self.import_html_embed(input, default_renderer~)
  }

  let payload = self.import_base64_state(input)
  { payload, macro_url: None, renderer: None, embed: false }
}

///|
pub fn QuiverUiAdapter::import_tikz_cd(
  self : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  let imported = Quiver::import_tikz_cd_result(input, default_renderer~)
  self.quiver = imported.quiver
  quiver_ui_import_result(
    self.quiver,
    imported.macro_url,
    imported.renderer,
    imported.embed,
  )
}

///|
pub fn QuiverUiAdapter::import_fletcher(
  self : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  let imported = Quiver::import_fletcher_result(input, default_renderer~)
  self.quiver = imported.quiver
  quiver_ui_import_result(
    self.quiver,
    imported.macro_url,
    imported.renderer,
    imported.embed,
  )
}

///|
pub fn QuiverUiAdapter::import_html_embed(
  self : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  let imported = Quiver::import_html_embed_result(input, default_renderer~)
  self.quiver = imported.quiver
  quiver_ui_import_result(
    self.quiver,
    imported.macro_url,
    imported.renderer,
    imported.embed,
  )
}

///|
pub fn QuiverUiImportResult::to_json_string(self : QuiverUiImportResult) -> String {
  quiver_ui_import_result_json(self).stringify()
}

///|
pub fn QuiverUiAdapter::import_share_url_json(
  self : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  self.import_share_url(input, default_renderer~).to_json_string()
}

///|
pub fn QuiverUiAdapter::import_share_text_json(
  self : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  self.import_share_text(input, default_renderer~).to_json_string()
}

///|
pub fn QuiverUiAdapter::import_text_auto_json(
  self : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  self.import_text_auto(input, default_renderer~).to_json_string()
}

///|
pub fn QuiverUiAdapter::import_tikz_cd_json(
  self : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  self.import_tikz_cd(input, default_renderer~).to_json_string()
}

///|
pub fn QuiverUiAdapter::import_fletcher_json(
  self : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  self.import_fletcher(input, default_renderer~).to_json_string()
}

///|
pub fn QuiverUiAdapter::import_html_embed_json(
  self : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  self.import_html_embed(input, default_renderer~).to_json_string()
}

///|
pub fn QuiverUiAdapter::paste_base64_selection(
  self : QuiverUiAdapter,
  payload : String,
  origin_x : Int,
  origin_y : Int,
  start_id? : Int = 1,
) -> QuiverUiSelectionImportResult raise {
  let imported = self.quiver.import_base64_v0_selection_auto_ids(
    payload,
    origin_x,
    origin_y,
    start_id~,
  )
  {
    payload: self.quiver.export_base64_v0(),
    imported_ids: imported.imported_ids,
    id_remap: quiver_ui_sorted_id_remap(imported.id_remap),
  }
}

///|
pub fn QuiverUiSelectionImportResult::to_json_string(
  self : QuiverUiSelectionImportResult,
) -> String {
  quiver_ui_selection_import_result_json(self).stringify()
}

///|
pub fn QuiverUiAdapter::paste_base64_selection_json(
  self : QuiverUiAdapter,
  payload : String,
  origin_x : Int,
  origin_y : Int,
  start_id? : Int = 1,
) -> String raise {
  self.paste_base64_selection(payload, origin_x, origin_y, start_id~).to_json_string()
}

///|
pub fn QuiverUiAdapter::add_vertex(
  self : QuiverUiAdapter,
  label : String,
  x : Int,
  y : Int,
  label_colour? : Colour = Colour::black(),
) -> Int {
  let id = self.quiver.next_available_id()
  self.quiver.add(
    CellData::from_vertex(Vertex::new(id, label, x, y, label_colour)),
  )
  id
}

///|
pub fn QuiverUiAdapter::add_edge(
  self : QuiverUiAdapter,
  source_id : Int,
  target_id : Int,
  label? : String = "",
  options? : EdgeOptions = EdgeOptions::at_level(1),
  label_colour? : Colour = Colour::black(),
) -> Int {
  if !self.quiver.contains_cell(source_id) {
    abort("missing source cell")
  }
  if !self.quiver.contains_cell(target_id) {
    abort("missing target cell")
  }

  let id = self.quiver.next_available_id()
  self.quiver.add(
    CellData::from_edge(
      Edge::new(id, label, source_id, target_id, options, label_colour),
    ),
  )
  self.quiver.connect(source_id, target_id, id)
  id
}

///|
pub fn QuiverUiAddResult::to_json_string(self : QuiverUiAddResult) -> String {
  quiver_ui_add_result_json(self).stringify()
}

///|
pub fn QuiverUiRemoveResult::to_json_string(self : QuiverUiRemoveResult) -> String {
  quiver_ui_remove_result_json(self).stringify()
}

///|
pub fn QuiverUiAdapter::add_vertex_result(
  self : QuiverUiAdapter,
  label : String,
  x : Int,
  y : Int,
  label_colour? : Colour = Colour::black(),
) -> QuiverUiAddResult {
  let id = self.add_vertex(label, x, y, label_colour~)
  { id, payload: self.quiver.export_base64_v0() }
}

///|
pub fn QuiverUiAdapter::add_vertex_json(
  self : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  let (label, x, y, label_colour) = quiver_ui_add_vertex_from_json(input_json)
  self.add_vertex_result(label, x, y, label_colour~).to_json_string()
}

///|
pub fn QuiverUiAdapter::add_edge_result(
  self : QuiverUiAdapter,
  source_id : Int,
  target_id : Int,
  label? : String = "",
  options? : EdgeOptions = EdgeOptions::at_level(1),
  label_colour? : Colour = Colour::black(),
) -> QuiverUiAddResult {
  let id = self.add_edge(source_id, target_id, label~, options~, label_colour~)
  { id, payload: self.quiver.export_base64_v0() }
}

///|
pub fn QuiverUiAdapter::add_edge_json(
  self : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  let (source_id, target_id, label, options, label_colour) =
    quiver_ui_add_edge_from_json(input_json)
  self.add_edge_result(
    source_id,
    target_id,
    label~,
    options~,
    label_colour~,
  ).to_json_string()
}

///|
pub fn QuiverUiAdapter::set_cell_label(
  self : QuiverUiAdapter,
  cell_id : Int,
  label : String,
) -> Bool {
  if !self.quiver.contains_cell(cell_id) {
    return false
  }

  match self.quiver.cells.get(cell_id) {
    Some(CellData::Vertex(vertex)) => {
      self.quiver.cells.set(
        cell_id,
        CellData::from_vertex(
          Vertex::new(
            vertex.cell.id,
            label,
            vertex.x,
            vertex.y,
            vertex.cell.label_colour,
          ),
        ),
      )
      true
    }
    Some(CellData::Edge(edge)) => {
      self.quiver.cells.set(
        cell_id,
        CellData::from_edge(
          Edge::new(
            edge.cell.id,
            label,
            edge.source,
            edge.target,
            edge.options,
            edge.cell.label_colour,
          ),
        ),
      )
      true
    }
    None => false
  }
}

///|
pub fn QuiverUiAdapter::set_cell_label_json(
  self : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  let (cell_id, label) = quiver_ui_set_cell_label_from_json(input_json)
  let ok = self.set_cell_label(cell_id, label)
  quiver_ui_ok_payload_result_json(ok, self.quiver.export_base64_v0()).stringify()
}

///|
pub fn QuiverUiAdapter::set_cell_label_colour(
  self : QuiverUiAdapter,
  cell_id : Int,
  label_colour : Colour,
) -> Bool {
  if !self.quiver.contains_cell(cell_id) {
    return false
  }

  match self.quiver.cells.get(cell_id) {
    Some(CellData::Vertex(vertex)) => {
      self.quiver.cells.set(
        cell_id,
        CellData::from_vertex(
          Vertex::new(
            vertex.cell.id,
            vertex.cell.label,
            vertex.x,
            vertex.y,
            label_colour,
          ),
        ),
      )
      true
    }
    Some(CellData::Edge(edge)) => {
      self.quiver.cells.set(
        cell_id,
        CellData::from_edge(
          Edge::new(
            edge.cell.id,
            edge.cell.label,
            edge.source,
            edge.target,
            edge.options,
            label_colour,
          ),
        ),
      )
      true
    }
    None => false
  }
}

///|
pub fn QuiverUiAdapter::set_cell_label_colour_json(
  self : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  let (cell_id, label_colour) = quiver_ui_set_cell_label_colour_from_json(input_json)
  let ok = self.set_cell_label_colour(cell_id, label_colour)
  quiver_ui_ok_payload_result_json(ok, self.quiver.export_base64_v0()).stringify()
}

///|
pub fn QuiverUiAdapter::move_vertex(
  self : QuiverUiAdapter,
  vertex_id : Int,
  x : Int,
  y : Int,
) -> Bool {
  if !self.quiver.contains_cell(vertex_id) {
    return false
  }

  match self.quiver.cells.get(vertex_id) {
    Some(CellData::Vertex(vertex)) => {
      self.quiver.cells.set(
        vertex_id,
        CellData::from_vertex(
          Vertex::new(
            vertex.cell.id,
            vertex.cell.label,
            x,
            y,
            vertex.cell.label_colour,
          ),
        ),
      )
      true
    }
    _ => false
  }
}

///|
pub fn QuiverUiAdapter::move_vertex_json(
  self : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  let (vertex_id, x, y) = quiver_ui_move_vertex_from_json(input_json)
  let ok = self.move_vertex(vertex_id, x, y)
  quiver_ui_ok_payload_result_json(ok, self.quiver.export_base64_v0()).stringify()
}

///|
pub fn QuiverUiAdapter::set_edge_options(
  self : QuiverUiAdapter,
  edge_id : Int,
  options : EdgeOptions,
) -> Bool {
  if !self.quiver.contains_cell(edge_id) {
    return false
  }

  match self.quiver.cells.get(edge_id) {
    Some(CellData::Edge(edge)) => {
      let safe_options = options.with_level(edge.cell.level)
      self.quiver.cells.set(
        edge_id,
        CellData::from_edge(
          Edge::new(
            edge.cell.id,
            edge.cell.label,
            edge.source,
            edge.target,
            safe_options,
            edge.cell.label_colour,
          ),
        ),
      )
      true
    }
    _ => false
  }
}

///|
pub fn QuiverUiAdapter::set_edge_options_json(
  self : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  let (edge_id, options) = quiver_ui_set_edge_options_from_json(input_json)
  let ok = self.set_edge_options(edge_id, options)
  quiver_ui_ok_payload_result_json(ok, self.quiver.export_base64_v0()).stringify()
}

///|
pub fn QuiverUiAdapter::set_edge_label_alignment(
  self : QuiverUiAdapter,
  edge_id : Int,
  label_alignment : String,
) -> Bool {
  if !self.quiver.contains_cell(edge_id) {
    return false
  }

  match self.quiver.cells.get(edge_id) {
    Some(CellData::Edge(edge)) => {
      let updated_options = match label_alignment.trim().to_string() {
        "left" => edge.options.with_label_alignment_left()
        "centre" => edge.options.with_label_alignment_centre()
        "center" => edge.options.with_label_alignment_centre()
        "right" => edge.options.with_label_alignment_right()
        "over" => edge.options.with_label_alignment_over()
        _ => return false
      }
      self.quiver.cells.set(
        edge_id,
        CellData::from_edge(
          Edge::new(
            edge.cell.id,
            edge.cell.label,
            edge.source,
            edge.target,
            updated_options,
            edge.cell.label_colour,
          ),
        ),
      )
      true
    }
    _ => false
  }
}

///|
pub fn QuiverUiAdapter::set_edge_label_alignment_json(
  self : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  let (edge_id, label_alignment) = quiver_ui_set_edge_label_alignment_from_json(
    input_json,
  )
  let ok = self.set_edge_label_alignment(
    edge_id,
    quiver_ui_label_alignment_name(label_alignment),
  )
  quiver_ui_ok_payload_result_json(ok, self.quiver.export_base64_v0()).stringify()
}

///|
pub fn QuiverUiAdapter::set_edge_label_position(
  self : QuiverUiAdapter,
  edge_id : Int,
  label_position : Int,
) -> Bool {
  if !self.quiver.contains_cell(edge_id) {
    return false
  }

  match self.quiver.cells.get(edge_id) {
    Some(CellData::Edge(edge)) => {
      let updated_options = edge.options.with_label_position(label_position)
      self.quiver.cells.set(
        edge_id,
        CellData::from_edge(
          Edge::new(
            edge.cell.id,
            edge.cell.label,
            edge.source,
            edge.target,
            updated_options,
            edge.cell.label_colour,
          ),
        ),
      )
      true
    }
    _ => false
  }
}

///|
pub fn QuiverUiAdapter::set_edge_label_position_json(
  self : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  let (edge_id, label_position) = quiver_ui_set_edge_label_position_from_json(
    input_json,
  )
  let ok = self.set_edge_label_position(edge_id, label_position)
  quiver_ui_ok_payload_result_json(ok, self.quiver.export_base64_v0()).stringify()
}

///|
pub fn QuiverUiAdapter::reconnect_edge(
  self : QuiverUiAdapter,
  edge_id : Int,
  source_id : Int,
  target_id : Int,
) -> Bool {
  if !self.quiver.contains_cell(edge_id) ||
    !self.quiver.contains_cell(source_id) ||
    !self.quiver.contains_cell(target_id) {
    return false
  }

  match self.quiver.cells.get(edge_id) {
    Some(CellData::Edge(_)) => {
      self.quiver.connect(source_id, target_id, edge_id)
      true
    }
    _ => false
  }
}

///|
pub fn QuiverUiAdapter::reconnect_edge_json(
  self : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  let (edge_id, source_id, target_id) = quiver_ui_reconnect_edge_from_json(input_json)
  let ok = self.reconnect_edge(edge_id, source_id, target_id)
  quiver_ui_ok_payload_result_json(ok, self.quiver.export_base64_v0()).stringify()
}

///|
pub fn QuiverUiAdapter::apply_mutation_batch(
  self : QuiverUiAdapter,
  batch : QuiverUiMutationBatch,
) -> QuiverUiMutationBatchResult {
  let label_results : Array[Bool] = []
  for patch in batch.labels {
    label_results.push(self.set_cell_label(patch.cell_id, patch.label))
  }

  let label_colour_results : Array[Bool] = []
  for patch in batch.label_colours {
    label_colour_results.push(
      self.set_cell_label_colour(patch.cell_id, patch.label_colour),
    )
  }

  let vertex_position_results : Array[Bool] = []
  for patch in batch.vertex_positions {
    vertex_position_results.push(
      self.move_vertex(patch.vertex_id, patch.x, patch.y),
    )
  }

  let edge_option_results : Array[Bool] = []
  for patch in batch.edge_options {
    edge_option_results.push(self.set_edge_options(patch.edge_id, patch.options))
  }

  let edge_connection_results : Array[Bool] = []
  for patch in batch.edge_connections {
    edge_connection_results.push(
      self.reconnect_edge(patch.edge_id, patch.source_id, patch.target_id),
    )
  }

  {
    payload: self.quiver.export_base64_v0(),
    label_results,
    label_colour_results,
    vertex_position_results,
    edge_option_results,
    edge_connection_results,
  }
}

///|
pub fn QuiverUiMutationBatchResult::to_json_string(
  self : QuiverUiMutationBatchResult,
) -> String {
  quiver_ui_mutation_batch_result_json(self).stringify()
}

///|
pub fn QuiverUiAdapter::apply_mutation_batch_json(
  self : QuiverUiAdapter,
  batch_json : String,
) -> QuiverUiMutationBatchResult raise {
  self.apply_mutation_batch(quiver_ui_mutation_batch_from_json(batch_json))
}

///|
pub fn QuiverUiAdapter::apply_mutation_batch_json_result(
  self : QuiverUiAdapter,
  batch_json : String,
) -> String raise {
  self.apply_mutation_batch_json(batch_json).to_json_string()
}

///|
pub fn QuiverUiAdapter::remove(
  self : QuiverUiAdapter,
  cell_id : Int,
  when : Int,
) -> Array[Int] {
  self.quiver.remove(cell_id, when)
}

///|
pub fn QuiverUiAdapter::remove_result(
  self : QuiverUiAdapter,
  cell_id : Int,
  when : Int,
) -> QuiverUiRemoveResult {
  let removed_ids = self.remove(cell_id, when)
  { removed_ids, payload: self.quiver.export_base64_v0() }
}

///|
pub fn QuiverUiAdapter::remove_json(
  self : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  let (cell_id, when) = quiver_ui_remove_from_json(input_json)
  self.remove_result(cell_id, when).to_json_string()
}

///|
pub fn QuiverUiAdapter::flush(self : QuiverUiAdapter, when : Int) -> Unit {
  self.quiver.flush(when)
}

///|
pub fn QuiverUiAdapter::flush_json(
  self : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  self.flush(quiver_ui_flush_from_json(input_json))
  quiver_ui_payload_result_json(self.quiver.export_base64_v0()).stringify()
}

///|
pub fn QuiverUiAdapter::all_cells(self : QuiverUiAdapter) -> Array[CellData] {
  self.quiver.all_cells()
}

///|
pub fn QuiverUiAdapter::all_cell_ids(self : QuiverUiAdapter) -> Array[Int] {
  self.quiver.all_cell_ids()
}

///|
pub fn QuiverUiAdapter::snapshot(self : QuiverUiAdapter) -> QuiverUiSnapshot {
  let cell_ids = self.quiver.all_cell_ids()
  let vertices : Array[QuiverUiVertexData] = []
  let edges : Array[QuiverUiEdgeData] = []
  let dependencies : Array[QuiverUiCellDependenciesData] = []
  for cell_id in cell_ids {
    dependencies.push(quiver_ui_cell_dependencies_data(self.quiver, cell_id))
    match self.quiver.cells.get(cell_id) {
      Some(CellData::Vertex(vertex)) => vertices.push(quiver_ui_vertex_data(vertex))
      Some(CellData::Edge(edge)) => edges.push(quiver_ui_edge_data(edge))
      None => ()
    }
  }
  { payload: self.quiver.export_base64_v0(), cell_ids, vertices, edges, dependencies }
}

///|
pub fn QuiverUiSnapshot::to_json_string(self : QuiverUiSnapshot) -> String {
  quiver_ui_snapshot_json(self).stringify()
}

///|
pub fn QuiverUiAdapter::snapshot_json(self : QuiverUiAdapter) -> String {
  self.snapshot().to_json_string()
}

///|
pub fn QuiverUiAdapter::dependencies_of(
  self : QuiverUiAdapter,
  cell_id : Int,
) -> Array[Int] {
  quiver_ui_order_dependency_ids(self.quiver, self.quiver.dependencies_of(cell_id))
}

///|
pub fn QuiverUiAdapter::reverse_dependencies_of(
  self : QuiverUiAdapter,
  cell_id : Int,
) -> Array[Int] {
  quiver_ui_order_reverse_dependency_ids(
    self.quiver,
    self.quiver.reverse_dependencies_of(cell_id),
  )
}

///|
pub fn QuiverUiAdapter::transitive_dependencies(
  self : QuiverUiAdapter,
  roots : Array[Int],
  exclude_roots? : Bool = false,
) -> Array[Int] {
  self.quiver.transitive_dependencies(roots, exclude_roots~)
}

///|
pub fn QuiverUiAdapter::transitive_reverse_dependencies(
  self : QuiverUiAdapter,
  roots : Array[Int],
) -> Array[Int] {
  self.quiver.transitive_reverse_dependencies(roots)
}

///|
pub fn QuiverUiAdapter::connected_components(
  self : QuiverUiAdapter,
  roots : Array[Int],
) -> Array[Int] {
  self.quiver.connected_components(roots)
}

///|
pub fn QuiverUiAdapter::export_base64_state(self : QuiverUiAdapter) -> String {
  self.quiver.export_base64_v0()
}

///|
pub fn QuiverUiAdapter::export_base64_selection(
  self : QuiverUiAdapter,
  selected_ids : Array[Int],
  include_dependencies? : Bool = true,
) -> String {
  self.quiver.export_base64_v0_selection(selected_ids, include_dependencies~)
}

///|
pub fn QuiverUiAdapter::export_tikz_cd(
  self : QuiverUiAdapter,
  settings? : TikzCdExportSettings = TikzCdExportSettings::default(),
  options? : TikzCdExportOptions = TikzCdExportOptions::default(),
  definitions? : TikzCdExportDefinitions = TikzCdExportDefinitions::default(),
) -> TikzCdExportResult {
  self.quiver.export_tikz_cd_result(settings~, options~, definitions~)
}

///|
pub fn TikzCdExportResult::to_json_string(self : TikzCdExportResult) -> String {
  quiver_ui_tikz_export_result_json(self).stringify()
}

///|
pub fn QuiverUiAdapter::export_tikz_cd_json(
  self : QuiverUiAdapter,
  settings? : TikzCdExportSettings = TikzCdExportSettings::default(),
  options? : TikzCdExportOptions = TikzCdExportOptions::default(),
  definitions? : TikzCdExportDefinitions = TikzCdExportDefinitions::default(),
) -> String {
  self.export_tikz_cd(settings~, options~, definitions~).to_json_string()
}

///|
pub fn QuiverUiAdapter::export_fletcher(
  self : QuiverUiAdapter,
  settings? : FletcherExportSettings = FletcherExportSettings::default(),
  options? : FletcherExportOptions = FletcherExportOptions::default(),
) -> String {
  self.quiver.export_fletcher(settings~, options~)
}

///|
pub fn QuiverUiAdapter::export_html_embed(
  self : QuiverUiAdapter,
  settings : HtmlEmbedExportSettings,
  options? : HtmlEmbedExportOptions = HtmlEmbedExportOptions::default(),
) -> String {
  self.quiver.export_html_embed(settings, options~)
}

///|
pub fn ffi_adapter_new() -> QuiverUiAdapter {
  QuiverUiAdapter::new()
}

///|
pub fn ffi_adapter_reset(adapter : QuiverUiAdapter) -> Unit {
  adapter.reset()
}

///|
pub fn ffi_adapter_import_base64(
  adapter : QuiverUiAdapter,
  payload : String,
) -> String raise {
  adapter.import_base64_state(payload)
}

///|
pub fn ffi_adapter_import_share_url(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  adapter.import_share_url(input, default_renderer~)
}

///|
pub fn ffi_adapter_import_share_url_json(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  adapter.import_share_url_json(input, default_renderer~)
}

///|
pub fn ffi_adapter_import_share_text(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  adapter.import_share_text(input, default_renderer~)
}

///|
pub fn ffi_adapter_import_share_text_json(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  adapter.import_share_text_json(input, default_renderer~)
}

///|
pub fn ffi_adapter_import_text_auto(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  adapter.import_text_auto(input, default_renderer~)
}

///|
pub fn ffi_adapter_import_text_auto_json(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  adapter.import_text_auto_json(input, default_renderer~)
}

///|
pub fn ffi_adapter_import_tikz_cd(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  adapter.import_tikz_cd(input, default_renderer~)
}

///|
pub fn ffi_adapter_import_tikz_cd_json(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  adapter.import_tikz_cd_json(input, default_renderer~)
}

///|
pub fn ffi_adapter_import_fletcher(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  adapter.import_fletcher(input, default_renderer~)
}

///|
pub fn ffi_adapter_import_fletcher_json(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  adapter.import_fletcher_json(input, default_renderer~)
}

///|
pub fn ffi_adapter_import_html_embed(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  adapter.import_html_embed(input, default_renderer~)
}

///|
pub fn ffi_adapter_import_html_embed_json(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  adapter.import_html_embed_json(input, default_renderer~)
}

///|
pub fn ffi_adapter_paste_base64_selection(
  adapter : QuiverUiAdapter,
  payload : String,
  origin_x : Int,
  origin_y : Int,
  start_id? : Int = 1,
) -> QuiverUiSelectionImportResult raise {
  adapter.paste_base64_selection(payload, origin_x, origin_y, start_id~)
}

///|
pub fn ffi_adapter_paste_base64_selection_json(
  adapter : QuiverUiAdapter,
  payload : String,
  origin_x : Int,
  origin_y : Int,
  start_id? : Int = 1,
) -> String raise {
  adapter.paste_base64_selection_json(payload, origin_x, origin_y, start_id~)
}

///|
pub fn ffi_adapter_add_vertex(
  adapter : QuiverUiAdapter,
  label : String,
  x : Int,
  y : Int,
  label_colour? : Colour = Colour::black(),
) -> Int {
  adapter.add_vertex(label, x, y, label_colour~)
}

///|
pub fn ffi_adapter_add_vertex_json(
  adapter : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  adapter.add_vertex_json(input_json)
}

///|
pub fn ffi_adapter_add_edge(
  adapter : QuiverUiAdapter,
  source_id : Int,
  target_id : Int,
  label? : String = "",
  options? : EdgeOptions = EdgeOptions::at_level(1),
  label_colour? : Colour = Colour::black(),
) -> Int {
  adapter.add_edge(source_id, target_id, label~, options~, label_colour~)
}

///|
pub fn ffi_adapter_add_edge_json(
  adapter : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  adapter.add_edge_json(input_json)
}

///|
pub fn ffi_adapter_set_cell_label(
  adapter : QuiverUiAdapter,
  cell_id : Int,
  label : String,
) -> Bool {
  adapter.set_cell_label(cell_id, label)
}

///|
pub fn ffi_adapter_set_cell_label_json(
  adapter : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  adapter.set_cell_label_json(input_json)
}

///|
pub fn ffi_adapter_set_cell_label_colour(
  adapter : QuiverUiAdapter,
  cell_id : Int,
  label_colour : Colour,
) -> Bool {
  adapter.set_cell_label_colour(cell_id, label_colour)
}

///|
pub fn ffi_adapter_set_cell_label_colour_json(
  adapter : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  adapter.set_cell_label_colour_json(input_json)
}

///|
pub fn ffi_adapter_move_vertex(
  adapter : QuiverUiAdapter,
  vertex_id : Int,
  x : Int,
  y : Int,
) -> Bool {
  adapter.move_vertex(vertex_id, x, y)
}

///|
pub fn ffi_adapter_move_vertex_json(
  adapter : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  adapter.move_vertex_json(input_json)
}

///|
pub fn ffi_adapter_set_edge_options(
  adapter : QuiverUiAdapter,
  edge_id : Int,
  options : EdgeOptions,
) -> Bool {
  adapter.set_edge_options(edge_id, options)
}

///|
pub fn ffi_adapter_set_edge_options_json(
  adapter : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  adapter.set_edge_options_json(input_json)
}

///|
pub fn ffi_adapter_set_edge_label_alignment(
  adapter : QuiverUiAdapter,
  edge_id : Int,
  label_alignment : String,
) -> Bool {
  adapter.set_edge_label_alignment(edge_id, label_alignment)
}

///|
pub fn ffi_adapter_set_edge_label_alignment_json(
  adapter : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  adapter.set_edge_label_alignment_json(input_json)
}

///|
pub fn ffi_adapter_set_edge_label_position(
  adapter : QuiverUiAdapter,
  edge_id : Int,
  label_position : Int,
) -> Bool {
  adapter.set_edge_label_position(edge_id, label_position)
}

///|
pub fn ffi_adapter_set_edge_label_position_json(
  adapter : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  adapter.set_edge_label_position_json(input_json)
}

///|
pub fn ffi_adapter_reconnect_edge(
  adapter : QuiverUiAdapter,
  edge_id : Int,
  source_id : Int,
  target_id : Int,
) -> Bool {
  adapter.reconnect_edge(edge_id, source_id, target_id)
}

///|
pub fn ffi_adapter_reconnect_edge_json(
  adapter : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  adapter.reconnect_edge_json(input_json)
}

///|
pub fn ffi_adapter_apply_mutation_batch(
  adapter : QuiverUiAdapter,
  batch : QuiverUiMutationBatch,
) -> QuiverUiMutationBatchResult {
  adapter.apply_mutation_batch(batch)
}

///|
pub fn ffi_adapter_apply_mutation_batch_json(
  adapter : QuiverUiAdapter,
  batch_json : String,
) -> String raise {
  adapter.apply_mutation_batch_json_result(batch_json)
}

///|
pub fn ffi_adapter_remove(
  adapter : QuiverUiAdapter,
  cell_id : Int,
  when : Int,
) -> Array[Int] {
  adapter.remove(cell_id, when)
}

///|
pub fn ffi_adapter_remove_json(
  adapter : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  adapter.remove_json(input_json)
}

///|
pub fn ffi_adapter_flush(adapter : QuiverUiAdapter, when : Int) -> Unit {
  adapter.flush(when)
}

///|
pub fn ffi_adapter_flush_json(
  adapter : QuiverUiAdapter,
  input_json : String,
) -> String raise {
  adapter.flush_json(input_json)
}

///|
pub fn ffi_adapter_all_cells(adapter : QuiverUiAdapter) -> Array[CellData] {
  adapter.all_cells()
}

///|
pub fn ffi_adapter_all_cell_ids(adapter : QuiverUiAdapter) -> Array[Int] {
  adapter.all_cell_ids()
}

///|
pub fn ffi_adapter_snapshot(adapter : QuiverUiAdapter) -> QuiverUiSnapshot {
  adapter.snapshot()
}

///|
pub fn ffi_adapter_snapshot_json(adapter : QuiverUiAdapter) -> String {
  adapter.snapshot_json()
}

///|
pub fn ffi_adapter_dependencies_of(
  adapter : QuiverUiAdapter,
  cell_id : Int,
) -> Array[Int] {
  adapter.dependencies_of(cell_id)
}

///|
pub fn ffi_adapter_reverse_dependencies_of(
  adapter : QuiverUiAdapter,
  cell_id : Int,
) -> Array[Int] {
  adapter.reverse_dependencies_of(cell_id)
}

///|
pub fn ffi_adapter_transitive_dependencies(
  adapter : QuiverUiAdapter,
  roots : Array[Int],
  exclude_roots? : Bool = false,
) -> Array[Int] {
  adapter.transitive_dependencies(roots, exclude_roots~)
}

///|
pub fn ffi_adapter_transitive_reverse_dependencies(
  adapter : QuiverUiAdapter,
  roots : Array[Int],
) -> Array[Int] {
  adapter.transitive_reverse_dependencies(roots)
}

///|
pub fn ffi_adapter_connected_components(
  adapter : QuiverUiAdapter,
  roots : Array[Int],
) -> Array[Int] {
  adapter.connected_components(roots)
}

///|
pub fn ffi_adapter_export_base64(adapter : QuiverUiAdapter) -> String {
  adapter.export_base64_state()
}

///|
pub fn ffi_adapter_export_base64_selection(
  adapter : QuiverUiAdapter,
  selected_ids : Array[Int],
  include_dependencies? : Bool = true,
) -> String {
  adapter.export_base64_selection(selected_ids, include_dependencies~)
}

///|
pub fn ffi_adapter_export_tikz_cd(
  adapter : QuiverUiAdapter,
  settings? : TikzCdExportSettings = TikzCdExportSettings::default(),
  options? : TikzCdExportOptions = TikzCdExportOptions::default(),
  definitions? : TikzCdExportDefinitions = TikzCdExportDefinitions::default(),
) -> TikzCdExportResult {
  adapter.export_tikz_cd(settings~, options~, definitions~)
}

///|
pub fn ffi_adapter_export_tikz_cd_json(
  adapter : QuiverUiAdapter,
  settings? : TikzCdExportSettings = TikzCdExportSettings::default(),
  options? : TikzCdExportOptions = TikzCdExportOptions::default(),
  definitions? : TikzCdExportDefinitions = TikzCdExportDefinitions::default(),
) -> String {
  adapter.export_tikz_cd_json(settings~, options~, definitions~)
}

///|
pub fn ffi_adapter_export_fletcher(
  adapter : QuiverUiAdapter,
  settings? : FletcherExportSettings = FletcherExportSettings::default(),
  options? : FletcherExportOptions = FletcherExportOptions::default(),
) -> String {
  adapter.export_fletcher(settings~, options~)
}

///|
pub fn ffi_adapter_export_html_embed(
  adapter : QuiverUiAdapter,
  settings : HtmlEmbedExportSettings,
  options? : HtmlEmbedExportOptions = HtmlEmbedExportOptions::default(),
) -> String {
  adapter.export_html_embed(settings, options~)
}
