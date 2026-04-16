///|
// tikz-cd parser and import logic split from quiver_export_tikz.mbt.

///|
fn tikz_trim_left(input : String) -> String {
  let mut start = 0
  while start < input.length() {
    let ch = input.unsafe_get(start)
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
      start = start + 1
      continue
    }
    break
  }
  if start == 0 {
    input
  } else {
    input.unsafe_substring(start~, end=input.length())
  }
}

///|
fn tikz_trim_left_length(input : String) -> Int {
  let mut start = 0
  while start < input.length() {
    if tikz_is_whitespace(input.unsafe_get(start)) {
      start = start + 1
      continue
    }
    break
  }
  start
}

///|
fn tikz_is_whitespace(ch : UInt16) -> Bool {
  ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r'
}

///|
fn tikz_first_non_whitespace_offset(input : String) -> Int {
  let mut i = 0
  while i < input.length() {
    if !tikz_is_whitespace(input.unsafe_get(i)) {
      return i
    }
    i = i + 1
  }
  0
}

///|
fn tikz_line_column_from_index(input : String, index : Int) -> (Int, Int) {
  let limit = if index < 0 {
    0
  } else if index > input.length() {
    input.length()
  } else {
    index
  }
  let mut line = 1
  let mut column = 1
  let mut i = 0
  while i < limit {
    if input.unsafe_get(i) == '\n' {
      line = line + 1
      column = 1
    } else {
      column = column + 1
    }
    i = i + 1
  }
  (line, column)
}

///|
fn tikz_error_with_position_if_missing(
  error : TikzCdImportError,
  line : Int,
  column : Int,
) -> TikzCdImportError {
  if error.line > 0 || error.column > 0 {
    return error
  }
  {
    kind: error.kind,
    message: error.message,
    line,
    column,
  }
}

///|
fn tikz_is_ascii_letter(ch : UInt16) -> Bool {
  (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
}

///|
fn tikz_consume_row_separator_suffix(body : String, after_separator : Int) -> Int {
  let mut i = after_separator
  while i < body.length() && tikz_is_whitespace(body.unsafe_get(i)) {
    i = i + 1
  }
  if i < body.length() && body.unsafe_get(i) == '*' {
    // Support starred row breaks (e.g. "\\*" and "\\* [0.6em]").
    i = i + 1
    while i < body.length() && tikz_is_whitespace(body.unsafe_get(i)) {
      i = i + 1
    }
  }
  if i < body.length() && body.unsafe_get(i) == '[' {
    let mut depth = 1
    i = i + 1
    while i < body.length() && depth > 0 {
      let ch = body.unsafe_get(i)
      if ch == '[' {
        depth = depth + 1
      } else if ch == ']' {
        depth = depth - 1
      }
      i = i + 1
    }
  }
  i
}

///|
fn tikz_take_cr_row_separator(body : String, index : Int) -> Int? {
  if index + 2 >= body.length() {
    return None
  }
  if body.unsafe_get(index + 1) != 'c' || body.unsafe_get(index + 2) != 'r' {
    return None
  }

  let mut after = index + 3
  if after + 1 < body.length() &&
    body.unsafe_get(after) == 'c' &&
    body.unsafe_get(after + 1) == 'r' {
    // Support TeX-style "\crcr" row separators.
    after = after + 2
  }

  if after < body.length() && tikz_is_ascii_letter(body.unsafe_get(after)) {
    // Keep control words like "\crossing" intact.
    return None
  }

  Some(after)
}

///|
fn tikz_take_tabularnewline_row_separator(body : String, index : Int) -> Int? {
  let token = "tabularnewline"
  let start = index + 1
  let end = start + token.length()
  if end > body.length() {
    return None
  }
  if body.unsafe_substring(start~, end=end) != token {
    return None
  }
  if end < body.length() && tikz_is_ascii_letter(body.unsafe_get(end)) {
    // Keep control words like "\tabularnewlinex" intact.
    return None
  }
  Some(end)
}

///|
priv struct TikzEnvironmentBody {
  body : String
  body_offset : Int
  ampersand_replacement : String?
}

///|
priv struct TikzArrowMatch {
  start : Int
  options_start : Int
  open_delimiter : UInt16
  close_delimiter : UInt16
}

///|
priv struct TikzParsedArrow {
  direction : String?
  reverse : Bool
  is_loop : Bool
  is_phantom : Bool
  name : String?
  source_center_anchor : Bool
  target_center_anchor : Bool
  label : String
  from_x : Int?
  from_y : Int?
  from_ref : String?
  to_x : Int?
  to_y : Int?
  to_ref : String?
  options : EdgeOptions
  label_colour : Colour
}

///|
priv struct TikzParsedVertexLabel {
  label : String
  label_colour : Colour
}

///|
priv struct TikzPendingArrow {
  default_source_x : Int
  default_source_y : Int
  reverse : Bool
  is_loop : Bool
  source_x : Int?
  source_y : Int?
  source_ref : String?
  source_center_anchor : Bool
  target_x : Int?
  target_y : Int?
  target_ref : String?
  target_center_anchor : Bool
  is_phantom : Bool
  name : String?
  label : String
  line : Int
  column : Int
  options : EdgeOptions
  label_colour : Colour
}

///|
priv struct TikzTextSegment {
  text : String
  start : Int
}

///|
priv struct TikzNamedCellRef {
  id : Int
  center_anchor : Bool
}

///|
priv struct TikzResolvedEndpoint {
  id : Int
  center_anchor : Bool
}

///|
priv struct TikzParsedLabelOptions {
  swap : Bool
  description : Bool
  marking : Bool
  pos : Int?
  colour : Colour?
}

///|
priv struct TikzParsedDecorationOption {
  style_name : String
  colour : Colour?
  rotate : Int?
}

///|
priv struct TikzParsedArrowBodyDecorationOption {
  style_body : String
  colour : Colour?
}

///|
priv struct TikzParsedLoopOptions {
  is_loop : Bool
  clockwise_hint : Int?
  in_angle : Double?
  out_angle : Double?
  distance_mm : Double?
}

///|
fn tikz_parse_ampersand_replacement(options : String) -> String? {
  for option in tikz_split_arrow_options(options) {
    match tikz_option_key_value(option) {
      Some((key, value)) => {
        let key_token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(key))
          .replace_all(old=" ", new="")
          .replace_all(old="\t", new="")
        if key_token == "ampersandreplacement" {
          let token = tikz_unwrap_braced_text(value).trim().to_string()
          if token != "" {
            return Some(token)
          }
        }
      }
      None => ()
    }
  }
  None
}

///|
fn tikz_find_token_outside_comments(input : String, token : String) -> Int? {
  if token == "" {
    return None
  }

  let mut in_comment = false
  let mut i = 0
  while i < input.length() {
    let ch = input.unsafe_get(i)
    if in_comment {
      if ch == '\n' {
        in_comment = false
      }
      i = i + 1
      continue
    }

    if ch == '%' && !tikz_is_escaped_at(input, i) {
      in_comment = true
      i = i + 1
      continue
    }

    if i + token.length() <= input.length() &&
      input.unsafe_substring(start=i, end=i + token.length()) == token {
      return Some(i)
    }

    i = i + 1
  }
  None
}

///|
fn tikz_find_environment_tokens(input : String) -> (Int, String, String)? {
  let begin_token = "\\begin{tikzcd}"
  let end_token = "\\end{tikzcd}"
  let begin_star_token = "\\begin{tikzcd*}"
  let end_star_token = "\\end{tikzcd*}"

  let begin_index = tikz_find_token_outside_comments(input, begin_token)
  let begin_star_index = tikz_find_token_outside_comments(input, begin_star_token)
  match begin_index {
    Some(index) =>
      match begin_star_index {
        Some(star_index) =>
          if star_index < index {
            Some((star_index, begin_star_token, end_star_token))
          } else {
            Some((index, begin_token, end_token))
          }
        None => Some((index, begin_token, end_token))
      }
    None =>
      match begin_star_index {
        Some(star_index) => Some((star_index, begin_star_token, end_star_token))
        None => None
      }
  }
}

///|
fn tikz_looks_like_environment(input : String) -> Bool {
  match tikz_find_environment_tokens(input) {
    Some(_) => true
    None => false
  }
}

///|
fn tikz_extract_environment_body(input : String) -> TikzEnvironmentBody? {
  match tikz_find_environment_tokens(input) {
    Some((begin_index, begin_token, end_token)) => {
      let after_begin_start = begin_index + begin_token.length()
      let after_begin = input.unsafe_substring(
        start=after_begin_start,
        end=input.length(),
      )
      let after_begin_trimmed = tikz_trim_left_length(after_begin)
      let mut rest_start = after_begin_start + after_begin_trimmed
      let mut rest = if after_begin_trimmed == 0 {
        after_begin
      } else {
        after_begin.unsafe_substring(start=after_begin_trimmed, end=after_begin.length())
      }
      let mut ampersand_replacement : String? = None
      if rest.has_prefix("[") {
        let options_body = rest.unsafe_substring(start=1, end=rest.length())
        match tikz_find_closing_delimiter(options_body, '[', ']') {
          Some(close_index) => {
            let options = options_body.unsafe_substring(start=0, end=close_index)
            ampersand_replacement = tikz_parse_ampersand_replacement(options)
            rest = options_body.unsafe_substring(
              start=close_index + 1,
              end=options_body.length(),
            )
            rest_start = rest_start + close_index + 2
          }
          None => ()
        }
      }
      match tikz_find_token_outside_comments(rest, end_token) {
        Some(end_index) =>
          Some({
            body: rest.unsafe_substring(start=0, end=end_index),
            body_offset: rest_start,
            ampersand_replacement,
          })
        None => None
      }
    }
    None => None
  }
}

///|
fn tikz_split_rows_with_offsets(body : String) -> Array[TikzTextSegment] {
  let rows : Array[TikzTextSegment] = []
  let mut segment_start = 0
  let mut i = 0
  let mut brace_depth = 0
  let mut bracket_depth = 0
  let mut paren_depth = 0
  let mut in_quote = false
  while i < body.length() {
    let ch = body.unsafe_get(i)
    let escaped = tikz_is_escaped_at(body, i)
    if ch == '"' && !escaped {
      in_quote = !in_quote
      i = i + 1
      continue
    }

    if !in_quote && !escaped {
      if ch == '{' {
        brace_depth = brace_depth + 1
      } else if ch == '}' {
        if brace_depth > 0 {
          brace_depth = brace_depth - 1
        }
      } else if ch == '[' {
        bracket_depth = bracket_depth + 1
      } else if ch == ']' {
        if bracket_depth > 0 {
          bracket_depth = bracket_depth - 1
        }
      } else if ch == '(' {
        paren_depth = paren_depth + 1
      } else if ch == ')' {
        if paren_depth > 0 {
          paren_depth = paren_depth - 1
        }
      }
    }

    let at_top_level = !in_quote &&
      brace_depth == 0 &&
      bracket_depth == 0 &&
      paren_depth == 0
    if at_top_level && ch == '\\' {
      if i + 1 < body.length() && body.unsafe_get(i + 1) == '\\' {
        rows.push({
          text: body.unsafe_substring(start=segment_start, end=i),
          start: segment_start,
        })
        i = tikz_consume_row_separator_suffix(body, i + 2)
        segment_start = i
        continue
      }

      match tikz_take_cr_row_separator(body, i) {
        Some(after_cr) => {
          rows.push({
            text: body.unsafe_substring(start=segment_start, end=i),
            start: segment_start,
          })
          i = tikz_consume_row_separator_suffix(body, after_cr)
          segment_start = i
          continue
        }
        None => ()
      }

      match tikz_take_tabularnewline_row_separator(body, i) {
        Some(after_tabularnewline) => {
          rows.push({
            text: body.unsafe_substring(start=segment_start, end=i),
            start: segment_start,
          })
          i = tikz_consume_row_separator_suffix(body, after_tabularnewline)
          segment_start = i
          continue
        }
        None => ()
      }
    }
    i = i + 1
  }
  rows.push({
    text: body.unsafe_substring(start=segment_start, end=body.length()),
    start: segment_start,
  })
  rows
}

fn tikz_find_unescaped_percent(line : String) -> Int? {
  let mut i = 0
  while i < line.length() {
    if line.unsafe_get(i) == '%' {
      let mut slash_count = 0
      let mut j = i
      while j > 0 && line.unsafe_get(j - 1) == '\\' {
        slash_count = slash_count + 1
        j = j - 1
      }
      if slash_count % 2 == 0 {
        return Some(i)
      }
    }
    i = i + 1
  }
  None
}

///|
fn tikz_strip_line_comments(body : String) -> String {
  let rows : Array[String] = []
  for line_view in body.split("\n") {
    let line = line_view.to_string()
    match tikz_find_unescaped_percent(line) {
      Some(index) => rows.push(line.unsafe_substring(start=0, end=index))
      None => rows.push(line)
    }
  }
  rows.join("\n")
}

fn tikz_split_cells_with_offsets(
  row : String,
  ampersand_replacement : String?,
) -> Array[TikzTextSegment] {
  let cells : Array[TikzTextSegment] = []
  let mut segment_start = 0
  let mut i = 0
  let mut brace_depth = 0
  let mut bracket_depth = 0
  let mut paren_depth = 0
  let mut in_quotes = false
  while i < row.length() {
    if !in_quotes &&
      brace_depth == 0 &&
      bracket_depth == 0 &&
      paren_depth == 0 {
      match ampersand_replacement {
        Some(token) =>
          if token != "" &&
            i + token.length() <= row.length() &&
            row.unsafe_substring(start=i, end=i + token.length()) == token {
            cells.push({
              text: row.unsafe_substring(start=segment_start, end=i),
              start: segment_start,
            })
            i = i + token.length()
            segment_start = i
            continue
          }
        None => ()
      }
    }

    let ch = row.unsafe_get(i)
    if ch == '\\' {
      if i + 1 < row.length() {
        // Skip escaped next char so it cannot act as a delimiter.
        i = i + 2
        continue
      }
      i = i + 1
      continue
    }

    if ch == '"' {
      in_quotes = !in_quotes
      i = i + 1
      continue
    }

    if !in_quotes {
      if ch == '{' {
        brace_depth = brace_depth + 1
      } else if ch == '}' && brace_depth > 0 {
        brace_depth = brace_depth - 1
      } else if ch == '[' {
        bracket_depth = bracket_depth + 1
      } else if ch == ']' && bracket_depth > 0 {
        bracket_depth = bracket_depth - 1
      } else if ch == '(' {
        paren_depth = paren_depth + 1
      } else if ch == ')' && paren_depth > 0 {
        paren_depth = paren_depth - 1
      } else if ampersand_replacement is None &&
        ch == '&' &&
        brace_depth == 0 &&
        bracket_depth == 0 &&
        paren_depth == 0 {
        cells.push({
          text: row.unsafe_substring(start=segment_start, end=i),
          start: segment_start,
        })
        i = i + 1
        segment_start = i
        continue
      }
    }

    i = i + 1
  }
  cells.push({
    text: row.unsafe_substring(start=segment_start, end=row.length()),
    start: segment_start,
  })
  cells
}

///|
fn tikz_unwrap_braced_text(input : String) -> String {
  let trimmed = input.trim().to_string()
  if trimmed.length() >= 2 && trimmed.has_prefix("{") && trimmed.has_suffix("}") {
    trimmed
    .unsafe_substring(start=1, end=trimmed.length() - 1)
    .trim()
    .to_string()
  } else {
    trimmed
  }
}

///|
fn tikz_strip_math_wrapper(input : String) -> String {
  let trimmed = input.trim().to_string()
  if trimmed.length() >= 2 && trimmed.has_prefix("$") && trimmed.has_suffix("$") {
    trimmed
    .unsafe_substring(start=1, end=trimmed.length() - 1)
    .trim()
    .to_string()
  } else {
    trimmed
  }
}

///|
fn tikz_parse_positive_int(input : String) -> Int? {
  let value = input.trim().to_string()
  if value == "" {
    return None
  }

  let bytes = @utf8.encode(value)
  let mut out = 0
  for byte in bytes {
    let code = byte.to_int()
    if code < 48 || code > 57 {
      return None
    }
    out = out * 10 + (code - 48)
  }
  Some(out)
}

///|
fn tikz_parse_grid_reference(value : String) -> (Int, Int)? {
  let raw = tikz_unwrap_braced_text(value)
  let compact = raw.replace_all(old=" ", new="").replace_all(old="\t", new="")
  match compact.find("-") {
    Some(split_at) => {
      let row_text = compact.unsafe_substring(start=0, end=split_at)
      let col_text = compact.unsafe_substring(
        start=split_at + 1,
        end=compact.length(),
      )
      if row_text == "" || col_text == "" || col_text.contains("-") {
        return None
      }
      match
        (tikz_parse_positive_int(row_text), tikz_parse_positive_int(col_text)) {
        (Some(row), Some(col)) =>
          if row >= 1 && col >= 1 {
            Some((col - 1, row - 1))
          } else {
            None
          }
        _ => None
      }
    }
    None => None
  }
}

///|
fn tikz_parse_reference_name(value : String) -> String? {
  let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  if token == "" {
    None
  } else {
    Some(token)
  }
}

///|
fn tikz_is_direction_token(token : String) -> Bool {
  if token == "" {
    return false
  }
  for ch in token {
    if ch != 'r' && ch != 'l' && ch != 'u' && ch != 'd' {
      return false
    }
  }
  true
}

///|
fn tikz_is_escaped_at(value : String, index : Int) -> Bool {
  let mut slash_count = 0
  let mut i = index
  while i > 0 && value.unsafe_get(i - 1) == '\\' {
    slash_count = slash_count + 1
    i = i - 1
  }
  slash_count % 2 == 1
}

///|
fn tikz_find_unescaped_quote(value : String, start : Int) -> Int? {
  let mut i = start
  while i < value.length() {
    if value.unsafe_get(i) == '"' && !tikz_is_escaped_at(value, i) {
      return Some(i)
    }
    i = i + 1
  }
  None
}

///|
fn tikz_extract_first_quoted(value : String) -> String? {
  match tikz_find_unescaped_quote(value, 0) {
    Some(start) => {
      let content_start = start + 1
      match tikz_find_unescaped_quote(value, content_start) {
        Some(end) =>
          Some(
            value
            .unsafe_substring(start=content_start, end=end)
            .replace_all(old="\\\"", new="\""),
          )
        None => None
      }
    }
    None => None
  }
}

///|
fn tikz_option_key_value(option : String) -> (String, String)? {
  match option.find("=") {
    Some(index) =>
      Some(
        (
          option.unsafe_substring(start=0, end=index).trim().to_string(),
          option
          .unsafe_substring(start=index + 1, end=option.length())
          .trim()
          .to_string(),
        ),
      )
    None => None
  }
}

///|
fn tikz_is_label_modifier(option : String) -> Bool {
  match option {
    "'" => true
    "swap" => true
    "description" => true
    "marking" => true
    "allow upside down" => true
    "at start" => true
    "at end" => true
    "near start" => true
    "near end" => true
    "very near start" => true
    "very near end" => true
    "midway" => true
    _ => false
  }
}

///|
fn tikz_is_arrow_flag_token(option : String) -> Bool {
  match option {
    "->" => true
    "<-" => true
    "<->" => true
    "|->" => true
    "<-|" => true
    "->>" => true
    "<<-" => true
    ">->" => true
    "<-<" => true
    "Rightarrow" => true
    "Leftarrow" => true
    "Leftrightarrow" => true
    "mapsto" => true
    "mapsfrom" => true
    "Mapsto" => true
    "Mapsfrom" => true
    "hookrightarrow" => true
    "hookleftarrow" => true
    "rightarrowtail" => true
    "leftarrowtail" => true
    "rightarrow" => true
    "leftarrow" => true
    "leftrightarrow" => true
    "twoheadrightarrow" => true
    "twoheadleftarrow" => true
    "rightharpoonup" => true
    "rightharpoondown" => true
    "leftharpoonup" => true
    "leftharpoondown" => true
    "dashrightarrow" => true
    "dashleftarrow" => true
    "rightsquigarrow" => true
    "leftsquigarrow" => true
    "leftrightsquigarrow" => true
    "dash" => true
    "equal" => true
    "double line" => true
    "dashed" => true
    "dotted" => true
    "squiggly" => true
    "no body" => true
    "no head" => true
    "no tail" => true
    "maps to" => true
    "tail" => true
    "2tail" => true
    "tail reversed" => true
    "2tail reversed" => true
    "hook" => true
    "hook'" => true
    "harpoon" => true
    "harpoon'" => true
    "shift right" => true
    "shift left" => true
    "bend left" => true
    "bend right" => true
    "to head" => true
    "two heads" => true
    "equals" => true
    "loop" => true
    "loop left" => true
    "loop right" => true
    "phantom" => true
    _ => false
  }
}

///|
fn tikz_arrow_flag_reverse(option : String) -> Bool? {
  let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(option))
  match token {
    "->" => Some(false)
    "<-" => Some(true)
    "|->" => Some(false)
    "<-|" => Some(true)
    "->>" => Some(false)
    "<<-" => Some(true)
    ">->" => Some(false)
    "<-<" => Some(true)
    "Rightarrow" => Some(false)
    "Leftarrow" => Some(true)
    "mapsto" => Some(false)
    "mapsfrom" => Some(true)
    "Mapsto" => Some(false)
    "Mapsfrom" => Some(true)
    "hookrightarrow" => Some(false)
    "hookleftarrow" => Some(true)
    "rightarrowtail" => Some(false)
    "leftarrowtail" => Some(true)
    "rightarrow" => Some(false)
    "leftarrow" => Some(true)
    "twoheadrightarrow" => Some(false)
    "twoheadleftarrow" => Some(true)
    "rightharpoonup" => Some(false)
    "rightharpoondown" => Some(false)
    "leftharpoonup" => Some(true)
    "leftharpoondown" => Some(true)
    "dashrightarrow" => Some(false)
    "dashleftarrow" => Some(true)
    "rightsquigarrow" => Some(false)
    "leftsquigarrow" => Some(true)
    _ => None
  }
}

///|
fn tikz_apply_empty_arrow_style(options : EdgeOptions) -> EdgeOptions {
  options
  .with_style_tail("none")
  .with_style_body("none")
  .with_style_head("none")
}

///|
fn tikz_parse_level_option_value(value : String) -> Int? {
  let text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
  tikz_parse_positive_int(text)
}

///|
fn tikz_parse_signed_double(value : String) -> Double? {
  let text = value.trim().to_string()
  if text == "" {
    return None
  }

  let mut index = 0
  let mut sign = 1.0
  if text.unsafe_get(0) == '-' {
    sign = -1.0
    index = 1
  } else if text.unsafe_get(0) == '+' {
    index = 1
  }
  if index >= text.length() {
    return None
  }

  let mut seen_digit = false
  let mut seen_dot = false
  let mut int_part = 0
  let mut frac_part = 0
  let mut frac_scale = 1
  while index < text.length() {
    let ch = text.unsafe_get(index)
    if ch == '.' {
      if seen_dot {
        return None
      }
      seen_dot = true
      index = index + 1
      continue
    }

    if ch < '0' || ch > '9' {
      return None
    }
    seen_digit = true
    let digit = (ch - '0').to_int()
    if !seen_dot {
      int_part = int_part * 10 + digit
    } else {
      frac_part = frac_part * 10 + digit
      frac_scale = frac_scale * 10
    }
    index = index + 1
  }

  if !seen_digit {
    return None
  }

  Some(
    sign * (int_part.to_double() + frac_part.to_double() / frac_scale.to_double()),
  )
}

///|
fn tikz_parse_shift_magnitude(value : String) -> Int? {
  let text_raw = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  let text = tikz_trim_supported_unit(text_raw)
  match tikz_parse_signed_double(text) {
    Some(shift_value) => {
      let shift_abs = Double::abs(shift_value)
      if shift_abs == 0.0 {
        return Some(0)
      }
      let rounded = tikz_round_to_int(shift_abs)
      if rounded < 1 {
        Some(1)
      } else {
        Some(rounded)
      }
    }
    None => None
  }
}

///|
fn tikz_trim_supported_unit(value : String) -> String {
  let text = value.trim().to_string()
  let units = ["pt", "ex", "em", "mm", "cm"]
  for unit in units {
    if text.has_suffix(unit) && text.length() > unit.length() {
      return text.unsafe_substring(start=0, end=text.length() - unit.length())
    }
  }
  text
}

///|
fn tikz_parse_bend_curve_magnitude(value : String) -> Int? {
  let mut text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  if text.has_suffix("deg") {
    text = text.unsafe_substring(start=0, end=text.length() - 3)
  }
  match tikz_parse_signed_double(text) {
    Some(angle_value) => {
      let angle_abs = Double::abs(angle_value)
      if angle_abs == 0.0 {
        return None
      }
      let curve = tikz_round_to_int(angle_abs / 30.0)
      if curve < 1 {
        Some(1)
      } else {
        Some(curve)
      }
    }
    None => None
  }
}

///|
fn tikz_take_braced_group(input : String) -> (String, String)? {
  let text = input.trim().to_string()
  if !text.has_prefix("{") {
    return None
  }

  let mut depth = 0
  let mut i = 0
  while i < text.length() {
    let ch = text.unsafe_get(i)
    if ch == '{' {
      depth = depth + 1
    } else if ch == '}' {
      depth = depth - 1
      if depth == 0 {
        let inner = text.unsafe_substring(start=1, end=i)
        let rest = text.unsafe_substring(start=i + 1, end=text.length())
        return Some((inner, rest))
      }
    }
    i = i + 1
  }
  None
}

///|
fn tikz_parse_between_option(value : String) -> (Int, Int)? {
  match tikz_take_braced_group(value) {
    Some((source_text, rest)) =>
      match tikz_take_braced_group(rest) {
        Some((target_text, _)) =>
          match
            (
              tikz_parse_label_pos_percent(source_text),
              tikz_parse_label_pos_percent(target_text),
            ) {
            (Some(source), Some(target_end)) =>
              if source >= 0 && source <= 100 && target_end >= 0 &&
                target_end <= 100 {
                Some((source, 100 - target_end))
              } else {
                None
              }
            _ => None
          }
        None => None
      }
    None => None
  }
}

///|
fn tikz_parse_curve_height_option(value : String) -> Int? {
  let text = value.trim().to_string()
  let inner = if text.has_prefix("{") && text.has_suffix("}") {
    text.unsafe_substring(start=1, end=text.length() - 1).trim().to_string()
  } else {
    text
  }
  let tokens = tikz_split_arrow_options(inner)
  if tokens.length() == 0 {
    return None
  }

  let mut parsed_height : Int? = None
  for token in tokens {
    match tikz_option_key_value(token) {
      Some((key_raw, value_raw)) => {
        let key_token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(key_raw))
          .trim()
          .to_string()
        if key_token == "height" {
          let height_text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value_raw))
            .trim()
            .to_string()
          let height_value = tikz_trim_supported_unit(height_text)
          match tikz_parse_signed_double(height_value) {
            Some(height_pt) =>
              parsed_height = Some(tikz_round_to_int(height_pt / 6.0))
            None => return None
          }
        } else if key_token == "pos" {
          if tikz_parse_label_pos_percent(value_raw) is None {
            return None
          }
        } else {
          return None
        }
      }
      None => return None
    }
  }

  parsed_height
}

///|
fn tikz_ascii_lower(value : String) -> String {
  let out : Array[String] = []
  for byte in @utf8.encode(value) {
    let code = byte.to_int()
    if code >= 65 && code <= 90 {
      out.push((code + 32).unsafe_to_char().to_string())
    } else {
      out.push(code.unsafe_to_char().to_string())
    }
  }
  out.join("")
}

///|
fn tikz_normalise_colour_name(value : String) -> String {
  let mut text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  if text.has_prefix("(") && text.has_suffix(")") && text.length() >= 2 {
    text = text
      .unsafe_substring(start=1, end=text.length() - 1)
      .trim()
      .to_string()
  }
  if text.has_prefix("\\") {
    text = text.unsafe_substring(start=1, end=text.length())
  }
  match text.find("!") {
    Some(index) =>
      text = text.unsafe_substring(start=0, end=index).trim().to_string()
    None => ()
  }
  tikz_ascii_lower(text)
}

///|
fn tikz_named_colour(name : String) -> Colour? {
  match name {
    "black" => Some(Colour::black())
    "white" => Some(Colour::new(0, 0, 100, 1.0))
    "red" => Some(Colour::new(0, 100, 50, 1.0))
    "green" => Some(Colour::new(120, 100, 25, 1.0))
    "blue" => Some(Colour::new(240, 100, 50, 1.0))
    "yellow" => Some(Colour::new(60, 100, 50, 1.0))
    "cyan" => Some(Colour::new(180, 100, 50, 1.0))
    "magenta" => Some(Colour::new(300, 100, 50, 1.0))
    "gray" => Some(Colour::new(0, 0, 50, 1.0))
    "grey" => Some(Colour::new(0, 0, 50, 1.0))
    "orange" => Some(Colour::new(30, 100, 50, 1.0))
    "purple" => Some(Colour::new(300, 100, 25, 1.0))
    _ => None
  }
}

///|
fn tikz_parse_rgb_255_component(value : String) -> Int? {
  match tikz_parse_positive_int(value.trim().to_string()) {
    Some(component) =>
      if component >= 0 && component <= 255 {
        Some(component)
      } else {
        None
      }
    None => None
  }
}

///|
fn tikz_parse_rgb_255_colour(value : String) -> Colour? {
  let compact = value.replace_all(old=" ", new="")
  if !compact.has_prefix("rgb,255:red,") {
    return None
  }

  let after_red = compact.unsafe_substring(start=12, end=compact.length())
  match after_red.find(";green,") {
    Some(green_index) => {
      let red_text = after_red.unsafe_substring(start=0, end=green_index)
      let after_green = after_red.unsafe_substring(
        start=green_index + 7,
        end=after_red.length(),
      )
      match after_green.find(";blue,") {
        Some(blue_index) => {
          let green_text = after_green.unsafe_substring(start=0, end=blue_index)
          let blue_text = after_green.unsafe_substring(
            start=blue_index + 6,
            end=after_green.length(),
          )
          match
            (
              tikz_parse_rgb_255_component(red_text),
              tikz_parse_rgb_255_component(green_text),
              tikz_parse_rgb_255_component(blue_text),
            ) {
            (Some(r_int), Some(g_int), Some(b_int)) => {
              let r = r_int.to_double() / 255.0
              let g = g_int.to_double() / 255.0
              let b = b_int.to_double() / 255.0
              let max_channel = Double::max(r, Double::max(g, b))
              let min_channel = Double::min(r, Double::min(g, b))
              let delta = max_channel - min_channel
              let l = (max_channel + min_channel) / 2.0
              if delta == 0.0 {
                return Some(Colour::new(0, 0, tikz_round_to_int(l * 100.0), 1.0))
              }

              let abs_l = Double::abs(2.0 * l - 1.0)
              let s = delta / (1.0 - abs_l)
              let h = if max_channel == r {
                60.0 * tikz_mod((g - b) / delta, 6.0)
              } else if max_channel == g {
                60.0 * (((b - r) / delta) + 2.0)
              } else {
                60.0 * (((r - g) / delta) + 4.0)
              }
              Some(
                Colour::new(
                  tikz_round_to_int(h),
                  tikz_round_to_int(s * 100.0),
                  tikz_round_to_int(l * 100.0),
                  1.0,
                ),
              )
            }
            _ => None
          }
        }
        None => None
      }
    }
    None => None
  }
}

///|
fn tikz_parse_colour_option(value : String) -> Colour? {
  let inner = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  match tikz_parse_rgb_255_colour(inner) {
    Some(colour) => Some(colour)
    None => tikz_named_colour(tikz_normalise_colour_name(inner))
  }
}

///|
fn tikz_parse_rotate_option(value : String) -> Int? {
  let text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  match tikz_parse_signed_double(text) {
    Some(value_double) => Some(tikz_round_to_int(value_double))
    None => None
  }
}

///|
fn tikz_decoration_style_name(content : String) -> String? {
  let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(content))
    .trim()
    .to_string()
  if token == "\\dashv" {
    return Some("adjunction")
  }
  if token == "\\lrcorner" {
    return Some("corner")
  }
  if token == "\\ulcorner" {
    return Some("corner-inverse")
  }
  None
}

///|
fn tikz_parse_decoration_option(option : String) -> TikzParsedDecorationOption? {
  match tikz_extract_first_quoted(option) {
    Some(content) =>
      match tikz_decoration_style_name(content) {
        Some(style_name) => {
          let mut colour : Colour? = None
          let mut rotate : Int? = None
          for suffix_option in tikz_label_suffix_options(option) {
            match tikz_option_key_value(suffix_option) {
              Some((key, value)) => {
                let key_token = tikz_strip_math_wrapper(
                  tikz_unwrap_braced_text(key),
                )
                if key_token == "text" {
                  match tikz_parse_colour_option(value) {
                    Some(parsed_colour) => colour = Some(parsed_colour)
                    None => ()
                  }
                } else if key_token == "rotate" {
                  match tikz_parse_rotate_option(value) {
                    Some(parsed_rotate) => rotate = Some(parsed_rotate)
                    None => ()
                  }
                }
              }
              None => ()
            }
          }
          Some({ style_name, colour, rotate })
        }
        None => None
      }
    None => None
  }
}

///|
fn tikz_apply_decoration_rotation(
  options : EdgeOptions,
  style_name : String,
  rotate : Int,
) -> EdgeOptions {
  match style_name {
    "adjunction" => options.with_angle(-rotate)
    "corner" => options.with_angle(45 - rotate)
    "corner-inverse" => options.with_angle(45 - rotate)
    _ => options
  }
}

///|
fn tikz_is_background_colour_expression(value : String) -> Bool {
  let compact = tikz_ascii_lower(
    tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
      .replace_all(old=" ", new="")
      .replace_all(old="\t", new=""),
  )
  compact.contains("/tikz/commutativediagrams/backgroundcolor")
}

///|
fn tikz_arrow_body_decoration_style(content : String) -> String? {
  let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(content))
    .trim()
    .to_string()
  if token == "\\shortmid" {
    return Some("barred")
  }
  if token == "\\shortmid\\shortmid" {
    return Some("double barred")
  }
  if token == "\\bullet" {
    return Some("bullet solid")
  }
  if token == "\\circ" {
    return Some("bullet hollow")
  }
  None
}

///|
fn tikz_parse_arrow_body_decoration_option(
  option : String,
) -> TikzParsedArrowBodyDecorationOption? {
  match tikz_extract_first_quoted(option) {
    Some(content) =>
      match tikz_arrow_body_decoration_style(content) {
        Some(base_style_body) => {
          let mut style_body = base_style_body
          let mut colour : Colour? = None
          for suffix_option in tikz_label_suffix_options(option) {
            match tikz_option_key_value(suffix_option) {
              Some((key, value)) => {
                let key_token = tikz_strip_math_wrapper(
                  tikz_unwrap_braced_text(key),
                )
                if key_token == "text" {
                  if style_body == "bullet solid" &&
                    tikz_is_background_colour_expression(value) {
                    style_body = "bullet hollow"
                  } else {
                    match tikz_parse_colour_option(value) {
                      Some(parsed_colour) => colour = Some(parsed_colour)
                      None => ()
                    }
                  }
                }
              }
              None => ()
            }
          }
          Some({ style_body, colour })
        }
        None => None
      }
    None => None
  }
}

///|
fn tikz_loop_options_default() -> TikzParsedLoopOptions {
  {
    is_loop: false,
    clockwise_hint: None,
    in_angle: None,
    out_angle: None,
    distance_mm: None,
  }
}

///|
fn tikz_signed_angle_delta(from : Double, to : Double) -> Double {
  let raw = tikz_mod(to - from + 180.0, 360.0) - 180.0
  if raw == -180.0 {
    180.0
  } else {
    raw
  }
}

///|
fn tikz_parse_angle_option(value : String) -> Double? {
  let mut text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  if text.has_suffix("deg") {
    text = text.unsafe_substring(start=0, end=text.length() - 3)
  }
  tikz_parse_signed_double(text)
}

///|
fn tikz_parse_distance_option(value : String) -> Double? {
  let text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  match tikz_parse_signed_double(tikz_trim_supported_unit(text)) {
    Some(distance_mm) => if distance_mm > 0.0 { Some(distance_mm) } else { None }
    None => None
  }
}

///|
fn tikz_apply_loop_flag_option(
  loop_options : TikzParsedLoopOptions,
  option : String,
) -> TikzParsedLoopOptions {
  let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(option))
    .trim()
    .to_string()
  if token == "loop left" {
    return { ..loop_options, is_loop: true, clockwise_hint: Some(-1) }
  }
  if token == "loop right" {
    return { ..loop_options, is_loop: true, clockwise_hint: Some(1) }
  }
  if token == "loop" {
    return { ..loop_options, is_loop: true }
  }
  loop_options
}

///|
fn tikz_apply_loop_key_value_option(
  loop_options : TikzParsedLoopOptions,
  key : String,
  value : String,
) -> TikzParsedLoopOptions {
  let key_token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(key))
  if key_token == "in" {
    match tikz_parse_angle_option(value) {
      Some(in_angle) => return { ..loop_options, in_angle: Some(in_angle) }
      None => ()
    }
  }
  if key_token == "out" {
    match tikz_parse_angle_option(value) {
      Some(out_angle) => return { ..loop_options, out_angle: Some(out_angle) }
      None => ()
    }
  }
  if key_token == "distance" {
    match tikz_parse_distance_option(value) {
      Some(distance_mm) => return { ..loop_options, distance_mm: Some(distance_mm) }
      None => ()
    }
  }
  loop_options
}

///|
fn tikz_apply_loop_geometry_options(
  options : EdgeOptions,
  loop_options : TikzParsedLoopOptions,
) -> EdgeOptions {
  if !loop_options.is_loop {
    return options
  }

  let mut clockwise = match loop_options.clockwise_hint {
    Some(value) => if value < 0 { -1 } else { 1 }
    None =>
      if options.radius < 0 {
        -1
      } else {
        1
      }
  }

  let mut abs_radius = Int::abs(options.radius)
  if abs_radius < 1 {
    abs_radius = 1
  }

  let mut angle = options.angle
  match (loop_options.in_angle, loop_options.out_angle) {
    (Some(in_angle), Some(out_angle)) => {
      let delta = tikz_signed_angle_delta(in_angle, out_angle)
      if delta > 0.0 {
        clockwise = 1
      } else if delta < 0.0 {
        clockwise = -1
      }

      let spread = Double::abs(delta) / 2.0
      let loop_angle = tikz_mod(in_angle + delta / 2.0, 360.0)
      angle = tikz_round_to_int(
        180.0 - 90.0 * clockwise.to_double() - loop_angle,
      )

      let radius_from_spread = 1.0 + (spread - 30.0) / 2.5
      if radius_from_spread >= 1.0 {
        abs_radius = tikz_round_to_int(radius_from_spread)
      }
    }
    _ => ()
  }

  match loop_options.distance_mm {
    Some(distance_mm) => {
      let radius_from_distance = 1.0 + (distance_mm - 5.0) / 2.5
      if radius_from_distance >= 1.0 {
        abs_radius = tikz_round_to_int(radius_from_distance)
      }
    }
    None => ()
  }

  if abs_radius < 1 {
    abs_radius = 1
  }
  options.with_radius(abs_radius * clockwise).with_angle(angle)
}

///|
fn tikz_parse_label_pos_percent(value : String) -> Int? {
  let text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  if text == "" {
    return None
  }

  match text.find(".") {
    Some(dot_index) => {
      let whole_text = text.unsafe_substring(start=0, end=dot_index)
      let frac_text = text.unsafe_substring(start=dot_index + 1, end=text.length())
      if frac_text == "" {
        return None
      }

      let whole_value = if whole_text == "" {
        0
      } else {
        match tikz_parse_positive_int(whole_text) {
          Some(value) => value
          None => return None
        }
      }

      if whole_value > 1 {
        return None
      }

      let mut frac_value = 0
      let mut frac_scale = 1
      for byte in @utf8.encode(frac_text) {
        let code = byte.to_int()
        if code < 48 || code > 57 {
          return None
        }
        frac_value = frac_value * 10 + (code - 48)
        frac_scale = frac_scale * 10
      }

      if whole_value == 1 && frac_value != 0 {
        return None
      }

      let numerator = whole_value * frac_scale + frac_value
      let percent_numerator = numerator * 100
      let rounded = (percent_numerator + frac_scale / 2) / frac_scale
      if rounded >= 0 && rounded <= 100 {
        Some(rounded)
      } else {
        None
      }
    }
    None =>
      match tikz_parse_positive_int(text) {
        Some(value) =>
          if value <= 1 {
            Some(value * 100)
          } else if value <= 100 {
            Some(value)
          } else {
            None
          }
        None => None
      }
  }
}

///|
fn tikz_apply_arrow_flag_option(
  options : EdgeOptions,
  option : String,
) -> EdgeOptions {
  let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(option))
  match token {
    "->" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "<-" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "<->" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("arrowhead")
      .with_style_head("arrowhead")
    "|->" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("maps to")
      .with_style_head("arrowhead")
    "<-|" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("maps to")
      .with_style_head("arrowhead")
    "->>" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("epi")
    "<<-" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("epi")
    ">->" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("mono")
      .with_style_head("arrowhead")
    "<-<" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("mono")
      .with_style_head("arrowhead")
    "Rightarrow" =>
      options
      .with_level(2)
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "Leftarrow" =>
      options
      .with_level(2)
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "Leftrightarrow" =>
      options
      .with_level(2)
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("arrowhead")
      .with_style_head("arrowhead")
    "mapsto" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("maps to")
      .with_style_head("arrowhead")
    "mapsfrom" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("maps to")
      .with_style_head("arrowhead")
    "Mapsto" =>
      options
      .with_level(2)
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("maps to")
      .with_style_head("arrowhead")
    "Mapsfrom" =>
      options
      .with_level(2)
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("maps to")
      .with_style_head("arrowhead")
    "hookrightarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("hook", side="top")
      .with_style_head("arrowhead")
    "hookleftarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("hook", side="top")
      .with_style_head("arrowhead")
    "rightarrowtail" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("mono")
      .with_style_head("arrowhead")
    "leftarrowtail" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("mono")
      .with_style_head("arrowhead")
    "rightarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "leftarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "leftrightarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("arrowhead")
      .with_style_head("arrowhead")
    "twoheadrightarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("epi")
    "twoheadleftarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("epi")
    "rightharpoonup" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("harpoon", side="top")
    "rightharpoondown" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("harpoon", side="bottom")
    "leftharpoonup" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("harpoon", side="top")
    "leftharpoondown" =>
      options
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("harpoon", side="bottom")
    "dashrightarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("dashed")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "dashleftarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("dashed")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "rightsquigarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("squiggly")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "leftsquigarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("squiggly")
      .with_style_tail("none")
      .with_style_head("arrowhead")
    "leftrightsquigarrow" =>
      options
      .with_style_name("arrow")
      .with_style_body("squiggly")
      .with_style_tail("arrowhead")
      .with_style_head("arrowhead")
    "dash" =>
      options
      .with_level(1)
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("none")
    "equal" =>
      options
      .with_level(2)
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("none")
    "double line" => options.with_level(2)
    "dashed" => options.with_style_body("dashed")
    "dotted" => options.with_style_body("dotted")
    "squiggly" => options.with_style_body("squiggly")
    "no body" => options.with_style_body("none")
    "no head" => options.with_style_head("none")
    "no tail" => options.with_style_tail("none")
    "maps to" => options.with_style_tail("maps to")
    "tail" => options.with_style_tail("mono")
    "2tail" => options.with_level(2).with_style_tail("mono")
    "tail reversed" => options.with_style_tail("arrowhead")
    "2tail reversed" => options.with_level(2).with_style_tail("arrowhead")
    "hook" => options.with_style_tail("hook", side="top")
    "hook'" => options.with_style_tail("hook", side="bottom")
    "harpoon" => options.with_style_head("harpoon", side="top")
    "harpoon'" => options.with_style_head("harpoon", side="bottom")
    "shift right" => options.with_offset(1)
    "shift left" => options.with_offset(-1)
    "bend left" => options.with_curve(1)
    "bend right" => options.with_curve(-1)
    "to head" => options.with_style_head("cell")
    "two heads" => options.with_style_head("epi")
    "equals" =>
      options
      .with_level(2)
      .with_style_name("arrow")
      .with_style_body("cell")
      .with_style_tail("none")
      .with_style_head("none")
    _ => options
  }
}

///|
fn tikz_apply_arrow_key_value_option(
  options : EdgeOptions,
  key : String,
  value : String,
) -> EdgeOptions {
  let key_token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(key))
  let value_raw = value.trim().to_string()
  let value_token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
  if key_token == "draw" && value_token == "none" {
    return tikz_apply_empty_arrow_style(options)
  }

  if key_token == "scaling nfold" {
    match tikz_parse_level_option_value(value_token) {
      Some(level) => {
        let clamped = if level < 2 {
          2
        } else if level > 4 {
          4
        } else {
          level
        }
        return options.with_level(clamped)
      }
      None => ()
    }
  }

  if key_token == "shift right" {
    match tikz_parse_shift_magnitude(value_raw) {
      Some(magnitude) => return options.with_offset(magnitude)
      None => ()
    }
  }

  if key_token == "shift left" {
    match tikz_parse_shift_magnitude(value_raw) {
      Some(magnitude) => return options.with_offset(-magnitude)
      None => ()
    }
  }

  if key_token == "curve" {
    match tikz_parse_curve_height_option(value_token) {
      Some(curve) => return options.with_curve(curve)
      None => ()
    }
  }

  if key_token == "bend left" {
    match tikz_parse_bend_curve_magnitude(value_raw) {
      Some(curve) => return options.with_curve(curve)
      None => ()
    }
  }

  if key_token == "bend right" {
    match tikz_parse_bend_curve_magnitude(value_raw) {
      Some(curve) => return options.with_curve(-curve)
      None => ()
    }
  }

  let key_compact = key_token
    .replace_all(old=" ", new="")
    .replace_all(old="\t", new="")
  if key_compact == "shorten<" {
    match tikz_parse_shorten_magnitude(value_raw) {
      Some(source) => return options.with_shorten(source, options.shorten.target)
      None => ()
    }
  }
  if key_compact == "shorten>" {
    match tikz_parse_shorten_magnitude(value_raw) {
      Some(target) => return options.with_shorten(options.shorten.source, target)
      None => ()
    }
  }

  if key_token == "between" {
    match tikz_parse_between_option(value_raw) {
      Some((source, target)) => return options.with_shorten(source, target)
      None => ()
    }
  }

  options
}

///|
fn tikz_label_options_default() -> TikzParsedLabelOptions {
  {
    swap: false,
    description: false,
    marking: false,
    pos: None,
    colour: None,
  }
}

///|
fn tikz_apply_label_flag_option(
  label_options : TikzParsedLabelOptions,
  option : String,
) -> TikzParsedLabelOptions {
  let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(option))
  match token {
    "'" => { ..label_options, swap: !label_options.swap }
    "swap" => { ..label_options, swap: !label_options.swap }
    "description" => { ..label_options, description: true }
    "marking" => { ..label_options, marking: true }
    "allow upside down" => label_options
    "at start" => { ..label_options, pos: Some(0) }
    "very near start" => { ..label_options, pos: Some(10) }
    "near start" => { ..label_options, pos: Some(20) }
    "midway" => { ..label_options, pos: Some(50) }
    "near end" => { ..label_options, pos: Some(80) }
    "very near end" => { ..label_options, pos: Some(90) }
    "at end" => { ..label_options, pos: Some(1) }
    _ => label_options
  }
}

///|
fn tikz_apply_label_key_value_option(
  label_options : TikzParsedLabelOptions,
  key : String,
  value : String,
) -> TikzParsedLabelOptions {
  let key_token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(key))
  if key_token == "pos" {
    match tikz_parse_label_pos_percent(value) {
      Some(pos) => { ..label_options, pos: Some(pos) }
      None => label_options
    }
  } else if key_token == "text" {
    match tikz_parse_colour_option(value) {
      Some(colour) => { ..label_options, colour: Some(colour) }
      None => label_options
    }
  } else {
    tikz_apply_label_flag_option(label_options, key_token)
  }
}

///|
fn tikz_label_suffix_options(option : String) -> Array[String] {
  let suffix_options : Array[String] = []
  match tikz_find_unescaped_quote(option, 0) {
    Some(start) => {
      match tikz_find_unescaped_quote(option, start + 1) {
        Some(end) => {
          let mut suffix = option
            .unsafe_substring(start=end + 1, end=option.length())
            .trim()
            .to_string()

          if suffix.has_prefix("'") {
            suffix_options.push("'")
            suffix = suffix
              .unsafe_substring(start=1, end=suffix.length())
              .trim()
              .to_string()
          }

          if suffix == "" {
            return suffix_options
          }

          if suffix.has_prefix("{") && suffix.has_suffix("}") {
            let inner = suffix.unsafe_substring(start=1, end=suffix.length() - 1)
            for opt in tikz_split_arrow_options(inner) {
              suffix_options.push(opt)
            }
          } else {
            suffix_options.push(suffix)
          }
        }
        None => ()
      }
    }
    None => ()
  }
  suffix_options
}

///|
fn tikz_apply_label_options_to_edge_options(
  options : EdgeOptions,
  label_options : TikzParsedLabelOptions,
) -> EdgeOptions {
  let aligned = if label_options.marking {
    options.with_label_alignment_over()
  } else if label_options.description {
    options.with_label_alignment_centre()
  } else if label_options.swap {
    options.with_label_alignment_right()
  } else {
    options.with_label_alignment_left()
  }

  match label_options.pos {
    Some(pos) => aligned.with_label_position(pos)
    None => aligned
  }
}

///|
fn tikz_parse_shorten_magnitude(value : String) -> Int? {
  let text = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()
  let magnitude_text = tikz_trim_supported_unit(text)
  if magnitude_text == text {
    return None
  }

  match tikz_parse_signed_double(magnitude_text) {
    Some(raw_value) => {
      let rounded = tikz_round_to_int(raw_value)
      if rounded < 0 {
        None
      } else if rounded > 100 {
        Some(100)
      } else {
        Some(rounded)
      }
    }
    None => None
  }
}

///|
fn tikz_extract_arrow_label_option(option : String) -> String? {
  match tikz_extract_first_quoted(option) {
    Some(value) => return Some(value)
    None => ()
  }

  if option.contains("=") {
    return None
  }

  let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(option))
  if token == "" ||
    tikz_is_direction_token(token) ||
    tikz_is_label_modifier(token) ||
    tikz_is_arrow_flag_token(token) {
    None
  } else {
    Some(token)
  }
}

///|
fn tikz_extract_bare_arrow_label_option(option : String) -> String? {
  if tikz_extract_first_quoted(option) is Some(_) || option.contains("=") {
    return None
  }

  let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(option))
  if token == "" ||
    tikz_is_direction_token(token) ||
    tikz_is_label_modifier(token) ||
    tikz_is_arrow_flag_token(token) {
    None
  } else {
    Some(token)
  }
}

///|
fn tikz_take_leading_positional_label(input : String) -> (String, String)? {
  let mut i = 0
  while i < input.length() && tikz_is_whitespace(input.unsafe_get(i)) {
    i = i + 1
  }
  if i >= input.length() {
    return None
  }

  let marker = input.unsafe_get(i)
  if marker != '^' && marker != '_' && marker != '|' {
    return None
  }
  let alignment = if marker == '_' {
    "right"
  } else if marker == '|' {
    "centre"
  } else {
    "left"
  }
  i = i + 1
  if marker == '|' &&
    i < input.length() &&
    input.unsafe_get(i) == '-' {
    i = i + 1
  }
  while i < input.length() && tikz_is_whitespace(input.unsafe_get(i)) {
    i = i + 1
  }
  if i >= input.length() {
    return None
  }

  let start = i
  let first = input.unsafe_get(i)
  if first == '{' {
    let mut depth = 1
    let mut j = i + 1
    while j < input.length() && depth > 0 {
      let ch = input.unsafe_get(j)
      if ch == '\\' {
        if j + 1 < input.length() {
          j = j + 2
          continue
        } else {
          break
        }
      }
      if ch == '{' {
        depth = depth + 1
      } else if ch == '}' {
        depth = depth - 1
      }
      j = j + 1
    }
    if depth != 0 || j <= start + 1 {
      return None
    }

    let label = input
      .unsafe_substring(start=start + 1, end=j - 1)
      .trim()
      .to_string()
    let normalised = tikz_strip_math_wrapper(label).trim().to_string()
    if normalised == "" {
      None
    } else {
      Some((normalised, alignment))
    }
  } else if first == '"' {
    match tikz_find_unescaped_quote(input, i + 1) {
      Some(end_quote) =>
        if end_quote <= i + 1 {
          None
        } else {
          let label = input
            .unsafe_substring(start=i + 1, end=end_quote)
            .replace_all(old="\\\"", new="\"")
          let normalised = tikz_strip_math_wrapper(label).trim().to_string()
          if normalised == "" {
            None
          } else {
            Some((normalised, alignment))
          }
        }
      None => None
    }
  } else {
    let mut j = i
    while j < input.length() {
      let ch = input.unsafe_get(j)
      if tikz_is_whitespace(ch) ||
        ch == '\\' ||
        ch == '&' ||
        ch == '[' ||
        ch == ']' ||
        ch == ',' {
        break
      }
      j = j + 1
    }
    if j == i {
      return None
    }

    let label = input.unsafe_substring(start=i, end=j).trim().to_string()
    let normalised = tikz_strip_math_wrapper(label).trim().to_string()
    if normalised == "" {
      None
    } else {
      Some((normalised, alignment))
    }
  }
}

fn tikz_next_arrow_match(input : String) -> TikzArrowMatch? {
  let mut brace_depth = 0
  let mut bracket_depth = 0
  let mut paren_depth = 0
  let mut in_quotes = false
  let mut math_mode = 0
  let mut i = 0
  while i < input.length() {
    let ch = input.unsafe_get(i)
    let escaped = tikz_is_escaped_at(input, i)
    if ch == '"' && !escaped {
      in_quotes = !in_quotes
      i = i + 1
      continue
    }

    if !in_quotes && ch == '$' && !escaped {
      if math_mode == 0 {
        if i + 1 < input.length() && input.unsafe_get(i + 1) == '$' {
          math_mode = 2
          i = i + 2
        } else {
          math_mode = 1
          i = i + 1
        }
        continue
      }
      if math_mode == 1 {
        math_mode = 0
        i = i + 1
        continue
      }
      if i + 1 < input.length() && input.unsafe_get(i + 1) == '$' {
        math_mode = 0
        i = i + 2
        continue
      }
    }

    if math_mode != 0 {
      i = i + 1
      continue
    }

    if !in_quotes && !escaped {
      if ch == '{' {
        brace_depth = brace_depth + 1
      } else if ch == '}' && brace_depth > 0 {
        brace_depth = brace_depth - 1
      } else if ch == '[' {
        bracket_depth = bracket_depth + 1
      } else if ch == ']' && bracket_depth > 0 {
        bracket_depth = bracket_depth - 1
      } else if ch == '(' {
        paren_depth = paren_depth + 1
      } else if ch == ')' && paren_depth > 0 {
        paren_depth = paren_depth - 1
      }
    }

    if ch != '\\' {
      i = i + 1
      continue
    }

    if in_quotes || brace_depth != 0 || bracket_depth != 0 || paren_depth != 0 {
      i = i + 1
      continue
    }

    let rest = input.unsafe_substring(start=i, end=input.length())
    let command_len = if rest.has_prefix("\\arrow") {
      6
    } else if rest.has_prefix("\\ar") {
      3
    } else {
      0
    }

    if command_len == 0 {
      i = i + 1
      continue
    }

    let command_end = i + command_len
    if command_end < input.length() &&
      tikz_is_ascii_letter(input.unsafe_get(command_end)) {
      // Avoid matching command prefixes like "\arrowtail".
      i = i + 1
      continue
    }

    let mut options_start = i + command_len
    while options_start < input.length() &&
      tikz_is_whitespace(input.unsafe_get(options_start)) {
      options_start = options_start + 1
    }
    if options_start < input.length() {
      let open = input.unsafe_get(options_start)
      if open == '[' {
        return Some({
          start: i,
          options_start: options_start + 1,
          open_delimiter: '[',
          close_delimiter: ']',
        })
      }
      if open == '{' {
        return Some({
          start: i,
          options_start: options_start + 1,
          open_delimiter: '{',
          close_delimiter: '}',
        })
      }
    }
    i = i + 1
  }

  None
}

///|
fn tikz_split_arrow_options(raw_options : String) -> Array[String] {
  let options : Array[String] = []
  let mut segment_start = 0
  let mut i = 0
  let mut brace_depth = 0
  let mut bracket_depth = 0
  let mut paren_depth = 0
  let mut in_quotes = false

  while i < raw_options.length() {
    let ch = raw_options.unsafe_get(i)
    if ch == '\\' {
      if i + 1 < raw_options.length() {
        i = i + 2
      } else {
        i = i + 1
      }
      continue
    }

    if ch == '"' {
      in_quotes = !in_quotes
      i = i + 1
      continue
    }

    if !in_quotes {
      if ch == '{' {
        brace_depth = brace_depth + 1
      } else if ch == '}' && brace_depth > 0 {
        brace_depth = brace_depth - 1
      } else if ch == '[' {
        bracket_depth = bracket_depth + 1
      } else if ch == ']' && bracket_depth > 0 {
        bracket_depth = bracket_depth - 1
      } else if ch == '(' {
        paren_depth = paren_depth + 1
      } else if ch == ')' && paren_depth > 0 {
        paren_depth = paren_depth - 1
      } else if ch == ',' &&
        brace_depth == 0 &&
        bracket_depth == 0 &&
        paren_depth == 0 {
        let option = raw_options
          .unsafe_substring(start=segment_start, end=i)
          .trim()
          .to_string()
        if option != "" {
          options.push(option)
        }
        i = i + 1
        segment_start = i
        continue
      }
    }

    i = i + 1
  }

  let option = raw_options
    .unsafe_substring(start=segment_start, end=raw_options.length())
    .trim()
    .to_string()
  if option != "" {
    options.push(option)
  }
  options
}

///|
fn tikz_has_empty_arrow_option(raw_options : String) -> Bool {
  if raw_options.trim().to_string() == "" {
    return false
  }

  let mut segment_start = 0
  let mut i = 0
  let mut brace_depth = 0
  let mut bracket_depth = 0
  let mut paren_depth = 0
  let mut in_quotes = false

  while i < raw_options.length() {
    let ch = raw_options.unsafe_get(i)
    if ch == '\\' {
      if i + 1 < raw_options.length() {
        i = i + 2
      } else {
        i = i + 1
      }
      continue
    }

    if ch == '"' {
      in_quotes = !in_quotes
      i = i + 1
      continue
    }

    if !in_quotes {
      if ch == '{' {
        brace_depth = brace_depth + 1
      } else if ch == '}' && brace_depth > 0 {
        brace_depth = brace_depth - 1
      } else if ch == '[' {
        bracket_depth = bracket_depth + 1
      } else if ch == ']' && bracket_depth > 0 {
        bracket_depth = bracket_depth - 1
      } else if ch == '(' {
        paren_depth = paren_depth + 1
      } else if ch == ')' && paren_depth > 0 {
        paren_depth = paren_depth - 1
      } else if ch == ',' &&
        brace_depth == 0 &&
        bracket_depth == 0 &&
        paren_depth == 0 {
        let segment = raw_options
          .unsafe_substring(start=segment_start, end=i)
          .trim()
          .to_string()
        if segment == "" {
          return true
        }
        i = i + 1
        segment_start = i
        continue
      }
    }

    i = i + 1
  }

  raw_options
    .unsafe_substring(start=segment_start, end=raw_options.length())
    .trim()
    .to_string() == ""
}

///|
fn tikz_find_closing_delimiter(
  input : String,
  open_delimiter : UInt16,
  close_delimiter : UInt16,
) -> Int? {
  let mut in_quotes = false
  let mut brace_depth = 0
  let mut bracket_depth = 0
  let mut paren_depth = 0
  let mut i = 0
  while i < input.length() {
    let ch = input.unsafe_get(i)

    if ch == '\\' {
      if i + 1 < input.length() {
        i = i + 2
      } else {
        i = i + 1
      }
      continue
    }

    if ch == '"' {
      in_quotes = !in_quotes
      i = i + 1
      continue
    }

    if in_quotes {
      i = i + 1
      continue
    }

    if ch == '{' {
      brace_depth = brace_depth + 1
      i = i + 1
      continue
    }
    if ch == '[' {
      bracket_depth = bracket_depth + 1
      i = i + 1
      continue
    }
    if ch == '(' {
      paren_depth = paren_depth + 1
      i = i + 1
      continue
    }
    if ch == '}' {
      if open_delimiter == '{' &&
        close_delimiter == '}' &&
        brace_depth == 0 &&
        bracket_depth == 0 &&
        paren_depth == 0 {
        return Some(i)
      }
      if brace_depth > 0 {
        brace_depth = brace_depth - 1
      }
      i = i + 1
      continue
    }
    if ch == ']' {
      if open_delimiter == '[' &&
        close_delimiter == ']' &&
        bracket_depth == 0 &&
        brace_depth == 0 &&
        paren_depth == 0 {
        return Some(i)
      }
      if bracket_depth > 0 {
        bracket_depth = bracket_depth - 1
      }
      i = i + 1
      continue
    }
    if ch == ')' {
      if paren_depth > 0 {
        paren_depth = paren_depth - 1
      }
      i = i + 1
      continue
    }

    i = i + 1
  }
  None
}

///|
fn tikz_cell_label_raw(cell : String) -> String {
  let trimmed = cell.trim().to_string()
  match tikz_next_arrow_match(trimmed) {
    Some(matched) =>
      trimmed
      .unsafe_substring(start=0, end=matched.start)
      .trim()
      .to_string()
    None => trimmed
  }
}

///|
fn tikz_take_leading_braced_group(input : String) -> (String, String)? {
  let trimmed = tikz_trim_left(input)
  if trimmed == "" || trimmed.unsafe_get(0) != '{' {
    return None
  }

  let after_open = trimmed.unsafe_substring(start=1, end=trimmed.length())
  match tikz_find_closing_delimiter(after_open, '{', '}') {
    Some(close_index) =>
      Some(
        (
          after_open.unsafe_substring(start=0, end=close_index),
          after_open.unsafe_substring(start=close_index + 1, end=after_open.length()),
        ),
      )
    None => None
  }
}

///|
fn tikz_unwrap_trivial_braced_label(label_raw : String) -> String {
  let mut trimmed = label_raw.trim().to_string()
  while true {
    match tikz_take_leading_braced_group(trimmed) {
      Some((inner, rest)) =>
        if tikz_trim_left(rest) == "" {
          trimmed = inner.trim().to_string()
          continue
        } else {
          break
        }
      None => break
    }
  }
  trimmed
}

///|
fn tikz_looks_like_textcolor_vertex_label(label_raw : String) -> Bool {
  tikz_unwrap_trivial_braced_label(label_raw).has_prefix("\\textcolor")
}

///|
fn tikz_parse_textcolor_vertex_label(label_raw : String) -> TikzParsedVertexLabel? {
  let trimmed = tikz_unwrap_trivial_braced_label(label_raw)
  if !trimmed.has_prefix("\\textcolor") {
    return None
  }
  let rest = trimmed.unsafe_substring(start=10, end=trimmed.length())
  match tikz_take_leading_braced_group(rest) {
    Some((colour_text, after_colour)) =>
      match tikz_parse_colour_option(colour_text) {
        Some(label_colour) =>
          match tikz_take_leading_braced_group(after_colour) {
            Some((label_text, _)) =>
              Some({
                label: tikz_unwrap_braced_text(label_text),
                label_colour,
              })
            None => {
              let plain_label = tikz_trim_left(after_colour).trim().to_string()
              if plain_label == "" {
                None
              } else {
                Some({
                  label: tikz_unwrap_braced_text(plain_label),
                  label_colour,
                })
              }
            }
          }
        None => None
      }
    None => None
  }
}

///|
fn tikz_parse_vertex_label(label_raw : String) -> TikzParsedVertexLabel {
  match tikz_parse_textcolor_vertex_label(label_raw) {
    Some(parsed) => parsed
    None => {
      label: tikz_unwrap_braced_text(label_raw),
      label_colour: Colour::black(),
    }
  }
}

///|
fn tikz_collect_cell_arrows(cell : String) -> Array[TikzParsedArrow] {
  let arrows : Array[TikzParsedArrow] = []
  let mut rest = cell
  while true {
    match tikz_next_arrow_match(rest) {
      Some(matched) => {
        let after_arrow = rest.unsafe_substring(
          start=matched.options_start,
          end=rest.length(),
        )
        match
          tikz_find_closing_delimiter(
            after_arrow,
            matched.open_delimiter,
            matched.close_delimiter,
          ) {
          Some(end) => {
            let raw_options = after_arrow.unsafe_substring(start=0, end~)
            let options = tikz_split_arrow_options(raw_options)

            let mut direction : String? = None
            let mut label = ""
            let mut from_x : Int? = None
            let mut from_y : Int? = None
            let mut from_ref : String? = None
            let mut to_x : Int? = None
            let mut to_y : Int? = None
            let mut to_ref : String? = None
            let mut is_phantom = false
            let mut name : String? = None
            let mut source_center_anchor = false
            let mut target_center_anchor = false
            let mut parsed_options = EdgeOptions::at_level(1)
            let mut parsed_reverse = false
            let mut parsed_label_options = tikz_label_options_default()
            let mut parsed_label_colour = Colour::black()
            let mut parsed_loop_options = tikz_loop_options_default()

            for option in options {
              match tikz_parse_decoration_option(option) {
                Some(parsed_decoration) => {
                  parsed_options = parsed_options.with_style_name(
                    parsed_decoration.style_name,
                  )
                  match parsed_decoration.colour {
                    Some(colour) => parsed_options = parsed_options.with_colour(colour)
                    None => ()
                  }
                  match parsed_decoration.rotate {
                    Some(rotate) =>
                      parsed_options = tikz_apply_decoration_rotation(
                        parsed_options,
                        parsed_decoration.style_name,
                        rotate,
                      )
                    None => ()
                  }
                  continue
                }
                None => ()
              }

              match tikz_parse_arrow_body_decoration_option(option) {
                Some(parsed_decoration) => {
                  parsed_options = parsed_options.with_style_body(
                    parsed_decoration.style_body,
                  )
                  match parsed_decoration.colour {
                    Some(colour) => parsed_options = parsed_options.with_colour(colour)
                    None => ()
                  }
                  continue
                }
                None => ()
              }

              if label == "" {
                match tikz_extract_arrow_label_option(option) {
                  Some(value) => label = value
                  None => ()
                }
              }

              match tikz_option_key_value(option) {
                Some((key, value)) =>
                  {
                    let key_token = tikz_strip_math_wrapper(
                      tikz_unwrap_braced_text(key),
                    )
                    let value_token = tikz_strip_math_wrapper(
                      tikz_unwrap_braced_text(value),
                    )
                    if key_token == "from" {
                      match tikz_parse_grid_reference(value) {
                        Some((x, y)) => {
                          from_x = Some(x)
                          from_y = Some(y)
                        }
                        None =>
                          match tikz_parse_reference_name(value) {
                            Some(reference_name) => from_ref = Some(reference_name)
                            None => ()
                          }
                      }
                    } else if key_token == "to" {
                      match tikz_parse_grid_reference(value) {
                        Some((x, y)) => {
                          to_x = Some(x)
                          to_y = Some(y)
                        }
                        None =>
                          match tikz_parse_reference_name(value) {
                            Some(reference_name) => to_ref = Some(reference_name)
                            None => ()
                          }
                      }
                    } else {
                      if key_token == "name" {
                        match tikz_parse_reference_name(value) {
                          Some(reference_name) => name = Some(reference_name)
                          None => ()
                        }
                      }
                      if key_token == "draw" || key_token == "color" {
                        match tikz_parse_colour_option(value) {
                          Some(colour) => {
                            parsed_options = parsed_options.with_colour(colour)
                            if key_token == "color" {
                              parsed_label_colour = colour
                            }
                          }
                          None => ()
                        }
                      } else if key_token == "start anchor" {
                        if value_token == "center" {
                          source_center_anchor = true
                        }
                      } else if key_token == "end anchor" {
                        if value_token == "center" {
                          target_center_anchor = true
                        }
                      } else if key_token == "text" {
                        match tikz_parse_colour_option(value) {
                          Some(colour) => parsed_label_colour = colour
                          None => ()
                        }
                      }
                      parsed_loop_options = tikz_apply_loop_key_value_option(
                        parsed_loop_options,
                        key,
                        value,
                      )
                      parsed_options = tikz_apply_arrow_key_value_option(
                        parsed_options,
                        key,
                        value,
                      )
                      parsed_label_options = tikz_apply_label_key_value_option(
                        parsed_label_options,
                        key,
                        value,
                      )
                    }
                  }
                None => {
                  let direction_candidate = tikz_unwrap_braced_text(option)
                  let option_token = tikz_strip_math_wrapper(direction_candidate)
                  if option_token == "phantom" {
                    is_phantom = true
                    parsed_options = tikz_apply_empty_arrow_style(
                      parsed_options,
                    )
                    parsed_label_options = {
                      ..parsed_label_options,
                      description: true,
                    }
                  }
                  if direction is None &&
                    tikz_is_direction_token(option_token) {
                    direction = Some(option_token)
                  }
                  if label == "" {
                    match tikz_extract_arrow_label_option(option) {
                      Some(value) => label = value
                      None => ()
                    }
                  }
                  match tikz_arrow_flag_reverse(option) {
                    Some(reverse) => parsed_reverse = reverse
                    None => ()
                  }
                  parsed_options = tikz_apply_arrow_flag_option(
                      parsed_options,
                      option,
                    )
                  parsed_loop_options = tikz_apply_loop_flag_option(
                    parsed_loop_options,
                    option,
                  )
                  parsed_label_options = tikz_apply_label_flag_option(
                    parsed_label_options,
                    option,
                  )
                }
              }

              for suffix_option in tikz_label_suffix_options(option) {
                match tikz_option_key_value(suffix_option) {
                  Some((key, value)) => {
                    let key_token = tikz_strip_math_wrapper(
                      tikz_unwrap_braced_text(key),
                    )
                    if key_token == "name" {
                      match tikz_parse_reference_name(value) {
                        Some(reference_name) => name = Some(reference_name)
                        None => ()
                      }
                    }
                    parsed_label_options = tikz_apply_label_key_value_option(
                      parsed_label_options,
                      key,
                      value,
                    )
                  }
                  None =>
                    parsed_label_options = tikz_apply_label_flag_option(
                      parsed_label_options,
                      suffix_option,
                    )
                }
              }
            }

            parsed_options = tikz_apply_label_options_to_edge_options(
              parsed_options,
              parsed_label_options,
            )
            parsed_options = tikz_apply_loop_geometry_options(
              parsed_options,
              parsed_loop_options,
            )
            let label_colour = match parsed_label_options.colour {
              Some(colour) => colour
              None => parsed_label_colour
            }

            let remaining_after_arrow = after_arrow.unsafe_substring(
              start=end + 1,
              end=after_arrow.length(),
            )
            if label == "" {
              match tikz_take_leading_positional_label(remaining_after_arrow) {
                Some((suffix_label, alignment)) => {
                  label = suffix_label
                  parsed_options = match alignment {
                    "right" => parsed_options.with_label_alignment_right()
                    "centre" => parsed_options.with_label_alignment_centre()
                    _ => parsed_options
                  }
                }
                None => ()
              }
            }

            arrows.push({
              direction,
              reverse: parsed_reverse,
              is_loop: parsed_loop_options.is_loop,
              is_phantom,
              name,
              source_center_anchor,
              target_center_anchor,
              label,
              from_x,
              from_y,
              from_ref,
              to_x,
              to_y,
              to_ref,
              options: parsed_options,
              label_colour,
            })

            rest = remaining_after_arrow
          }
          None => break
        }
      }
      None => break
    }
  }
  arrows
}

///|
fn tikz_direction_delta(direction : String) -> (Int, Int) {
  let mut dx = 0
  let mut dy = 0
  for ch in direction {
    if ch == 'r' {
      dx = dx + 1
    } else if ch == 'l' {
      dx = dx - 1
    } else if ch == 'd' {
      dy = dy + 1
    } else if ch == 'u' {
      dy = dy - 1
    }
  }
  (dx, dy)
}

///|
fn tikz_grid_key(x : Int, y : Int) -> String {
  ["x=", x.to_string(), ",y=", y.to_string()].join("")
}

///|
fn tikz_resolve_pending_endpoint_id(
  grid_x : Int?,
  grid_y : Int?,
  reference_name : String?,
  default_x : Int,
  default_y : Int,
  use_default : Bool,
  vertex_by_key : Map[String, Int],
  named_cell_ids : Map[String, TikzNamedCellRef],
) -> TikzResolvedEndpoint? {
  match reference_name {
    Some(name) =>
      match named_cell_ids.get(name) {
        Some(named) => Some({ id: named.id, center_anchor: named.center_anchor })
        None =>
          match tikz_parse_grid_reference(name) {
            Some((x, y)) =>
              match vertex_by_key.get(tikz_grid_key(x, y)) {
                Some(id) => Some({ id, center_anchor: false })
                None => None
              }
            None => None
          }
      }
    None => {
      let resolved_grid = match (grid_x, grid_y) {
        (Some(x), Some(y)) => Some((x, y))
        _ =>
          if use_default {
            Some((default_x, default_y))
          } else {
            None
          }
      }
      match resolved_grid {
        Some((x, y)) =>
          match vertex_by_key.get(tikz_grid_key(x, y)) {
            Some(id) => Some({ id, center_anchor: false })
            None => None
          }
        None => None
      }
    }
  }
}

///|
fn tikz_edge_matches_phantom_anchor(
  edge : Edge,
  source_id : Int,
  target_id : Int,
  options : EdgeOptions,
) -> Bool {
  edge.source == source_id &&
  edge.target == target_id &&
  edge.options.offset == options.offset &&
  edge.options.curve == options.curve
}

///|
fn tikz_find_phantom_anchor_edge_id(
  quiver : Quiver,
  source_id : Int,
  target_id : Int,
  options : EdgeOptions,
) -> Int? {
  let mut matched : Int? = None
  for cell in quiver.all_cells() {
    match cell {
      CellData::Edge(edge) =>
        if tikz_edge_matches_phantom_anchor(edge, source_id, target_id, options) {
          matched = Some(edge.cell.id)
        }
      _ => ()
    }
  }
  matched
}

///|
fn tikz_is_phantom_helper_name(reference_name : String) -> Bool {
  let name = reference_name.trim().to_string()
  if name.length() < 2 || !name.has_suffix("p") {
    return false
  }

  let prefix = name.unsafe_substring(start=0, end=name.length() - 1)
  if prefix == "" {
    return false
  }

  for byte in @utf8.encode(prefix) {
    let code = byte.to_int()
    if code < 48 || code > 57 {
      return false
    }
  }
  true
}

///|
fn tikz_has_wrapper_marker(input : String) -> Bool {
  for raw_line in input.split("\n") {
    let line = raw_line.to_string().trim().to_string()
    if line == "" {
      continue
    }
    if line.has_prefix("% ") ||
      line.has_prefix("// ") ||
      line.contains("<!--") ||
      line.contains("src=") {
      return true
    }
  }
  false
}

///|
fn tikz_is_share_reference_candidate(reference : String) -> Bool {
  if reference == "" {
    return false
  }

  let has_share_markers = reference.contains("q.uiver.app") ||
    reference.contains("#q=") ||
    reference.contains("?q=") ||
    reference.contains("&q=") ||
    reference.has_prefix("q=") ||
    reference.has_prefix("r=") ||
    reference.has_prefix("macro_url=") ||
    reference.has_prefix("embed")

  if has_share_markers {
    let parsed = Quiver::parse_base64_share_url(reference)
    match parsed.payload {
      Some(payload) => {
        let payload_result : Result[Quiver, Error] = try? Quiver::import_base64_v0(
          payload,
        )
        return payload_result is Ok(_)
      }
      None => return false
    }
  }

  let parsed : Result[Quiver, Error] = try? Quiver::import_base64_v0(reference)
  parsed is Ok(_)
}

///|
fn tikz_promote_imported_edge_level(
  quiver : Quiver,
  edge_id : Int,
  minimum_level : Int,
) -> Unit {
  if minimum_level < 1 {
    return
  }

  match quiver.cells.get(edge_id) {
    Some(CellData::Edge(edge)) => {
      if edge.cell.level >= minimum_level {
        return
      }
      let old_level = edge.cell.level
      quiver.remove_from_level(old_level, edge_id)
      quiver.ensure_level(minimum_level)
      quiver.cells_by_level[minimum_level].set(edge_id, true)
      quiver.cells.set(
        edge_id,
        CellData::Edge(edge.reconnected(edge.source, edge.target, minimum_level)),
      )
    }
    _ => ()
  }
}

///|
fn tikz_ensure_implicit_vertex_at(
  quiver : Quiver,
  vertex_by_key : Map[String, Int],
  x : Int,
  y : Int,
  next_id : Int,
) -> Int {
  let key = tikz_grid_key(x, y)
  match vertex_by_key.get(key) {
    Some(_) => next_id
    None => {
      let vertex_id = next_id
      quiver.add(CellData::from_vertex(Vertex::new_black(vertex_id, "", x, y)))
      vertex_by_key.set(key, vertex_id)
      vertex_id + 1
    }
  }
}

///|
fn tikz_import_error(
  kind : String,
  message : String,
  line? : Int = 0,
  column? : Int = 0,
) -> TikzCdImportError {
  { kind, message, line, column }
}

///|
fn tikz_is_supported_style_diagram_option_key(key_token : String) -> Bool {
  let key = key_token.trim().to_string()
  if key == "cells" {
    return true
  }
  if key.has_prefix("every arrow") ||
    key.has_prefix("every label") ||
    key.has_prefix("every cell") ||
    key.has_prefix("every matrix") ||
    key.has_prefix("every diagram") ||
    key.has_prefix("every edge") ||
    key.has_prefix("every row") ||
    key.has_prefix("every column") {
    return true
  }
  false
}

///|
fn tikz_is_supported_style_diagram_option_token(token : String) -> Bool {
  let trimmed = token.trim().to_string()
  let sep_prefixes = ["sep/", "row sep/", "column sep/"]
  for prefix in sep_prefixes {
    if trimmed.has_prefix(prefix) {
      let suffix = trimmed
        .unsafe_substring(start=prefix.length(), end=trimmed.length())
        .trim()
        .to_string()
      return suffix != ""
    }
  }
  false
}

///|
fn tikz_validate_diagram_options(options : String) -> TikzCdImportError? {
  for option in tikz_split_arrow_options(options) {
    let trimmed = option.trim().to_string()
    if trimmed == "" {
      return Some(
        tikz_import_error(
          "syntax",
          "empty tikzcd diagram option",
        ),
      )
    }

    match tikz_option_key_value(option) {
      Some((key, value)) => {
        let key_token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(key))
          .trim()
          .to_string()
        let key_compact = key_token
          .replace_all(old=" ", new="")
          .replace_all(old="\t", new="")
        let value_token = tikz_unwrap_braced_text(value).trim().to_string()

        if key_compact == "ampersandreplacement" {
          if value_token == "" {
            return Some(
              tikz_import_error(
                "option",
                "ampersand replacement must not be empty",
              ),
            )
          }
          continue
        }

        if key_token == "sep" ||
          key_token == "row sep" ||
          key_token == "column sep" {
          if value_token == "" {
            return Some(
              tikz_import_error(
                "option",
                [key_token, " must not be empty"].join(""),
              ),
            )
          }
          continue
        }

        if tikz_is_supported_style_diagram_option_key(key_token) {
          if value_token == "" {
            return Some(
              tikz_import_error(
                "option",
                [key_token, " must not be empty"].join(""),
              ),
            )
          }
          continue
        }

        return Some(
          tikz_import_error(
            "option",
            ["unknown tikzcd diagram option: ", key_token].join(""),
          ),
        )
      }
      None => {
        if trimmed == "cramped" ||
          tikz_is_supported_style_diagram_option_token(trimmed) {
          continue
        }

        return Some(
          tikz_import_error(
            "option",
            ["unknown tikzcd diagram option: ", trimmed].join(""),
          ),
        )
      }
    }
  }
  None
}

///|
fn tikz_validate_label_suffix_option(option : String) -> String? {
  let suffixes = tikz_label_suffix_options(option)
  for suffix in suffixes {
    let suffix_trimmed = suffix.trim().to_string()
    if suffix_trimmed == "" {
      return Some("empty label suffix option")
    }

    match tikz_option_key_value(suffix_trimmed) {
      Some((key, value)) => {
        let key_token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(key))
          .trim()
          .to_string()
        let value_token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
          .trim()
          .to_string()
        if key_token == "name" {
          if tikz_parse_reference_name(value) is None {
            return Some("invalid name value in label suffix")
          }
          continue
        }

        if key_token == "pos" {
          if tikz_parse_label_pos_percent(value) is None {
            return Some("invalid pos value in label suffix")
          }
          continue
        }

        if key_token == "text" {
          if value_token == "" ||
            (tikz_parse_colour_option(value) is None &&
              !tikz_is_background_colour_expression(value)) {
            return Some("invalid text colour in label suffix")
          }
          continue
        }

        if key_token == "anchor" ||
          key_token == "inner sep" ||
          key_token == "rotate" {
          continue
        }

        if tikz_is_label_modifier(key_token) {
          continue
        }

        return Some(["unknown label suffix option: ", key_token].join(""))
      }
      None => {
        if suffix_trimmed == "'" || tikz_is_label_modifier(suffix_trimmed) {
          continue
        }
        return Some(
          ["unknown label suffix option: ", suffix_trimmed].join(""),
        )
      }
    }
  }
  None
}

///|
fn tikz_validate_arrow_key_value_option(
  key : String,
  value : String,
) -> String? {
  let key_token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(key))
    .trim()
    .to_string()
  let key_compact = key_token
    .replace_all(old=" ", new="")
    .replace_all(old="\t", new="")
  let value_token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(value))
    .trim()
    .to_string()

  if key_token == "from" || key_token == "to" {
    if value_token.contains(" ") || value_token.contains("\t") {
      return Some(
        ["invalid ", key_token, " endpoint reference"].join(""),
      )
    }
    if tikz_parse_grid_reference(value) is None &&
      tikz_parse_reference_name(value) is None {
      return Some(
        ["invalid ", key_token, " endpoint reference"].join(""),
      )
    }
    return None
  }

  if key_token == "name" {
    if tikz_parse_reference_name(value) is None {
      return Some("invalid name option")
    }
    return None
  }

  if key_token == "draw" {
    if value_token == "none" {
      return None
    }
    if value_token == "" || tikz_parse_colour_option(value) is None {
      return Some("invalid draw colour option")
    }
    return None
  }

  if key_token == "color" {
    if value_token == "" || tikz_parse_colour_option(value) is None {
      return Some(
        ["invalid ", key_token, " colour option"].join(""),
      )
    }
    return None
  }

  if key_token == "text" {
    if value_token == "" ||
      (tikz_parse_colour_option(value) is None &&
        !tikz_is_background_colour_expression(value)) {
      return Some("invalid text colour option")
    }
    return None
  }

  if key_token == "start anchor" || key_token == "end anchor" {
    if value_token == "" {
      return Some(
        ["invalid ", key_token, " value"].join(""),
      )
    }
    return None
  }

  if key_token == "scaling nfold" {
    if tikz_parse_level_option_value(value_token) is None {
      return Some("invalid scaling nfold value")
    }
    return None
  }

  if key_token == "shift right" || key_token == "shift left" {
    if tikz_parse_shift_magnitude(value) is None {
      return Some(
        ["invalid ", key_token, " value"].join(""),
      )
    }
    return None
  }

  if key_token == "curve" {
    if tikz_parse_curve_height_option(value) is None {
      return Some("invalid curve value")
    }
    return None
  }

  if key_token == "bend left" || key_token == "bend right" {
    if tikz_parse_bend_curve_magnitude(value) is None {
      return Some(
        ["invalid ", key_token, " value"].join(""),
      )
    }
    return None
  }

  if key_token == "between" {
    if tikz_parse_between_option(value) is None {
      return Some("invalid between value")
    }
    return None
  }

  if key_compact == "shorten<" || key_compact == "shorten>" {
    if tikz_parse_shorten_magnitude(value) is None {
      return Some("invalid shorten value")
    }
    return None
  }

  if key_token == "in" || key_token == "out" {
    if tikz_parse_angle_option(value) is None {
      return Some(
        ["invalid ", key_token, " loop angle"].join(""),
      )
    }
    return None
  }

  if key_token == "distance" {
    if tikz_parse_distance_option(value) is None {
      return Some("invalid loop distance")
    }
    return None
  }

  if key_token == "pos" {
    if tikz_parse_label_pos_percent(value) is None {
      return Some("invalid pos value")
    }
    return None
  }

  if tikz_is_label_modifier(key_token) {
    return None
  }

  Some(["unknown arrow option: ", key_token].join(""))
}

///|
fn tikz_validate_arrow_option(option : String) -> String? {
  let trimmed = option.trim().to_string()
  if trimmed == "" {
    return Some("empty arrow option")
  }

  if tikz_parse_decoration_option(trimmed) is Some(_) {
    return None
  }
  if tikz_parse_arrow_body_decoration_option(trimmed) is Some(_) {
    return None
  }
  if tikz_extract_first_quoted(trimmed) is Some(_) {
    return tikz_validate_label_suffix_option(trimmed)
  }

  match tikz_option_key_value(trimmed) {
    Some((key, value)) => tikz_validate_arrow_key_value_option(key, value)
    None => {
      let token = tikz_strip_math_wrapper(tikz_unwrap_braced_text(trimmed))
        .trim()
        .to_string()
      if token == "phantom" ||
        tikz_is_direction_token(token) ||
        tikz_is_arrow_flag_token(token) ||
        tikz_is_label_modifier(token) {
        return None
      }

      Some(["unknown arrow option: ", token].join(""))
    }
  }
}

///|
fn tikz_validate_cell_arrow_options(cell : String) -> TikzCdImportError? {
  let mut rest = cell
  while true {
    match tikz_next_arrow_match(rest) {
      Some(matched) => {
        let after_arrow = rest.unsafe_substring(
          start=matched.options_start,
          end=rest.length(),
        )
        match tikz_find_closing_delimiter(
          after_arrow,
          matched.open_delimiter,
          matched.close_delimiter,
        ) {
          Some(end) => {
            let raw_options = after_arrow.unsafe_substring(start=0, end~)
            if tikz_has_empty_arrow_option(raw_options) {
              return Some(
                tikz_import_error(
                  "syntax",
                  "empty arrow option",
                ),
              )
            }
            let options = tikz_split_arrow_options(raw_options)
            let bare_labels : Array[String] = []
            let mut has_to = false
            let mut has_from = false
            let mut has_direction = false
            let mut is_loop = false

            for option in options {
              let trimmed = option.trim().to_string()
              if trimmed == "" {
                return Some(
                  tikz_import_error(
                    "syntax",
                    "empty arrow option",
                  ),
                )
              }
              if tikz_extract_first_quoted(trimmed) is Some(_) {
                match tikz_validate_arrow_option(trimmed) {
                  Some(message) =>
                    return Some(
                      tikz_import_error("option", message),
                    )
                  None => ()
                }
              } else if tikz_extract_bare_arrow_label_option(trimmed) is Some(token) {
                bare_labels.push(token)
              } else {
                match tikz_validate_arrow_option(trimmed) {
                  Some(message) =>
                    return Some(
                      tikz_import_error("option", message),
                    )
                  None => ()
                }
              }

              match tikz_option_key_value(trimmed) {
                Some((key, _)) => {
                  let key_token = tikz_strip_math_wrapper(
                    tikz_unwrap_braced_text(key),
                  )
                    .trim()
                    .to_string()
                  if key_token == "to" {
                    has_to = true
                  }
                  if key_token == "from" {
                    has_from = true
                  }
                  if key_token == "name" {
                    // Named arrows are still required to provide a target.
                    ()
                  }
                }
                None => {
                  let token = tikz_strip_math_wrapper(
                    tikz_unwrap_braced_text(trimmed),
                  )
                    .trim()
                    .to_string()
                  if tikz_is_direction_token(token) {
                    has_direction = true
                  }
                  if token == "loop" ||
                    token == "loop left" ||
                    token == "loop right" {
                    is_loop = true
                  }
                }
              }
            }

            if bare_labels.length() > 1 {
              return Some(
                tikz_import_error(
                  "option",
                  ["unknown arrow option: ", bare_labels[1]].join(""),
                ),
              )
            }
            if bare_labels.length() == 1 && (has_from || has_to) {
              return Some(
                tikz_import_error(
                  "option",
                  ["unknown arrow option: ", bare_labels[0]].join(""),
                ),
              )
            }

            if !has_to && !has_direction && !is_loop {
              return Some(
                tikz_import_error(
                  "reference",
                  "arrow is missing target (to=... or direction)",
                ),
              )
            }

            rest = after_arrow.unsafe_substring(
              start=end + 1,
              end=after_arrow.length(),
            )
          }
          None =>
            return Some(
              tikz_import_error(
                "syntax",
                "unterminated arrow options",
              ),
            )
        }
      }
      None => break
    }
  }
  None
}

///|
fn tikz_validate_cell_vertex_label(cell : String) -> TikzCdImportError? {
  let label_raw = tikz_cell_label_raw(cell)
  if label_raw == "" {
    return None
  }

  if tikz_looks_like_textcolor_vertex_label(label_raw) &&
    tikz_parse_textcolor_vertex_label(label_raw) is None {
    return Some(
      tikz_import_error(
        "option",
        "invalid textcolor vertex label",
      ),
    )
  }

  None
}

///|
fn tikz_validate_environment_and_options(input : String) -> TikzCdImportError? {
  let (begin_index, begin_token, end_token) = match tikz_find_environment_tokens(
    input,
  ) {
    Some(found) => found
    None =>
      return Some(
        tikz_import_error(
          "syntax",
          "missing tikzcd environment start token",
          line=1,
          column=1,
        ),
      )
  }

  let after_begin_start = begin_index + begin_token.length()
  let after_begin = input.unsafe_substring(
    start=after_begin_start,
    end=input.length(),
  )
  let after_begin_trimmed = tikz_trim_left_length(after_begin)
  let mut rest_start = after_begin_start + after_begin_trimmed
  let mut rest = if after_begin_trimmed == 0 {
    after_begin
  } else {
    after_begin.unsafe_substring(start=after_begin_trimmed, end=after_begin.length())
  }
  let mut ampersand_replacement : String? = None

  if rest.has_prefix("[") {
    let options_body = rest.unsafe_substring(start=1, end=rest.length())
    match tikz_find_closing_delimiter(options_body, '[', ']') {
      Some(close_index) => {
        let options = options_body.unsafe_substring(start=0, end=close_index)
        match tikz_validate_diagram_options(options) {
          Some(error) => {
            let (line, column) = tikz_line_column_from_index(input, rest_start)
            return Some(tikz_error_with_position_if_missing(error, line, column))
          }
          None => ()
        }
        ampersand_replacement = tikz_parse_ampersand_replacement(options)
        rest = options_body.unsafe_substring(
          start=close_index + 1,
          end=options_body.length(),
        )
        rest_start = rest_start + close_index + 2
      }
      None => {
        let (line, column) = tikz_line_column_from_index(input, rest_start)
        return Some(
          tikz_import_error(
            "syntax",
            "unterminated tikzcd diagram options",
            line=line,
            column=column,
          ),
        )
      }
    }
  }

  let end_index = match tikz_find_token_outside_comments(rest, end_token) {
    Some(index) => index
    None => {
      let (line, column) = tikz_line_column_from_index(input, rest_start)
      return Some(
        tikz_import_error(
          "syntax",
          "missing tikzcd environment end token",
          line=line,
          column=column,
        ),
      )
    }
  }

  let body = rest.unsafe_substring(start=0, end=end_index)
  let tail = rest.unsafe_substring(
    start=end_index + end_token.length(),
    end=rest.length(),
  )
  let tail_without_comments = tikz_strip_line_comments(tail)
  let tail_trimmed = tail_without_comments.trim().to_string()
  if tail_trimmed != "" &&
    tail_trimmed != "\\]" &&
    tail_trimmed != "\\)" &&
    tail_trimmed != "$$" {
    let (line, column) = tikz_line_column_from_index(
      input,
      rest_start + end_index + end_token.length(),
    )
    return Some(
      tikz_import_error(
        "syntax",
        "unexpected content after \\end{tikzcd}",
        line=line,
        column=column,
      ),
    )
  }

  let body_without_comments = tikz_strip_line_comments(body)
  for row_segment in tikz_split_rows_with_offsets(body_without_comments) {
    let row = row_segment.text.trim().to_string()
    if row == "" {
      continue
    }
    for cell_segment in tikz_split_cells_with_offsets(
      row_segment.text,
      ampersand_replacement,
    ) {
      let cell = cell_segment.text.trim().to_string()
      let cell_offset = tikz_first_non_whitespace_offset(cell_segment.text)
      let cell_absolute = rest_start + row_segment.start + cell_segment.start + cell_offset
      let (line, column) = tikz_line_column_from_index(input, cell_absolute)
      match tikz_validate_cell_vertex_label(cell) {
        Some(error) =>
          return Some(tikz_error_with_position_if_missing(error, line, column))
        None => ()
      }
      match tikz_validate_cell_arrow_options(cell) {
        Some(error) =>
          return Some(tikz_error_with_position_if_missing(error, line, column))
        None => ()
      }
    }
  }
  None
}

///|
fn Quiver::import_tikz_cd_minimal(
  input : String,
) -> Result[Quiver, TikzCdImportError] {
  let environment = match tikz_extract_environment_body(input) {
    Some(value) => value
    None =>
      return Err(
        tikz_import_error(
          "syntax",
          "missing tikzcd environment",
        ),
      )
  }

  let body_without_comments = tikz_strip_line_comments(environment.body)
  let rows = tikz_split_rows_with_offsets(body_without_comments)
  let quiver = Quiver::new()
  let vertex_by_key : Map[String, Int] = Map::new()
  let pending_arrows : Array[TikzPendingArrow] = []
  let mut next_id = 1

  let mut y = 0
  for row_segment in rows {
    let row = row_segment.text.trim().to_string()
    if row == "" {
      continue
    }
    let cells = tikz_split_cells_with_offsets(
      row_segment.text,
      environment.ampersand_replacement,
    )
    let mut x = 0
    for cell_segment in cells {
      let cell = cell_segment.text.trim().to_string()
      let cell_offset = tikz_first_non_whitespace_offset(cell_segment.text)
      let cell_absolute = environment.body_offset +
        row_segment.start +
        cell_segment.start +
        cell_offset
      let (cell_line, cell_column) = tikz_line_column_from_index(input, cell_absolute)
      let label_raw = tikz_cell_label_raw(cell)
      if label_raw != "" {
        let parsed_vertex = tikz_parse_vertex_label(label_raw)
        let vertex_id = next_id
        next_id = next_id + 1
        quiver.add(
          CellData::from_vertex(
            Vertex::new(
              vertex_id,
              parsed_vertex.label,
              x,
              y,
              parsed_vertex.label_colour,
            ),
          ),
        )
        vertex_by_key.set(tikz_grid_key(x, y), vertex_id)
      }

      for parsed_arrow in tikz_collect_cell_arrows(cell) {
        let default_source_x = match parsed_arrow.from_x {
          Some(value) => value
          None => x
        }
        let default_source_y = match parsed_arrow.from_y {
          Some(value) => value
          None => y
        }

        let target_coords = if parsed_arrow.to_ref is Some(_) {
          None
        } else {
          match (parsed_arrow.to_x, parsed_arrow.to_y) {
            (Some(tx), Some(ty)) => Some((tx, ty))
            _ =>
              match parsed_arrow.direction {
                Some(direction) => {
                  let (dx, dy) = tikz_direction_delta(direction)
                  Some((default_source_x + dx, default_source_y + dy))
                }
                None =>
                  if parsed_arrow.is_loop {
                    Some((default_source_x, default_source_y))
                  } else {
                    None
                  }
              }
          }
        }

        let (target_x, target_y) = match target_coords {
          Some((tx, ty)) => (Some(tx), Some(ty))
          None => (None, None)
        }

        pending_arrows.push({
          default_source_x,
          default_source_y,
          reverse: parsed_arrow.reverse,
          is_loop: parsed_arrow.is_loop,
          source_x: parsed_arrow.from_x,
          source_y: parsed_arrow.from_y,
          source_ref: parsed_arrow.from_ref,
          source_center_anchor: parsed_arrow.source_center_anchor,
          target_x,
          target_y,
          target_ref: parsed_arrow.to_ref,
          target_center_anchor: parsed_arrow.target_center_anchor,
          is_phantom: parsed_arrow.is_phantom,
          name: parsed_arrow.name,
          label: parsed_arrow.label,
          line: cell_line,
          column: cell_column,
          options: parsed_arrow.options,
          label_colour: parsed_arrow.label_colour,
        })
      }

      x = x + 1
    }
    y = y + 1
  }

  for pending in pending_arrows {
    if pending.source_ref is None {
      let (source_x, source_y) = match (pending.source_x, pending.source_y) {
        (Some(x), Some(y)) => (x, y)
        _ => (pending.default_source_x, pending.default_source_y)
      }
      next_id = tikz_ensure_implicit_vertex_at(
        quiver,
        vertex_by_key,
        source_x,
        source_y,
        next_id,
      )
    }

    if pending.target_ref is None {
      match (pending.target_x, pending.target_y) {
        (Some(x), Some(y)) =>
          next_id = tikz_ensure_implicit_vertex_at(
            quiver,
            vertex_by_key,
            x,
            y,
            next_id,
          )
        _ => ()
      }
    }
  }

  let named_cell_ids : Map[String, TikzNamedCellRef] = Map::new()
  let mut pending_round = pending_arrows.copy()
  let mut made_progress = true
  while pending_round.length() > 0 && made_progress {
    made_progress = false
    let next_round : Array[TikzPendingArrow] = []
    for pending in pending_round {
      let source_endpoint = match
        tikz_resolve_pending_endpoint_id(
          pending.source_x,
          pending.source_y,
          pending.source_ref,
          pending.default_source_x,
          pending.default_source_y,
          true,
          vertex_by_key,
          named_cell_ids,
        ) {
        Some(value) => value
        None => {
          next_round.push(pending)
          continue
        }
      }
      let target_endpoint = match
        tikz_resolve_pending_endpoint_id(
          pending.target_x,
          pending.target_y,
          pending.target_ref,
          pending.default_source_x,
          pending.default_source_y,
          false,
          vertex_by_key,
          named_cell_ids,
        ) {
        Some(value) => value
        None => {
          next_round.push(pending)
          continue
        }
      }

      let source_id = source_endpoint.id
      let target_id = target_endpoint.id
      let source_center_anchor = pending.source_center_anchor ||
        source_endpoint.center_anchor
      let target_center_anchor = pending.target_center_anchor ||
        target_endpoint.center_anchor
      let (
        resolved_source_id,
        resolved_target_id,
        resolved_source_center_anchor,
        resolved_target_center_anchor,
      ) = if pending.reverse {
        (target_id, source_id, target_center_anchor, source_center_anchor)
      } else {
        (source_id, target_id, source_center_anchor, target_center_anchor)
      }

      if pending.is_loop {
        if resolved_source_id != resolved_target_id {
          return Err(
            tikz_import_error(
              "reference",
              "loop arrow source and target must match",
              line=pending.line,
              column=pending.column,
            ),
          )
        }
      } else if resolved_source_id == resolved_target_id {
        return Err(
          tikz_import_error(
            "reference",
            "arrow source and target are identical without loop",
            line=pending.line,
            column=pending.column,
          ),
        )
      }

      if pending.is_phantom {
        let matched_helper_edge_id = tikz_find_phantom_anchor_edge_id(
          quiver,
          resolved_source_id,
          resolved_target_id,
          pending.options,
        )
        let helper_reference = match pending.name {
          Some(reference_name) =>
            if tikz_is_phantom_helper_name(reference_name) {
              Some(reference_name)
            } else {
              None
            }
          None => None
        }
        match helper_reference {
          Some(reference_name) =>
            match matched_helper_edge_id {
              Some(edge_id) => {
                named_cell_ids.set(reference_name, {
                  id: edge_id,
                  center_anchor: resolved_source_center_anchor ||
                    resolved_target_center_anchor,
                })
                made_progress = true
              }
              None => next_round.push(pending)
            }
          None => ()
        }
        if helper_reference is Some(_) {
          continue
        }

        if pending.name is None {
          if matched_helper_edge_id is Some(_) {
            made_progress = true
            continue
          }
        }
      }

      let edge_id = next_id
      next_id = next_id + 1
      let edge_options = pending.options
        .with_edge_alignment_source(!resolved_source_center_anchor)
        .with_edge_alignment_target(!resolved_target_center_anchor)
      quiver.add(
        CellData::from_edge(
          Edge::new(
            edge_id,
            pending.label,
            resolved_source_id,
            resolved_target_id,
            edge_options,
            pending.label_colour,
          ),
        ),
      )
      quiver.connect(resolved_source_id, resolved_target_id, edge_id)
      tikz_promote_imported_edge_level(quiver, edge_id, pending.options.level)
      match pending.name {
        Some(reference_name) =>
          named_cell_ids.set(reference_name, {
            id: edge_id,
            center_anchor: false,
          })
        None => ()
      }
      made_progress = true
    }
    pending_round = next_round
  }

  if pending_round.length() > 0 {
    let unresolved = pending_round[0]
    match unresolved.source_ref {
      Some(reference_name) =>
        return Err(
          tikz_import_error(
            "reference",
            ["unresolved arrow endpoint reference: ", reference_name].join(""),
            line=unresolved.line,
            column=unresolved.column,
          ),
        )
      None => ()
    }
    match unresolved.target_ref {
      Some(reference_name) =>
        return Err(
          tikz_import_error(
            "reference",
            ["unresolved arrow endpoint reference: ", reference_name].join(""),
            line=unresolved.line,
            column=unresolved.column,
          ),
        )
      None => ()
    }
    return Err(
      tikz_import_error(
        "reference",
        "unresolved arrow endpoint reference",
        line=unresolved.line,
        column=unresolved.column,
      ),
    )
  }

  Ok(quiver)
}

///|
fn tikz_has_share_reference_hint(input : String) -> Bool {
  if !tikz_has_wrapper_marker(input) {
    return false
  }

  match Quiver::extract_base64_share_reference(input) {
    Some(reference) => tikz_is_share_reference_candidate(reference)
    None => false
  }
}

///|
fn tikz_try_import_success(
  quiver : Quiver,
  macro_url : String?,
  renderer : String?,
  embed : Bool,
) -> TikzCdTryImportResult {
  { ok: true, quiver: Some(quiver), macro_url, renderer, embed, error: None }
}

///|
fn tikz_try_import_failure(
  kind : String,
  message : String,
) -> TikzCdTryImportResult {
  {
    ok: false,
    quiver: None,
    macro_url: None,
    renderer: None,
    embed: false,
    error: Some(tikz_import_error(kind, message)),
  }
}

///|
pub fn Quiver::try_import_tikz_cd_result(
  input : String,
  default_renderer? : String = "canvas",
) -> TikzCdTryImportResult {
  let looks_like_tikz = tikz_looks_like_environment(input)
  if looks_like_tikz {
    match tikz_validate_environment_and_options(input) {
      Some(validation_error) =>
        return {
          ok: false,
          quiver: None,
          macro_url: None,
          renderer: None,
          embed: false,
          error: Some(validation_error),
        }
      None => ()
    }

    if !tikz_has_share_reference_hint(input) {
      match Quiver::import_tikz_cd_minimal(input) {
        Ok(quiver) =>
          return tikz_try_import_success(
            quiver,
            None,
            None,
            false,
          )
        Err(import_error) =>
          return {
            ok: false,
            quiver: None,
            macro_url: None,
            renderer: None,
            embed: false,
            error: Some(import_error),
          }
      }
    }

    // Prefer wrapper import when a share reference is detected, but keep
    // handwritten diagrams robust when the wrapper marker is malformed.
    let imported : Result[Base64ShareImportResult, Error] = try? Quiver::import_base64_share_text(
      input,
      default_renderer~,
    )
    match imported {
      Ok(result) =>
        tikz_try_import_success(
          result.quiver,
          result.macro_url,
          result.renderer,
          result.embed,
        )
      Err(_) => {
        match Quiver::import_tikz_cd_minimal(input) {
          Ok(quiver) =>
            tikz_try_import_success(
              quiver,
              None,
              None,
              false,
            )
          Err(import_error) => {
            {
              ok: false,
              quiver: None,
              macro_url: None,
              renderer: None,
              embed: false,
              error: Some(import_error),
            }
          }
        }
      }
    }
  } else {
    let imported : Result[Base64ShareImportResult, Error] = try? Quiver::import_base64_share_text(
      input,
      default_renderer~,
    )
    match imported {
      Ok(result) =>
        tikz_try_import_success(
          result.quiver,
          result.macro_url,
          result.renderer,
          result.embed,
        )
      Err(error) =>
        tikz_try_import_failure(
          "share",
          error.to_string(),
        )
    }
  }
}
