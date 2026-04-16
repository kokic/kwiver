///|
fn browser_demo_point(x : Double, y : Double) -> @engine.Point {
  @engine.Point::new(x, y)
}

///|
fn browser_demo_bezier(
  origin_x : Double,
  origin_y : Double,
  w : Double,
  h : Double,
  angle : Double,
) -> @engine.Bezier {
  @engine.Bezier::new(browser_demo_point(origin_x, origin_y), w, h, angle)
}

///|
fn browser_demo_arc(
  origin_x : Double,
  origin_y : Double,
  chord : Double,
  major : Bool,
  radius : Double,
  angle : Double,
) -> @engine.Arc {
  @engine.Arc::new(
    browser_demo_point(origin_x, origin_y),
    chord,
    major,
    radius,
    angle,
  )
}

///|
pub fn ffi_browser_demo_bezier_point(
  origin_x : Double,
  origin_y : Double,
  w : Double,
  h : Double,
  angle : Double,
  t : Double,
) -> @engine.Point {
  browser_demo_bezier(origin_x, origin_y, w, h, angle).point(t)
}

///|
pub fn ffi_browser_demo_bezier_tangent(
  origin_x : Double,
  origin_y : Double,
  w : Double,
  h : Double,
  angle : Double,
  t : Double,
) -> Double {
  browser_demo_bezier(origin_x, origin_y, w, h, angle).tangent(t)
}

///|
pub fn ffi_browser_demo_bezier_arc_length(
  origin_x : Double,
  origin_y : Double,
  w : Double,
  h : Double,
  angle : Double,
  t : Double,
) -> Double {
  browser_demo_bezier(origin_x, origin_y, w, h, angle).arc_length(t)
}

///|
pub fn ffi_browser_demo_bezier_t_after_length(
  origin_x : Double,
  origin_y : Double,
  w : Double,
  h : Double,
  angle : Double,
  length : Double,
) -> Double {
  browser_demo_bezier(origin_x, origin_y, w, h, angle).t_after_length()(length)
}

///|
pub fn ffi_browser_demo_bezier_height(
  origin_x : Double,
  origin_y : Double,
  w : Double,
  h : Double,
  angle : Double,
) -> Double {
  browser_demo_bezier(origin_x, origin_y, w, h, angle).height()
}

///|
pub fn ffi_browser_demo_bezier_width(
  origin_x : Double,
  origin_y : Double,
  w : Double,
  h : Double,
  angle : Double,
) -> Double {
  browser_demo_bezier(origin_x, origin_y, w, h, angle).width()
}

///|
fn browser_demo_rounded_rectangle(
  centre_x : Double,
  centre_y : Double,
  width : Double,
  height : Double,
  radius : Double,
) -> @engine.RoundedRectangle {
  @engine.RoundedRectangle::new(
    browser_demo_point(centre_x, centre_y),
    width,
    height,
    radius,
  )
}

///|
pub fn ffi_browser_demo_bezier_intersections_with_rounded_rectangle(
  origin_x : Double,
  origin_y : Double,
  w : Double,
  h : Double,
  angle : Double,
  centre_x : Double,
  centre_y : Double,
  width : Double,
  height : Double,
  radius : Double,
  permit_containment : Bool,
) -> Array[@engine.CurvePoint] {
  browser_demo_bezier(origin_x, origin_y, w, h, angle).intersections_with_rounded_rectangle(
    browser_demo_rounded_rectangle(centre_x, centre_y, width, height, radius),
    permit_containment,
  )
}

///|
pub fn ffi_browser_demo_arc_point(
  origin_x : Double,
  origin_y : Double,
  chord : Double,
  major : Bool,
  radius : Double,
  angle : Double,
  t : Double,
) -> @engine.Point {
  browser_demo_arc(origin_x, origin_y, chord, major, radius, angle).point(t)
}

///|
pub fn ffi_browser_demo_arc_tangent(
  origin_x : Double,
  origin_y : Double,
  chord : Double,
  major : Bool,
  radius : Double,
  angle : Double,
  t : Double,
) -> Double {
  browser_demo_arc(origin_x, origin_y, chord, major, radius, angle).tangent(t)
}

///|
pub fn ffi_browser_demo_arc_arc_length(
  origin_x : Double,
  origin_y : Double,
  chord : Double,
  major : Bool,
  radius : Double,
  angle : Double,
  t : Double,
) -> Double {
  browser_demo_arc(origin_x, origin_y, chord, major, radius, angle).arc_length(t)
}

///|
pub fn ffi_browser_demo_arc_t_after_length(
  origin_x : Double,
  origin_y : Double,
  chord : Double,
  major : Bool,
  radius : Double,
  angle : Double,
  length : Double,
) -> Double {
  browser_demo_arc(origin_x, origin_y, chord, major, radius, angle).t_after_length()(length)
}

///|
pub fn ffi_browser_demo_arc_height(
  origin_x : Double,
  origin_y : Double,
  chord : Double,
  major : Bool,
  radius : Double,
  angle : Double,
) -> Double {
  browser_demo_arc(origin_x, origin_y, chord, major, radius, angle).height()
}

///|
pub fn ffi_browser_demo_arc_width(
  origin_x : Double,
  origin_y : Double,
  chord : Double,
  major : Bool,
  radius : Double,
  angle : Double,
) -> Double {
  browser_demo_arc(origin_x, origin_y, chord, major, radius, angle).width()
}

///|
pub fn ffi_browser_demo_arc_intersections_with_rounded_rectangle(
  origin_x : Double,
  origin_y : Double,
  chord : Double,
  major : Bool,
  radius : Double,
  angle : Double,
  centre_x : Double,
  centre_y : Double,
  width : Double,
  height : Double,
  rect_radius : Double,
  permit_containment : Bool,
) -> Array[@engine.CurvePoint] {
  browser_demo_arc(
    origin_x,
    origin_y,
    chord,
    major,
    radius,
    angle,
  ).intersections_with_rounded_rectangle(
    browser_demo_rounded_rectangle(centre_x, centre_y, width, height, rect_radius),
    permit_containment,
  )
}

///|
pub fn ffi_browser_demo_arc_angle_in_arc(
  origin_x : Double,
  origin_y : Double,
  chord : Double,
  major : Bool,
  radius : Double,
  angle : Double,
  target_angle : Double,
) -> Bool {
  browser_demo_arc(origin_x, origin_y, chord, major, radius, angle).angle_in_arc(
    target_angle,
  )
}
