///|
///|
fn test_json_get(root : Map[String, Json], key : String) -> Json {
  match root.get(key) {
    Some(value) => value
    None => abort("missing json key")
  }
}

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
test "ui ffi adapter export tikz json wrapper includes metadata contract" {
  let adapter = ffi_adapter_new()
  let source_id = ffi_adapter_add_vertex(adapter, "A", 0, 0)
  let target_id = ffi_adapter_add_vertex(adapter, "B", 1, 0)
  ignore(
    ffi_adapter_add_edge(
      adapter,
      source_id,
      target_id,
      label="f",
      options=EdgeOptions::at_level(1).with_shorten(10, 0),
    ),
  )

  let exported_json = ffi_adapter_export_tikz_cd_json(adapter)
  let root : Map[String, Json] = @json.from_json(@json.parse(exported_json))
  let data : String = @json.from_json(test_json_get(root, "data"))
  inspect(data.contains("\\begin{tikzcd}"), content="true")
  inspect(data.contains("\\arrow["), content="true")

  let metadata : Map[String, Json] = @json.from_json(test_json_get(root, "metadata"))
  let incompatibilities : Array[String] = @json.from_json(
    test_json_get(metadata, "tikz_incompatibilities"),
  )
  inspect(incompatibilities, content="[]")

  let dependencies : Map[String, Json] = @json.from_json(
    test_json_get(metadata, "dependencies"),
  )
  match dependencies.get("quiver") {
    Some(raw_reasons) => {
      let reasons : Map[String, Json] = @json.from_json(raw_reasons)
      inspect(reasons.get("shortened arrows") is Some(_), content="true")
    }
    None => abort("expected quiver dependency")
  }
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
test "ui ffi adapter add remove flush json wrappers carry payload" {
  let adapter = ffi_adapter_new()

  let add_vertex_json = ffi_adapter_add_vertex_json(
    adapter,
    "{\"label\":\"A\",\"x\":0,\"y\":0}",
  )
  let add_vertex_result : Map[String, Json] = @json.from_json(
    @json.parse(add_vertex_json),
  )
  let vertex_id : Int = @json.from_json(test_json_get(add_vertex_result, "id"))
  let payload_after_add_vertex : String = @json.from_json(
    test_json_get(add_vertex_result, "payload"),
  )
  inspect(vertex_id, content="1")
  inspect(
    payload_after_add_vertex == ffi_adapter_export_base64(adapter),
    content="true",
  )

  let target_id = ffi_adapter_add_vertex(adapter, "B", 1, 0)
  inspect(target_id, content="2")

  let add_edge_json = ffi_adapter_add_edge_json(
    adapter,
    "{\"source_id\":1,\"target_id\":2,\"label\":\"f\"}",
  )
  let add_edge_result : Map[String, Json] = @json.from_json(@json.parse(add_edge_json))
  let edge_id : Int = @json.from_json(test_json_get(add_edge_result, "id"))
  let payload_after_add_edge : String = @json.from_json(
    test_json_get(add_edge_result, "payload"),
  )
  inspect(edge_id, content="3")
  inspect(
    payload_after_add_edge == ffi_adapter_export_base64(adapter),
    content="true",
  )

  let remove_json = ffi_adapter_remove_json(adapter, "{\"cell_id\":1,\"when\":9}")
  let remove_result : Map[String, Json] = @json.from_json(@json.parse(remove_json))
  let removed_ids : Array[Int] = @json.from_json(
    test_json_get(remove_result, "removed_ids"),
  )
  removed_ids.sort()
  let payload_after_remove : String = @json.from_json(
    test_json_get(remove_result, "payload"),
  )
  inspect(removed_ids, content="[1, 3]")
  inspect(
    payload_after_remove == ffi_adapter_export_base64(adapter),
    content="true",
  )

  let flush_json = ffi_adapter_flush_json(adapter, "{\"when\":9}")
  let flush_result : Map[String, Json] = @json.from_json(@json.parse(flush_json))
  let payload_after_flush : String = @json.from_json(
    test_json_get(flush_result, "payload"),
  )
  inspect(
    payload_after_flush == ffi_adapter_export_base64(adapter),
    content="true",
  )
  inspect(ffi_adapter_all_cell_ids(adapter), content="[2]")
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
test "ui ffi adapter import share text supports exported wrappers and iframe-only" {
  let source = ffi_adapter_new()
  let source_id = ffi_adapter_add_vertex(source, "A", 0, 0)
  let target_id = ffi_adapter_add_vertex(source, "B", 1, 0)
  ignore(ffi_adapter_add_edge(source, source_id, target_id, label="f"))

  let tikz_output = ffi_adapter_export_tikz_cd(source).data

  let target = ffi_adapter_new()
  let imported_tikz = ffi_adapter_import_share_text(target, tikz_output)
  inspect(imported_tikz.macro_url, content="None")
  inspect(imported_tikz.renderer, content="None")
  inspect(imported_tikz.embed, content="false")
  inspect(ffi_adapter_all_cell_ids(target), content="[1, 2, 3]")

  let payload = ffi_adapter_export_base64(source)
  let iframe_only = [
    "<iframe src='https://q.uiver.app#r=svg&q=", payload, "&embed'></iframe>",
  ].join("")
  let imported_iframe = ffi_adapter_import_share_text(target, iframe_only)
  inspect(ffi_adapter_all_cell_ids(target), content="[1, 2, 3]")
  match imported_iframe.renderer {
    Some(value) => inspect(value, content="svg")
    None => abort("expected renderer")
  }
  inspect(imported_iframe.embed, content="true")
}

///|
test "ui ffi adapter import text auto supports handwritten tikz and raw payload" {
  let adapter = ffi_adapter_new()
  let tikz = [
    "\\begin{tikzcd}\n", "A \\arrow[r, \"f\"] & B\n", "\\end{tikzcd}",
  ].join("")

  let imported_tikz = ffi_adapter_import_text_auto(adapter, tikz)
  inspect(imported_tikz.renderer, content="None")
  inspect(imported_tikz.embed, content="false")
  inspect(ffi_adapter_all_cell_ids(adapter), content="[1, 2, 3]")

  let source = ffi_adapter_new()
  ignore(ffi_adapter_add_vertex(source, "X", 0, 0))
  let payload = ffi_adapter_export_base64(source)

  let imported_payload = ffi_adapter_import_text_auto(adapter, payload)
  inspect(imported_payload.payload, content=payload)
  inspect(imported_payload.renderer, content="None")
  inspect(imported_payload.embed, content="false")
  inspect(ffi_adapter_all_cell_ids(adapter), content="[1]")
}

///|
test "ui ffi adapter import and paste json wrappers expose plain contracts" {
  let source = ffi_adapter_new()
  let left_id = ffi_adapter_add_vertex(source, "L", 2, 3)
  let right_id = ffi_adapter_add_vertex(source, "R", 4, 3)
  let edge_id = ffi_adapter_add_edge(source, left_id, right_id, label="g")
  let selection_payload = ffi_adapter_export_base64_selection(source, [edge_id])

  let target = ffi_adapter_new()
  let tikz = ffi_adapter_export_tikz_cd(source).data
  let imported_json = ffi_adapter_import_text_auto_json(target, tikz)
  let imported : Map[String, Json] = @json.from_json(@json.parse(imported_json))
  let imported_payload : String = @json.from_json(test_json_get(imported, "payload"))
  let imported_embed : Bool = @json.from_json(test_json_get(imported, "embed"))
  inspect(imported_payload == ffi_adapter_export_base64(target), content="true")
  inspect(imported_embed, content="false")
  inspect(test_json_get(imported, "renderer") is Json::Null, content="true")
  inspect(test_json_get(imported, "macro_url") is Json::Null, content="true")
  inspect(ffi_adapter_all_cell_ids(target), content="[1, 2, 3]")

  let target_paste = ffi_adapter_new()
  ignore(ffi_adapter_add_vertex(target_paste, "Existing", 0, 0))
  let pasted_json = ffi_adapter_paste_base64_selection_json(
    target_paste,
    selection_payload,
    10,
    20,
    start_id=1,
  )
  let pasted : Map[String, Json] = @json.from_json(@json.parse(pasted_json))
  let pasted_payload : String = @json.from_json(test_json_get(pasted, "payload"))
  let imported_ids : Array[Int] = @json.from_json(test_json_get(pasted, "imported_ids"))
  let remap : Array[Map[String, Json]] = @json.from_json(test_json_get(pasted, "id_remap"))
  inspect(imported_ids, content="[2, 3, 4]")
  inspect(remap.length(), content="3")
  let remap0_old : Int = @json.from_json(test_json_get(remap[0], "old_id"))
  let remap0_new : Int = @json.from_json(test_json_get(remap[0], "new_id"))
  inspect(remap0_old, content="1")
  inspect(remap0_new, content="2")
  inspect(pasted_payload == ffi_adapter_export_base64(target_paste), content="true")
}

///|
test "ui ffi adapter exposes dependency graph queries" {
  let adapter = ffi_adapter_new()
  let source_id = ffi_adapter_add_vertex(adapter, "A", 0, 0)
  let target_id = ffi_adapter_add_vertex(adapter, "B", 1, 0)
  let edge_id = ffi_adapter_add_edge(adapter, source_id, target_id, label="f")
  let higher_edge_id = ffi_adapter_add_edge(
    adapter,
    edge_id,
    target_id,
    label="alpha",
    options=EdgeOptions::at_level(2),
  )

  inspect(ffi_adapter_dependencies_of(adapter, source_id), content="[3]")
  inspect(ffi_adapter_dependencies_of(adapter, target_id), content="[3, 4]")
  inspect(ffi_adapter_reverse_dependencies_of(adapter, edge_id), content="[1, 2]")
  inspect(
    ffi_adapter_transitive_dependencies(adapter, [source_id]),
    content="[1, 3, 4]",
  )
  inspect(
    ffi_adapter_transitive_dependencies(adapter, [edge_id], exclude_roots=true),
    content="[4]",
  )
  inspect(
    ffi_adapter_transitive_reverse_dependencies(adapter, [higher_edge_id]),
    content="[1, 2, 3, 4]",
  )
  inspect(
    ffi_adapter_connected_components(adapter, [source_id]),
    content="[1, 2, 3, 4]",
  )
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
test "ui ffi adapter apply_mutation_batch_json supports plain json batch input" {
  let adapter = ffi_adapter_new()
  let source_id = ffi_adapter_add_vertex(adapter, "A", 0, 0)
  let target_id = ffi_adapter_add_vertex(adapter, "B", 2, 0)
  let edge_id = ffi_adapter_add_edge(adapter, source_id, target_id, label="f")

  inspect(source_id, content="1")
  inspect(target_id, content="2")
  inspect(edge_id, content="3")

  let batch_json = [
    "{",
    "\"labels\":[{\"cell_id\":1,\"label\":\"A-json\"}],",
    "\"label_colours\":[{\"cell_id\":3,\"label_colour\":{\"h\":120,\"s\":100,\"l\":25,\"a\":1}}],",
    "\"vertex_positions\":[{\"vertex_id\":1,\"x\":5,\"y\":7}],",
    "\"edge_options\":[{\"edge_id\":3,\"options\":{",
    "\"label_alignment\":\"left\",",
    "\"label_position\":50,",
    "\"offset\":0,",
    "\"curve\":-2,",
    "\"radius\":3,",
    "\"angle\":0,",
    "\"shorten_source\":0,",
    "\"shorten_target\":0,",
    "\"level\":1,",
    "\"shape\":\"bezier\",",
    "\"colour\":{\"h\":0,\"s\":100,\"l\":50,\"a\":1},",
    "\"edge_alignment_source\":true,",
    "\"edge_alignment_target\":true,",
    "\"style\":{",
    "\"name\":\"arrow\",",
    "\"tail\":{\"name\":\"none\",\"side\":\"\"},",
    "\"body\":{\"name\":\"barred\",\"side\":\"\"},",
    "\"head\":{\"name\":\"epi\",\"side\":\"\"}",
    "}}}],",
    "\"edge_connections\":[{\"edge_id\":3,\"source_id\":2,\"target_id\":1}]",
    "}",
  ].join("")

  let result_json = ffi_adapter_apply_mutation_batch_json(adapter, batch_json)
  let result : Map[String, Json] = @json.from_json(@json.parse(result_json))
  let label_results : Array[Bool] = @json.from_json(
    test_json_get(result, "label_results"),
  )
  let label_colour_results : Array[Bool] = @json.from_json(
    test_json_get(result, "label_colour_results"),
  )
  let vertex_position_results : Array[Bool] = @json.from_json(
    test_json_get(result, "vertex_position_results"),
  )
  let edge_option_results : Array[Bool] = @json.from_json(
    test_json_get(result, "edge_option_results"),
  )
  let edge_connection_results : Array[Bool] = @json.from_json(
    test_json_get(result, "edge_connection_results"),
  )
  inspect(label_results, content="[true]")
  inspect(label_colour_results, content="[true]")
  inspect(vertex_position_results, content="[true]")
  inspect(edge_option_results, content="[true]")
  inspect(edge_connection_results, content="[true]")

  let payload : String = @json.from_json(test_json_get(result, "payload"))
  inspect(payload == ffi_adapter_export_base64(adapter), content="true")

  let quiver = Quiver::import_base64_v0(payload)
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
      inspect(vertex.cell.label, content="A-json")
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
      inspect(edge.options.style.body.name, content="barred")
      inspect(edge.options.style.head.name, content="epi")
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

///|
test "ui ffi adapter snapshot exposes js-friendly model data" {
  let adapter = ffi_adapter_new()
  let source_id = ffi_adapter_add_vertex(adapter, "A", 0, 0)
  let target_id = ffi_adapter_add_vertex(adapter, "B", 2, 1)
  let options = EdgeOptions::at_level(1)
    .with_label_alignment_over()
    .with_label_position(40)
    .with_offset(5)
    .with_curve(2)
    .with_radius(7)
    .with_angle(30)
    .with_shorten(3, 4)
    .with_shape_arc()
    .with_colour(Colour::new(120, 100, 25, 1.0))
    .with_edge_alignment(false, true)
    .with_style_tail("mono", side="top")
    .with_style_body("barred")
    .with_style_head("epi", side="bottom")
  ignore(
    ffi_adapter_add_edge(
      adapter,
      source_id,
      target_id,
      label="f",
      options~,
      label_colour=Colour::new(240, 100, 50, 1.0),
    ),
  )

  let snapshot = ffi_adapter_snapshot(adapter)
  inspect(snapshot.payload == ffi_adapter_export_base64(adapter), content="true")
  inspect(snapshot.cell_ids, content="[1, 2, 3]")
  inspect(snapshot.vertices.length(), content="2")
  inspect(snapshot.edges.length(), content="1")
  inspect(snapshot.dependencies.length(), content="3")

  inspect(snapshot.vertices[0].id, content="1")
  inspect(snapshot.vertices[0].label, content="A")
  inspect(snapshot.vertices[0].label_colour.h, content="0")
  inspect(snapshot.vertices[1].id, content="2")
  inspect(snapshot.vertices[1].x, content="2")
  inspect(snapshot.vertices[1].y, content="1")

  let edge = snapshot.edges[0]
  inspect(edge.id, content="3")
  inspect(edge.source_id, content="1")
  inspect(edge.target_id, content="2")
  inspect(edge.label, content="f")
  inspect(edge.label_colour.h, content="240")
  inspect(edge.options.label_alignment, content="over")
  inspect(edge.options.label_position, content="40")
  inspect(edge.options.offset, content="5")
  inspect(edge.options.curve, content="2")
  inspect(edge.options.radius, content="7")
  inspect(edge.options.angle, content="30")
  inspect(edge.options.shorten_source, content="3")
  inspect(edge.options.shorten_target, content="4")
  inspect(edge.options.shape, content="arc")
  inspect(edge.options.colour.h, content="120")
  inspect(edge.options.edge_alignment_source, content="false")
  inspect(edge.options.edge_alignment_target, content="true")
  inspect(edge.options.style.tail.name, content="mono")
  inspect(edge.options.style.tail.side, content="top")
  inspect(edge.options.style.body.name, content="barred")
  inspect(edge.options.style.head.name, content="epi")
  inspect(edge.options.style.head.side, content="bottom")

  inspect(snapshot.dependencies[0].cell_id, content="1")
  inspect(snapshot.dependencies[0].dependencies, content="[3]")
  inspect(snapshot.dependencies[0].reverse_dependencies, content="[]")
  inspect(snapshot.dependencies[2].cell_id, content="3")
  inspect(snapshot.dependencies[2].dependencies, content="[]")
  inspect(snapshot.dependencies[2].reverse_dependencies, content="[1, 2]")
}

///|
test "ui ffi adapter snapshot_json returns stable plain json shape" {
  let adapter = ffi_adapter_new()
  let source_id = ffi_adapter_add_vertex(adapter, "A", 0, 0)
  let target_id = ffi_adapter_add_vertex(adapter, "B", 1, 0)
  let options = EdgeOptions::at_level(1)
    .with_label_alignment_right()
    .with_style_head("epi")
    .with_style_body("barred")
    .with_colour(Colour::new(120, 100, 25, 1.0))
  ignore(
    ffi_adapter_add_edge(
      adapter,
      source_id,
      target_id,
      label="f",
      options~,
      label_colour=Colour::new(240, 100, 50, 1.0),
    ),
  )

  let snapshot_json = ffi_adapter_snapshot_json(adapter)
  let root : Map[String, Json] = @json.from_json(@json.parse(snapshot_json))
  let payload : String = @json.from_json(test_json_get(root, "payload"))
  inspect(payload == ffi_adapter_export_base64(adapter), content="true")

  let cell_ids : Array[Int] = @json.from_json(test_json_get(root, "cell_ids"))
  inspect(cell_ids, content="[1, 2, 3]")

  let vertices : Array[Map[String, Json]] = @json.from_json(
    test_json_get(root, "vertices"),
  )
  inspect(vertices.length(), content="2")
  let vertex0_label : String = @json.from_json(test_json_get(vertices[0], "label"))
  inspect(vertex0_label, content="A")

  let edges : Array[Map[String, Json]] = @json.from_json(test_json_get(root, "edges"))
  inspect(edges.length(), content="1")
  let edge0_source : Int = @json.from_json(test_json_get(edges[0], "source_id"))
  let edge0_target : Int = @json.from_json(test_json_get(edges[0], "target_id"))
  let edge0_label : String = @json.from_json(test_json_get(edges[0], "label"))
  inspect(edge0_source, content="1")
  inspect(edge0_target, content="2")
  inspect(edge0_label, content="f")

  let edge_options : Map[String, Json] = @json.from_json(
    test_json_get(edges[0], "options"),
  )
  let edge_label_alignment : String = @json.from_json(
    test_json_get(edge_options, "label_alignment"),
  )
  inspect(edge_label_alignment, content="right")
  let edge_style : Map[String, Json] = @json.from_json(
    test_json_get(edge_options, "style"),
  )
  let edge_style_name : String = @json.from_json(test_json_get(edge_style, "name"))
  inspect(edge_style_name, content="arrow")
  let edge_style_body : Map[String, Json] = @json.from_json(
    test_json_get(edge_style, "body"),
  )
  let edge_style_body_name : String = @json.from_json(
    test_json_get(edge_style_body, "name"),
  )
  inspect(edge_style_body_name, content="barred")
  let edge_style_head : Map[String, Json] = @json.from_json(
    test_json_get(edge_style, "head"),
  )
  let edge_style_head_name : String = @json.from_json(
    test_json_get(edge_style_head, "name"),
  )
  inspect(edge_style_head_name, content="epi")

  let dependencies : Array[Map[String, Json]] = @json.from_json(
    test_json_get(root, "dependencies"),
  )
  inspect(dependencies.length(), content="3")
  let deps0 : Array[Int] = @json.from_json(
    test_json_get(dependencies[0], "dependencies"),
  )
  let rev_deps2 : Array[Int] = @json.from_json(
    test_json_get(dependencies[2], "reverse_dependencies"),
  )
  inspect(
    deps0,
    content="[3]",
  )
  inspect(
    rev_deps2,
    content="[1, 2]",
  )
}
