///|
fn sort_ids(ids : Array[Int]) -> Array[Int] {
  let out = ids.copy()
  out.sort()
  out
}

///|
fn cell_ids(cells : Array[CellData]) -> Array[Int] {
  let ids = cells.map(cell => cell.id())
  sort_ids(ids)
}

///|
test "quiver add and contains" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  inspect(quiver.contains_cell(1), content="true")
  inspect(quiver.all_cell_ids().length(), content="1")
  inspect(cell_ids(quiver.all_cells()), content="[1]")
}

///|
test "quiver remove cascades through dependencies" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))
  quiver.add(
    CellData::from_edge(
      Edge::new(3, "f", 1, 2, EdgeOptions::at_level(1), Colour::black()),
    ),
  )

  quiver.connect(1, 2, 3)

  inspect(sort_ids(quiver.remove(1, 5)), content="[1, 3]")
  inspect(quiver.contains_cell(1), content="false")
  inspect(quiver.contains_cell(3), content="false")

  quiver.flush(5)
  inspect(sort_ids(quiver.all_cell_ids()), content="[2]")
  inspect(cell_ids(quiver.all_cells()), content="[2]")
}

///|
test "quiver transitive closures" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))
  quiver.add(
    CellData::from_edge(
      Edge::new(3, "f", 1, 2, EdgeOptions::at_level(1), Colour::black()),
    ),
  )
  quiver.add(
    CellData::from_edge(
      Edge::new(4, "alpha", 3, 2, EdgeOptions::at_level(2), Colour::black()),
    ),
  )

  quiver.connect(1, 2, 3)
  quiver.connect(3, 2, 4)

  inspect(sort_ids(quiver.transitive_dependencies([1])), content="[1, 3, 4]")
  inspect(
    sort_ids(quiver.transitive_dependencies([3], exclude_roots=true)),
    content="[4]",
  )
  inspect(
    sort_ids(quiver.transitive_reverse_dependencies([4])),
    content="[1, 2, 3, 4]",
  )
  inspect(sort_ids(quiver.connected_components([1])), content="[1, 2, 3, 4]")
}

///|
test "quiver next_available_id skips occupied ids and reuses flushed ids" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(3, "B", 1, 0)))

  inspect(quiver.next_available_id(), content="2")
  inspect(quiver.next_available_id(start=3), content="4")

  ignore(quiver.remove(1, 10))
  inspect(quiver.next_available_id(start=1), content="2")

  quiver.flush(10)
  inspect(quiver.next_available_id(start=1), content="1")
}
