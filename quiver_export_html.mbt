///|
pub struct HtmlEmbedExportSettings {
  base_url : String
  fixed_size : Bool
  width : Int
  height : Int
  diagram_width : Int
  diagram_height : Int
  embed_padding : Int
}

///|
pub struct HtmlEmbedExportOptions {
  share_base_url : String?
  macro_url : String?
  renderer : String?
}

///|
pub fn HtmlEmbedExportSettings::default(
  base_url : String,
) -> HtmlEmbedExportSettings {
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

///|
pub fn HtmlEmbedExportOptions::default() -> HtmlEmbedExportOptions {
  { share_base_url: None, macro_url: None, renderer: None }
}

///|
pub fn HtmlEmbedExportOptions::with_share_base_url(
  self : HtmlEmbedExportOptions,
  base_url : String,
) -> HtmlEmbedExportOptions {
  {
    share_base_url: Some(base_url),
    macro_url: self.macro_url,
    renderer: self.renderer,
  }
}

///|
pub fn HtmlEmbedExportOptions::without_share_base_url(
  self : HtmlEmbedExportOptions,
) -> HtmlEmbedExportOptions {
  { share_base_url: None, macro_url: self.macro_url, renderer: self.renderer }
}

///|
pub fn HtmlEmbedExportOptions::with_macro_url(
  self : HtmlEmbedExportOptions,
  macro_url : String,
) -> HtmlEmbedExportOptions {
  {
    share_base_url: self.share_base_url,
    macro_url: Some(macro_url),
    renderer: self.renderer,
  }
}

///|
pub fn HtmlEmbedExportOptions::without_macro_url(
  self : HtmlEmbedExportOptions,
) -> HtmlEmbedExportOptions {
  {
    share_base_url: self.share_base_url,
    macro_url: None,
    renderer: self.renderer,
  }
}

///|
pub fn HtmlEmbedExportOptions::with_renderer(
  self : HtmlEmbedExportOptions,
  renderer : String,
) -> HtmlEmbedExportOptions {
  {
    share_base_url: self.share_base_url,
    macro_url: self.macro_url,
    renderer: Some(renderer),
  }
}

///|
pub fn HtmlEmbedExportOptions::without_renderer(
  self : HtmlEmbedExportOptions,
) -> HtmlEmbedExportOptions {
  {
    share_base_url: self.share_base_url,
    macro_url: self.macro_url,
    renderer: None,
  }
}

///|
pub fn HtmlEmbedExportSettings::with_fixed_size(
  self : HtmlEmbedExportSettings,
  width : Int,
  height : Int,
) -> HtmlEmbedExportSettings {
  {
    base_url: self.base_url,
    fixed_size: true,
    width: if width < 1 {
      1
    } else {
      width
    },
    height: if height < 1 {
      1
    } else {
      height
    },
    diagram_width: self.diagram_width,
    diagram_height: self.diagram_height,
    embed_padding: self.embed_padding,
  }
}

///|
pub fn HtmlEmbedExportSettings::with_dynamic_size(
  self : HtmlEmbedExportSettings,
  diagram_width : Int,
  diagram_height : Int,
  embed_padding? : Int = 24,
) -> HtmlEmbedExportSettings {
  {
    base_url: self.base_url,
    fixed_size: false,
    width: self.width,
    height: self.height,
    diagram_width: if diagram_width < 0 {
      0
    } else {
      diagram_width
    },
    diagram_height: if diagram_height < 0 {
      0
    } else {
      diagram_height
    },
    embed_padding: if embed_padding < 0 {
      0
    } else {
      embed_padding
    },
  }
}

///|
fn html_embed_url(
  quiver : Quiver,
  settings : HtmlEmbedExportSettings,
  options : HtmlEmbedExportOptions,
) -> String {
  let share_base_url = match options.share_base_url {
    Some(url) => Some(url)
    None => Some(settings.base_url)
  }
  quiver.export_base64_share_url(
    share_base_url,
    options.macro_url,
    renderer?=options.renderer,
  )
}

///|
fn html_embed_extract_src(input : String) -> String? {
  let single_quote = Int::to_byte(39)
  let is_space = (byte : Byte) => byte == b' ' || byte == b'\t'

  for raw_line_view in input.split("\n") {
    let line = raw_line_view.to_string()
    let bytes = @utf8.encode(line)
    let mut i = 0
    while i + 2 < bytes.length() {
      if bytes.unsafe_get(i) == b's' &&
        bytes.unsafe_get(i + 1) == b'r' &&
        bytes.unsafe_get(i + 2) == b'c' {
        let mut j = i + 3
        while j < bytes.length() && is_space(bytes.unsafe_get(j)) {
          j = j + 1
        }
        if j >= bytes.length() || bytes.unsafe_get(j) != b'=' {
          i = i + 1
          continue
        }
        j = j + 1
        while j < bytes.length() && is_space(bytes.unsafe_get(j)) {
          j = j + 1
        }
        if j >= bytes.length() {
          i = i + 1
          continue
        }
        let quote = bytes.unsafe_get(j)
        if quote != b'"' && quote != single_quote {
          i = i + 1
          continue
        }
        j = j + 1
        let value_start = j
        while j < bytes.length() && bytes.unsafe_get(j) != quote {
          j = j + 1
        }
        if j < bytes.length() {
          return Some(line.unsafe_substring(start=value_start, end=j))
        }
      }
      i = i + 1
    }
  }
  None
}

///|
pub fn Quiver::export_html_embed(
  self : Quiver,
  settings : HtmlEmbedExportSettings,
  options? : HtmlEmbedExportOptions = HtmlEmbedExportOptions::default(),
) -> String {
  let url = html_embed_url(self, settings, options)
  let src = if self.is_empty() { url + "#embed" } else { url + "&embed" }
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

///|
pub fn Quiver::import_html_embed_result(
  input : String,
  default_renderer? : String = "canvas",
) -> Base64ShareImportResult raise {
  let reference = match html_embed_extract_src(input) {
    Some(url) => url
    None =>
      match Quiver::extract_base64_share_reference(input) {
        Some(value) => value
        None => input
      }
  }
  Quiver::import_base64_share_url_result(reference, default_renderer~)
}

///|
pub fn Quiver::import_html_embed(
  input : String,
  default_renderer? : String = "canvas",
) -> Quiver raise {
  Quiver::import_html_embed_result(input, default_renderer~).quiver
}
