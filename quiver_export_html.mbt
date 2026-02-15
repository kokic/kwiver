pub struct HtmlEmbedExportSettings {
  base_url : String
  fixed_size : Bool
  width : Int
  height : Int
  diagram_width : Int
  diagram_height : Int
  embed_padding : Int
}

pub struct HtmlEmbedExportOptions {
  share_base_url : String?
  macro_url : String?
}

pub fn HtmlEmbedExportSettings::default(base_url : String) -> HtmlEmbedExportSettings {
  {
    base_url,
    fixed_size: false,
    width: 400,
    height: 400,
    diagram_width: 400,
    diagram_height: 400,
    embed_padding: 24,
  }
}

pub fn HtmlEmbedExportOptions::default() -> HtmlEmbedExportOptions {
  { share_base_url: None, macro_url: None }
}

pub fn HtmlEmbedExportOptions::with_share_base_url(
  self : HtmlEmbedExportOptions,
  base_url : String,
) -> HtmlEmbedExportOptions {
  { share_base_url: Some(base_url), macro_url: self.macro_url }
}

pub fn HtmlEmbedExportOptions::with_macro_url(
  self : HtmlEmbedExportOptions,
  macro_url : String,
) -> HtmlEmbedExportOptions {
  { share_base_url: self.share_base_url, macro_url: Some(macro_url) }
}

pub fn HtmlEmbedExportOptions::without_macro_url(
  self : HtmlEmbedExportOptions,
) -> HtmlEmbedExportOptions {
  { share_base_url: self.share_base_url, macro_url: None }
}

pub fn HtmlEmbedExportSettings::with_fixed_size(
  self : HtmlEmbedExportSettings,
  width : Int,
  height : Int,
) -> HtmlEmbedExportSettings {
  {
    base_url: self.base_url,
    fixed_size: true,
    width: if width < 1 { 1 } else { width },
    height: if height < 1 { 1 } else { height },
    diagram_width: self.diagram_width,
    diagram_height: self.diagram_height,
    embed_padding: self.embed_padding,
  }
}

pub fn HtmlEmbedExportSettings::with_dynamic_size(
  self : HtmlEmbedExportSettings,
  diagram_width : Int,
  diagram_height : Int,
  embed_padding~ : Int = 24,
) -> HtmlEmbedExportSettings {
  {
    base_url: self.base_url,
    fixed_size: false,
    width: self.width,
    height: self.height,
    diagram_width: if diagram_width < 0 { 0 } else { diagram_width },
    diagram_height: if diagram_height < 0 { 0 } else { diagram_height },
    embed_padding: if embed_padding < 0 { 0 } else { embed_padding },
  }
}

fn html_embed_url(
  quiver : Quiver,
  settings : HtmlEmbedExportSettings,
  options : HtmlEmbedExportOptions,
) -> String {
  let share_base_url = match options.share_base_url {
    Some(url) => Some(url)
    None => Some(settings.base_url)
  }
  quiver.export_base64_share_url(share_base_url, options.macro_url)
}

pub fn Quiver::export_html_embed(
  self : Quiver,
  settings : HtmlEmbedExportSettings,
  options~ : HtmlEmbedExportOptions = HtmlEmbedExportOptions::default(),
) -> String {
  let url = html_embed_url(self, settings, options)
  let src = if self.is_empty() {
    url + "#embed"
  } else {
    url + "&embed"
  }
  let (width, height) = if settings.fixed_size {
    (settings.width, settings.height)
  } else {
    (
      settings.diagram_width + 2 * settings.embed_padding,
      settings.diagram_height + 2 * settings.embed_padding,
    )
  }
  [
    "<!-- ",
    url,
    " -->\n<iframe class=\"quiver-embed\" src=\"",
    src,
    "\" width=\"",
    width.to_string(),
    "\" height=\"",
    height.to_string(),
    "\" style=\"border-radius: 8px; border: none;\"></iframe>",
  ].join("")
}
