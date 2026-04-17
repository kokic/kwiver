///|
pub struct ArrowHeadRenderPartPlan {
  has_path : Bool
  d : String
  total_width : Double
}

///|
pub struct ArrowPathRenderPlan {
  d : String
  dash_array : String?
}

///|
pub struct ArrowCircleRenderPlan {
  cx : Double
  cy : Double
  r : Double
}

///|
pub struct ArrowBodyDecorationRenderPlan {
  kind : String
  path_d : String
  circle : ArrowCircleRenderPlan?
  mask_circle : ArrowCircleRenderPlan?
}

///|
pub struct ArrowRenderPlan {
  ok : Bool
  edge_valid : Bool
  angle : Double
  shift : Point
  svg_width : Double
  svg_height : Double
  offset : Point
  start : CurvePoint
  end : CurvePoint
  background : ArrowPathRenderPlan
  edge : ArrowPathRenderPlan
  clipping_path : ArrowPathRenderPlan
  decoration : ArrowBodyDecorationRenderPlan
  tail : ArrowHeadRenderPartPlan
  tail_mask : ArrowHeadRenderPartPlan
  head : ArrowHeadRenderPartPlan
  head_mask : ArrowHeadRenderPartPlan
}

///|
const ARROW_RENDER_LINE_SPACING : Double = 4.5

///|
const ARROW_RENDER_STROKE_WIDTH : Double = 1.5

///|
const ARROW_RENDER_BACKGROUND_PADDING : Double = 16.0

///|
const ARROW_RENDER_MASK_PADDING : Double = 4.0

///|
const ARROW_RENDER_HEAD_SPACING : Double = 2.0

///|
const ARROW_RENDER_SQUIGGLY_PADDING : Double = 4.0

///|
const ARROW_RENDER_SQUIGGLY_TRIANGLE_HEIGHT : Double = 2.0

///|
const ARROW_RENDER_ADJUNCTION_LINE_LENGTH : Double = 16.0

///|
const ARROW_RENDER_CORNER_LENGTH : Double = 12.0

///|
const ARROW_RENDER_ENDPOINT_PADDING : Double = 1.0

///|
const ARROW_RENDER_ARC_OUTER_DIS : Double = 96.0

///|
const ARROW_RENDER_ARC_INNER_DIS : Double = 64.0

///|
const ARROW_RENDER_SQRT_2 : Double = 1.4142135623730951

///|
priv enum ArrowRenderCurveData {
  Bezier(Bezier)
  Arc(Arc)
}

///|
priv struct ArrowHeadRenderContext {
  curve : ArrowRenderCurveData
  stroke_width : Double
  head_width : Double
  head_height : Double
  shorten_start : Double
  shorten_end : Double
  shorten_tail : Double
  shorten_head : Double
  dash_padding_start : Double
  dash_padding_end : Double
  offset : Point
  level : Int
  direction_angle : Double
}

///|
fn arrow_render_zero_point() -> Point {
  Point::new(0.0, 0.0)
}

///|
fn arrow_render_zero_curve_point() -> CurvePoint {
  CurvePoint::new(arrow_render_zero_point(), 0.0, 0.0)
}

///|
fn arrow_render_max(left : Double, right : Double) -> Double {
  if left > right {
    left
  } else {
    right
  }
}

///|
fn arrow_render_clamp(minimum : Double, value : Double, maximum : Double) -> Double {
  if value < minimum {
    minimum
  } else if value > maximum {
    maximum
  } else {
    value
  }
}

///|
fn arrow_render_rad_to_deg(rad : Double) -> Double {
  rad * 180.0 / @math.PI
}

///|
fn arrow_render_bool_digit(value : Bool) -> String {
  if value {
    "1"
  } else {
    "0"
  }
}

///|
fn arrow_render_curve(
  shape_is_arc : Bool,
  is_loop : Bool,
  length : Double,
  curve : Double,
  loop_angle : Double,
) -> ArrowRenderCurveData {
  if !shape_is_arc {
    ArrowRenderCurveData::Bezier(Bezier::new(arrow_render_zero_point(), length, curve, 0.0))
  } else if is_loop {
    ArrowRenderCurveData::Arc(Arc::new(arrow_render_zero_point(), length, true, curve, loop_angle))
  } else {
    ArrowRenderCurveData::Arc(arrow_render_arc_for_chord(length, curve))
  }
}

///|
fn arrow_render_arc_for_chord(chord : Double, loop_radius : Double) -> Arc {
  let semicircle_radius = ARROW_RENDER_ARC_INNER_DIS / 2.0
  let boundary_dis = ARROW_RENDER_ARC_OUTER_DIS - ARROW_RENDER_ARC_INNER_DIS
  let sagitta = if chord >= ARROW_RENDER_ARC_OUTER_DIS {
    EPSILON
  } else {
    semicircle_radius * ((ARROW_RENDER_ARC_OUTER_DIS - chord) / boundary_dis)
  }
  let r_for_sagitta = sagitta / 2.0 + chord * chord / (8.0 * sagitta)
  let r = if chord <= ARROW_RENDER_ARC_INNER_DIS {
    semicircle_radius +
    (ARROW_RENDER_ARC_INNER_DIS - chord) / ARROW_RENDER_ARC_INNER_DIS *
    (loop_radius - semicircle_radius)
  } else {
    r_for_sagitta
  }
  Arc::new(arrow_render_zero_point(), chord, chord <= ARROW_RENDER_ARC_INNER_DIS, r, 0.0)
}

///|
fn arrow_render_curve_point(curve : ArrowRenderCurveData, t : Double) -> Point {
  match curve {
    ArrowRenderCurveData::Bezier(bezier) => bezier.point(t)
    ArrowRenderCurveData::Arc(arc) => arc.point(t)
  }
}

///|
fn arrow_render_curve_tangent(curve : ArrowRenderCurveData, t : Double) -> Double {
  match curve {
    ArrowRenderCurveData::Bezier(bezier) => bezier.tangent(t)
    ArrowRenderCurveData::Arc(arc) => arc.tangent(t)
  }
}

///|
fn arrow_render_curve_arc_length(curve : ArrowRenderCurveData, t : Double) -> Double {
  match curve {
    ArrowRenderCurveData::Bezier(bezier) => bezier.arc_length(t)
    ArrowRenderCurveData::Arc(arc) => arc.arc_length(t)
  }
}

///|
fn arrow_render_curve_t_after_length(
  curve : ArrowRenderCurveData,
  length : Double,
) -> Double {
  match curve {
    ArrowRenderCurveData::Bezier(bezier) => bezier.t_after_length(clamp=true)(length)
    ArrowRenderCurveData::Arc(arc) => arc.t_after_length(clamp=true)(length)
  }
}

///|
fn arrow_render_curve_height(curve : ArrowRenderCurveData) -> Double {
  match curve {
    ArrowRenderCurveData::Bezier(bezier) => bezier.height()
    ArrowRenderCurveData::Arc(arc) => arc.height()
  }
}

///|
fn arrow_render_curve_width(curve : ArrowRenderCurveData) -> Double {
  match curve {
    ArrowRenderCurveData::Bezier(bezier) => bezier.width()
    ArrowRenderCurveData::Arc(arc) => arc.width()
  }
}

///|
fn arrow_render_part_none(total_width? : Double = 0.0) -> ArrowHeadRenderPartPlan {
  { has_path: false, d: "", total_width }
}

///|
fn arrow_render_path_none() -> ArrowPathRenderPlan {
  { d: "", dash_array: None }
}

///|
fn arrow_render_path_plan(
  d : String,
  dash_array? : String? = None,
) -> ArrowPathRenderPlan {
  { d, dash_array }
}

///|
fn arrow_render_circle_plan(point : Point, radius : Double) -> ArrowCircleRenderPlan {
  { cx: point.x, cy: point.y, r: radius }
}

///|
fn arrow_render_decoration_none() -> ArrowBodyDecorationRenderPlan {
  { kind: "none", path_d: "", circle: None, mask_circle: None }
}

///|
fn arrow_render_commands_to_part(
  commands : Array[String],
  total_width : Double,
) -> ArrowHeadRenderPartPlan {
  if commands.is_empty() {
    arrow_render_part_none(total_width=total_width)
  } else {
    { has_path: true, d: commands.join("\n"), total_width }
  }
}

///|
fn arrow_render_commands_to_path_plan(
  commands : Array[String],
  dash_array? : String? = None,
) -> ArrowPathRenderPlan {
  if commands.is_empty() {
    arrow_render_path_none()
  } else {
    arrow_render_path_plan(commands.join("\n"), dash_array~)
  }
}

///|
fn arrow_render_move_to(commands : Array[String], point : Point) -> Unit {
  commands.push(["M", point.x.to_string(), point.y.to_string()].join(" "))
}

///|
fn arrow_render_line_to(commands : Array[String], point : Point) -> Unit {
  if point.x == 0.0 {
    commands.push(["V", point.y.to_string()].join(" "))
  } else if point.y == 0.0 {
    commands.push(["H", point.x.to_string()].join(" "))
  } else {
    commands.push(["L", point.x.to_string(), point.y.to_string()].join(" "))
  }
}

///|
fn arrow_render_line_by(commands : Array[String], point : Point) -> Unit {
  if point.x == 0.0 {
    commands.push(["v", point.y.to_string()].join(" "))
  } else if point.y == 0.0 {
    commands.push(["h", point.x.to_string()].join(" "))
  } else {
    commands.push(["l", point.x.to_string(), point.y.to_string()].join(" "))
  }
}

///|
fn arrow_render_curve_by(
  commands : Array[String],
  control : Point,
  next : Point,
) -> Unit {
  commands.push(
    [
      "q",
      control.x.to_string(),
      control.y.to_string(),
      next.x.to_string(),
      next.y.to_string(),
    ]
    .join(" "),
  )
}

///|
fn arrow_render_arc_by(
  commands : Array[String],
  radius : Point,
  angle : Double,
  large_arc : Bool,
  clockwise : Bool,
  next : Point,
) -> Unit {
  commands.push(
    [
      "a",
      Double::abs(radius.x).to_string(),
      Double::abs(radius.y).to_string(),
      arrow_render_rad_to_deg(angle).to_string(),
      arrow_render_bool_digit(large_arc),
      arrow_render_bool_digit(clockwise),
      next.x.to_string(),
      next.y.to_string(),
    ]
    .join(" "),
  )
}

///|
fn arrow_render_curve_path(commands : Array[String], curve : ArrowRenderCurveData, offset : Point) -> Unit {
  arrow_render_move_to(commands, offset)
  match curve {
    ArrowRenderCurveData::Bezier(bezier) => arrow_render_curve_by(
      commands,
      Point::new(bezier.w / 2.0, bezier.h),
      Point::new(bezier.w, 0.0),
    )
    ArrowRenderCurveData::Arc(arc) => {
      if !arc.major && Double::abs(arc.sagitta) <= 1.0 {
        arrow_render_line_by(commands, Point::new(arc.chord, 0.0))
      } else {
        let radius = Double::abs(arc.radius)
        arrow_render_arc_by(
          commands,
          Point::new(radius, radius),
          0.0,
          arc.major,
          arc.radius >= 0.0,
          Point::new(arc.chord, 0.0),
        )
      }
    }
  }
}

///|
fn arrow_render_string_array(values : Array[Double]) -> String {
  let parts : Array[String] = []
  for value in values {
    parts.push(value.to_string())
  }
  parts.join(" ")
}

///|
fn arrow_render_dash_array(
  arclen_to_start : Double,
  dashes : Array[Double],
  arclen_to_end : Double,
  arclen : Double,
) -> String {
  [
    "0",
    arclen_to_start.to_string(),
    arrow_render_string_array(dashes),
    (arclen - arclen_to_end).to_string(),
  ]
  .join(" ")
}

///|
fn arrow_render_style_contains(styles : Array[String], target : String) -> Bool {
  for style in styles {
    if style == target {
      return true
    }
  }
  false
}

///|
fn arrow_render_styles_have_hook(styles : Array[String]) -> Bool {
  if styles.is_empty() {
    false
  } else {
    styles[0].has_prefix("hook")
  }
}

///|
fn arrow_render_head_margins(style : String, head_width : Double) -> (Double, Double, Double) {
  match style {
    "epi" => (0.0, head_width, 0.0)
    "corner" => (0.0, head_width, 0.0)
    "corner-inverse" => (0.0, head_width, 0.0)
    "mono" => (0.0, head_width, head_width)
    "maps to" => (head_width / 2.0, head_width / 2.0, 0.0)
    _ => (0.0, 0.0, 0.0)
  }
}

///|
fn arrow_render_adjust_dash_padding(
  curve : ArrowRenderCurveData,
  styles : Array[String],
  endpoint : CurvePoint,
  is_start : Bool,
  head_width : Double,
  edge_width : Double,
) -> Double {
  if styles.is_empty() || styles[0] != "mono" {
    return 0.0
  }

  let arclen_to_endpoint = arrow_render_curve_arc_length(curve, endpoint.t)
  let head_direction = if is_start { 1.0 } else { -1.0 }
  let head_angle = arrow_render_curve_tangent(
    curve,
    arrow_render_curve_t_after_length(
      curve,
      arclen_to_endpoint + head_width * head_direction,
    ),
  )
  let endpoint_angle = arrow_render_curve_tangent(curve, endpoint.t)
  let diff_angle = endpoint_angle - head_angle
  Double::abs(edge_width * @math.sin(diff_angle) / 2.0)
}

///|
fn arrow_render_draw_epi_like(
  commands : Array[String],
  context : ArrowHeadRenderContext,
  point : Point,
  angle : Double,
  start_sign : Double,
  end_ind : Bool,
  is_mask : Bool,
  is_start : Bool,
  head_style : String,
) -> Unit {
  for pair in [(-1.0, end_ind), (1.0, !end_ind)] {
    let (side_sign, side_ind) = pair
    arrow_render_move_to(commands, point)
    arrow_render_arc_by(
      commands,
      Point::new(start_sign * context.head_width, context.head_height / 2.0),
      angle,
      false,
      side_ind,
      Point::new(start_sign * context.head_width, side_sign * context.head_height / 2.0)
      .rotate(angle),
    )
    if is_mask {
      let distance = match head_style {
        "epi" => -start_sign * (context.head_width + ARROW_RENDER_MASK_PADDING)
        "mono" => {
          let padding = if is_start {
            context.dash_padding_start
          } else {
            context.dash_padding_end
          }
          start_sign * (ARROW_RENDER_MASK_PADDING + padding * 2.0)
        }
        _ => 0.0
      }
      arrow_render_line_by(commands, Point::lendir(distance, angle))
      arrow_render_line_by(
        commands,
        Point::new(0.0, -side_sign * context.head_height / 2.0).rotate(angle),
      )
    }
  }
}

///|
fn arrow_render_draw_corner(
  commands : Array[String],
  context : ArrowHeadRenderContext,
  point : Point,
  arclen_to_head : Double,
  start_sign : Double,
  end_ind : Bool,
  is_inverse : Bool,
) -> Unit {
  let base_shift = if is_inverse {
    0.0
  } else {
    ARROW_RENDER_CORNER_LENGTH / ARROW_RENDER_SQRT_2 * start_sign
  }
  let base_point = arrow_render_curve_point(
    context.curve,
    arrow_render_curve_t_after_length(context.curve, arclen_to_head + base_shift),
  )
  .add(context.offset)
  let pi_4 = @math.PI / 4.0
  let end_rotation = if end_ind { 1.0 } else { 0.0 }
  let corner_angle = (if is_inverse { 0.0 } else { @math.PI }) +
    pi_4 * @math.round(4.0 * context.direction_angle / @math.PI) -
    context.direction_angle
  for side_sign in [-1.0, 1.0] {
    arrow_render_move_to(commands, if is_inverse { point } else { base_point })
    arrow_render_line_by(
      commands,
      Point::lendir(
        ARROW_RENDER_CORNER_LENGTH,
        corner_angle + @math.PI * end_rotation + side_sign * @math.PI / 4.0,
      ),
    )
  }
}

///|
fn arrow_render_heads(
  context : ArrowHeadRenderContext,
  styles : Array[String],
  endpoint : CurvePoint,
  is_start : Bool,
  is_mask : Bool,
) -> ArrowHeadRenderPartPlan {
  if styles.is_empty() {
    return arrow_render_part_none()
  }

  let start_sign = if is_start { 1.0 } else { -1.0 }
  let end_ind = !is_start
  let commands : Array[String] = []
  let mut total_width = 0.0
  let arclen_to_endpoint = arrow_render_curve_arc_length(context.curve, endpoint.t) +
    (if is_start {
      context.shorten_start + context.shorten_tail
    } else {
      context.shorten_end + context.shorten_head
    }) *
    start_sign

  if arrow_render_style_contains(styles, "harpoon-top") ||
    arrow_render_style_contains(styles, "harpoon-bottom") {
    let edge_bottom = context.stroke_width + ARROW_RENDER_LINE_SPACING
    let side_sign = if arrow_render_style_contains(styles, "harpoon-top") {
      1.0
    } else {
      -1.0
    }
    let t = arrow_render_curve_t_after_length(context.curve, arclen_to_endpoint)
    let angle = arrow_render_curve_tangent(context.curve, t)
    let point = arrow_render_curve_point(context.curve, t)
    .add(context.offset)
    .add(
      Point::new(
        0.0,
        side_sign * context.stroke_width / 2.0 -
        side_sign * ARROW_RENDER_STROKE_WIDTH / 2.0,
      )
      .rotate(angle),
    )
    arrow_render_move_to(commands, point)
    arrow_render_arc_by(
      commands,
      Point::new(start_sign * context.head_width, edge_bottom),
      angle,
      false,
      if side_sign == 1.0 { end_ind } else { !end_ind },
      Point::new(start_sign * context.head_width, -edge_bottom * side_sign).rotate(angle),
    )
    total_width = context.head_width
    if is_mask {
      arrow_render_line_by(
        commands,
        Point::lendir(-start_sign * (context.head_width + ARROW_RENDER_MASK_PADDING), angle),
      )
      arrow_render_line_by(
        commands,
        Point::new(0.0, edge_bottom * side_sign).rotate(angle),
      )
    }
    return arrow_render_commands_to_part(commands, total_width)
  }

  if arrow_render_style_contains(styles, "hook-top") ||
    arrow_render_style_contains(styles, "hook-bottom") {
    if is_mask {
      return arrow_render_part_none()
    }

    let t = arrow_render_curve_t_after_length(context.curve, arclen_to_endpoint)
    let base_point = arrow_render_curve_point(context.curve, t)
    let angle = arrow_render_curve_tangent(context.curve, t)
    let side_sign = if arrow_render_style_contains(styles, "hook-top") {
      -1.0
    } else {
      1.0
    }
    let mask_adjustment = 0.5
    for i in 0..<context.level {
      let point = base_point
      .add(context.offset)
      .add(
        Point::new(
          mask_adjustment,
          side_sign * context.stroke_width / 2.0 -
          side_sign * ARROW_RENDER_STROKE_WIDTH / 2.0 -
          side_sign * (ARROW_RENDER_LINE_SPACING + ARROW_RENDER_STROKE_WIDTH) *
          i.to_double(),
        )
        .rotate(angle),
      )
      arrow_render_move_to(commands, point)
      arrow_render_arc_by(
        commands,
        Point::new(start_sign * context.head_width, context.head_width),
        angle,
        false,
        if side_sign == 1.0 { end_ind } else { !end_ind },
        Point::new(0.0, side_sign * context.head_width * 2.0).rotate(angle),
      )
    }
    return arrow_render_commands_to_part(commands, total_width)
  }

  let arclens_to_head : Array[Double] = []
  let mut prev_margin = 0.0
  let mut heads_arclen = 0.0
  for i in 0..<styles.length() {
    let (margin_left, margin_right, margin_begin) = arrow_render_head_margins(
      styles[i],
      context.head_width,
    )
    if i == 0 {
      heads_arclen += margin_begin
    } else {
      let collapse = if styles[i] == styles[i - 1] { 2.0 } else { 1.0 }
      heads_arclen += (prev_margin + margin_right) / collapse + ARROW_RENDER_HEAD_SPACING
    }
    prev_margin = margin_left
    arclens_to_head.push(heads_arclen)
    total_width = heads_arclen + margin_left
  }

  let mut index = styles.length()
  while index > 0 {
    let i = index - 1
    if !is_mask || i == 0 {
      let head_style = styles[i]
      let arclen_to_head = arclen_to_endpoint + arclens_to_head[i] * start_sign
      let t = arrow_render_curve_t_after_length(context.curve, arclen_to_head)
      let point = arrow_render_curve_point(context.curve, t).add(context.offset)
      let angle = arrow_render_curve_tangent(context.curve, t)

      match head_style {
        "mono" => arrow_render_draw_epi_like(
          commands,
          context,
          point,
          angle + @math.PI,
          start_sign,
          end_ind,
          is_mask,
          is_start,
          "mono",
        )
        "epi" => arrow_render_draw_epi_like(
          commands,
          context,
          point,
          angle,
          start_sign,
          end_ind,
          is_mask,
          is_start,
          "epi",
        )
        "corner" => arrow_render_draw_corner(
          commands,
          context,
          point,
          arclen_to_head,
          start_sign,
          end_ind,
          false,
        )
        "corner-inverse" => arrow_render_draw_corner(
          commands,
          context,
          point,
          arclen_to_head,
          start_sign,
          end_ind,
          true,
        )
        "maps to" => {
          arrow_render_move_to(
            commands,
            point.add(Point::lendir(context.head_height / 2.0, angle + @math.PI / 2.0)),
          )
          arrow_render_line_by(
            commands,
            Point::lendir(context.head_height, angle - @math.PI / 2.0),
          )
        }
        _ => ()
      }
    }
    index = i
  }

  arrow_render_commands_to_part(commands, total_width)
}

///|
fn arrow_render_body_decoration(
  curve : ArrowRenderCurveData,
  start : CurvePoint,
  end : CurvePoint,
  shorten_tail : Double,
  shorten_head : Double,
  head_height : Double,
  offset : Point,
  body_style : String,
) -> ArrowBodyDecorationRenderPlan {
  let arclen_to_start = arrow_render_curve_arc_length(curve, start.t)
  let arclen_to_end = arrow_render_curve_arc_length(curve, end.t)
  let start_t = arrow_render_max(
    start.t,
    arrow_render_curve_t_after_length(curve, arclen_to_start + shorten_tail),
  )
  let end_t_raw = arrow_render_curve_t_after_length(curve, arclen_to_end - shorten_head)
  let end_t = if end_t_raw < end.t { end_t_raw } else { end.t }
  let mid = (start_t + end_t) / 2.0

  match body_style {
    "double proarrow" => {
      let commands : Array[String] = []
      let arclen_to_mid = arrow_render_curve_arc_length(curve, mid)
      let angle = arrow_render_curve_tangent(curve, mid)
      let normal = angle + @math.PI / 2.0
      let adj_seg = Point::new(head_height, 0.0)
      let adj_seg_2 = adj_seg.div(2.0)
      for bar_offset in [-2.5, 2.5] {
        let bar_t = arrow_render_curve_t_after_length(
          curve,
          arrow_render_clamp(arclen_to_start, arclen_to_mid + bar_offset, arclen_to_end),
        )
        let centre = arrow_render_curve_point(curve, bar_t).add(offset)
        arrow_render_move_to(commands, centre.sub(adj_seg_2.rotate(normal)))
        arrow_render_line_by(commands, adj_seg.rotate(normal))
      }
      {
        kind: "path",
        path_d: commands.join("\n"),
        circle: None,
        mask_circle: None,
      }
    }
    "proarrow" => {
      let commands : Array[String] = []
      let arclen_to_mid = arrow_render_curve_arc_length(curve, mid)
      let angle = arrow_render_curve_tangent(curve, mid)
      let normal = angle + @math.PI / 2.0
      let adj_seg = Point::new(head_height, 0.0)
      let adj_seg_2 = adj_seg.div(2.0)
      let bar_t = arrow_render_curve_t_after_length(
        curve,
        arrow_render_clamp(arclen_to_start, arclen_to_mid, arclen_to_end),
      )
      let centre = arrow_render_curve_point(curve, bar_t).add(offset)
      arrow_render_move_to(commands, centre.sub(adj_seg_2.rotate(normal)))
      arrow_render_line_by(commands, adj_seg.rotate(normal))
      {
        kind: "path",
        path_d: commands.join("\n"),
        circle: None,
        mask_circle: None,
      }
    }
    "bullet solid" => {
      let centre = arrow_render_curve_point(curve, mid).add(offset)
      {
        kind: "solid-circle",
        path_d: "",
        circle: Some(arrow_render_circle_plan(centre, head_height / 2.0)),
        mask_circle: None,
      }
    }
    "bullet hollow" => {
      let centre = arrow_render_curve_point(curve, mid).add(offset)
      let circle = arrow_render_circle_plan(centre, head_height / 2.0)
      {
        kind: "hollow-circle",
        path_d: "",
        circle: Some(circle),
        mask_circle: Some(circle),
      }
    }
    _ => arrow_render_decoration_none()
  }
}

///|
fn arrow_render_edge_path(
  curve : ArrowRenderCurveData,
  start : CurvePoint,
  end : CurvePoint,
  offset : Point,
  body_style : String,
  dash_style : String,
  level : Int,
  shorten_start : Double,
  shorten_end : Double,
  shorten_tail : Double,
  shorten_head : Double,
  dash_padding_start : Double,
  dash_padding_end : Double,
  total_width_of_tails : Double,
  total_width_of_heads : Double,
) -> ArrowPathRenderPlan {
  let mut arclen_to_start = arrow_render_curve_arc_length(curve, start.t) +
    (shorten_tail + shorten_start) - dash_padding_start
  let mut arclen_to_end = arrow_render_curve_arc_length(curve, end.t) -
    (shorten_head + shorten_end) + dash_padding_end
  let mut arclen = arrow_render_curve_arc_length(curve, 1.0)
  let half_wavelength = ARROW_RENDER_SQUIGGLY_TRIANGLE_HEIGHT * 2.0
  let commands : Array[String] = []

  match body_style {
    "line" => arrow_render_curve_path(commands, curve, offset)
    "proarrow" => arrow_render_curve_path(commands, curve, offset)
    "double proarrow" => arrow_render_curve_path(commands, curve, offset)
    "bullet solid" => arrow_render_curve_path(commands, curve, offset)
    "bullet hollow" => arrow_render_curve_path(commands, curve, offset)
    "adjunction" => {
      let centre = arrow_render_curve_point(curve, 0.5).add(offset)
      let angle = arrow_render_curve_tangent(curve, 0.5)
      let normal = angle + @math.PI / 2.0
      let adj_seg = Point::new(ARROW_RENDER_ADJUNCTION_LINE_LENGTH, 0.0)
      let adj_seg_2 = adj_seg.div(2.0)
      arrow_render_move_to(commands, centre.sub(adj_seg_2.rotate(angle)))
      arrow_render_line_by(commands, adj_seg.rotate(angle))
      arrow_render_move_to(
        commands,
        centre.add(adj_seg_2.rotate(angle)).sub(adj_seg_2.rotate(normal)),
      )
      arrow_render_line_by(commands, adj_seg.rotate(normal))
    }
    "squiggly" => {
      let arclen_to_squiggle_start =
        arclen_to_start + total_width_of_tails + ARROW_RENDER_SQUIGGLY_PADDING
      let squiggle_start_point = arrow_render_curve_point(
        curve,
        arrow_render_curve_t_after_length(curve, arclen_to_squiggle_start),
      )
      let arclen_to_squiggle_end =
        arclen_to_end - (total_width_of_heads + ARROW_RENDER_SQUIGGLY_PADDING)
      let start_point = arrow_render_curve_point(
        curve,
        arrow_render_curve_t_after_length(curve, arclen_to_start),
      )
      let end_point = arrow_render_curve_point(
        curve,
        arrow_render_curve_t_after_length(curve, arclen_to_end),
      )

      arrow_render_move_to(commands, start_point.add(offset))
      arrow_render_line_to(commands, squiggle_start_point.add(offset))

      let mut path_len = squiggle_start_point.sub(start_point).length()
      let mut prev_point = squiggle_start_point
      let mut l = arclen_to_squiggle_start
      let mut sign = -1.0
      let mut amplitude = 1

      while l + amplitude.to_double() * half_wavelength / 2.0 < arclen_to_squiggle_end {
        l += half_wavelength / 2.0
        let t = arrow_render_curve_t_after_length(curve, l)
        let angle = arrow_render_curve_tangent(curve, t) + @math.PI / 2.0 * sign
        let next_point = arrow_render_curve_point(curve, t).add(
          Point::lendir(ARROW_RENDER_SQUIGGLY_TRIANGLE_HEIGHT * amplitude.to_double(), angle),
        )
        path_len += next_point.sub(prev_point).length()
        prev_point = next_point
        arrow_render_line_to(commands, next_point.add(offset))
        if amplitude == 1 {
          sign = -sign
          amplitude = 0
        } else {
          amplitude = 1
        }
      }

      arrow_render_line_to(commands, end_point.add(offset))
      path_len += end_point.sub(prev_point).length()
      arclen_to_start = 0.0
      arclen_to_end = path_len + dash_padding_start
      arclen = path_len + dash_padding_start + dash_padding_end
    }
    _ => ()
  }

  if body_style == "none" || body_style == "adjunction" {
    return arrow_render_commands_to_path_plan(commands)
  }

  let mut arclen_line = arclen_to_end - arclen_to_start
  let mut dashes : Array[Double] = [arclen_line]

  if dash_style != "solid" {
    match body_style {
      "squiggly" => {
        if level == 1 {
          let dash_offset = 4.0
          dashes = [total_width_of_tails + dash_offset, 0.0]
          arclen_line -= total_width_of_tails + total_width_of_heads - dash_offset
        }
      }
      "line" => dashes = []
      "proarrow" => dashes = []
      "double proarrow" => dashes = []
      "bullet solid" => dashes = []
      "bullet hollow" => dashes = []
      _ => ()
    }

    if body_style == "squiggly" && level > 1 {
      dashes = [arclen_line]
    } else if body_style == "line" || body_style == "proarrow" ||
      body_style == "double proarrow" || body_style == "bullet solid" ||
      body_style == "bullet hollow" || body_style == "squiggly" {
      if arclen_line > 0.0 {
        let triangle_side = half_wavelength * ARROW_RENDER_SQRT_2
        let dash_pairs = if body_style != "squiggly" {
          if dash_style == "dashed" {
            [6.0, 6.0]
          } else {
            [2.0, 4.0]
          }
        } else if dash_style == "dashed" {
          [2.0 * triangle_side, 1.0 * triangle_side]
        } else {
          [0.5 * triangle_side, 0.25 * triangle_side]
        }
        let mut dash_gap_length = 0.0
        for part in dash_pairs {
          dash_gap_length += part
        }
        let dashes_and_gaps = arclen_line / dash_gap_length
        let whole_pairs = @math.floor(dashes_and_gaps).to_int()
        dashes = dashes
        for _ in 0..<whole_pairs {
          for part in dash_pairs {
            dashes.push(part)
          }
        }
        if dashes_and_gaps > whole_pairs.to_double() {
          let mut deficit = arclen_line - whole_pairs.to_double() * dash_gap_length
          for part in dash_pairs {
            if part <= deficit {
              dashes.push(part)
              deficit -= part
            } else {
              break
            }
          }
          dashes.push(deficit)
        }
        if dashes.length() % 2 != 1 {
          dashes.push(0.0)
        }
      } else {
        dashes = [arclen_line]
      }

      if body_style == "squiggly" {
        dashes.push(0.0)
        dashes.push(total_width_of_heads)
      }
    }
  }

  arrow_render_commands_to_path_plan(
    commands,
    dash_array=Some(
      arrow_render_dash_array(arclen_to_start, dashes, arclen_to_end, arclen),
    ),
  )
}

///|
fn arrow_render_background_path(
  curve : ArrowRenderCurveData,
  offset : Point,
  arclen_to_start : Double,
  arclen_to_end : Double,
  arclen : Double,
) -> ArrowPathRenderPlan {
  let commands : Array[String] = []
  arrow_render_curve_path(commands, curve, offset)
  arrow_render_commands_to_path_plan(
    commands,
    dash_array=Some(
      [
        "0",
        arclen_to_start.to_string(),
        (arclen_to_end - arclen_to_start).to_string(),
        @math.ceil(arclen - arclen_to_end).to_string(),
      ]
      .join(" "),
    ),
  )
}

///|
fn arrow_render_clipping_path(
  curve : ArrowRenderCurveData,
  offset : Point,
  arclen_to_start : Double,
  arclen_to_end : Double,
  arclen : Double,
  shorten_start : Double,
  shorten_end : Double,
  shorten_tail : Double,
  shorten_head : Double,
) -> ArrowPathRenderPlan {
  let commands : Array[String] = []
  arrow_render_curve_path(commands, curve, offset)
  arrow_render_commands_to_path_plan(
    commands,
    dash_array=Some(
      [
        (arclen_to_start + shorten_tail + shorten_start + ARROW_RENDER_ENDPOINT_PADDING)
        .to_string(),
        (
          arclen_to_end -
          (
            arclen_to_start +
            shorten_start +
            shorten_tail +
            ARROW_RENDER_ENDPOINT_PADDING * 2.0 +
            shorten_head +
            shorten_end
          )
        )
        .to_string(),
        (
          arclen - arclen_to_end + shorten_head + shorten_end +
          ARROW_RENDER_ENDPOINT_PADDING
        )
        .to_string(),
      ]
      .join(" "),
    ),
  )
}

///|
pub fn arrow_render_plan_invalid() -> ArrowRenderPlan {
  {
    ok: false,
    edge_valid: false,
    angle: 0.0,
    shift: arrow_render_zero_point(),
    svg_width: 0.0,
    svg_height: 0.0,
    offset: arrow_render_zero_point(),
    start: arrow_render_zero_curve_point(),
    end: arrow_render_zero_curve_point(),
    background: arrow_render_path_none(),
    edge: arrow_render_path_none(),
    clipping_path: arrow_render_path_none(),
    decoration: arrow_render_decoration_none(),
    tail: arrow_render_part_none(),
    tail_mask: arrow_render_part_none(),
    head: arrow_render_part_none(),
    head_mask: arrow_render_part_none(),
  }
}

///|
pub fn arrow_render_plan_local(
  shape_is_arc : Bool,
  is_loop : Bool,
  length : Double,
  curve : Double,
  loop_angle : Double,
  start : CurvePoint,
  end : CurvePoint,
  level : Int,
  stroke_width : Double,
  edge_width : Double,
  head_width : Double,
  head_height : Double,
  shift_distance : Double,
  shorten_tail : Double,
  shorten_head : Double,
  body_style : String,
  dash_style : String,
  direction_angle : Double,
  tails : Array[String],
  heads : Array[String],
) -> ArrowRenderPlan {
  let curve_data = arrow_render_curve(shape_is_arc, is_loop, length, curve, loop_angle)
  let curve_width = arrow_render_curve_width(curve_data)
  let curve_height = 2.0 * Double::abs(arrow_render_curve_height(curve_data))
  let padding = ARROW_RENDER_BACKGROUND_PADDING +
    arrow_render_max(head_height, ARROW_RENDER_STROKE_WIDTH) / 2.0
  let offset = Point::new(
    padding + (curve_width - length) / 2.0,
    padding + curve_height / 2.0,
  )
  let svg_width = curve_width + padding * 2.0
  let svg_height = curve_height + padding * 2.0
  let shorten_start = if arrow_render_styles_have_hook(tails) { head_width } else { 0.0 }
  let shorten_end = if arrow_render_styles_have_hook(heads) { head_width } else { 0.0 }
  let dash_padding_start = arrow_render_adjust_dash_padding(
    curve_data,
    tails,
    start,
    true,
    head_width,
    edge_width,
  )
  let dash_padding_end = arrow_render_adjust_dash_padding(
    curve_data,
    heads,
    end,
    false,
    head_width,
    edge_width,
  )
  let context = {
    curve: curve_data,
    stroke_width,
    head_width,
    head_height,
    shorten_start,
    shorten_end,
    shorten_tail,
    shorten_head,
    dash_padding_start,
    dash_padding_end,
    offset,
    level,
    direction_angle,
  }
  let tail = arrow_render_heads(context, tails, start, true, false)
  let tail_mask = arrow_render_heads(context, tails, start, true, true)
  let head = arrow_render_heads(context, heads, end, false, false)
  let head_mask = arrow_render_heads(context, heads, end, false, true)
  let decoration = arrow_render_body_decoration(
    curve_data,
    start,
    end,
    shorten_tail,
    shorten_head,
    head_height,
    offset,
    body_style,
  )
  let arclen_to_start = arrow_render_curve_arc_length(curve_data, start.t)
  let arclen_to_end = arrow_render_curve_arc_length(curve_data, end.t)
  let arclen = arrow_render_curve_arc_length(curve_data, 1.0)
  let edge_valid = arclen_to_end - arclen_to_start -
    shorten_tail -
    shorten_head -
    shorten_start -
    shorten_end -
    dash_padding_start -
    dash_padding_end -
    tail.total_width -
    head.total_width >=
    0.0
  {
    ok: true,
    edge_valid,
    angle: direction_angle,
    shift: Point::new(0.0, shift_distance).rotate(direction_angle),
    svg_width,
    svg_height,
    offset,
    start,
    end,
    background: arrow_render_background_path(
      curve_data,
      offset,
      arclen_to_start,
      arclen_to_end,
      arclen,
    ),
    edge: if edge_valid {
      arrow_render_edge_path(
        curve_data,
        start,
        end,
        offset,
        body_style,
        dash_style,
        level,
        shorten_start,
        shorten_end,
        shorten_tail,
        shorten_head,
        dash_padding_start,
        dash_padding_end,
        tail.total_width,
        head.total_width,
      )
    } else {
      arrow_render_path_none()
    },
    clipping_path: if edge_valid {
      arrow_render_clipping_path(
        curve_data,
        offset,
        arclen_to_start,
        arclen_to_end,
        arclen,
        shorten_start,
        shorten_end,
        shorten_tail,
        shorten_head,
      )
    } else {
      arrow_render_path_none()
    },
    decoration,
    tail,
    tail_mask,
    head,
    head_mask,
  }
}
