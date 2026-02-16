pub struct QuiverUiAdapter {
  mut quiver : Quiver
}

pub struct QuiverUiImportResult {
  payload : String
  macro_url : String?
  renderer : String?
  embed : Bool
}

pub struct QuiverUiIdRemap {
  old_id : Int
  new_id : Int
}

pub struct QuiverUiSelectionImportResult {
  payload : String
  imported_ids : Array[Int]
  id_remap : Array[QuiverUiIdRemap]
}

pub fn QuiverUiAdapter::new() -> QuiverUiAdapter {
  { quiver: Quiver::new() }
}

fn quiver_ui_import_result(
  quiver : Quiver,
  macro_url : String?,
  renderer : String?,
  embed : Bool,
) -> QuiverUiImportResult {
  {
    payload: quiver.export_base64_v0(),
    macro_url,
    renderer,
    embed,
  }
}

fn quiver_ui_sorted_id_remap(remap : Map[Int, Int]) -> Array[QuiverUiIdRemap] {
  let out : Array[QuiverUiIdRemap] = []
  remap.each((old_id, new_id) => out.push({ old_id, new_id }))
  out.sort_by((a, b) => a.old_id - b.old_id)
  out
}

pub fn QuiverUiAdapter::reset(self : QuiverUiAdapter) -> Unit {
  self.quiver = Quiver::new()
}

pub fn QuiverUiAdapter::import_base64_state(
  self : QuiverUiAdapter,
  payload : String,
) -> String raise {
  self.quiver = Quiver::import_base64_v0(payload)
  self.quiver.export_base64_v0()
}

pub fn QuiverUiAdapter::import_share_url(
  self : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  let imported = Quiver::import_base64_share_url_result(
    input,
    default_renderer=default_renderer,
  )
  self.quiver = imported.quiver
  quiver_ui_import_result(
    self.quiver,
    imported.macro_url,
    imported.renderer,
    imported.embed,
  )
}

pub fn QuiverUiAdapter::import_tikz_cd(
  self : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  let imported = Quiver::import_tikz_cd_result(
    input,
    default_renderer=default_renderer,
  )
  self.quiver = imported.quiver
  quiver_ui_import_result(
    self.quiver,
    imported.macro_url,
    imported.renderer,
    imported.embed,
  )
}

pub fn QuiverUiAdapter::import_fletcher(
  self : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  let imported = Quiver::import_fletcher_result(
    input,
    default_renderer=default_renderer,
  )
  self.quiver = imported.quiver
  quiver_ui_import_result(
    self.quiver,
    imported.macro_url,
    imported.renderer,
    imported.embed,
  )
}

pub fn QuiverUiAdapter::import_html_embed(
  self : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  let imported = Quiver::import_html_embed_result(
    input,
    default_renderer=default_renderer,
  )
  self.quiver = imported.quiver
  quiver_ui_import_result(
    self.quiver,
    imported.macro_url,
    imported.renderer,
    imported.embed,
  )
}

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
    start_id=start_id,
  )
  {
    payload: self.quiver.export_base64_v0(),
    imported_ids: imported.imported_ids,
    id_remap: quiver_ui_sorted_id_remap(imported.id_remap),
  }
}

pub fn QuiverUiAdapter::add_vertex(
  self : QuiverUiAdapter,
  label : String,
  x : Int,
  y : Int,
  label_colour? : Colour = Colour::black(),
) -> Int {
  let id = self.quiver.next_available_id()
  self.quiver.add(
    CellData::from_vertex(
      Vertex::new(id, label, x, y, label_colour),
    ),
  )
  id
}

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
      Edge::new(
        id,
        label,
        source_id,
        target_id,
        options,
        label_colour,
      ),
    ),
  )
  self.quiver.connect(source_id, target_id, id)
  id
}

pub fn QuiverUiAdapter::remove(
  self : QuiverUiAdapter,
  cell_id : Int,
  when : Int,
) -> Array[Int] {
  self.quiver.remove(cell_id, when)
}

pub fn QuiverUiAdapter::flush(self : QuiverUiAdapter, when : Int) -> Unit {
  self.quiver.flush(when)
}

pub fn QuiverUiAdapter::all_cells(self : QuiverUiAdapter) -> Array[CellData] {
  self.quiver.all_cells()
}

pub fn QuiverUiAdapter::all_cell_ids(self : QuiverUiAdapter) -> Array[Int] {
  self.quiver.all_cell_ids()
}

pub fn QuiverUiAdapter::export_base64_state(self : QuiverUiAdapter) -> String {
  self.quiver.export_base64_v0()
}

pub fn QuiverUiAdapter::export_base64_selection(
  self : QuiverUiAdapter,
  selected_ids : Array[Int],
  include_dependencies? : Bool = true,
) -> String {
  self.quiver.export_base64_v0_selection(
    selected_ids,
    include_dependencies=include_dependencies,
  )
}

pub fn QuiverUiAdapter::export_tikz_cd(
  self : QuiverUiAdapter,
  settings~ : TikzCdExportSettings = TikzCdExportSettings::default(),
  options~ : TikzCdExportOptions = TikzCdExportOptions::default(),
  definitions~ : TikzCdExportDefinitions = TikzCdExportDefinitions::default(),
) -> TikzCdExportResult {
  self.quiver.export_tikz_cd_result(
    settings=settings,
    options=options,
    definitions=definitions,
  )
}

pub fn QuiverUiAdapter::export_fletcher(
  self : QuiverUiAdapter,
  settings~ : FletcherExportSettings = FletcherExportSettings::default(),
  options~ : FletcherExportOptions = FletcherExportOptions::default(),
) -> String {
  self.quiver.export_fletcher(settings=settings, options=options)
}

pub fn QuiverUiAdapter::export_html_embed(
  self : QuiverUiAdapter,
  settings : HtmlEmbedExportSettings,
  options~ : HtmlEmbedExportOptions = HtmlEmbedExportOptions::default(),
) -> String {
  self.quiver.export_html_embed(settings, options=options)
}

pub fn ffi_adapter_new() -> QuiverUiAdapter {
  QuiverUiAdapter::new()
}

pub fn ffi_adapter_reset(adapter : QuiverUiAdapter) -> Unit {
  adapter.reset()
}

pub fn ffi_adapter_import_base64(
  adapter : QuiverUiAdapter,
  payload : String,
) -> String raise {
  adapter.import_base64_state(payload)
}

pub fn ffi_adapter_import_share_url(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  adapter.import_share_url(input, default_renderer=default_renderer)
}

pub fn ffi_adapter_import_tikz_cd(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  adapter.import_tikz_cd(input, default_renderer=default_renderer)
}

pub fn ffi_adapter_import_fletcher(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  adapter.import_fletcher(input, default_renderer=default_renderer)
}

pub fn ffi_adapter_import_html_embed(
  adapter : QuiverUiAdapter,
  input : String,
  default_renderer? : String = "canvas",
) -> QuiverUiImportResult raise {
  adapter.import_html_embed(input, default_renderer=default_renderer)
}

pub fn ffi_adapter_paste_base64_selection(
  adapter : QuiverUiAdapter,
  payload : String,
  origin_x : Int,
  origin_y : Int,
  start_id? : Int = 1,
) -> QuiverUiSelectionImportResult raise {
  adapter.paste_base64_selection(
    payload,
    origin_x,
    origin_y,
    start_id=start_id,
  )
}

pub fn ffi_adapter_add_vertex(
  adapter : QuiverUiAdapter,
  label : String,
  x : Int,
  y : Int,
  label_colour? : Colour = Colour::black(),
) -> Int {
  adapter.add_vertex(label, x, y, label_colour=label_colour)
}

pub fn ffi_adapter_add_edge(
  adapter : QuiverUiAdapter,
  source_id : Int,
  target_id : Int,
  label? : String = "",
  options? : EdgeOptions = EdgeOptions::at_level(1),
  label_colour? : Colour = Colour::black(),
) -> Int {
  adapter.add_edge(
    source_id,
    target_id,
    label=label,
    options=options,
    label_colour=label_colour,
  )
}

pub fn ffi_adapter_remove(
  adapter : QuiverUiAdapter,
  cell_id : Int,
  when : Int,
) -> Array[Int] {
  adapter.remove(cell_id, when)
}

pub fn ffi_adapter_flush(adapter : QuiverUiAdapter, when : Int) -> Unit {
  adapter.flush(when)
}

pub fn ffi_adapter_all_cells(adapter : QuiverUiAdapter) -> Array[CellData] {
  adapter.all_cells()
}

pub fn ffi_adapter_all_cell_ids(adapter : QuiverUiAdapter) -> Array[Int] {
  adapter.all_cell_ids()
}

pub fn ffi_adapter_export_base64(adapter : QuiverUiAdapter) -> String {
  adapter.export_base64_state()
}

pub fn ffi_adapter_export_base64_selection(
  adapter : QuiverUiAdapter,
  selected_ids : Array[Int],
  include_dependencies? : Bool = true,
) -> String {
  adapter.export_base64_selection(
    selected_ids,
    include_dependencies=include_dependencies,
  )
}

pub fn ffi_adapter_export_tikz_cd(
  adapter : QuiverUiAdapter,
  settings~ : TikzCdExportSettings = TikzCdExportSettings::default(),
  options~ : TikzCdExportOptions = TikzCdExportOptions::default(),
  definitions~ : TikzCdExportDefinitions = TikzCdExportDefinitions::default(),
) -> TikzCdExportResult {
  adapter.export_tikz_cd(
    settings=settings,
    options=options,
    definitions=definitions,
  )
}

pub fn ffi_adapter_export_fletcher(
  adapter : QuiverUiAdapter,
  settings~ : FletcherExportSettings = FletcherExportSettings::default(),
  options~ : FletcherExportOptions = FletcherExportOptions::default(),
) -> String {
  adapter.export_fletcher(settings=settings, options=options)
}

pub fn ffi_adapter_export_html_embed(
  adapter : QuiverUiAdapter,
  settings : HtmlEmbedExportSettings,
  options~ : HtmlEmbedExportOptions = HtmlEmbedExportOptions::default(),
) -> String {
  adapter.export_html_embed(settings, options=options)
}

