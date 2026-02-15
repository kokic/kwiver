pub struct FletcherExportSettings {
  centre_diagram : Bool
}

pub fn FletcherExportSettings::default() -> FletcherExportSettings {
  { centre_diagram: false }
}

pub fn FletcherExportSettings::with_centre_diagram(
  _self : FletcherExportSettings,
  value~ : Bool = true,
) -> FletcherExportSettings {
  { centre_diagram: value }
}

pub struct FletcherExportOptions {
  share_base_url : String?
  macro_url : String?
}

pub fn FletcherExportOptions::default() -> FletcherExportOptions {
  { share_base_url: None, macro_url: None }
}

pub fn FletcherExportOptions::with_share_base_url(
  self : FletcherExportOptions,
  base_url : String,
) -> FletcherExportOptions {
  { share_base_url: Some(base_url), macro_url: self.macro_url }
}

pub fn FletcherExportOptions::with_macro_url(
  self : FletcherExportOptions,
  macro_url : String,
) -> FletcherExportOptions {
  { share_base_url: self.share_base_url, macro_url: Some(macro_url) }
}

pub fn FletcherExportOptions::without_macro_url(
  self : FletcherExportOptions,
) -> FletcherExportOptions {
  { share_base_url: self.share_base_url, macro_url: None }
}

fn fletcher_coords(vertex : Vertex) -> String {
  ["(", vertex.x.to_string(), ", ", vertex.y.to_string(), ")"].join("")
}

fn fletcher_format_label(label : String) -> String {
  if label == "" {
    ""
  } else {
    ["[$", label, "$]"].join("")
  }
}

fn fletcher_arg_list(args : Array[String]) -> String {
  let effective : Array[String] = []
  for arg in args {
    if arg != "" {
      effective.push(arg)
    }
  }
  if effective.is_empty() {
    ""
  } else {
    [", ", effective.join(", ")].join("")
  }
}

fn fletcher_repeat(token : String, count : Int) -> String {
  if count <= 0 {
    return ""
  }
  let out : Array[String] = []
  for _ in 0..<count {
    out.push(token)
  }
  out.join("")
}

fn fletcher_round_to_int(x : Double) -> Int {
  if x >= 0.0 {
    @math.floor(x + 0.5).to_int()
  } else {
    -@math.floor(-x + 0.5).to_int()
  }
}

fn fletcher_colour_to_typst_hsl(colour : Colour) -> String {
  let saturation = fletcher_round_to_int(colour.s.to_double() * 2.55)
  let lightness = fletcher_round_to_int(colour.l.to_double() * 2.55)
  [
    "color.hsl(",
    colour.h.to_string(),
    "deg, ",
    saturation.to_string(),
    ", ",
    lightness.to_string(),
    ")",
  ].join("")
}

fn fletcher_int_sign(value : Int) -> Double {
  if value > 0 {
    1.0
  } else if value < 0 {
    -1.0
  } else {
    0.0
  }
}

fn fletcher_arrow_marks(edge : Edge) -> (String, Array[String]) {
  if edge.options.style.name != "arrow" {
    return ("-", [])
  }

  let mut marks = ""
  let extra_args : Array[String] = []

  match edge.options.style.tail.name {
    "maps to" => marks += "|"
    "mono" => marks += ">"
    "hook" => marks += if edge.options.style.tail.side == "top" { "hook" } else { "hook'" }
    "arrowhead" => marks += "<"
    _ => ()
  }

  match edge.options.style.body.name {
    "cell" => {
      let mut level = edge.options.level
      if level > 3 {
        level = 1
        extra_args.push("extrude: (-6,-2,2,6)")
        extra_args.push("mark-scale: 2")
      }
      marks += if level == 1 { "-" } else { fletcher_repeat("=", edge.options.level - 1) }
    }
    "dashed" => marks += "--"
    "dotted" => marks += ".."
    "squiggly" => marks += "~"
    "barred" => marks += "-|-"
    "double barred" => marks += "-||-"
    "bullet solid" => marks += "-@-"
    "bullet hollow" => marks += "-O-"
    "none" => marks += " "
    _ => marks += "-"
  }

  match edge.options.style.head.name {
    "none" => ()
    "arrowhead" => marks += ">"
    "epi" => marks += ">>"
    "harpoon" =>
      marks += if edge.options.style.head.side == "top" { "harpoon" } else { "harpoon'" }
    _ => ()
  }

  (marks, extra_args)
}

fn fletcher_wrap_output(
  quiver : Quiver,
  settings : FletcherExportSettings,
  options : FletcherExportOptions,
  lines : Array[String],
) -> String {
  let payload = quiver.export_base64_v0()
  let body = lines.join("\n")
  let diagram = if body == "" {
    "diagram({\n})"
  } else {
    ["diagram({\n", body, "\n})"].join("")
  }
  let wrapped = if settings.centre_diagram {
    ["align(center, ", diagram, ")"].join("")
  } else {
    diagram
  }
  [
    "// ",
    export_share_link(payload, quiver.is_empty(), options.share_base_url, options.macro_url),
    "\n#",
    wrapped,
  ].join("")
}

pub fn Quiver::export_fletcher(
  self : Quiver,
  settings~ : FletcherExportSettings = FletcherExportSettings::default(),
  options~ : FletcherExportOptions = FletcherExportOptions::default(),
) -> String {
  let vertices : Array[Vertex] = []
  let vertices_by_id : @hashmap.HashMap[Int, Vertex] = @hashmap.new()
  let edges : Array[Edge] = []

  for cell in self.all_cells() {
    match cell {
      CellData::Vertex(vertex) => {
        vertices.push(vertex)
        vertices_by_id.set(vertex.cell.id, vertex)
      }
      CellData::Edge(edge) => edges.push(edge)
    }
  }

  edges.sort_by((a, b) => {
    if a.cell.level != b.cell.level {
      a.cell.level - b.cell.level
    } else {
      a.cell.id - b.cell.id
    }
  })

  let lines : Array[String] = []

  for vertex in vertices {
    let label_arg = if vertex.cell.label != "" && vertex.cell.label_colour.is_not_black() {
      ["text(", fletcher_colour_to_typst_hsl(vertex.cell.label_colour), ")", fletcher_format_label(vertex.cell.label)].join("")
    } else {
      fletcher_format_label(vertex.cell.label)
    }
    lines.push(["\tnode(", fletcher_coords(vertex), fletcher_arg_list([label_arg]), ")"].join(""))
  }

  for edge in edges {
    if edge.cell.level > 1 {
      break
    }

    match (vertices_by_id.get(edge.source), vertices_by_id.get(edge.target)) {
      (Some(source), Some(target)) => {
        let args : Array[String] = [fletcher_format_label(edge.cell.label)]

        if edge.cell.label != "" {
          let label_side = match edge.options.label_alignment {
            LabelAlignment::Left => "left"
            LabelAlignment::Centre => "center"
            LabelAlignment::Right => "right"
            LabelAlignment::Over => "center"
          }

          match edge.options.label_alignment {
            LabelAlignment::Over => {
              args.push("label-fill: false")
              args.push("label-angle: right")
            }
            _ => ()
          }

          args.push(["label-side: ", label_side].join(""))

          if edge.options.label_position != 50 {
            args.push(["label-pos: ", (edge.options.label_position.to_double() / 100.0).to_string()].join(""))
          }
        }

        if edge.options.offset != 0 && edge.source != edge.target && edge.options.curve == 0 {
          args.push(["shift: ", (-edge.options.offset.to_double() / 20.0).to_string()].join(""))
        }

        let (arrow_marks, arrow_args) = fletcher_arrow_marks(edge)
        if arrow_marks != "-" {
          args.push(["\"", arrow_marks, "\""].join(""))
          for arrow_arg in arrow_args {
            args.push(arrow_arg)
          }
        }

        if edge.cell.label != "" && edge.cell.label_colour.is_not_black() {
          args[0] = ["text(", fletcher_colour_to_typst_hsl(edge.cell.label_colour), ")", args[0]].join("")
        }
        if edge.options.colour.is_not_black() {
          args.push(["stroke: ", fletcher_colour_to_typst_hsl(edge.options.colour)].join(""))
        }

        if edge.source == edge.target {
          let loop_bend = fletcher_int_sign(edge.options.radius) *
            ((Int::abs(edge.options.radius).to_double() - 1.0) * (150.0 - 130.0) / 4.0 + 130.0)
          args.push(["bend: ", loop_bend.to_string(), "deg"].join(""))
          args.push(["loop-angle: ", (90 - edge.options.angle).to_string(), "deg"].join(""))
        } else if edge.options.curve != 0 {
          args.push(["bend: ", (-edge.options.curve.to_double() * 90.0 / 5.0).to_string(), "deg"].join(""))
        }

        lines.push(
          [
            "\tedge(",
            fletcher_coords(source),
            ", ",
            fletcher_coords(target),
            fletcher_arg_list(args),
            ")",
          ].join(""),
        )
      }
      _ => ()
    }
  }

  fletcher_wrap_output(self, settings, options, lines)
}
