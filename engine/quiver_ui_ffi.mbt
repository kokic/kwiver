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
pub fn QuiverUiAdapter::remove(
  self : QuiverUiAdapter,
  cell_id : Int,
  when : Int,
) -> Array[Int] {
  self.quiver.remove(cell_id, when)
}

///|
pub fn QuiverUiAdapter::flush(self : QuiverUiAdapter, when : Int) -> Unit {
  self.quiver.flush(when)
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
pub fn ffi_adapter_import_share_text(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  adapter.import_share_text(input, default_renderer~)
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
pub fn ffi_adapter_import_tikz_cd(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  adapter.import_tikz_cd(input, default_renderer~)
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
pub fn ffi_adapter_import_html_embed(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  adapter.import_html_embed(input, default_renderer~)
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
pub fn ffi_adapter_set_cell_label(
  adapter : QuiverUiAdapter,
  cell_id : Int,
  label : String,
) -> Bool {
  adapter.set_cell_label(cell_id, label)
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
pub fn ffi_adapter_move_vertex(
  adapter : QuiverUiAdapter,
  vertex_id : Int,
  x : Int,
  y : Int,
) -> Bool {
  adapter.move_vertex(vertex_id, x, y)
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
pub fn ffi_adapter_reconnect_edge(
  adapter : QuiverUiAdapter,
  edge_id : Int,
  source_id : Int,
  target_id : Int,
) -> Bool {
  adapter.reconnect_edge(edge_id, source_id, target_id)
}

///|
pub fn ffi_adapter_apply_mutation_batch(
  adapter : QuiverUiAdapter,
  batch : QuiverUiMutationBatch,
) -> QuiverUiMutationBatchResult {
  adapter.apply_mutation_batch(batch)
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
pub fn ffi_adapter_flush(adapter : QuiverUiAdapter, when : Int) -> Unit {
  adapter.flush(when)
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
