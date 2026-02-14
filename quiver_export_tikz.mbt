pub struct TikzCdExportSettings {
  centre_diagram : Bool
  ampersand_replacement : Bool
  cramped : Bool
  standalone : Bool
}

pub fn TikzCdExportSettings::default() -> TikzCdExportSettings {
  {
    centre_diagram: false,
    ampersand_replacement: false,
    cramped: false,
    standalone: false,
  }
}

pub fn TikzCdExportSettings::with_centre_diagram(
  self : TikzCdExportSettings,
  value~ : Bool = true,
) -> TikzCdExportSettings {
  {
    centre_diagram: value,
    ampersand_replacement: self.ampersand_replacement,
    cramped: self.cramped,
    standalone: self.standalone,
  }
}

pub fn TikzCdExportSettings::with_ampersand_replacement(
  self : TikzCdExportSettings,
  value~ : Bool = true,
) -> TikzCdExportSettings {
  {
    centre_diagram: self.centre_diagram,
    ampersand_replacement: value,
    cramped: self.cramped,
    standalone: self.standalone,
  }
}

pub fn TikzCdExportSettings::with_cramped(
  self : TikzCdExportSettings,
  value~ : Bool = true,
) -> TikzCdExportSettings {
  {
    centre_diagram: self.centre_diagram,
    ampersand_replacement: self.ampersand_replacement,
    cramped: value,
    standalone: self.standalone,
  }
}

pub fn TikzCdExportSettings::with_standalone(
  self : TikzCdExportSettings,
  value~ : Bool = true,
) -> TikzCdExportSettings {
  {
    centre_diagram: self.centre_diagram,
    ampersand_replacement: self.ampersand_replacement,
    cramped: self.cramped,
    standalone: value,
  }
}

fn tikz_coord_key(x : Int, y : Int) -> String {
  [x.to_string(), ",", y.to_string()].join("")
}

fn tikz_escape_label(label : String) -> String {
  label.replace_all(old="\"", new="\\\"")
}

fn tikz_begin_line(settings : TikzCdExportSettings) -> String {
  let options : Array[String] = []
  if settings.ampersand_replacement {
    options.push("ampersand replacement=\\&")
  }
  if settings.cramped {
    options.push("cramped")
  }

  if options.is_empty() {
    "\\begin{tikzcd}"
  } else {
    ["\\begin{tikzcd}[", options.join(","), "]"].join("")
  }
}

fn tikz_wrap_output(settings : TikzCdExportSettings, tikzcd : String) -> String {
  if settings.standalone {
    [
      "\\documentclass[tikz]{standalone}\n\\usepackage{quiver}\n\\begin{document}\n",
      tikzcd,
      "\n\\end{document}",
    ].join("")
  } else if settings.centre_diagram {
    ["\\[", tikzcd, "\\]"].join("")
  } else {
    tikzcd
  }
}

fn tikz_repeat(token : String, count : Int) -> String {
  if count <= 0 {
    return ""
  }
  let out : Array[String] = []
  for _ in 0..<count {
    out.push(token)
  }
  out.join("")
}

fn tikz_direction_option(source : Vertex, target : Vertex) -> String? {
  let dx = target.x - source.x
  let dy = target.y - source.y
  let parts : Array[String] = []

  if dy < 0 {
    parts.push(tikz_repeat("u", Int::abs(dy)))
  } else if dy > 0 {
    parts.push(tikz_repeat("d", dy))
  }

  if dx < 0 {
    parts.push(tikz_repeat("l", Int::abs(dx)))
  } else if dx > 0 {
    parts.push(tikz_repeat("r", dx))
  }

  let direction = parts.join("")
  if direction == "" { None } else { Some(direction) }
}

fn tikz_append_label_options(options : Array[String], edge : Edge) -> Unit {
  if edge.cell.label != "" {
    options.push(["\"", tikz_escape_label(edge.cell.label), "\""].join(""))

    match edge.options.label_alignment {
      LabelAlignment::Right => options.push("swap")
      LabelAlignment::Centre => options.push("description")
      LabelAlignment::Over => {
        options.push("marking")
        options.push("allow upside down")
      }
      LabelAlignment::Left => ()
    }

    if edge.options.label_position != 50 {
      options.push(
        ["pos=", (edge.options.label_position.to_double() / 100.0).to_string()].join(""),
      )
    }
  }
}

fn tikz_append_style_options(options : Array[String], edge : Edge) -> Unit {
  if edge.options.style.name != "arrow" {
    return
  }

  if edge.options.level == 2 {
    if edge.options.style.head.name == "none" {
      options.push("equals")
    } else {
      options.push("Rightarrow")
    }
  } else if edge.options.level > 2 {
    options.push("Rightarrow")
    options.push(["scaling nfold=", edge.options.level.to_string()].join(""))
  }

  match edge.options.style.body.name {
    "dashed" => options.push("dashed")
    "dotted" => options.push("dotted")
    "squiggly" => options.push("squiggly")
    "none" => options.push("no body")
    _ => ()
  }

  match edge.options.style.tail.name {
    "maps to" => options.push("maps to")
    "mono" => {
      if edge.options.level == 2 {
        options.push("2tail")
      } else {
        options.push("tail")
      }
    }
    "hook" => {
      let suffix = if edge.options.style.tail.side == "top" { "" } else { "'" }
      options.push(["hook", suffix].join(""))
    }
    "arrowhead" => {
      if edge.options.level == 2 {
        options.push("2tail reversed")
      } else {
        options.push("tail reversed")
      }
    }
    _ => ()
  }

  match edge.options.style.head.name {
    "none" => if edge.options.level != 2 { options.push("no head") }
    "epi" => options.push("two heads")
    "harpoon" => {
      let suffix = if edge.options.style.head.side == "top" { "" } else { "'" }
      options.push(["harpoon", suffix].join(""))
    }
    _ => ()
  }
}

fn tikz_append_geometry_options(options : Array[String], edge : Edge) -> Unit {
  if edge.options.offset != 0 {
    let side = if edge.options.offset > 0 { "right" } else { "left" }
    let abs_offset = Int::abs(edge.options.offset)
    if abs_offset == 1 {
      options.push(["shift ", side].join(""))
    } else {
      options.push(["shift ", side, "=", abs_offset.to_string()].join(""))
    }
  }

  if edge.options.curve != 0 {
    // Keep a compact fixed mapping in pt for minimum viable parity.
    let curve_height_pt = edge.options.curve.to_double() * 6.0
    options.push(["curve={height=", curve_height_pt.to_string(), "pt}"].join(""))
  }

  if edge.options.shorten.source != 0 || edge.options.shorten.target != 0 {
    let source = edge.options.shorten.source.to_double() / 100.0
    let target = (100 - edge.options.shorten.target).to_double() / 100.0
    options.push(["between={", source.to_string(), "}{", target.to_string(), "}"].join(""))
  }
}

pub fn Quiver::export_tikz_cd(
  self : Quiver,
  settings~ : TikzCdExportSettings = TikzCdExportSettings::default(),
) -> String {
  let vertices_by_id : @hashmap.HashMap[Int, Vertex] = @hashmap.new()
  let edges : Array[Edge] = []

  let mut has_vertex = false
  let mut min_x = 0
  let mut max_x = 0
  let mut min_y = 0
  let mut max_y = 0

  for cell in self.all_cells() {
    match cell {
      CellData::Vertex(vertex) => {
        vertices_by_id.set(vertex.cell.id, vertex)
        if !has_vertex {
          has_vertex = true
          min_x = vertex.x
          max_x = vertex.x
          min_y = vertex.y
          max_y = vertex.y
        } else {
          min_x = Int::min(min_x, vertex.x)
          max_x = Int::max(max_x, vertex.x)
          min_y = Int::min(min_y, vertex.y)
          max_y = Int::max(max_y, vertex.y)
        }
      }
      CellData::Edge(edge) => edges.push(edge)
    }
  }

  let begin_line = tikz_begin_line(settings)
  if !has_vertex {
    let empty = [begin_line, "\n\\end{tikzcd}"].join("")
    return tikz_wrap_output(settings, empty)
  }

  let vertex_id_by_coord : @hashmap.HashMap[String, Int] = @hashmap.new()
  vertices_by_id.each((id, vertex) => {
    vertex_id_by_coord.set(tikz_coord_key(vertex.x, vertex.y), id)
  })

  let outgoing_arrows : @hashmap.HashMap[Int, Array[String]] = @hashmap.new()
  for edge in edges {
    match (vertices_by_id.get(edge.source), vertices_by_id.get(edge.target)) {
      (Some(source), Some(target)) => {
        let source_row = source.y - min_y + 1
        let source_col = source.x - min_x + 1
        let target_row = target.y - min_y + 1
        let target_col = target.x - min_x + 1

        let arrow_options : Array[String] = []
        match tikz_direction_option(source, target) {
          Some(direction) => arrow_options.push(direction)
          None => {
            arrow_options.push(
              ["from=", source_row.to_string(), "-", source_col.to_string()].join(""),
            )
            arrow_options.push(
              ["to=", target_row.to_string(), "-", target_col.to_string()].join(""),
            )
          }
        }

        tikz_append_label_options(arrow_options, edge)
        tikz_append_geometry_options(arrow_options, edge)
        tikz_append_style_options(arrow_options, edge)

        let arrow = ["\\arrow[", arrow_options.join(", "), "]"].join("")
        let list = outgoing_arrows.get_or_init(edge.source, () => [])
        list.push(arrow)
      }
      _ => ()
    }
  }

  let column_separator = if settings.ampersand_replacement {
    " \\& "
  } else {
    " & "
  }
  let rows : Array[String] = []
  for y in min_y..=max_y {
    let columns : Array[String] = []
    for x in min_x..=max_x {
      let content = match vertex_id_by_coord.get(tikz_coord_key(x, y)) {
        Some(vertex_id) => {
          let label = match vertices_by_id.get(vertex_id) {
            Some(vertex) => vertex.cell.label
            None => ""
          }
          let arrows = match outgoing_arrows.get(vertex_id) {
            Some(list) => list
            None => []
          }
          let arrow_text = arrows.join(" ")
          if label == "" {
            arrow_text
          } else if arrow_text == "" {
            label
          } else {
            [label, " ", arrow_text].join("")
          }
        }
        None => ""
      }
      columns.push(content)
    }
    rows.push(columns.join(column_separator))
  }

  let body = rows.join(" \\\\\n")
  let tikzcd = [begin_line, "\n", body, "\n\\end{tikzcd}"].join("")
  tikz_wrap_output(settings, tikzcd)
}
