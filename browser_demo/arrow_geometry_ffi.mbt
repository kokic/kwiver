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
fn browser_demo_arrow_shape(
  is_endpoint : Bool,
  origin_x : Double,
  origin_y : Double,
  width : Double,
  height : Double,
  radius : Double,
) -> @geometry.ArrowShape {
  let origin = browser_demo_point(origin_x, origin_y)
  if is_endpoint {
    @geometry.ArrowShape::endpoint(origin)
  } else {
    @geometry.ArrowShape::rounded_rect(origin, width, height, radius)
  }
}

///|
fn browser_demo_arrow_options(
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
fn browser_demo_arrow_local_curve_point(
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
pub fn ffi_browser_demo_arrow_find_endpoints_local(
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
  let render_source = browser_demo_point(render_source_x, render_source_y)
  let render_target = browser_demo_point(render_target_x, render_target_y)
  let render_angle = render_target.sub(render_source).angle()

  let source = browser_demo_arrow_shape(
    source_is_endpoint,
    source_origin_x,
    source_origin_y,
    source_width,
    source_height,
    source_radius,
  )
  let target = browser_demo_arrow_shape(
    target_is_endpoint,
    target_origin_x,
    target_origin_y,
    target_width,
    target_height,
    target_radius,
  )
  let options = browser_demo_arrow_options(shape_is_arc, curve, radius, angle, offset)
  let curve_model = @geometry.ArrowCurveModel::new(
    render_source,
    render_target,
    options,
  )
  let layout = @geometry.ArrowLayout::new(source, target, curve_model, options)
  let endpoints = layout.clipped_endpoints()

  let start = browser_demo_arrow_local_curve_point(
    endpoints.start,
    render_source,
    render_angle,
  )
  let end = browser_demo_arrow_local_curve_point(
    endpoints.end,
    render_source,
    render_angle,
  )

  let ok = (source_is_endpoint || endpoints.start.t > @engine.EPSILON) &&
    (target_is_endpoint || endpoints.end.t < 1.0 - @engine.EPSILON) &&
    endpoints.end.t >= endpoints.start.t

  { ok, start, end }
}
