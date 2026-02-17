///|
test "quiver html export for empty quiver uses #embed and fixed size" {
  let quiver = Quiver::new()
  let settings = HtmlEmbedExportSettings::default("https://q.uiver.app").with_fixed_size(
    500, 320,
  )

  inspect(
    quiver.export_html_embed(settings),
    content="<!-- https://q.uiver.app -->\n<iframe class=\"quiver-embed\" src=\"https://q.uiver.app#embed\" width=\"500\" height=\"320\" style=\"border-radius: 8px; border: none;\"></iframe>",
  )
}

///|
test "quiver html export for non-empty quiver includes q payload and &embed" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let settings = HtmlEmbedExportSettings::default("https://q.uiver.app").with_fixed_size(
    400, 400,
  )
  let payload = quiver.export_base64_v0()
  let expected = [
    "<!-- https://q.uiver.app#q=", payload, " -->\n<iframe class=\"quiver-embed\" src=\"https://q.uiver.app#q=",
    payload, "&embed\" width=\"400\" height=\"400\" style=\"border-radius: 8px; border: none;\"></iframe>",
  ].join("")

  inspect(quiver.export_html_embed(settings), content=expected)
}

///|
test "quiver html export dynamic size uses padding" {
  let quiver = Quiver::new()
  let settings = HtmlEmbedExportSettings::default("https://q.uiver.app").with_dynamic_size(
    300,
    200,
    embed_padding=10,
  )

  let html = quiver.export_html_embed(settings)
  inspect(
    html,
    content="<!-- https://q.uiver.app -->\n<iframe class=\"quiver-embed\" src=\"https://q.uiver.app#embed\" width=\"320\" height=\"220\" style=\"border-radius: 8px; border: none;\"></iframe>",
  )
}

///|
test "quiver html export supports macro_url in share link for non-empty quiver" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let settings = HtmlEmbedExportSettings::default("https://q.uiver.app").with_fixed_size(
    400, 400,
  )
  let payload = quiver.export_base64_v0()
  let options = HtmlEmbedExportOptions::default().with_macro_url(
    "https://example.com/macros.tex",
  )

  let expected = [
    "<!-- https://q.uiver.app#q=", payload, "&macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex -->\n<iframe class=\"quiver-embed\" src=\"https://q.uiver.app#q=",
    payload, "&macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex&embed\" width=\"400\" height=\"400\" style=\"border-radius: 8px; border: none;\"></iframe>",
  ].join("")

  inspect(quiver.export_html_embed(settings, options~), content=expected)
}

///|
test "quiver html export supports non-default renderer in share link for non-empty quiver" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let settings = HtmlEmbedExportSettings::default("https://q.uiver.app").with_fixed_size(
    400, 400,
  )
  let payload = quiver.export_base64_v0()
  let options = HtmlEmbedExportOptions::default().with_renderer("svg")

  let expected = [
    "<!-- https://q.uiver.app#r=svg&q=", payload, " -->\n<iframe class=\"quiver-embed\" src=\"https://q.uiver.app#r=svg&q=",
    payload, "&embed\" width=\"400\" height=\"400\" style=\"border-radius: 8px; border: none;\"></iframe>",
  ].join("")

  inspect(quiver.export_html_embed(settings, options~), content=expected)
}

///|
test "quiver html export omits renderer when explicitly default" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let settings = HtmlEmbedExportSettings::default("https://q.uiver.app").with_fixed_size(
    400, 400,
  )
  let payload = quiver.export_base64_v0()
  let options = HtmlEmbedExportOptions::default().with_renderer("canvas")

  let expected = [
    "<!-- https://q.uiver.app#q=", payload, " -->\n<iframe class=\"quiver-embed\" src=\"https://q.uiver.app#q=",
    payload, "&embed\" width=\"400\" height=\"400\" style=\"border-radius: 8px; border: none;\"></iframe>",
  ].join("")

  inspect(quiver.export_html_embed(settings, options~), content=expected)
}

///|
test "quiver html export without_renderer clears previously configured renderer" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let settings = HtmlEmbedExportSettings::default("https://q.uiver.app").with_fixed_size(
    400, 400,
  )
  let payload = quiver.export_base64_v0()
  let options = HtmlEmbedExportOptions::default()
    .with_renderer("svg")
    .without_renderer()

  let expected = [
    "<!-- https://q.uiver.app#q=", payload, " -->\n<iframe class=\"quiver-embed\" src=\"https://q.uiver.app#q=",
    payload, "&embed\" width=\"400\" height=\"400\" style=\"border-radius: 8px; border: none;\"></iframe>",
  ].join("")

  inspect(quiver.export_html_embed(settings, options~), content=expected)
}

///|
test "quiver html export omits macro_url for empty quiver and allows base override" {
  let quiver = Quiver::new()
  let settings = HtmlEmbedExportSettings::default("https://q.uiver.app").with_fixed_size(
    500, 320,
  )
  let options = HtmlEmbedExportOptions::default()
    .with_share_base_url("https://alt.uiver.app")
    .with_macro_url("https://example.com/macros.tex")

  inspect(
    quiver.export_html_embed(settings, options~),
    content="<!-- https://alt.uiver.app -->\n<iframe class=\"quiver-embed\" src=\"https://alt.uiver.app#embed\" width=\"500\" height=\"320\" style=\"border-radius: 8px; border: none;\"></iframe>",
  )
}

///|
test "quiver html export without_share_base_url restores settings base url" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let settings = HtmlEmbedExportSettings::default("https://q.uiver.app").with_fixed_size(
    400, 400,
  )
  let payload = quiver.export_base64_v0()
  let options = HtmlEmbedExportOptions::default()
    .with_share_base_url("https://alt.uiver.app")
    .without_share_base_url()

  let expected = [
    "<!-- https://q.uiver.app#q=", payload, " -->\n<iframe class=\"quiver-embed\" src=\"https://q.uiver.app#q=",
    payload, "&embed\" width=\"400\" height=\"400\" style=\"border-radius: 8px; border: none;\"></iframe>",
  ].join("")

  inspect(quiver.export_html_embed(settings, options~), content=expected)
}

///|
test "quiver html import wrapper roundtrips from embed output and preserves metadata" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  quiver.add(CellData::from_vertex(Vertex::new_black(2, "B", 1, 0)))
  quiver.add(
    CellData::from_edge(
      Edge::new(3, "f", 1, 2, EdgeOptions::at_level(1), Colour::black()),
    ),
  )
  quiver.connect(1, 2, 3)

  let settings = HtmlEmbedExportSettings::default("https://q.uiver.app")
  let options = HtmlEmbedExportOptions::default()
    .with_share_base_url("https://q.uiver.app")
    .with_renderer("svg")
    .with_macro_url("https://example.com/macros.tex")
  let out = quiver.export_html_embed(settings, options~)

  let imported = Quiver::import_html_embed_result(out)
  inspect(imported.quiver.all_cell_ids(), content="[1, 2, 3]")
  match imported.renderer {
    Some(value) => inspect(value, content="svg")
    None => abort("expected renderer")
  }
  match imported.macro_url {
    Some(value) => inspect(value, content="https://example.com/macros.tex")
    None => abort("expected macro_url")
  }
  inspect(imported.embed, content="true")

  let imported_quiver = Quiver::import_html_embed(out)
  inspect(imported_quiver.all_cell_ids(), content="[1, 2, 3]")
}

///|
test "quiver html import wrapper falls back to comment when iframe src is absent" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let payload = quiver.export_base64_v0()
  let comment_only = ["<!-- https://q.uiver.app#q=", payload, " -->"].join("")

  let imported = Quiver::import_html_embed_result(comment_only)
  inspect(imported.quiver.all_cell_ids(), content="[1]")
  inspect(imported.embed, content="false")
}

///|
test "quiver html import wrapper supports single-quoted iframe src" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let payload = quiver.export_base64_v0()
  let iframe = [
    "<iframe src='https://q.uiver.app#r=svg&q=", payload, "&embed'></iframe>",
  ].join("")

  let imported = Quiver::import_html_embed_result(iframe)
  inspect(imported.quiver.all_cell_ids(), content="[1]")
  match imported.renderer {
    Some(value) => inspect(value, content="svg")
    None => abort("expected renderer")
  }
  inspect(imported.embed, content="true")
}

///|
test "quiver html import wrapper supports spaced src assignment" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let payload = quiver.export_base64_v0()
  let iframe = [
    "<iframe class='quiver-embed' src = \"https://q.uiver.app#q=", payload, "&embed\" width='400'></iframe>",
  ].join("")

  let imported = Quiver::import_html_embed_result(iframe)
  inspect(imported.quiver.all_cell_ids(), content="[1]")
  inspect(imported.embed, content="true")
}
