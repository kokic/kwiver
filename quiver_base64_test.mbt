fn find_edge(quiver : Quiver, id : Int) -> Edge? {
  for cell in quiver.all_cells() {
    match cell {
      CellData::Edge(edge) => if edge.cell.id == id { return Some(edge) }
      _ => ()
    }
  }
  None
}

test "base64 v0 roundtrip preserves ids and structure" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let options = EdgeOptions::at_level(1)
  let edge = Edge::new(3, "f", 1, 2, options, Colour::new(120, 60, 60, 1.0))
  quiver.add(CellData::from_edge(edge))
  quiver.connect(1, 2, 3)

  let encoded = quiver.export_base64_v0()
  let decoded = Quiver::import_base64_v0(encoded)

  inspect(decoded.all_cell_ids(), content="[1, 2, 3]")
  inspect(decoded.connected_components([1]), content="[1, 2, 3]")
}

test "base64 v0 roundtrip preserves edge options" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(10, "X", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(11, "Y", 2, 1)))

  let options = EdgeOptions::at_level(1)
  let edge = Edge::new(12, "g", 10, 11, options, Colour::new(30, 60, 60, 1.0))
  quiver.add(CellData::from_edge(edge))
  quiver.connect(10, 11, 12)

  let encoded = quiver.export_base64_v0()
  let decoded = Quiver::import_base64_v0(encoded)
  let decoded_edge = find_edge(decoded, 12)

  inspect(decoded_edge is Some(_), content="true")
  match decoded_edge {
    Some(edge) => {
      inspect(edge.options.label_position, content="50")
      inspect(edge.options.offset, content="0")
      inspect(edge.options.curve, content="0")
      inspect(edge.options.shorten.source, content="0")
      inspect(edge.options.shorten.target, content="0")
      inspect(edge.options.style.body.name, content="cell")
      inspect(edge.cell.label_colour.h, content="30")
    }
    None => abort("expected edge")
  }
}
