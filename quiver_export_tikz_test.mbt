fn has_string(values : Array[String], target : String) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}

fn has_dependency_reason(
  metadata : TikzCdExportMetadata,
  package_name : String,
  reason : String,
) -> Bool {
  match metadata.dependencies.get(package_name) {
    Some(reasons) => reasons.contains(reason)
    None => false
  }
}

fn tikz_test_find_edge_by_label(quiver : Quiver, label : String) -> Edge? {
  for cell in quiver.all_cells() {
    match cell {
      CellData::Edge(edge) => if edge.cell.label == label { return Some(edge) }
      _ => ()
    }
  }
  None
}

fn tikz_test_find_vertex_id_by_label(quiver : Quiver, label : String) -> Int? {
  for cell in quiver.all_cells() {
    match cell {
      CellData::Vertex(vertex) => if vertex.cell.label == label { return Some(vertex.cell.id) }
      _ => ()
    }
  }
  None
}

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
  inspect(out.contains("A & B\n\t\\arrow[r, \"f\"]"), content="true")
  inspect(out.contains("\\end{tikzcd}"), content="true")
}

test "tikz-cd export prepends base64 comment line" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))

  let out = quiver.export_tikz_cd()
  inspect(out.has_prefix("% "), content="true")
  inspect(out.contains("\n\\begin{tikzcd}"), content="true")
}

test "tikz-cd export supports share URL comment with encoded macro_url" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let options = TikzCdExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .with_macro_url("https://example.com/macros.tex")

  let out = quiver.export_tikz_cd(options=options)
  inspect(out.has_prefix("% https://q.uiver.app#q="), content="true")
  inspect(out.contains("&macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex"), content="true")
}

test "tikz-cd export share URL includes renderer when non-default" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let options = TikzCdExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .with_renderer("svg")

  let out = quiver.export_tikz_cd(options=options)
  inspect(out.has_prefix("% https://q.uiver.app#r=svg&q="), content="true")
}

test "tikz-cd export share URL omits renderer when explicitly default" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let options = TikzCdExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .with_renderer("canvas")

  let out = quiver.export_tikz_cd(options=options)
  inspect(out.has_prefix("% https://q.uiver.app#q="), content="true")
  inspect(out.contains("#r="), content="false")
}

test "tikz-cd export share URL omits q and macro_url for empty quiver" {
  let quiver = Quiver::new()
  let options = TikzCdExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .with_macro_url("https://example.com/macros.tex")

  let out = quiver.export_tikz_cd(options=options)
  inspect(out.has_prefix("% https://q.uiver.app\n"), content="true")
  inspect(out.contains("#q="), content="false")
  inspect(out.contains("macro_url="), content="false")
}

test "tikz-cd export without_share_base_url falls back to payload comment" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let options = TikzCdExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .without_share_base_url()
  let payload = quiver.export_base64_v0()

  let out = quiver.export_tikz_cd(options=options)
  inspect(out.has_prefix(["% ", payload, "\n"].join("")), content="true")
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

test "tikz-cd export uses sparse vertex matrix without trailing empty columns" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 3, 1)))

  let out = quiver.export_tikz_cd()
  inspect(out.contains("A \\\\\n\t&&& B"), content="true")
  inspect(out.contains("A &  &  & "), content="false")
}

test "tikz-cd export formats complex labels like quiver js" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "[a]", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "\\alpha", 1, 0)))
  quiver.add(CellData::from_edge(Edge::new(
    3,
    "x\\\\y",
    1,
    2,
    EdgeOptions::at_level(1),
    Colour::black(),
  )))
  quiver.connect(1, 2, 3)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("{[a]}"), content="true")
  inspect(out.contains("\\alpha"), content="true")
  inspect(out.contains("\\begin{array}{c} x\\\\y \\end{array}"), content="true")
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
  inspect(out.contains("\"\"{name=0, anchor=center, inner sep=0}"), content="true")
  inspect(out.contains("from=0, to=1-2"), content="true")
}

test "tikz-cd export metadata records dependencies and incompatibilities" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  quiver.add(CellData::from_edge(Edge::new(
    3,
    "",
    1,
    2,
    EdgeOptions::at_level(1),
    Colour::black(),
  )))
  quiver.connect(1, 2, 3)

  quiver.add(CellData::from_edge(Edge::new(
    4,
    "",
    3,
    2,
    EdgeOptions::at_level(1),
    Colour::black(),
  )))
  quiver.connect(3, 2, 4)

  let options = EdgeOptions::at_level(1)
    .with_style_tail("hook")
    .with_style_body("bullet solid")
    .with_style_head("epi")
    .with_shorten(10, 0)

  quiver.add(CellData::from_edge(Edge::new(
    5,
    "",
    4,
    2,
    options,
    Colour::black(),
  )))
  quiver.connect(4, 2, 5)

  let result = quiver.export_tikz_cd_result()
  inspect(
    has_string(
      result.metadata.tikz_incompatibilities,
      "double arrows or higher with decorations",
    ),
    content="true",
  )
  inspect(
    has_string(
      result.metadata.tikz_incompatibilities,
      "double arrows or higher with hook tails",
    ),
    content="true",
  )
  inspect(
    has_string(
      result.metadata.tikz_incompatibilities,
      "double arrows or higher with multiple heads",
    ),
    content="true",
  )
  inspect(
    has_dependency_reason(result.metadata, "quiver", "shortened arrows"),
    content="true",
  )
  inspect(
    has_dependency_reason(result.metadata, "tikz-nfold", "triple arrows or higher"),
    content="true",
  )
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
  inspect(out.contains("from=0p, to=1-2"), content="true")
  inspect(
    out.contains(
      "\"\"{name=0p, anchor=center, inner sep=0}, phantom, from=1-1, to=1-2, start anchor=center, end anchor=center",
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
  inspect(out.contains("\\arrow[r, \"h\"'{pos=0.7}, dashed, maps to, no head]"), content="true")
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

test "tikz-cd export emits centre/over label options as label-local parameters" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(3, "C", 2, 0)))

  let centre_options = EdgeOptions::at_level(1)
    .with_label_alignment_centre()
    .with_label_position(60)
  quiver.add(CellData::from_edge(Edge::new(
    4,
    "c",
    1,
    2,
    centre_options,
    Colour::black(),
  )))
  quiver.connect(1, 2, 4)

  let over_options = EdgeOptions::at_level(1)
    .with_label_alignment_over()
    .with_label_position(30)
  quiver.add(CellData::from_edge(Edge::new(
    5,
    "o",
    2,
    3,
    over_options,
    Colour::black(),
  )))
  quiver.connect(2, 3, 5)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("\"c\"{description, pos=0.6}"), content="true")
  inspect(out.contains("\"o\"{marking, allow upside down, pos=0.3}"), content="true")
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
    out.contains("\"\\bullet\"{marking, text=red}"),
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
    out.contains("\"\\circ\"{marking, text=red}"),
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
  inspect(out.contains("draw=red"), content="true")
  inspect(out.contains("\"c\"{text=blue}"), content="true")
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

test "tikz-cd export uses named colours from definitions" {
  let quiver = Quiver::new()
  let named = Colour::new(30, 100, 50, 1.0)
  quiver.add(CellData::from_vertex(Vertex::new(1, "V", 0, 0, named)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let options = EdgeOptions::at_level(1).with_colour(named)
  quiver.add(CellData::from_edge(Edge::new(
    3,
    "f",
    1,
    2,
    options,
    Colour::black(),
  )))
  quiver.connect(1, 2, 3)

  let definitions = TikzCdExportDefinitions::default().with_colour("myorange", named)
  let out = quiver.export_tikz_cd(definitions=definitions)
  inspect(out.contains("\\textcolor{myorange}{V}"), content="true")
  inspect(out.contains("draw=myorange"), content="true")
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
  let f_index = match out.find("\\arrow[r, \"f\"]") {
    Some(index) => index
    None => -1
  }
  let g_index = match out.find("\\arrow[rr, \"g\"]") {
    Some(index) => index
    None => -1
  }
  inspect(f_index >= 0, content="true")
  inspect(g_index > f_index, content="true")
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

test "tikz-cd export maps adjunction loop rotation from angle option" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))

  let options = EdgeOptions::at_level(1)
    .with_style_name("adjunction")
    .with_angle(30)
  quiver.add(CellData::from_edge(Edge::new(
    2,
    "",
    1,
    1,
    options,
    Colour::black(),
  )))
  quiver.connect(1, 1, 2)

  let out = quiver.export_tikz_cd()
  inspect(out.contains("\"\\dashv\"{anchor=center, rotate=-30}"), content="true")
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
    out.contains("\\arrow[r, draw=none, \"\\dashv\"{anchor=center, text=red}]"),
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

  inspect(out.has_prefix("% "), content="true")
  inspect(out.contains("\n\\[\\begin{tikzcd}[ampersand replacement=\\&,cramped]"), content="true")
  inspect(out.has_suffix("\\end{tikzcd}\\]"), content="true")
}

test "tikz-cd export maps equal non-normal seps to sep shorthand" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "X", 0, 0)))
  let options = TikzCdExportOptions::default()
    .with_sep_em(2.70)

  let out = quiver.export_tikz_cd(options=options)
  inspect(out.contains("\\begin{tikzcd}[sep=large]"), content="true")
  inspect(out.contains("column sep="), content="false")
  inspect(out.contains("row sep="), content="false")
}

test "tikz-cd export maps distinct seps to column and row options" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "X", 0, 0)))
  let options = TikzCdExportOptions::default()
    .with_column_sep_em(2.25)
    .with_row_sep_em(0.90)

  let out = quiver.export_tikz_cd(options=options)
  inspect(out.contains("\\begin{tikzcd}[column sep=2.25em,row sep=small]"), content="true")
}

test "tikz-cd import wrapper roundtrips from exported text and preserves metadata" {
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

  let options = TikzCdExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .with_renderer("svg")
    .with_macro_url("https://example.com/macros.tex")
  let out = quiver.export_tikz_cd(options=options)

  let imported = Quiver::import_tikz_cd_result(out)
  inspect(imported.quiver.all_cell_ids(), content="[1, 2, 3]")
  match imported.renderer {
    Some(value) => inspect(value, content="svg")
    None => abort("expected renderer")
  }
  match imported.macro_url {
    Some(value) => inspect(value, content="https://example.com/macros.tex")
    None => abort("expected macro_url")
  }

  let imported_quiver = Quiver::import_tikz_cd(out)
  inspect(imported_quiver.all_cell_ids(), content="[1, 2, 3]")
}

test "tikz-cd import minimal parser supports handwritten matrix and right arrow" {
  let input = [
    "\\begin{tikzcd}\n",
    "A \\arrow[r, \"f\"] & B\n",
    "\\end{tikzcd}",
  ].join("")

  let imported = Quiver::import_tikz_cd_result(input)
  inspect(imported.macro_url is None, content="true")
  inspect(imported.renderer is None, content="true")
  inspect(imported.embed, content="false")
  inspect(imported.quiver.all_cell_ids(), content="[1, 2, 3]")

  let source_id = match tikz_test_find_vertex_id_by_label(imported.quiver, "A") {
    Some(value) => value
    None => abort("expected vertex A")
  }
  let target_id = match tikz_test_find_vertex_id_by_label(imported.quiver, "B") {
    Some(value) => value
    None => abort("expected vertex B")
  }
  match tikz_test_find_edge_by_label(imported.quiver, "f") {
    Some(edge) => {
      inspect(edge.source == source_id, content="true")
      inspect(edge.target == target_id, content="true")
    }
    None => abort("expected edge f")
  }
}

test "tikz-cd import minimal parser supports diagonal direction shorthand" {
  let input = [
    "\\begin{tikzcd}\n",
    "A \\arrow[dr, \"g\"] & B \\\\\n",
    "C & D\n",
    "\\end{tikzcd}",
  ].join("")

  let quiver = Quiver::import_tikz_cd(input)
  inspect(quiver.all_cell_ids(), content="[1, 2, 3, 4, 5]")

  let source_id = match tikz_test_find_vertex_id_by_label(quiver, "A") {
    Some(value) => value
    None => abort("expected vertex A")
  }
  let target_id = match tikz_test_find_vertex_id_by_label(quiver, "D") {
    Some(value) => value
    None => abort("expected vertex D")
  }
  match tikz_test_find_edge_by_label(quiver, "g") {
    Some(edge) => {
      inspect(edge.source == source_id, content="true")
      inspect(edge.target == target_id, content="true")
    }
    None => abort("expected edge g")
  }
}

test "tikz-cd import parser supports ar alias, braced vertex labels, and bare arrow labels" {
  let input = [
    "\\begin{tikzcd}\n",
    "{A} \\ar[r, f] & {B}\n",
    "\\end{tikzcd}",
  ].join("")

  let quiver = Quiver::import_tikz_cd(input)
  inspect(quiver.all_cell_ids(), content="[1, 2, 3]")

  let source_id = match tikz_test_find_vertex_id_by_label(quiver, "A") {
    Some(value) => value
    None => abort("expected vertex A")
  }
  let target_id = match tikz_test_find_vertex_id_by_label(quiver, "B") {
    Some(value) => value
    None => abort("expected vertex B")
  }
  match tikz_test_find_edge_by_label(quiver, "f") {
    Some(edge) => {
      inspect(edge.source == source_id, content="true")
      inspect(edge.target == target_id, content="true")
    }
    None => abort("expected edge f")
  }
}

test "tikz-cd import parser supports from/to matrix references" {
  let input = [
    "\\begin{tikzcd}\n",
    "A & B \\arrow[from={1-1}, to={2-2}, \"h\"] \\\\\n",
    "C & D\n",
    "\\end{tikzcd}",
  ].join("")

  let quiver = Quiver::import_tikz_cd(input)
  inspect(quiver.all_cell_ids(), content="[1, 2, 3, 4, 5]")

  let source_id = match tikz_test_find_vertex_id_by_label(quiver, "A") {
    Some(value) => value
    None => abort("expected vertex A")
  }
  let target_id = match tikz_test_find_vertex_id_by_label(quiver, "D") {
    Some(value) => value
    None => abort("expected vertex D")
  }
  match tikz_test_find_edge_by_label(quiver, "h") {
    Some(edge) => {
      inspect(edge.source == source_id, content="true")
      inspect(edge.target == target_id, content="true")
    }
    None => abort("expected edge h")
  }
}

test "tikz-cd import parser supports ampersand replacement and brace arrow options" {
  let input = [
    "\\begin{tikzcd}[ampersand replacement=\\&]\n",
    "A \\arrow{r, \"k\"} \\& B\n",
    "\\end{tikzcd}",
  ].join("")

  let quiver = Quiver::import_tikz_cd(input)
  inspect(quiver.all_cell_ids(), content="[1, 2, 3]")

  let source_id = match tikz_test_find_vertex_id_by_label(quiver, "A") {
    Some(value) => value
    None => abort("expected vertex A")
  }
  let target_id = match tikz_test_find_vertex_id_by_label(quiver, "B") {
    Some(value) => value
    None => abort("expected vertex B")
  }
  match tikz_test_find_edge_by_label(quiver, "k") {
    Some(edge) => {
      inspect(edge.source == source_id, content="true")
      inspect(edge.target == target_id, content="true")
    }
    None => abort("expected edge k")
  }
}
