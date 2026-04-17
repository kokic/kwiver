///|
pub struct ArrowHeadRenderPartPlan {
  has_path : Bool
  d : String
  total_width : Double
}

///|
pub struct ArrowRenderPlan {
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
const ARROW_RENDER_MASK_PADDING : Double = 4.0

///|
const ARROW_RENDER_HEAD_SPACING : Double = 2.0

///|
const ARROW_RENDER_CORNER_LENGTH : Double = 12.0

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
    ArrowRenderCurveData::Bezier(Bezier::new(Point::zero(), length, curve, 0.0))
  } else if is_loop {
    ArrowRenderCurveData::Arc(Arc::new(Point::zero(), length, true, curve, loop_angle))
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
  Arc::new(Point::zero(), chord, chord <= ARROW_RENDER_ARC_INNER_DIS, r, 0.0)
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
fn arrow_render_part_none(total_width? : Double = 0.0) -> ArrowHeadRenderPartPlan {
  { has_path: false, d: "", total_width }
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
fn arrow_render_move_to(commands : Array[String], point : Point) -> Unit {
  commands.push(["M", point.x.to_string(), point.y.to_string()].join(" "))
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
fn arrow_render_style_contains(styles : Array[String], target : String) -> Bool {
  for style in styles {
    if style == target {
      return true
    }
  }
  false
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
  head_width : Double,
  head_height : Double,
  shorten_start : Double,
  shorten_end : Double,
  shorten_tail : Double,
  shorten_head : Double,
  dash_padding_start : Double,
  dash_padding_end : Double,
  offset : Point,
  direction_angle : Double,
  tails : Array[String],
  heads : Array[String],
) -> ArrowRenderPlan {
  let curve_data = arrow_render_curve(shape_is_arc, is_loop, length, curve, loop_angle)
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

  {
    tail: arrow_render_heads(context, tails, start, true, false),
    tail_mask: arrow_render_heads(context, tails, start, true, true),
    head: arrow_render_heads(context, heads, end, false, false),
    head_mask: arrow_render_heads(context, heads, end, false, true),
  }
}
