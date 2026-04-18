///|
test "selection panel state derives arrow inspector semantics" {
  let adapter = ffi_adapter_new()
  let source_id = ffi_adapter_add_vertex(adapter, "A", 0, 0)
  let target_id = ffi_adapter_add_vertex(adapter, "B", 4, 0)
  let edge_id = ffi_adapter_add_edge(
    adapter,
    source_id,
    target_id,
    label="f",
    options=EdgeOptions::at_level(4)
      .with_label_alignment_right()
      .with_label_position(80)
      .with_offset(11)
      .with_curve(-3)
      .with_shorten(6, 4)
      .with_colour(Colour::new(120, 100, 25, 1.0))
      .with_style_tail("hook", side="top")
      .with_style_body("cell")
      .with_style_head("harpoon", side="bottom"),
    label_colour=Colour::new(240, 100, 50, 1.0),
  )

  let state = adapter.selection_panel_state([edge_id])
  inspect(state.selection_size, content="1")
  inspect(state.has_selection, content="true")
  inspect(state.has_selected_edges, content="true")
  inspect(state.has_selected_nonloop_edges, content="true")
  inspect(state.has_selected_loop_edges, content="false")

  match state.label {
    Some(value) => inspect(value, content="f")
    None => abort("expected unanimous edge label")
  }
  match state.label_colour {
    Some(value) => inspect(value.h, content="240")
    None => abort("expected unanimous label colour")
  }
  match state.edge_angle {
    Some(value) => inspect(value == 0.0, content="true")
    None => abort("expected edge angle")
  }
  match state.label_alignment {
    Some(value) => inspect(value, content="right")
    None => abort("expected label alignment")
  }
  match state.label_position {
    Some(value) => inspect(value, content="80")
    None => abort("expected label position")
  }
  match state.offset {
    Some(value) => inspect(value, content="11")
    None => abort("expected offset")
  }
  match state.curve {
    Some(value) => inspect(value, content="-3")
    None => abort("expected curve")
  }
  inspect(state.radius is None, content="true")
  inspect(state.angle is None, content="true")
  match state.length {
    Some(value) => {
      inspect(value.source, content="6")
      inspect(value.target, content="4")
    }
    None => abort("expected shorten values")
  }
  match state.level {
    Some(value) => inspect(value >= 1, content="true")
    None => abort("expected edge level")
  }
  match state.edge_type {
    Some(value) => inspect(value, content="arrow")
    None => abort("expected edge type")
  }
  match state.edge_colour {
    Some(value) => inspect(value.h, content="120")
    None => abort("expected edge colour")
  }
  match state.tail_type {
    Some(value) => inspect(value, content="top-hook")
    None => abort("expected tail type")
  }
  match state.body_type {
    Some(value) => inspect(value, content="solid")
    None => abort("expected body type")
  }
  match state.head_type {
    Some(value) => inspect(value, content="bottom-harpoon")
    None => abort("expected head type")
  }
  inspect(state.all_edges_are_arrows, content="true")
  inspect(state.corners, content="0")
  inspect(state.inverse_corners, content="0")
  inspect(state.endpoint_positioning_source_visible, content="false")
  inspect(state.endpoint_positioning_source_checked, content="true")
  inspect(state.endpoint_positioning_target_visible, content="false")
  inspect(state.endpoint_positioning_target_checked, content="true")
}

///|
test "selection panel state derives corner endpoint semantics" {
  let adapter = ffi_adapter_new()
  let source_id = ffi_adapter_add_vertex(adapter, "A", 0, 0)
  let target_id = ffi_adapter_add_vertex(adapter, "B", 3, 0)
  let base_edge_id = ffi_adapter_add_edge(adapter, source_id, target_id, label="f")
  let source_corner_id = ffi_adapter_add_edge(
    adapter,
    base_edge_id,
    target_id,
    label="g",
    options=EdgeOptions::at_level(2)
      .with_style_name("corner")
      .with_edge_alignment_source(false),
  )
  let target_inverse_id = ffi_adapter_add_edge(
    adapter,
    source_id,
    base_edge_id,
    label="h",
    options=EdgeOptions::at_level(2)
      .with_style_name("corner-inverse")
      .with_edge_alignment_target(false),
  )

  let state = adapter.selection_panel_state([source_corner_id, target_inverse_id])
  inspect(state.selection_size, content="2")
  inspect(state.has_selection, content="true")
  inspect(state.has_selected_edges, content="true")
  inspect(state.has_selected_nonloop_edges, content="true")
  inspect(state.has_selected_loop_edges, content="false")
  inspect(state.edge_type is None, content="true")
  inspect(state.tail_type is None, content="true")
  inspect(state.body_type is None, content="true")
  inspect(state.head_type is None, content="true")
  inspect(state.all_edges_are_arrows, content="false")
  inspect(state.corners, content="1")
  inspect(state.inverse_corners, content="1")
  inspect(state.endpoint_positioning_source_visible, content="true")
  inspect(state.endpoint_positioning_source_checked, content="false")
  inspect(state.endpoint_positioning_target_visible, content="true")
  inspect(state.endpoint_positioning_target_checked, content="false")
}

///|
test "selection toolbar state derives selection capabilities" {
  let adapter = ffi_adapter_new()
  let source_id = ffi_adapter_add_vertex(adapter, "A", 0, 0)
  let target_id = ffi_adapter_add_vertex(adapter, "B", 1, 0)
  let edge_id = ffi_adapter_add_edge(adapter, source_id, target_id, label="f")

  let empty = adapter.selection_toolbar_state([])
  inspect(empty.all_cells_count, content="3")
  inspect(empty.selected_count, content="0")
  inspect(empty.has_selection, content="false")
  inspect(empty.has_any_cells, content="true")
  inspect(empty.has_vertices, content="true")
  inspect(empty.can_select_all, content="true")
  inspect(empty.can_expand_connected, content="false")
  inspect(empty.can_deselect_all, content="false")
  inspect(empty.can_delete, content="false")
  inspect(empty.can_transform, content="true")

  let partial = adapter.selection_toolbar_state([source_id])
  inspect(partial.selected_count, content="1")
  inspect(partial.has_selection, content="true")
  inspect(partial.can_select_all, content="true")
  inspect(partial.can_expand_connected, content="true")
  inspect(partial.can_deselect_all, content="true")
  inspect(partial.can_delete, content="true")
  inspect(partial.can_transform, content="true")

  let full = adapter.selection_toolbar_state([source_id, target_id, edge_id])
  inspect(full.selected_count, content="3")
  inspect(full.can_select_all, content="false")
  inspect(full.can_expand_connected, content="false")
}
