///|
pub struct QuiverUiSelectionSummary {
  roots : Array[Int32]
  all_cell_ids : Array[Int32]
  connected_component_ids : Array[Int32]
  transitive_dependency_ids : Array[Int32]
  transitive_dependency_ids_excluding_roots : Array[Int32]
  transitive_reverse_dependency_ids : Array[Int32]
}

///|
fn quiver_ui_selection_summary_json(summary : QuiverUiSelectionSummary) -> Json {
  let out : Map[String, Json] = Map([])
  out.set("roots", quiver_ui_int_array_json(summary.roots))
  out.set("all_cell_ids", quiver_ui_int_array_json(summary.all_cell_ids))
  out.set(
    "connected_component_ids",
    quiver_ui_int_array_json(summary.connected_component_ids),
  )
  out.set(
    "transitive_dependency_ids",
    quiver_ui_int_array_json(summary.transitive_dependency_ids),
  )
  out.set(
    "transitive_dependency_ids_excluding_roots",
    quiver_ui_int_array_json(summary.transitive_dependency_ids_excluding_roots),
  )
  out.set(
    "transitive_reverse_dependency_ids",
    quiver_ui_int_array_json(summary.transitive_reverse_dependency_ids),
  )
  Json::object(out)
}

///|
pub fn QuiverUiSelectionSummary::to_json_string(
  self : QuiverUiSelectionSummary,
) -> String {
  quiver_ui_selection_summary_json(self).stringify()
}

///|
pub fn QuiverUiAdapter::selection_summary(
  self : QuiverUiAdapter,
  roots : Array[Int32],
) -> QuiverUiSelectionSummary {
  {
    roots,
    all_cell_ids: self.quiver.all_cell_ids(),
    connected_component_ids: self.quiver.connected_components(roots),
    transitive_dependency_ids: self.quiver.transitive_dependencies(roots),
    transitive_dependency_ids_excluding_roots: self.quiver.transitive_dependencies(
      roots,
      exclude_roots=true,
    ),
    transitive_reverse_dependency_ids: self.quiver.transitive_reverse_dependencies(
      roots,
    ),
  }
}

///|
pub fn QuiverUiAdapter::selection_summary_json(
  self : QuiverUiAdapter,
  roots : Array[Int32],
) -> String {
  self.selection_summary(roots).to_json_string()
}

///|
pub fn ffi_adapter_selection_summary_json(
  adapter : QuiverUiAdapter,
  roots : Array[Int32],
) -> String {
  adapter.selection_summary_json(roots)
}
