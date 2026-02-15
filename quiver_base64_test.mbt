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

test "base64 share url encodes macro_url for non-empty quiver" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))

  let payload = quiver.export_base64_v0()
  let link = quiver.export_base64_share_url(
    Some("https://q.uiver.app"),
    Some("https://example.com/macros.tex"),
  )
  inspect(
    link == [
      "https://q.uiver.app#q=",
      payload,
      "&macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex",
    ].join(""),
    content="true",
  )
}

test "base64 share url includes renderer when non-default" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))

  let payload = quiver.export_base64_v0()
  let link = quiver.export_base64_share_url(
    Some("https://q.uiver.app"),
    None,
    renderer="svg",
  )
  inspect(
    link == ["https://q.uiver.app#r=svg&q=", payload].join(""),
    content="true",
  )
}

test "base64 share url omits renderer when default" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))

  let payload = quiver.export_base64_v0()
  let link = quiver.export_base64_share_url(
    Some("https://q.uiver.app"),
    None,
    renderer="canvas",
  )
  inspect(
    link == ["https://q.uiver.app#q=", payload].join(""),
    content="true",
  )
}

test "base64 share url percent-encodes renderer value" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))

  let payload = quiver.export_base64_v0()
  let link = quiver.export_base64_share_url(
    Some("https://q.uiver.app"),
    None,
    renderer="svg/canvas mode",
  )
  inspect(
    link == ["https://q.uiver.app#r=svg%2Fcanvas%20mode&q=", payload].join(""),
    content="true",
  )
}

test "base64 share url uses configurable default renderer" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))

  let payload = quiver.export_base64_v0()
  let link = quiver.export_base64_share_url(
    Some("https://q.uiver.app"),
    None,
    renderer="svg",
    default_renderer="svg",
  )
  inspect(
    link == ["https://q.uiver.app#q=", payload].join(""),
    content="true",
  )
}

test "base64 share url for empty quiver returns base only" {
  let quiver = Quiver::new()
  let link = quiver.export_base64_share_url(
    Some("https://q.uiver.app"),
    Some("https://example.com/macros.tex"),
  )
  inspect(link, content="https://q.uiver.app")
}

test "base64 share url without base returns payload" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let payload = quiver.export_base64_v0()
  let link = quiver.export_base64_share_url(None, Some("https://example.com/macros.tex"))
  inspect(link, content=payload)
}

test "base64 share url parser extracts payload renderer and macro_url" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let payload = quiver.export_base64_v0()
  let link = quiver.export_base64_share_url(
    Some("https://q.uiver.app"),
    Some("https://example.com/macros.tex"),
    renderer="svg",
  )
  let parsed = Quiver::parse_base64_share_url(link)

  match parsed.payload {
    Some(value) => inspect(value == payload, content="true")
    None => abort("expected payload")
  }
  match parsed.renderer {
    Some(value) => inspect(value, content="svg")
    None => abort("expected renderer")
  }
  match parsed.macro_url {
    Some(value) => inspect(value, content="https://example.com/macros.tex")
    None => abort("expected macro_url")
  }
}

test "base64 share url parser ignores embed and normalises default renderer" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let payload = quiver.export_base64_v0()
  let link = [
    "https://q.uiver.app#r=canvas&q=",
    payload,
    "&macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex&embed",
  ].join("")
  let parsed = Quiver::parse_base64_share_url(link)

  match parsed.payload {
    Some(value) => inspect(value == payload, content="true")
    None => abort("expected payload")
  }
  inspect(parsed.renderer is None, content="true")
  match parsed.macro_url {
    Some(value) => inspect(value, content="https://example.com/macros.tex")
    None => abort("expected macro_url")
  }
}

test "base64 import share url roundtrip works for full link and payload-only" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))
  let edge = Edge::new(3, "f", 1, 2, EdgeOptions::at_level(1), Colour::black())
  quiver.add(CellData::from_edge(edge))
  quiver.connect(1, 2, 3)

  let link = quiver.export_base64_share_url(
    Some("https://q.uiver.app"),
    Some("https://example.com/macros.tex"),
    renderer="svg",
  )
  let decoded_full = Quiver::import_base64_share_url(link)
  inspect(decoded_full.all_cell_ids(), content="[1, 2, 3]")

  let payload_only = quiver.export_base64_share_url(None, None)
  let decoded_payload = Quiver::import_base64_share_url(payload_only)
  inspect(decoded_payload.all_cell_ids(), content="[1, 2, 3]")
}

test "base64 import share url result preserves renderer and macro_url metadata" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let link = quiver.export_base64_share_url(
    Some("https://q.uiver.app"),
    Some("https://example.com/macros.tex"),
    renderer="svg",
  )

  let imported = Quiver::import_base64_share_url_result(link)
  inspect(imported.quiver.all_cell_ids(), content="[1]")
  match imported.renderer {
    Some(value) => inspect(value, content="svg")
    None => abort("expected renderer")
  }
  match imported.macro_url {
    Some(value) => inspect(value, content="https://example.com/macros.tex")
    None => abort("expected macro_url")
  }
}

test "base64 import share url result normalises default renderer" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let payload = quiver.export_base64_v0()
  let link = ["https://q.uiver.app#r=canvas&q=", payload].join("")

  let imported = Quiver::import_base64_share_url_result(link)
  inspect(imported.quiver.all_cell_ids(), content="[1]")
  inspect(imported.renderer is None, content="true")
}

test "panic base64 import share url without payload" {
  ignore(Quiver::import_base64_share_url("https://q.uiver.app"))
}
