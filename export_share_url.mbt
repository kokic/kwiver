fn export_is_url_unreserved(code : Int) -> Bool {
  let is_digit = code >= 48 && code <= 57
  let is_upper = code >= 65 && code <= 90
  let is_lower = code >= 97 && code <= 122
  is_digit || is_upper || is_lower || code == 45 || code == 46 || code == 95 || code == 126
}

fn export_hex_upper(n : Int) -> Char {
  if n < 10 {
    (48 + n).unsafe_to_char()
  } else {
    (55 + n).unsafe_to_char()
  }
}

fn export_percent_encode_component(value : String) -> String {
  let bytes = @utf8.encode(value)
  let out : Array[String] = []
  for byte in bytes {
    let code = byte.to_int()
    if export_is_url_unreserved(code) {
      out.push(code.unsafe_to_char().to_string())
    } else {
      out.push("%")
      out.push(export_hex_upper(code / 16).to_string())
      out.push(export_hex_upper(code % 16).to_string())
    }
  }
  out.join("")
}

fn export_share_link(
  payload : String,
  is_empty : Bool,
  share_base_url : String?,
  macro_url : String?,
) -> String {
  match share_base_url {
    Some(base_url) => {
      if is_empty {
        base_url
      } else {
        let macro_part = match macro_url {
          Some(value) => ["&macro_url=", export_percent_encode_component(value)].join("")
          None => ""
        }
        [base_url, "#q=", payload, macro_part].join("")
      }
    }
    None => payload
  }
}
