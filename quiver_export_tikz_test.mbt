test "tikz-cd export basic vertex grid and arrow" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))
  quiver.add(CellData::from_edge(Edge::new(
    3,
    "f",
    1,
    2,
    EdgeOptions::at_level(1),
    Colour::black(),
  )))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("\\begin{tikzcd}"), content="true")
  inspect(out.contains("A \\arrow[r, \"f\"] & B"), content="true")
  inspect(out.contains("\\end{tikzcd}"), content="true")
}

test "tikz-cd export normalises coordinates to 1-indexed grid" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", -1, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 1)))
  quiver.add(CellData::from_edge(Edge::new(
    3,
    "g",
    1,
    2,
    EdgeOptions::at_level(1),
    Colour::black(),
  )))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("\\arrow[drr, \"g\"]"), content="true")
}

test "tikz-cd export ignores higher edges between non-vertices" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  quiver.add(CellData::from_edge(Edge::new(
    3,
    "f",
    1,
    2,
    EdgeOptions::at_level(1),
    Colour::black(),
  )))
  quiver.connect(1, 2, 3)

  quiver.add(CellData::from_edge(Edge::new(
    4,
    "alpha",
    3,
    2,
    EdgeOptions::at_level(2),
    Colour::black(),
  )))
  quiver.connect(3, 2, 4)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("\"f\""), content="true")
  inspect(out.contains("\"alpha\""), content="false")
}

test "tikz-cd export maps basic arrow style options" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let options = EdgeOptions::at_level(1)
    .with_label_alignment_right()
    .with_label_position(70)
    .with_style_tail("maps to")
    .with_style_body("dashed")
    .with_style_head("none")

  quiver.add(CellData::from_edge(Edge::new(
    3,
    "h",
    1,
    2,
    options,
    Colour::black(),
  )))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("\\arrow[r, \"h\", swap, pos=0.7, dashed, maps to, no head]"), content="true")
}

test "tikz-cd export maps hook and harpoon side options" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let options = EdgeOptions::at_level(1)
    .with_style_tail("hook", side="bottom")
    .with_style_head("harpoon", side="bottom")

  quiver.add(CellData::from_edge(Edge::new(
    3,
    "k",
    1,
    2,
    options,
    Colour::black(),
  )))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("\\arrow[r, \"k\", hook', harpoon']"), content="true")
}

test "tikz-cd export maps offset curve and shorten options" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let options = EdgeOptions::at_level(1)
    .with_offset(2)
    .with_curve(-1)
    .with_shorten(10, 20)

  quiver.add(CellData::from_edge(Edge::new(
    3,
    "m",
    1,
    2,
    options,
    Colour::black(),
  )))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("shift right=2"), content="true")
  inspect(out.contains("curve={height=-6pt}"), content="true")
  inspect(out.contains("between={0.1}{0.8}"), content="true")
}

test "tikz-cd export supports wrapping options" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "X", 0, 0)))
  let settings = TikzCdExportSettings::default()
    .with_ampersand_replacement()
    .with_cramped()
    .with_centre_diagram()
  let out = quiver.export_tikz_cd(settings=settings)

  inspect(out.has_prefix("\\[\\begin{tikzcd}[ampersand replacement=\\&,cramped]"), content="true")
  inspect(out.has_suffix("\\end{tikzcd}\\]"), content="true")
}
