test "quiver html export for empty quiver uses #embed and fixed size" {
  let quiver = Quiver::new()
  let settings = HtmlEmbedExportSettings::default("https://q.uiver.app")
    .with_fixed_size(500, 320)

  inspect(
    quiver.export_html_embed(settings),
    content=
      "<!-- https://q.uiver.app -->\n<iframe class=\"quiver-embed\" src=\"https://q.uiver.app#embed\" width=\"500\" height=\"320\" style=\"border-radius: 8px; border: none;\"></iframe>",
  )
}

test "quiver html export for non-empty quiver includes q payload and &embed" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let settings = HtmlEmbedExportSettings::default("https://q.uiver.app")
    .with_fixed_size(400, 400)
  let payload = quiver.export_base64_v0()
  let expected = [
    "<!-- https://q.uiver.app#q=",
    payload,
    " -->\n<iframe class=\"quiver-embed\" src=\"https://q.uiver.app#q=",
    payload,
    "&embed\" width=\"400\" height=\"400\" style=\"border-radius: 8px; border: none;\"></iframe>",
  ].join("")

  inspect(
    quiver.export_html_embed(settings),
    content=expected,
  )
}

test "quiver html export dynamic size uses padding" {
  let quiver = Quiver::new()
  let settings = HtmlEmbedExportSettings::default("https://q.uiver.app")
    .with_dynamic_size(300, 200, embed_padding=10)

  let html = quiver.export_html_embed(settings)
  inspect(html, content=
    "<!-- https://q.uiver.app -->\n<iframe class=\"quiver-embed\" src=\"https://q.uiver.app#embed\" width=\"320\" height=\"220\" style=\"border-radius: 8px; border: none;\"></iframe>",
  )
}

test "quiver html export supports macro_url in share link for non-empty quiver" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let settings = HtmlEmbedExportSettings::default("https://q.uiver.app")
    .with_fixed_size(400, 400)
  let payload = quiver.export_base64_v0()
  let options = HtmlEmbedExportOptions::default()
    .with_macro_url("https://example.com/macros.tex")

  let expected = [
    "<!-- https://q.uiver.app#q=",
    payload,
    "&macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex -->\n<iframe class=\"quiver-embed\" src=\"https://q.uiver.app#q=",
    payload,
    "&macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex&embed\" width=\"400\" height=\"400\" style=\"border-radius: 8px; border: none;\"></iframe>",
  ].join("")

  inspect(
    quiver.export_html_embed(settings, options=options),
    content=expected,
  )
}

test "quiver html export supports non-default renderer in share link for non-empty quiver" {
  let quiver = Quiver::new()
  quiver.add(CellData::from_vertex(Vertex::new_black(1, "A", 0, 0)))
  let settings = HtmlEmbedExportSettings::default("https://q.uiver.app")
    .with_fixed_size(400, 400)
  let payload = quiver.export_base64_v0()
  let options = HtmlEmbedExportOptions::default().with_renderer("svg")

  let expected = [
    "<!-- https://q.uiver.app#r=svg&q=",
    payload,
    " -->\n<iframe class=\"quiver-embed\" src=\"https://q.uiver.app#r=svg&q=",
    payload,
    "&embed\" width=\"400\" height=\"400\" style=\"border-radius: 8px; border: none;\"></iframe>",
  ].join("")

  inspect(
    quiver.export_html_embed(settings, options=options),
    content=expected,
  )
}

test "quiver html export omits macro_url for empty quiver and allows base override" {
  let quiver = Quiver::new()
  let settings = HtmlEmbedExportSettings::default("https://q.uiver.app")
    .with_fixed_size(500, 320)
  let options = HtmlEmbedExportOptions::default()
    .with_share_base_url("https://alt.uiver.app")
    .with_macro_url("https://example.com/macros.tex")

  inspect(
    quiver.export_html_embed(settings, options=options),
    content=
      "<!-- https://alt.uiver.app -->\n<iframe class=\"quiver-embed\" src=\"https://alt.uiver.app#embed\" width=\"500\" height=\"320\" style=\"border-radius: 8px; border: none;\"></iframe>",
  )
}
