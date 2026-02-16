///|
test "fletcher export basic nodes and edge" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))
  quiver.add(
    CellData::from_edge(
      Edge::new(3, "f", 1, 2, EdgeOptions::at_level(1), Colour::black()),
    ),
  )
  quiver.connect(1, 2, 3)

  let out = quiver.export_fletcher()
  inspect(out.has_prefix("// "), content="true")
  inspect(out.contains("\n#diagram({\n"), content="true")
  inspect(out.contains("node((0, 0), [$A$])"), content="true")
  inspect(out.contains("node((1, 0), [$B$])"), content="true")
  inspect(out.contains("edge((0, 0), (1, 0), [$f$]"), content="true")
  inspect(out.contains("\"->\""), content="true")
}

///|
test "fletcher export supports centred diagram wrapper" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))

  let out = quiver.export_fletcher(
    settings=FletcherExportSettings::default().with_centre_diagram(),
  )

  inspect(out.contains("\n#align(center, diagram({\n"), content="true")
  inspect(out.has_suffix("\n}))"), content="true")
}

///|
test "fletcher export supports share URL comment with encoded macro_url" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let options = FletcherExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .with_macro_url("https://example.com/macros.tex")

  let out = quiver.export_fletcher(options~)
  inspect(out.has_prefix("// https://q.uiver.app#q="), content="true")
  inspect(
    out.contains("&macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex"),
    content="true",
  )
}

///|
test "fletcher export share URL includes renderer when non-default" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let options = FletcherExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .with_renderer("svg")

  let out = quiver.export_fletcher(options~)
  inspect(out.has_prefix("// https://q.uiver.app#r=svg&q="), content="true")
}

///|
test "fletcher export share URL omits renderer when explicitly default" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let options = FletcherExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .with_renderer("canvas")

  let out = quiver.export_fletcher(options~)
  inspect(out.has_prefix("// https://q.uiver.app#q="), content="true")
  inspect(out.contains("#r="), content="false")
}

///|
test "fletcher export share URL omits q and macro_url for empty quiver" {
  let quiver = Quiver::new()
  let options = FletcherExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .with_macro_url("https://example.com/macros.tex")

  let out = quiver.export_fletcher(options~)
  inspect(out.has_prefix("// https://q.uiver.app\n"), content="true")
  inspect(out.contains("#q="), content="false")
  inspect(out.contains("macro_url="), content="false")
}

///|
test "fletcher export without_share_base_url falls back to payload comment" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let options = FletcherExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .without_share_base_url()
  let payload = quiver.export_base64_v0()

  let out = quiver.export_fletcher(options~)
  inspect(out.has_prefix(["// ", payload, "\n"].join("")), content="true")
}

///|
test "fletcher export maps label options, styles, and colours" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let options = EdgeOptions::at_level(1)
    .with_label_alignment_over()
    .with_label_position(70)
    .with_curve(-2)
    .with_style_tail("maps to")
    .with_style_body("dashed")
    .with_style_head("arrowhead")
    .with_colour(Colour::new(0, 100, 50, 1.0))

  quiver.add(
    CellData::from_edge(
      Edge::new(3, "g", 1, 2, options, Colour::new(240, 100, 50, 1.0)),
    ),
  )
  quiver.connect(1, 2, 3)

  let out = quiver.export_fletcher()
  inspect(out.contains("\"|-->\""), content="true")
  inspect(out.contains("label-fill: false"), content="true")
  inspect(out.contains("label-angle: right"), content="true")
  inspect(out.contains("label-side: center"), content="true")
  inspect(out.contains("label-pos: 0.7"), content="true")
  inspect(out.contains("bend: 36deg"), content="true")
  inspect(out.contains("text(color.hsl(240deg"), content="true")
  inspect(out.contains("[$g$]"), content="true")
  inspect(out.contains("stroke: color.hsl(0deg"), content="true")
}

///|
test "fletcher export maps straight-edge offset to shift" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))

  let options = EdgeOptions::at_level(1).with_offset(2)
  quiver.add(
    CellData::from_edge(Edge::new(3, "", 1, 2, options, Colour::black())),
  )
  quiver.connect(1, 2, 3)

  let out = quiver.export_fletcher()
  inspect(out.contains("shift: -0.1"), content="true")
}

///|
test "fletcher export maps loop bend and loop-angle" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))

  let options = EdgeOptions::at_level(1)
    .with_shape_arc()
    .with_radius(3)
    .with_angle(45)

  quiver.add(
    CellData::from_edge(Edge::new(2, "", 1, 1, options, Colour::black())),
  )
  quiver.connect(1, 1, 2)

  let out = quiver.export_fletcher()
  inspect(out.contains("bend: 140deg"), content="true")
  inspect(out.contains("loop-angle: 45deg"), content="true")
}

///|
test "fletcher import wrapper roundtrips from exported text and preserves metadata" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))
  quiver.add(
    CellData::from_edge(
      Edge::new(3, "f", 1, 2, EdgeOptions::at_level(1), Colour::black()),
    ),
  )
  quiver.connect(1, 2, 3)

  let options = FletcherExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .with_renderer("svg")
    .with_macro_url("https://example.com/macros.tex")
  let out = quiver.export_fletcher(options~)

  let imported = Quiver::import_fletcher_result(out)
  inspect(imported.quiver.all_cell_ids(), content="[1, 2, 3]")
  match imported.renderer {
    Some(value) => inspect(value, content="svg")
    None => abort("expected renderer")
  }
  match imported.macro_url {
    Some(value) => inspect(value, content="https://example.com/macros.tex")
    None => abort("expected macro_url")
  }

  let imported_quiver = Quiver::import_fletcher(out)
  inspect(imported_quiver.all_cell_ids(), content="[1, 2, 3]")
}
