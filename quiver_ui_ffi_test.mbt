///|
test "ui ffi adapter wraps update/import/export calls" {
  let adapter = ffi_adapter_new()
  let source_id = ffi_adapter_add_vertex(adapter, "A", 0, 0)
  let target_id = ffi_adapter_add_vertex(adapter, "B", 1, 0)
  let edge_id = ffi_adapter_add_edge(adapter, source_id, target_id, label="f")

  inspect(edge_id, content="3")
  inspect(ffi_adapter_all_cell_ids(adapter), content="[1, 2, 3]")

  let payload = ffi_adapter_export_base64(adapter)
  let imported = ffi_adapter_new()
  ignore(ffi_adapter_import_base64(imported, payload))

  inspect(ffi_adapter_all_cell_ids(imported), content="[1, 2, 3]")

  let tikz = ffi_adapter_export_tikz_cd(imported).data
  inspect(tikz.contains("\\begin{tikzcd}"), content="true")
  inspect(tikz.contains("\\arrow["), content="true")
}

///|
test "ui ffi adapter selection paste returns deterministic remap and payload" {
  let source = ffi_adapter_new()
  let left_id = ffi_adapter_add_vertex(source, "L", 2, 3)
  let right_id = ffi_adapter_add_vertex(source, "R", 4, 3)
  let edge_id = ffi_adapter_add_edge(source, left_id, right_id, label="g")
  let selection_payload = ffi_adapter_export_base64_selection(source, [edge_id])

  let target = ffi_adapter_new()
  ignore(ffi_adapter_add_vertex(target, "Existing", 0, 0))

  let pasted = ffi_adapter_paste_base64_selection(
    target,
    selection_payload,
    10,
    20,
    start_id=1,
  )

  inspect(pasted.imported_ids, content="[2, 3, 4]")
  inspect(ffi_adapter_all_cell_ids(target), content="[1, 2, 3, 4]")
  inspect(pasted.id_remap.length(), content="3")
  inspect(pasted.id_remap[0].old_id, content="1")
  inspect(pasted.id_remap[0].new_id, content="2")
  inspect(pasted.id_remap[2].old_id, content="3")
  inspect(pasted.id_remap[2].new_id, content="4")
  inspect(pasted.payload != "", content="true")
}

///|
test "ui ffi adapter import tikz updates state with metadata defaults" {
  let adapter = ffi_adapter_new()
  let input = [
    "\\begin{tikzcd}\n", "A \\arrow[r, \"f\"] & B\n", "\\end{tikzcd}",
  ].join("")

  let imported = ffi_adapter_import_tikz_cd(adapter, input)
  inspect(imported.macro_url, content="None")
  inspect(imported.renderer, content="None")
  inspect(imported.embed, content="false")
  inspect(ffi_adapter_all_cell_ids(adapter).length(), content="3")

  let roundtrip = Quiver::import_base64_v0(imported.payload)
  inspect(roundtrip.all_cell_ids().length(), content="3")
}

///|
test "ui ffi adapter supports incremental mutation without reload" {
  let adapter = ffi_adapter_new()
  let source_id = ffi_adapter_add_vertex(adapter, "A", 0, 0)
  let target_id = ffi_adapter_add_vertex(adapter, "B", 2, 0)
  let edge_id = ffi_adapter_add_edge(adapter, source_id, target_id, label="f")

  inspect(ffi_adapter_set_cell_label(adapter, source_id, "A1"), content="true")
  inspect(
    ffi_adapter_set_cell_label_colour(
      adapter,
      edge_id,
      Colour::new(120, 100, 25, 1.0),
    ),
    content="true",
  )
  inspect(ffi_adapter_move_vertex(adapter, source_id, 5, 7), content="true")

  let options = EdgeOptions::at_level(9)
    .with_curve(2)
    .with_colour(Colour::new(0, 100, 50, 1.0))
    .with_style_head("epi")
  inspect(
    ffi_adapter_set_edge_options(adapter, edge_id, options),
    content="true",
  )
  inspect(
    ffi_adapter_reconnect_edge(adapter, edge_id, target_id, source_id),
    content="true",
  )

  let quiver = Quiver::import_base64_v0(ffi_adapter_export_base64(adapter))

  let mut source_vertex : Vertex? = None
  let mut edge_value : Edge? = None
  for cell in quiver.all_cells() {
    match cell {
      CellData::Vertex(vertex) =>
        if vertex.cell.id == source_id {
          source_vertex = Some(vertex)
        }
      CellData::Edge(edge) =>
        if edge.cell.id == edge_id {
          edge_value = Some(edge)
        }
    }
  }

  match source_vertex {
    Some(vertex) => {
      inspect(vertex.cell.label, content="A1")
      // Base64 canonical export normalises positions by top-left offset.
      inspect(vertex.x, content="3")
      inspect(vertex.y, content="7")
    }
    None => abort("expected updated source vertex")
  }

  match edge_value {
    Some(edge) => {
      inspect(edge.cell.label, content="f")
      inspect(edge.cell.label_colour.h, content="120")
      inspect(edge.source == target_id, content="true")
      inspect(edge.target == source_id, content="true")
      inspect(edge.options.curve, content="2")
      inspect(edge.options.style.head.name, content="epi")
      inspect(edge.options.level, content="1")
      inspect(edge.options.colour.h, content="0")
    }
    None => abort("expected updated edge")
  }
}

///|
test "ui ffi adapter applies mutation batch and reports per-op results" {
  let adapter = ffi_adapter_new()
  let source_id = ffi_adapter_add_vertex(adapter, "A", 0, 0)
  let target_id = ffi_adapter_add_vertex(adapter, "B", 2, 0)
  let edge_id = ffi_adapter_add_edge(adapter, source_id, target_id, label="f")

  let batch = QuiverUiMutationBatch::new(
    [
      QuiverUiSetLabelPatch::new(source_id, "A2"),
      QuiverUiSetLabelPatch::new(999, "missing"),
    ],
    [
      QuiverUiSetLabelColourPatch::new(
        edge_id,
        Colour::new(120, 100, 25, 1.0),
      ),
      QuiverUiSetLabelColourPatch::new(999, Colour::new(0, 0, 0, 1.0)),
    ],
    [
      QuiverUiMoveVertexPatch::new(source_id, 5, 7),
      QuiverUiMoveVertexPatch::new(999, 1, 1),
    ],
    [
      QuiverUiSetEdgeOptionsPatch::new(
        edge_id,
        EdgeOptions::at_level(9)
          .with_curve(-2)
          .with_style_head("epi")
          .with_colour(Colour::new(0, 100, 50, 1.0)),
      ),
      QuiverUiSetEdgeOptionsPatch::new(999, EdgeOptions::at_level(1)),
    ],
    [
      QuiverUiReconnectEdgePatch::new(edge_id, target_id, source_id),
      QuiverUiReconnectEdgePatch::new(999, source_id, target_id),
    ],
  )

  let result = ffi_adapter_apply_mutation_batch(adapter, batch)
  inspect(result.label_results, content="[true, false]")
  inspect(result.label_colour_results, content="[true, false]")
  inspect(result.vertex_position_results, content="[true, false]")
  inspect(result.edge_option_results, content="[true, false]")
  inspect(result.edge_connection_results, content="[true, false]")
  inspect(result.payload == ffi_adapter_export_base64(adapter), content="true")

  let quiver = Quiver::import_base64_v0(result.payload)
  let mut source_vertex : Vertex? = None
  let mut edge_value : Edge? = None
  for cell in quiver.all_cells() {
    match cell {
      CellData::Vertex(vertex) =>
        if vertex.cell.id == source_id {
          source_vertex = Some(vertex)
        }
      CellData::Edge(edge) =>
        if edge.cell.id == edge_id {
          edge_value = Some(edge)
        }
    }
  }

  match source_vertex {
    Some(vertex) => {
      inspect(vertex.cell.label, content="A2")
      // Base64 canonical export normalises positions by top-left offset.
      inspect(vertex.x, content="3")
      inspect(vertex.y, content="7")
    }
    None => abort("expected updated source vertex")
  }

  match edge_value {
    Some(edge) => {
      inspect(edge.cell.label_colour.h, content="120")
      inspect(edge.source == target_id, content="true")
      inspect(edge.target == source_id, content="true")
      inspect(edge.options.curve, content="-2")
      inspect(edge.options.style.head.name, content="epi")
      inspect(edge.options.level, content="1")
      inspect(edge.options.colour.h, content="0")
    }
    None => abort("expected updated edge")
  }
}

///|
test "ui ffi adapter mutation APIs return false for invalid ids" {
  let adapter = ffi_adapter_new()
  let vertex_id = ffi_adapter_add_vertex(adapter, "A", 0, 0)

  inspect(ffi_adapter_set_cell_label(adapter, 999, "x"), content="false")
  inspect(
    ffi_adapter_set_cell_label_colour(adapter, 999, Colour::black()),
    content="false",
  )
  inspect(ffi_adapter_move_vertex(adapter, 999, 1, 1), content="false")
  inspect(
    ffi_adapter_set_edge_options(adapter, vertex_id, EdgeOptions::at_level(1)),
    content="false",
  )
  inspect(
    ffi_adapter_reconnect_edge(adapter, vertex_id, vertex_id, vertex_id),
    content="false",
  )
  inspect(ffi_adapter_all_cell_ids(adapter), content="[1]")
}
