fn find_edge(quiver : Quiver, id : Int) -> Edge? {
  for cell in quiver.all_cells() {
    match cell {
      CellData::Edge(edge) => if edge.cell.id == id { return Some(edge) }
      _ => ()
    }
  }
  None
}

fn base64_encode_json(input : String) -> String {
  @base64.encode(@utf8.encode(input))
}

fn alignment_variant_to_int(alignment : LabelAlignment) -> Int {
  match alignment {
    LabelAlignment::Left => 0
    LabelAlignment::Centre => 1
    LabelAlignment::Right => 2
    LabelAlignment::Over => 3
  }
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

test "base64 v0 import supports js canonical minimal layout" {
  let encoded = base64_encode_json(
    "[0,2,[0,0,\"A\"],[1,0,\"B\"],[0,1,\"f\"]]",
  )
  let decoded = Quiver::import_base64_v0(encoded)

  inspect(decoded.all_cell_ids(), content="[1, 2, 3]")
  match find_edge(decoded, 3) {
    Some(edge) => {
      inspect(edge.source, content="1")
      inspect(edge.target, content="2")
      inspect(edge.cell.label, content="f")
    }
    None => abort("expected edge")
  }
}

test "base64 v0 import supports js canonical edge option deltas" {
  let encoded = base64_encode_json(
    [
      "[0,2,[0,0,\"A\"],[1,0,\"B\"],[0,1,\"g\",2,{\"offset\":7,\"curve\":20,\"shorten\":{\"source\":5,\"target\":6},\"colour\":[120,60,50,1],\"edge_alignment\":{\"source\":false},\"style\":{\"tail\":{\"name\":\"hook\",\"side\":\"left\"},\"body\":{\"name\":\"barred\"},\"head\":{\"name\":\"none\"}}},[30,50,50,1]]]",
    ].join(""),
  )
  let decoded = Quiver::import_base64_v0(encoded)

  match find_edge(decoded, 3) {
    Some(edge) => {
      inspect(alignment_variant_to_int(edge.options.label_alignment), content="2")
      inspect(edge.options.offset, content="7")
      inspect(edge.options.curve, content="20")
      inspect(edge.options.shorten.source, content="5")
      inspect(edge.options.shorten.target, content="6")
      inspect(edge.options.colour.h, content="120")
      inspect(edge.options.edge_alignment.source, content="false")
      inspect(edge.options.style.tail.name, content="hook")
      inspect(edge.options.style.tail.side, content="left")
      inspect(edge.options.style.body.name, content="barred")
      inspect(edge.options.style.head.name, content="none")
      inspect(edge.cell.label_colour.h, content="30")
    }
    None => abort("expected edge")
  }
}

test "base64 v0 import supports legacy js length option" {
  let encoded = base64_encode_json(
    "[0,2,[0,0,\"A\"],[1,0,\"B\"],[0,1,\"h\",0,{\"length\":80}]]",
  )
  let decoded = Quiver::import_base64_v0(encoded)

  match find_edge(decoded, 3) {
    Some(edge) => {
      inspect(edge.options.shorten.source, content="10")
      inspect(edge.options.shorten.target, content="10")
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
  inspect(parsed.embed, content="false")
}

test "base64 share url parser captures embed and normalises default renderer" {
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
  inspect(parsed.embed, content="true")
}

test "base64 share url parser supports hash embed without payload" {
  let parsed = Quiver::parse_base64_share_url("https://q.uiver.app#embed")
  inspect(parsed.payload is None, content="true")
  inspect(parsed.renderer is None, content="true")
  inspect(parsed.macro_url is None, content="true")
  inspect(parsed.embed, content="true")
}

test "base64 share url parser supports hash question prefix and html ampersands" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let payload = quiver.export_base64_v0()
  let link = [
    "https://q.uiver.app#?r=svg&q=",
    payload,
    "&amp;macro_url=https%3A%2F%2Fexample.com%2Fmy+macros.tex&amp;embed",
  ].join("")
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
    Some(value) => inspect(value, content="https://example.com/my macros.tex")
    None => abort("expected macro_url")
  }
  inspect(parsed.embed, content="true")
}

test "base64 share url parser supports query-style url without hash" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let payload = quiver.export_base64_v0()
  let link = ["https://q.uiver.app?q=", payload, "&embed"].join("")
  let parsed = Quiver::parse_base64_share_url(link)

  match parsed.payload {
    Some(value) => inspect(value == payload, content="true")
    None => abort("expected payload")
  }
  inspect(parsed.embed, content="true")
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
  inspect(imported.embed, content="false")
}

test "base64 import share url result normalises default renderer" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let payload = quiver.export_base64_v0()
  let link = ["https://q.uiver.app#r=canvas&q=", payload].join("")

  let imported = Quiver::import_base64_share_url_result(link)
  inspect(imported.quiver.all_cell_ids(), content="[1]")
  inspect(imported.renderer is None, content="true")
  inspect(imported.embed, content="false")
}

test "base64 share reference extraction supports tikz fletcher and html headers" {
  let payload = "abc123"
  let tikz = ["% https://q.uiver.app#q=", payload, "\n\\begin{tikzcd}"].join("")
  let fletcher = ["// https://q.uiver.app#q=", payload, "\n#diagram({})"].join("")
  let html = ["<!-- https://q.uiver.app#q=", payload, " -->\n<iframe></iframe>"].join("")

  match Quiver::extract_base64_share_reference(tikz) {
    Some(value) => inspect(value, content=["https://q.uiver.app#q=", payload].join(""))
    None => abort("expected tikz reference")
  }
  match Quiver::extract_base64_share_reference(fletcher) {
    Some(value) => inspect(value, content=["https://q.uiver.app#q=", payload].join(""))
    None => abort("expected fletcher reference")
  }
  match Quiver::extract_base64_share_reference(html) {
    Some(value) => inspect(value, content=["https://q.uiver.app#q=", payload].join(""))
    None => abort("expected html reference")
  }
}

test "base64 share reference extraction supports wrapped markdown and iframe src" {
  let payload = "abc123"
  let wrapped = [
    "```latex\n",
    "  % https://q.uiver.app#q=",
    payload,
    "\n\\begin{tikzcd}\n```",
  ].join("")
  let iframe_only = [
    "<iframe class=\"quiver-embed\" src=\"https://q.uiver.app#r=svg&q=",
    payload,
    "&embed\" width=\"400\" height=\"400\"></iframe>",
  ].join("")

  match Quiver::extract_base64_share_reference(wrapped) {
    Some(value) => inspect(value, content=["https://q.uiver.app#q=", payload].join(""))
    None => abort("expected wrapped reference")
  }
  match Quiver::extract_base64_share_reference(iframe_only) {
    Some(value) => inspect(value, content=["https://q.uiver.app#r=svg&q=", payload, "&embed"].join(""))
    None => abort("expected iframe reference")
  }
}

test "base64 share reference extraction supports single-quoted and spaced iframe src" {
  let payload = "abc123"
  let single_quoted = [
    "<iframe src='https://q.uiver.app#r=svg&q=",
    payload,
    "&embed'></iframe>",
  ].join("")
  let spaced_assignment = [
    "<iframe class='quiver-embed' src = \"https://q.uiver.app#q=",
    payload,
    "&embed\" width='400'></iframe>",
  ].join("")

  match Quiver::extract_base64_share_reference(single_quoted) {
    Some(value) => inspect(value, content=["https://q.uiver.app#r=svg&q=", payload, "&embed"].join(""))
    None => abort("expected single-quoted iframe reference")
  }
  match Quiver::extract_base64_share_reference(spaced_assignment) {
    Some(value) => inspect(value, content=["https://q.uiver.app#q=", payload, "&embed"].join(""))
    None => abort("expected spaced-assignment iframe reference")
  }
}

test "base64 import share text roundtrip from exporter outputs" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))
  let edge = Edge::new(3, "f", 1, 2, EdgeOptions::at_level(1), Colour::black())
  quiver.add(CellData::from_edge(edge))
  quiver.connect(1, 2, 3)

  let tikz_options = TikzCdExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .with_renderer("svg")
    .with_macro_url("https://example.com/macros.tex")
  let tikz_output = quiver.export_tikz_cd(options=tikz_options)
  let imported_tikz = Quiver::import_base64_share_text(tikz_output)
  inspect(imported_tikz.quiver.all_cell_ids(), content="[1, 2, 3]")
  match imported_tikz.renderer {
    Some(value) => inspect(value, content="svg")
    None => abort("expected renderer")
  }
  inspect(imported_tikz.embed, content="false")

  let fletcher_options = FletcherExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .with_macro_url("https://example.com/macros.tex")
  let fletcher_output = quiver.export_fletcher(options=fletcher_options)
  let imported_fletcher = Quiver::import_base64_share_text(fletcher_output)
  inspect(imported_fletcher.quiver.all_cell_ids(), content="[1, 2, 3]")
  match imported_fletcher.macro_url {
    Some(value) => inspect(value, content="https://example.com/macros.tex")
    None => abort("expected macro_url")
  }
  inspect(imported_fletcher.embed, content="false")

  let html_options = HtmlEmbedExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .with_renderer("svg")
  let html_settings = HtmlEmbedExportSettings::default("https://q.uiver.app")
  let html_output = quiver.export_html_embed(html_settings, options=html_options)
  let imported_html = Quiver::import_base64_share_text(html_output)
  inspect(imported_html.quiver.all_cell_ids(), content="[1, 2, 3]")
  match imported_html.renderer {
    Some(value) => inspect(value, content="svg")
    None => abort("expected renderer")
  }
  inspect(imported_html.embed, content="false")
}

test "base64 import share text works from wrapped markdown and iframe-only source" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let payload = quiver.export_base64_v0()

  let wrapped = [
    "```latex\n",
    "  % https://q.uiver.app#q=",
    payload,
    "\n\\begin{tikzcd}\n```",
  ].join("")
  let imported_wrapped = Quiver::import_base64_share_text(wrapped)
  inspect(imported_wrapped.quiver.all_cell_ids(), content="[1]")
  inspect(imported_wrapped.embed, content="false")

  let iframe_only = [
    "<iframe class=\"quiver-embed\" src=\"https://q.uiver.app#r=svg&q=",
    payload,
    "&embed\" width=\"400\" height=\"400\"></iframe>",
  ].join("")
  let imported_iframe = Quiver::import_base64_share_text(iframe_only)
  inspect(imported_iframe.quiver.all_cell_ids(), content="[1]")
  match imported_iframe.renderer {
    Some(value) => inspect(value, content="svg")
    None => abort("expected renderer")
  }
  inspect(imported_iframe.embed, content="true")
}

test "base64 import share text supports single-quoted and spaced iframe src" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let payload = quiver.export_base64_v0()

  let single_quoted = [
    "<iframe src='https://q.uiver.app#r=svg&q=",
    payload,
    "&embed'></iframe>",
  ].join("")
  let imported_single = Quiver::import_base64_share_text(single_quoted)
  inspect(imported_single.quiver.all_cell_ids(), content="[1]")
  match imported_single.renderer {
    Some(value) => inspect(value, content="svg")
    None => abort("expected renderer")
  }
  inspect(imported_single.embed, content="true")

  let spaced_assignment = [
    "<iframe class='quiver-embed' src = \"https://q.uiver.app#q=",
    payload,
    "&embed\" width='400'></iframe>",
  ].join("")
  let imported_spaced = Quiver::import_base64_share_text(spaced_assignment)
  inspect(imported_spaced.quiver.all_cell_ids(), content="[1]")
  inspect(imported_spaced.embed, content="true")
}

test "panic base64 import share url without payload" {
  ignore(Quiver::import_base64_share_url("https://q.uiver.app"))
}
