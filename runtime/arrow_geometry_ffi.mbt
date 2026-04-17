///|
pub struct BrowserDemoCurvePointResult {
  x : Double
  y : Double
  t : Double
  angle : Double
}

///|
pub struct BrowserDemoArrowEndpointsResult {
  ok : Bool
  start : BrowserDemoCurvePointResult
  end : BrowserDemoCurvePointResult
}

///|
fn runtime_curve_point(
  x : Double,
  y : Double,
  t : Double,
  angle : Double,
) -> @engine.CurvePoint {
  @engine.CurvePoint::new(runtime_point(x, y), t, angle)
}

///|
fn runtime_arrow_shape(
  is_endpoint : Bool,
  origin_x : Double,
  origin_y : Double,
  width : Double,
  height : Double,
  radius : Double,
) -> @geometry.ArrowShape {
  let origin = runtime_point(origin_x, origin_y)
  if is_endpoint {
    @geometry.ArrowShape::endpoint(origin)
  } else {
    @geometry.ArrowShape::rounded_rect(origin, width, height, radius)
  }
}

///|
fn runtime_arrow_options(
  shape_is_arc : Bool,
  curve : Int,
  radius : Int,
  angle : Int,
  offset : Int,
) -> @engine.EdgeOptions {
  let mut options = @engine.EdgeOptions::default()
  options = if shape_is_arc {
    options.with_shape_arc()
  } else {
    options.with_shape_bezier()
  }
  options
  .with_curve(curve)
  .with_radius(radius)
  .with_angle(angle)
  .with_offset(offset)
}

///|
fn runtime_arrow_options_with_label(
  shape_is_arc : Bool,
  curve : Int,
  radius : Int,
  angle : Int,
  offset : Int,
  label_alignment : String,
  label_position : Int,
) -> @engine.EdgeOptions {
  let options = runtime_arrow_options(shape_is_arc, curve, radius, angle, offset)
    .with_label_position(label_position)
  match label_alignment {
    "centre" => options.with_label_alignment_centre()
    "center" => options.with_label_alignment_centre()
    "right" => options.with_label_alignment_right()
    "over" => options.with_label_alignment_over()
    _ => options.with_label_alignment_left()
  }
}

///|
fn runtime_arrow_local_curve_point(
  point : @engine.CurvePoint,
  render_source : @engine.Point,
  render_angle : Double,
) -> BrowserDemoCurvePointResult {
  let local_point = point.point().sub(render_source).rotate(-render_angle)
  {
    x: local_point.x,
    y: local_point.y,
    t: point.t,
    angle: point.angle - render_angle,
  }
}

///|
fn runtime_arrow_style_tokens(csv : String) -> Array[String] {
  let tokens : Array[String] = []
  if csv == "" {
    return tokens
  }
  for part in csv.split(",") {
    let token = part.to_string()
    if token != "" {
      tokens.push(token)
    }
  }
  tokens
}

///|
pub fn ffi_runtime_arrow_find_endpoints_local(
  render_source_x : Double,
  render_source_y : Double,
  render_target_x : Double,
  render_target_y : Double,
  source_is_endpoint : Bool,
  source_origin_x : Double,
  source_origin_y : Double,
  source_width : Double,
  source_height : Double,
  source_radius : Double,
  target_is_endpoint : Bool,
  target_origin_x : Double,
  target_origin_y : Double,
  target_width : Double,
  target_height : Double,
  target_radius : Double,
  shape_is_arc : Bool,
  curve : Int,
  radius : Int,
  angle : Int,
  offset : Int,
) -> BrowserDemoArrowEndpointsResult {
  let render_source = runtime_point(render_source_x, render_source_y)
  let render_target = runtime_point(render_target_x, render_target_y)
  let render_angle = render_target.sub(render_source).angle()

  let source = runtime_arrow_shape(
    source_is_endpoint,
    source_origin_x,
    source_origin_y,
    source_width,
    source_height,
    source_radius,
  )
  let target = runtime_arrow_shape(
    target_is_endpoint,
    target_origin_x,
    target_origin_y,
    target_width,
    target_height,
    target_radius,
  )
  let options = runtime_arrow_options(shape_is_arc, curve, radius, angle, offset)
  let curve_model = @geometry.ArrowCurveModel::new(
    render_source,
    render_target,
    options,
  )
  let layout = @geometry.ArrowLayout::new(source, target, curve_model, options)
  let endpoints = layout.clipped_endpoints()

  let start = runtime_arrow_local_curve_point(
    endpoints.start,
    render_source,
    render_angle,
  )
  let end = runtime_arrow_local_curve_point(
    endpoints.end,
    render_source,
    render_angle,
  )

  let ok = (source_is_endpoint || endpoints.start.t > @engine.EPSILON) &&
    (target_is_endpoint || endpoints.end.t < 1.0 - @engine.EPSILON) &&
    endpoints.end.t >= endpoints.start.t

  { ok, start, end }
}

///|
pub fn ffi_runtime_arrow_label_position_local(
  render_source_x : Double,
  render_source_y : Double,
  render_target_x : Double,
  render_target_y : Double,
  source_is_endpoint : Bool,
  source_origin_x : Double,
  source_origin_y : Double,
  source_width : Double,
  source_height : Double,
  source_radius : Double,
  target_is_endpoint : Bool,
  target_origin_x : Double,
  target_origin_y : Double,
  target_width : Double,
  target_height : Double,
  target_radius : Double,
  shape_is_arc : Bool,
  curve : Int,
  radius : Int,
  angle : Int,
  offset : Int,
  label_alignment : String,
  label_position : Int,
  label_width : Double,
  label_height : Double,
  edge_width : Double,
) -> @engine.Point {
  let render_source = runtime_point(render_source_x, render_source_y)
  let render_target = runtime_point(render_target_x, render_target_y)

  let source = runtime_arrow_shape(
    source_is_endpoint,
    source_origin_x,
    source_origin_y,
    source_width,
    source_height,
    source_radius,
  )
  let target = runtime_arrow_shape(
    target_is_endpoint,
    target_origin_x,
    target_origin_y,
    target_width,
    target_height,
    target_radius,
  )
  let options = runtime_arrow_options_with_label(
    shape_is_arc,
    curve,
    radius,
    angle,
    offset,
    label_alignment,
    label_position,
  )
  let curve_model = @geometry.ArrowCurveModel::new(
    render_source,
    render_target,
    options,
  )
  let layout = @geometry.ArrowLayout::new(source, target, curve_model, options)
  layout.label_position_local(label_width, label_height, edge_width=edge_width)
}

///|
pub fn ffi_runtime_arrow_render_plan_local(
  shape_is_arc : Bool,
  is_loop : Bool,
  length : Double,
  curve : Double,
  loop_angle : Double,
  start_x : Double,
  start_y : Double,
  start_t : Double,
  start_angle : Double,
  end_x : Double,
  end_y : Double,
  end_t : Double,
  end_angle : Double,
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
  offset_x : Double,
  offset_y : Double,
  direction_angle : Double,
  tails_csv : String,
  heads_csv : String,
) -> @geometry.ArrowRenderPlan {
  @geometry.arrow_render_plan_local(
    shape_is_arc,
    is_loop,
    length,
    curve,
    loop_angle,
    runtime_curve_point(start_x, start_y, start_t, start_angle),
    runtime_curve_point(end_x, end_y, end_t, end_angle),
    level,
    stroke_width,
    head_width,
    head_height,
    shorten_start,
    shorten_end,
    shorten_tail,
    shorten_head,
    dash_padding_start,
    dash_padding_end,
    runtime_point(offset_x, offset_y),
    direction_angle,
    runtime_arrow_style_tokens(tails_csv),
    runtime_arrow_style_tokens(heads_csv),
  )
}
