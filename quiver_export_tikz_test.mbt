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

test "tikz-cd export supports edge-to-vertex via named edge references" {
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
  inspect(out.contains("\"alpha\""), content="true")
  inspect(out.contains("\"\"{name=e3, anchor=center, inner sep=0}"), content="true")
  inspect(out.contains("from=e3, to=1-2"), content="true")
}

test "tikz-cd export supports non-edge-aligned references via phantom anchors" {
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

  let options = EdgeOptions::at_level(2).with_edge_alignment_source(false)
  quiver.add(CellData::from_edge(Edge::new(
    4,
    "alpha",
    3,
    2,
    options,
    Colour::black(),
  )))
  quiver.connect(3, 2, 4)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("from=e3p, to=1-2"), content="true")
  inspect(
    out.contains(
      "\"\"{name=e3p, anchor=center, inner sep=0}, phantom, from=1-1, to=1-2, start anchor=center, end anchor=center",
    ),
    content="true",
  )
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

test "tikz-cd export maps barred arrow body decoration" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let options = EdgeOptions::at_level(1).with_style_body("barred")
  quiver.add(CellData::from_edge(Edge::new(
    3,
    "",
    1,
    2,
    options,
    Colour::black(),
  )))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("\"\\shortmid\"{marking}"), content="true")
}

test "tikz-cd export maps double barred arrow body decoration with midpoint" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let options = EdgeOptions::at_level(1)
    .with_style_body("double barred")
    .with_shorten(20, 10)
  quiver.add(CellData::from_edge(Edge::new(
    3,
    "",
    1,
    2,
    options,
    Colour::black(),
  )))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("\"\\shortmid\\shortmid\"{marking, pos=0.55}"), content="true")
}

test "tikz-cd export maps bullet solid arrow body decoration" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let options = EdgeOptions::at_level(1)
    .with_style_body("bullet solid")
    .with_colour(Colour::new(0, 100, 50, 1.0))
  quiver.add(CellData::from_edge(Edge::new(
    3,
    "",
    1,
    2,
    options,
    Colour::black(),
  )))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(
    out.contains("\"\\bullet\"{marking, text={rgb,255:red,255;green,0;blue,0}}"),
    content="true",
  )
}

test "tikz-cd export maps bullet hollow arrow body decoration" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let options = EdgeOptions::at_level(1)
    .with_style_body("bullet hollow")
    .with_colour(Colour::new(0, 100, 50, 1.0))
  quiver.add(CellData::from_edge(Edge::new(
    3,
    "",
    1,
    2,
    options,
    Colour::black(),
  )))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(
    out.contains("\"\\bullet\"{marking, text=\\pgfkeysvalueof{/tikz/commutative diagrams/background color}}"),
    content="true",
  )
  inspect(
    out.contains("\"\\circ\"{marking, text={rgb,255:red,255;green,0;blue,0}}"),
    content="true",
  )
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

test "tikz-cd export separates edge and label colours" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let options = EdgeOptions::at_level(1).with_colour(Colour::new(0, 100, 50, 1.0))
  quiver.add(CellData::from_edge(Edge::new(
    3,
    "c",
    1,
    2,
    options,
    Colour::new(240, 100, 50, 1.0),
  )))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("draw={rgb,255:red,255;green,0;blue,0}"), content="true")
  inspect(out.contains("\\textcolor{rgb,255:red,0;green,0;blue,255}{c}"), content="true")
  inspect(out.contains("color={rgb,255:red,255;green,0;blue,0}"), content="false")
}

test "tikz-cd export uses shared colour option when edge and label colours match" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let green = Colour::new(120, 100, 50, 1.0)
  let options = EdgeOptions::at_level(1).with_colour(green)
  quiver.add(CellData::from_edge(Edge::new(3, "p", 1, 2, options, green)))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("color={rgb,255:red,0;green,255;blue,0}"), content="true")
  inspect(out.contains("draw={rgb,255:red,0;green,255;blue,0}"), content="false")
  inspect(out.contains("\\textcolor"), content="false")
}

test "tikz-cd export uses draw=none for empty arrow style" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let options = EdgeOptions::at_level(1)
    .with_colour(Colour::new(0, 100, 50, 1.0))
    .with_style_tail("none")
    .with_style_body("none")
    .with_style_head("none")

  quiver.add(CellData::from_edge(Edge::new(
    3,
    "e",
    1,
    2,
    options,
    Colour::black(),
  )))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("draw=none"), content="true")
  inspect(out.contains("no body"), content="false")
  inspect(out.contains("no head"), content="false")
  inspect(out.contains("draw={rgb,255:red,255;green,0;blue,0}"), content="false")
}

test "tikz-cd export colours vertex labels" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new(
    1,
    "V",
    0,
    0,
    Colour::new(300, 100, 50, 1.0),
  )))

  let out = quiver.export_tikz_cd()
  inspect(out.contains("\\textcolor{rgb,255:red,255;green,0;blue,255}{V}"), content="true")
}

test "tikz-cd export sorts edges by source and target position" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(3, "C", 2, 0)))

  // Insert farther edge with smaller id first; output should still place r before rr.
  quiver.add(CellData::from_edge(Edge::new(
    4,
    "g",
    1,
    3,
    EdgeOptions::at_level(1),
    Colour::black(),
  )))
  quiver.connect(1, 3, 4)

  quiver.add(CellData::from_edge(Edge::new(
    5,
    "f",
    1,
    2,
    EdgeOptions::at_level(1),
    Colour::black(),
  )))
  quiver.connect(1, 2, 5)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("A \\arrow[r, \"f\"] \\arrow[rr, \"g\"]"), content="true")
}

test "tikz-cd export emits loop parameters for self-edge" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))

  let options = EdgeOptions::at_level(1)
    .with_radius(3)
    .with_angle(45)
  quiver.add(CellData::from_edge(Edge::new(
    2,
    "l",
    1,
    1,
    options,
    Colour::black(),
  )))
  quiver.connect(1, 1, 2)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("from=1-1, to=1-1"), content="true")
  inspect(out.contains("loop"), content="true")
  inspect(out.contains("in=10"), content="true")
  inspect(out.contains("out=80"), content="true")
  inspect(out.contains("distance=10mm"), content="true")
}

test "tikz-cd export loop supports negative radius" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))

  let options = EdgeOptions::at_level(1)
    .with_radius(-2)
    .with_angle(0)
  quiver.add(CellData::from_edge(Edge::new(
    2,
    "n",
    1,
    1,
    options,
    Colour::black(),
  )))
  quiver.connect(1, 1, 2)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("in=302.5"), content="true")
  inspect(out.contains("out=237.5"), content="true")
  inspect(out.contains("distance=7.5mm"), content="true")
}

test "tikz-cd export maps adjunction style" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let options = EdgeOptions::at_level(1).with_style_name("adjunction")
  quiver.add(CellData::from_edge(Edge::new(
    3,
    "",
    1,
    2,
    options,
    Colour::black(),
  )))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("\\arrow[r, draw=none, \"\\dashv\"{anchor=center}]"), content="true")
}

test "tikz-cd export maps non-arrow edge colour to decoration text" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let options = EdgeOptions::at_level(1)
    .with_style_name("adjunction")
    .with_colour(Colour::new(0, 100, 50, 1.0))
  quiver.add(CellData::from_edge(Edge::new(
    3,
    "",
    1,
    2,
    options,
    Colour::new(240, 100, 50, 1.0),
  )))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(
    out.contains("\\arrow[r, draw=none, \"\\dashv\"{anchor=center, text={rgb,255:red,255;green,0;blue,0}}]"),
    content="true",
  )
}

test "tikz-cd export non-arrow shared colour avoids decoration text override" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let green = Colour::new(120, 100, 50, 1.0)
  let options = EdgeOptions::at_level(1).with_style_name("adjunction").with_colour(green)
  quiver.add(CellData::from_edge(Edge::new(
    3,
    "",
    1,
    2,
    options,
    green,
  )))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("color={rgb,255:red,0;green,255;blue,0}"), content="true")
  inspect(out.contains("\"\\dashv\"{anchor=center, text={rgb,255:red,0;green,255;blue,0}}"), content="false")
}

test "tikz-cd export maps corner style" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let options = EdgeOptions::at_level(1).with_style_name("corner")
  quiver.add(CellData::from_edge(Edge::new(
    3,
    "",
    1,
    2,
    options,
    Colour::black(),
  )))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("\\arrow[r, draw=none, \"\\lrcorner\"{anchor=center, pos=0.125, rotate=45}]"), content="true")
}

test "tikz-cd export maps corner-inverse style" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let options = EdgeOptions::at_level(1).with_style_name("corner-inverse")
  quiver.add(CellData::from_edge(Edge::new(
    3,
    "",
    1,
    2,
    options,
    Colour::black(),
  )))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("\\arrow[r, draw=none, \"\\ulcorner\"{anchor=center, pos=0.125, rotate=45}]"), content="true")
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
