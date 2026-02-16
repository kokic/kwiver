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
    "\\begin{tikzcd}\n",
    "A \\arrow[r, \"f\"] & B\n",
    "\\end{tikzcd}",
  ].join("")

  let imported = ffi_adapter_import_tikz_cd(adapter, input)
  inspect(imported.macro_url, content="None")
  inspect(imported.renderer, content="None")
  inspect(imported.embed, content="false")
  inspect(ffi_adapter_all_cell_ids(adapter).length(), content="3")

  let roundtrip = Quiver::import_base64_v0(imported.payload)
  inspect(roundtrip.all_cell_ids().length(), content="3")
}

