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
pub fn ffi_browser_runtime_import_text_auto_json(
  runtime : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> String raise {
  runtime.import_text_auto_json(input, default_renderer~)
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

