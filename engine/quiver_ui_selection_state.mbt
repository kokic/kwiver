///|
pub struct QuiverUiSelectionPanelState {
  selection_size : Int
  has_selection : Bool
  has_selected_edges : Bool
  has_selected_nonloop_edges : Bool
  has_selected_loop_edges : Bool
  label : String?
  label_colour : QuiverUiColourData?
  edge_angle : Double?
  label_alignment : String?
  label_position : Int?
  offset : Int?
  curve : Int?
  radius : Int?
  angle : Int?
  length : EdgeShorten?
  level : Int?
  edge_type : String?
  edge_colour : QuiverUiColourData?
  tail_type : String?
  body_type : String?
  head_type : String?
  all_edges_are_arrows : Bool
  corners : Int
  inverse_corners : Int
  endpoint_positioning_source_visible : Bool
  endpoint_positioning_source_checked : Bool
  endpoint_positioning_target_visible : Bool
  endpoint_positioning_target_checked : Bool
}

///|
pub struct QuiverUiSelectionToolbarState {
  all_cells_count : Int
  selected_count : Int
  has_selection : Bool
  has_any_cells : Bool
  has_vertices : Bool
  can_select_all : Bool
  can_expand_connected : Bool
  can_deselect_all : Bool
  can_delete : Bool
  can_transform : Bool
}

///|
fn quiver_ui_unique_existing_ids(
  quiver : Quiver,
  selected_ids : Array[Int],
) -> Array[Int] {
  let unique_ids : Array[Int] = []
  let seen : @hashmap.HashMap[Int, Bool] = @hashmap.new()
  for cell_id in selected_ids {
    if quiver.contains_cell(cell_id) && !seen.contains(cell_id) {
      seen.set(cell_id, true)
      unique_ids.push(cell_id)
    }
  }
  unique_ids
}

///|
fn quiver_ui_unanimous_string(values : Array[String]) -> String? {
  if values.length() == 0 {
    return None
  }
  let first = values[0]
  for value in values {
    if value != first {
      return None
    }
  }
  Some(first)
}

///|
fn quiver_ui_unanimous_int(values : Array[Int]) -> Int? {
  if values.length() == 0 {
    return None
  }
  let first = values[0]
  for value in values {
    if value != first {
      return None
    }
  }
  Some(first)
}

///|
fn quiver_ui_unanimous_double(values : Array[Double]) -> Double? {
  if values.length() == 0 {
    return None
  }
  let first = values[0]
  for value in values {
    if value != first {
      return None
    }
  }
  Some(first)
}

///|
fn quiver_ui_colour_eq(left : Colour, right : Colour) -> Bool {
  left.h == right.h && left.s == right.s && left.l == right.l && left.a == right.a
}

///|
fn quiver_ui_unanimous_colour(values : Array[Colour]) -> QuiverUiColourData? {
  if values.length() == 0 {
    return None
  }
  let first = values[0]
  for value in values {
    if !quiver_ui_colour_eq(value, first) {
      return None
    }
  }
  Some(quiver_ui_colour_data(first))
}

///|
fn quiver_ui_edge_shorten_eq(left : EdgeShorten, right : EdgeShorten) -> Bool {
  left.source == right.source && left.target == right.target
}

///|
fn quiver_ui_unanimous_edge_shorten(values : Array[EdgeShorten]) -> EdgeShorten? {
  if values.length() == 0 {
    return None
  }
  let first = values[0]
  for value in values {
    if !quiver_ui_edge_shorten_eq(value, first) {
      return None
    }
  }
  Some(first)
}

///|
fn quiver_ui_panel_edge_component_type(component : EdgeEndpointStyle) -> String {
  match component.name {
    "cell" => "solid"
    "hook" => [component.side, "-hook"].join("")
    "harpoon" => [component.side, "-harpoon"].join("")
    _ => component.name
  }
}

///|
fn quiver_ui_cell_origin(
  quiver : Quiver,
  cell_id : Int,
  cache : @hashmap.HashMap[Int, Point],
) -> Point {
  match cache.get(cell_id) {
    Some(point) => point
    None =>
      match quiver.cells.get(cell_id) {
        Some(CellData::Vertex(vertex)) => {
          let point = Point::new(vertex.x.to_double(), vertex.y.to_double())
          cache.set(cell_id, point)
          point
        }
        Some(CellData::Edge(edge)) => {
          let point = if edge.source == edge.target {
            quiver_ui_cell_origin(quiver, edge.source, cache)
          } else {
            let source = quiver_ui_cell_origin(quiver, edge.source, cache)
            let target = quiver_ui_cell_origin(quiver, edge.target, cache)
            source.lerp(target, 0.5)
          }
          cache.set(cell_id, point)
          point
        }
        None => abort("missing cell origin")
      }
  }
}

///|
fn quiver_ui_panel_edge_angle(
  quiver : Quiver,
  edge : Edge,
  cache : @hashmap.HashMap[Int, Point],
) -> Double {
  if edge.source == edge.target {
    edge.options.angle.to_double() * 3.141592653589793 / 180.0
  } else {
    let source = quiver_ui_cell_origin(quiver, edge.source, cache)
    let target = quiver_ui_cell_origin(quiver, edge.target, cache)
    target.sub(source).angle()
  }
}

///|
fn quiver_ui_option_int_json(value : Int?) -> Json {
  match value {
    Some(number) => Json::number(number.to_double())
    None => Json::null()
  }
}

///|
fn quiver_ui_option_double_json(value : Double?) -> Json {
  match value {
    Some(number) => Json::number(number)
    None => Json::null()
  }
}

///|
fn quiver_ui_option_colour_json(value : QuiverUiColourData?) -> Json {
  match value {
    Some(colour) => quiver_ui_colour_json(colour)
    None => Json::null()
  }
}

///|
fn quiver_ui_edge_shorten_json(value : EdgeShorten) -> Json {
  let out : Map[String, Json] = Map::new()
  out.set("source", Json::number(value.source.to_double()))
  out.set("target", Json::number(value.target.to_double()))
  Json::object(out)
}

///|
fn quiver_ui_option_edge_shorten_json(value : EdgeShorten?) -> Json {
  match value {
    Some(shorten) => quiver_ui_edge_shorten_json(shorten)
    None => Json::null()
  }
}

///|
fn quiver_ui_selection_panel_state_json(
  state : QuiverUiSelectionPanelState,
) -> Json {
  let out : Map[String, Json] = Map::new()
  out.set("selection_size", Json::number(state.selection_size.to_double()))
  out.set("has_selection", Json::boolean(state.has_selection))
  out.set("has_selected_edges", Json::boolean(state.has_selected_edges))
  out.set(
    "has_selected_nonloop_edges",
    Json::boolean(state.has_selected_nonloop_edges),
  )
  out.set("has_selected_loop_edges", Json::boolean(state.has_selected_loop_edges))
  out.set("label", quiver_ui_option_string_json(state.label))
  out.set("label_colour", quiver_ui_option_colour_json(state.label_colour))
  out.set("edge_angle", quiver_ui_option_double_json(state.edge_angle))
  out.set(
    "label_alignment",
    quiver_ui_option_string_json(state.label_alignment),
  )
  out.set("label_position", quiver_ui_option_int_json(state.label_position))
  out.set("offset", quiver_ui_option_int_json(state.offset))
  out.set("curve", quiver_ui_option_int_json(state.curve))
  out.set("radius", quiver_ui_option_int_json(state.radius))
  out.set("angle", quiver_ui_option_int_json(state.angle))
  out.set("length", quiver_ui_option_edge_shorten_json(state.length))
  out.set("level", quiver_ui_option_int_json(state.level))
  out.set("edge_type", quiver_ui_option_string_json(state.edge_type))
  out.set("edge_colour", quiver_ui_option_colour_json(state.edge_colour))
  out.set("tail_type", quiver_ui_option_string_json(state.tail_type))
  out.set("body_type", quiver_ui_option_string_json(state.body_type))
  out.set("head_type", quiver_ui_option_string_json(state.head_type))
  out.set("all_edges_are_arrows", Json::boolean(state.all_edges_are_arrows))
  out.set("corners", Json::number(state.corners.to_double()))
  out.set("inverse_corners", Json::number(state.inverse_corners.to_double()))
  out.set(
    "endpoint_positioning_source_visible",
    Json::boolean(state.endpoint_positioning_source_visible),
  )
  out.set(
    "endpoint_positioning_source_checked",
    Json::boolean(state.endpoint_positioning_source_checked),
  )
  out.set(
    "endpoint_positioning_target_visible",
    Json::boolean(state.endpoint_positioning_target_visible),
  )
  out.set(
    "endpoint_positioning_target_checked",
    Json::boolean(state.endpoint_positioning_target_checked),
  )
  Json::object(out)
}

///|
fn quiver_ui_selection_toolbar_state_json(
  state : QuiverUiSelectionToolbarState,
) -> Json {
  let out : Map[String, Json] = Map::new()
  out.set("all_cells_count", Json::number(state.all_cells_count.to_double()))
  out.set("selected_count", Json::number(state.selected_count.to_double()))
  out.set("has_selection", Json::boolean(state.has_selection))
  out.set("has_any_cells", Json::boolean(state.has_any_cells))
  out.set("has_vertices", Json::boolean(state.has_vertices))
  out.set("can_select_all", Json::boolean(state.can_select_all))
  out.set("can_expand_connected", Json::boolean(state.can_expand_connected))
  out.set("can_deselect_all", Json::boolean(state.can_deselect_all))
  out.set("can_delete", Json::boolean(state.can_delete))
  out.set("can_transform", Json::boolean(state.can_transform))
  Json::object(out)
}

///|
pub fn QuiverUiSelectionPanelState::to_json_string(
  self : QuiverUiSelectionPanelState,
) -> String {
  quiver_ui_selection_panel_state_json(self).stringify()
}

///|
pub fn QuiverUiSelectionToolbarState::to_json_string(
  self : QuiverUiSelectionToolbarState,
) -> String {
  quiver_ui_selection_toolbar_state_json(self).stringify()
}

///|
pub fn QuiverUiAdapter::selection_panel_state(
  self : QuiverUiAdapter,
  selected_ids : Array[Int],
) -> QuiverUiSelectionPanelState {
  let selected_ids = quiver_ui_unique_existing_ids(self.quiver, selected_ids)
  let mut has_selected_edges = false
  let mut has_selected_nonloop_edges = false
  let mut has_selected_loop_edges = false
  let label_values : Array[String] = []
  let label_colour_values : Array[Colour] = []
  let edge_angle_values : Array[Double] = []
  let label_alignment_values : Array[String] = []
  let label_position_values : Array[Int] = []
  let offset_values : Array[Int] = []
  let curve_values : Array[Int] = []
  let radius_values : Array[Int] = []
  let angle_values : Array[Int] = []
  let length_values : Array[EdgeShorten] = []
  let level_values : Array[Int] = []
  let edge_type_values : Array[String] = []
  let edge_colour_values : Array[Colour] = []
  let tail_type_values : Array[String] = []
  let body_type_values : Array[String] = []
  let head_type_values : Array[String] = []
  let mut all_edges_are_arrows = true
  let mut corners = 0
  let mut inverse_corners = 0
  let mut endpoint_positioning_source_visible = false
  let mut endpoint_positioning_source_checked = true
  let mut endpoint_positioning_target_visible = false
  let mut endpoint_positioning_target_checked = true
  let origin_cache : @hashmap.HashMap[Int, Point] = @hashmap.new()
  for cell_id in selected_ids {
    match self.quiver.cells.get(cell_id) {
      Some(CellData::Vertex(vertex)) => {
        label_values.push(vertex.cell.label)
        label_colour_values.push(vertex.cell.label_colour)
      }
      Some(CellData::Edge(edge)) => {
        has_selected_edges = true
        label_values.push(edge.cell.label)
        label_colour_values.push(edge.cell.label_colour)
        edge_angle_values.push(
          quiver_ui_panel_edge_angle(self.quiver, edge, origin_cache),
        )
        label_alignment_values.push(
          quiver_ui_label_alignment_name(edge.options.label_alignment),
        )
        label_position_values.push(edge.options.label_position)
        offset_values.push(edge.options.offset)
        if edge.source != edge.target {
          has_selected_nonloop_edges = true
          curve_values.push(edge.options.curve)
        } else {
          has_selected_loop_edges = true
          radius_values.push(edge.options.radius)
          angle_values.push(edge.options.angle)
        }
        length_values.push(edge.options.shorten)
        level_values.push(edge.options.level)
        edge_type_values.push(edge.options.style.name)
        edge_colour_values.push(edge.options.colour)
        if edge.options.style.name == "arrow" {
          tail_type_values.push(
            quiver_ui_panel_edge_component_type(edge.options.style.tail),
          )
          body_type_values.push(
            quiver_ui_panel_edge_component_type(edge.options.style.body),
          )
          head_type_values.push(
            quiver_ui_panel_edge_component_type(edge.options.style.head),
          )
        } else {
          all_edges_are_arrows = false
          if edge.options.style.name == "corner" {
            corners += 1
          }
          if edge.options.style.name == "corner-inverse" {
            inverse_corners += 1
          }
        }
        let source_projection = quiver_ui_edge_endpoint_projection_data(
          self.quiver,
          edge.source,
        )
        if source_projection.kind == "edge" && source_projection.has_vertex_endpoint {
          endpoint_positioning_source_visible = true
          endpoint_positioning_source_checked =
            endpoint_positioning_source_checked &&
            edge.options.edge_alignment.source
        }
        let target_projection = quiver_ui_edge_endpoint_projection_data(
          self.quiver,
          edge.target,
        )
        if target_projection.kind == "edge" && target_projection.has_vertex_endpoint {
          endpoint_positioning_target_visible = true
          endpoint_positioning_target_checked =
            endpoint_positioning_target_checked &&
            edge.options.edge_alignment.target
        }
      }
      None => ()
    }
  }
  if !has_selected_edges {
    all_edges_are_arrows = false
    endpoint_positioning_source_checked = false
    endpoint_positioning_target_checked = false
  }
  {
    selection_size: selected_ids.length(),
    has_selection: selected_ids.length() > 0,
    has_selected_edges,
    has_selected_nonloop_edges,
    has_selected_loop_edges,
    label: quiver_ui_unanimous_string(label_values),
    label_colour: quiver_ui_unanimous_colour(label_colour_values),
    edge_angle: quiver_ui_unanimous_double(edge_angle_values),
    label_alignment: quiver_ui_unanimous_string(label_alignment_values),
    label_position: quiver_ui_unanimous_int(label_position_values),
    offset: quiver_ui_unanimous_int(offset_values),
    curve: quiver_ui_unanimous_int(curve_values),
    radius: quiver_ui_unanimous_int(radius_values),
    angle: quiver_ui_unanimous_int(angle_values),
    length: quiver_ui_unanimous_edge_shorten(length_values),
    level: quiver_ui_unanimous_int(level_values),
    edge_type: quiver_ui_unanimous_string(edge_type_values),
    edge_colour: quiver_ui_unanimous_colour(edge_colour_values),
    tail_type: quiver_ui_unanimous_string(tail_type_values),
    body_type: quiver_ui_unanimous_string(body_type_values),
    head_type: quiver_ui_unanimous_string(head_type_values),
    all_edges_are_arrows,
    corners,
    inverse_corners,
    endpoint_positioning_source_visible,
    endpoint_positioning_source_checked,
    endpoint_positioning_target_visible,
    endpoint_positioning_target_checked,
  }
}

///|
pub fn QuiverUiAdapter::selection_panel_state_json(
  self : QuiverUiAdapter,
  selected_ids : Array[Int],
) -> String {
  self.selection_panel_state(selected_ids).to_json_string()
}

///|
pub fn QuiverUiAdapter::selection_toolbar_state(
  self : QuiverUiAdapter,
  selected_ids : Array[Int],
) -> QuiverUiSelectionToolbarState {
  let selected_ids = quiver_ui_unique_existing_ids(self.quiver, selected_ids)
  let all_cells = self.quiver.all_cells()
  let all_cells_count = all_cells.length()
  let mut has_vertices = false
  for cell in all_cells {
    if cell.is_vertex() {
      has_vertices = true
    }
  }
  let connected_component_ids = if selected_ids.length() > 0 {
    self.quiver.connected_components(selected_ids)
  } else {
    []
  }
  let selected_count = selected_ids.length()
  let can_expand_connected = selected_count > 0 &&
    selected_count != connected_component_ids.length()
  {
    all_cells_count,
    selected_count,
    has_selection: selected_count > 0,
    has_any_cells: all_cells_count > 0,
    has_vertices,
    can_select_all: selected_count < all_cells_count,
    can_expand_connected,
    can_deselect_all: selected_count > 0,
    can_delete: selected_count > 0,
    can_transform: all_cells_count > 0,
  }
}

///|
pub fn QuiverUiAdapter::selection_toolbar_state_json(
  self : QuiverUiAdapter,
  selected_ids : Array[Int],
) -> String {
  self.selection_toolbar_state(selected_ids).to_json_string()
}

///|
pub fn ffi_adapter_selection_panel_state_json(
  adapter : QuiverUiAdapter,
  selected_ids : Array[Int],
) -> String {
  adapter.selection_panel_state_json(selected_ids)
}

///|
pub fn ffi_adapter_selection_toolbar_state_json(
  adapter : QuiverUiAdapter,
  selected_ids : Array[Int],
) -> String {
  adapter.selection_toolbar_state_json(selected_ids)
}
