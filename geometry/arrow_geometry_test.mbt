///|
fn assert_close_arrow(
  actual : Double,
  expected : Double,
  tolerance? : Double = 0.001,
) -> Unit {
  if Double::abs(actual - expected) > tolerance {
    abort("values are not close")
  }
}

///|
test "arrow geometry endpoints for point-to-point line" {
  let source = ArrowShape::endpoint(@engine.Point::new(0.0, 0.0))
  let target = ArrowShape::endpoint(@engine.Point::new(100.0, 0.0))
  let options = @engine.EdgeOptions::default()
  let geometry = ArrowGeometry::new(source, target, options)
  let endpoints = geometry.endpoints()

  assert_close_arrow(endpoints.start.x, 0.0)
  assert_close_arrow(endpoints.start.y, 0.0)
  assert_close_arrow(endpoints.end.x, 100.0)
  assert_close_arrow(endpoints.end.y, 0.0)
}

///|
test "arrow geometry rounded-rect source clipping" {
  let source = ArrowShape::rounded_rect(@engine.Point::new(0.0, 0.0), 20.0, 20.0, 4.0)
  let target = ArrowShape::endpoint(@engine.Point::new(100.0, 0.0))
  let options = @engine.EdgeOptions::default()
  let geometry = ArrowGeometry::new(source, target, options)
  let endpoints = geometry.endpoints()

  // Source should be near the right boundary of the rectangle.
  if endpoints.start.x < 8.0 || endpoints.start.x > 12.0 {
    abort("unexpected clipped source x")
  }
  assert_close_arrow(endpoints.end.x, 100.0)
}

///|
test "arrow geometry path uses shortening" {
  let source = ArrowShape::endpoint(@engine.Point::new(0.0, 0.0))
  let target = ArrowShape::endpoint(@engine.Point::new(100.0, 0.0))
  let options = @engine.EdgeOptions::default().with_shorten(10, 20)
  let geometry = ArrowGeometry::new(source, target, options)
  let points = geometry.path_points()

  if points.length() < 2 {
    abort("expected path with at least two points")
  }
  // 10% shorten from source, 20% from target.
  assert_close_arrow(points[0].x, 10.0, tolerance=1.0)
  assert_close_arrow(points[points.length() - 1].x, 80.0, tolerance=1.0)
}

///|
test "arrow geometry label position left-right differs" {
  let source = ArrowShape::endpoint(@engine.Point::new(0.0, 0.0))
  let target = ArrowShape::endpoint(@engine.Point::new(100.0, 0.0))

  let left = ArrowGeometry::new(
    source,
    target,
    @engine.EdgeOptions::default().with_label_alignment_left(),
  ).label_position(20.0, 10.0)

  let right = ArrowGeometry::new(
    source,
    target,
    @engine.EdgeOptions::default().with_label_alignment_right(),
  ).label_position(20.0, 10.0)

  // On a left-to-right edge, left label should go to negative y and right to positive y.
  if !(left.y < 0.0 && right.y > 0.0) {
    abort("unexpected label offset directions")
  }
}

///|
test "arrow geometry arc path and label" {
  let source = ArrowShape::endpoint(@engine.Point::new(0.0, 0.0))
  let target = ArrowShape::endpoint(@engine.Point::new(0.0, 0.0))
  let options = @engine.EdgeOptions::default()
    .with_shape_arc()
    .with_radius(3)
    .with_angle(45)
    .with_label_alignment_over()
  let geometry = ArrowGeometry::new(source, target, options)
  let points = geometry.path_points()
  if points.length() < 2 {
    abort("expected non-empty arc path")
  }
  let label = geometry.label_position(10.0, 6.0)
  // For loop arcs, label at over alignment should stay on curve and be finite.
  if label.x.is_nan() || label.y.is_nan() {
    abort("invalid label position")
  }
}

