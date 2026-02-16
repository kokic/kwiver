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
pub struct BrowserRuntime {
  adapter : @kwiver.QuiverUiAdapter
  mut selected_ids : Array[Int]
}

///|
pub fn BrowserRuntime::new() -> BrowserRuntime {
  { adapter: @kwiver.ffi_adapter_new(), selected_ids: [] }
}

///|
pub fn BrowserRuntime::reset(self : BrowserRuntime) -> Unit {
  @kwiver.ffi_adapter_reset(self.adapter)
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
  label_colour? : @kwiver.Colour = @kwiver.Colour::black(),
) -> Int {
  let id = @kwiver.ffi_adapter_add_vertex(
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
  options? : @kwiver.EdgeOptions = @kwiver.EdgeOptions::at_level(1),
  label_colour? : @kwiver.Colour = @kwiver.Colour::black(),
) -> Int {
  let id = @kwiver.ffi_adapter_add_edge(
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
pub fn BrowserRuntime::set_label(
  self : BrowserRuntime,
  cell_id : Int,
  label : String,
) -> Bool {
  @kwiver.ffi_adapter_set_cell_label(self.adapter, cell_id, label)
}

///|
pub fn BrowserRuntime::set_label_colour(
  self : BrowserRuntime,
  cell_id : Int,
  label_colour : @kwiver.Colour,
) -> Bool {
  @kwiver.ffi_adapter_set_cell_label_colour(self.adapter, cell_id, label_colour)
}

///|
pub fn BrowserRuntime::move_vertex(
  self : BrowserRuntime,
  vertex_id : Int,
  x : Int,
  y : Int,
) -> Bool {
  @kwiver.ffi_adapter_move_vertex(self.adapter, vertex_id, x, y)
}

///|
pub fn BrowserRuntime::set_edge_options(
  self : BrowserRuntime,
  edge_id : Int,
  options : @kwiver.EdgeOptions,
) -> Bool {
  @kwiver.ffi_adapter_set_edge_options(self.adapter, edge_id, options)
}

///|
pub fn BrowserRuntime::reconnect_edge(
  self : BrowserRuntime,
  edge_id : Int,
  source_id : Int,
  target_id : Int,
) -> Bool {
  @kwiver.ffi_adapter_reconnect_edge(
    self.adapter,
    edge_id,
    source_id,
    target_id,
  )
}

///|
pub fn BrowserRuntime::apply_mutation_batch(
  self : BrowserRuntime,
  batch : @kwiver.QuiverUiMutationBatch,
) -> @kwiver.QuiverUiMutationBatchResult {
  @kwiver.ffi_adapter_apply_mutation_batch(self.adapter, batch)
}

///|
pub fn BrowserRuntime::remove(
  self : BrowserRuntime,
  cell_id : Int,
  when : Int,
) -> Array[Int] {
  let removed = @kwiver.ffi_adapter_remove(self.adapter, cell_id, when)
  self.selected_ids.retain(id => !browser_contains_id(removed, id))
  removed
}

///|
pub fn BrowserRuntime::flush(self : BrowserRuntime, when : Int) -> Unit {
  @kwiver.ffi_adapter_flush(self.adapter, when)
}

///|
pub fn BrowserRuntime::all_cell_ids(self : BrowserRuntime) -> Array[Int] {
  @kwiver.ffi_adapter_all_cell_ids(self.adapter)
}

///|
pub fn BrowserRuntime::export_payload(self : BrowserRuntime) -> String {
  @kwiver.ffi_adapter_export_base64(self.adapter)
}

///|
pub fn BrowserRuntime::export_selection(
  self : BrowserRuntime,
  include_dependencies? : Bool = true,
) -> String {
  @kwiver.ffi_adapter_export_base64_selection(
    self.adapter,
    self.selected_ids,
    include_dependencies~,
  )
}

///|
pub fn BrowserRuntime::render_tikz(self : BrowserRuntime) -> String {
  @kwiver.ffi_adapter_export_tikz_cd(self.adapter).data
}

///|
pub fn BrowserRuntime::render_fletcher(
  self : BrowserRuntime,
  settings? : @kwiver.FletcherExportSettings = @kwiver.FletcherExportSettings::default(),
  options? : @kwiver.FletcherExportOptions = @kwiver.FletcherExportOptions::default(),
) -> String {
  @kwiver.ffi_adapter_export_fletcher(self.adapter, settings~, options~)
}

///|
pub fn BrowserRuntime::render_html_embed(
  self : BrowserRuntime,
  settings : @kwiver.HtmlEmbedExportSettings,
  options? : @kwiver.HtmlEmbedExportOptions = @kwiver.HtmlEmbedExportOptions::default(),
) -> String {
  @kwiver.ffi_adapter_export_html_embed(self.adapter, settings, options~)
}

///|
pub fn BrowserRuntime::import_payload(
  self : BrowserRuntime,
  payload : String,
) -> String raise {
  let normalised = @kwiver.ffi_adapter_import_base64(self.adapter, payload)
  self.selected_ids = []
  normalised
}

///|
pub fn BrowserRuntime::import_share_url(
  self : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> @kwiver.QuiverUiImportResult raise {
  let imported = @kwiver.ffi_adapter_import_share_url(
    self.adapter,
    input,
    default_renderer~,
  )
  self.selected_ids = []
  imported
}

///|
pub fn BrowserRuntime::import_tikz_cd(
  self : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> @kwiver.QuiverUiImportResult raise {
  let imported = @kwiver.ffi_adapter_import_tikz_cd(
    self.adapter,
    input,
    default_renderer~,
  )
  self.selected_ids = []
  imported
}

///|
pub fn BrowserRuntime::import_fletcher(
  self : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> @kwiver.QuiverUiImportResult raise {
  let imported = @kwiver.ffi_adapter_import_fletcher(
    self.adapter,
    input,
    default_renderer~,
  )
  self.selected_ids = []
  imported
}

///|
pub fn BrowserRuntime::import_html_embed(
  self : BrowserRuntime,
  input : String,
  default_renderer? : String = "canvas",
) -> @kwiver.QuiverUiImportResult raise {
  let imported = @kwiver.ffi_adapter_import_html_embed(
    self.adapter,
    input,
    default_renderer~,
  )
  self.selected_ids = []
  imported
}

///|
pub fn BrowserRuntime::paste_selection(
  self : BrowserRuntime,
  payload : String,
  origin_x : Int,
  origin_y : Int,
  start_id? : Int = 1,
) -> @kwiver.QuiverUiSelectionImportResult raise {
  let imported = @kwiver.ffi_adapter_paste_base64_selection(
    self.adapter,
    payload,
    origin_x,
    origin_y,
    start_id~,
  )
  self.selected_ids = imported.imported_ids.copy()
  imported
}
