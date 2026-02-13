fn assert_close_curve(actual : Double, expected : Double, tolerance~ : Double = 0.001) -> Unit {
  if Double::abs(actual - expected) > tolerance {
    abort("values are not close")
  }
}

test "arrow curve model bezier endpoints and svg" {
  let options = EdgeOptions::default().with_shape_bezier()
  let model = ArrowCurveModel::new(Point::new(0.0, 0.0), Point::new(100.0, 0.0), options)
  let interval = ArrowCurveInterval::full()
  let start = model.sample(interval.start_t)
  let end = model.sample(interval.end_t)
  let svg = model.path_svg(interval)

  assert_close_curve(start.x, 0.0)
  assert_close_curve(start.y, 0.0)
  assert_close_curve(end.x, 100.0)
  assert_close_curve(end.y, 0.0)

  if svg.length() == 0 {
    abort("expected non-empty path svg")
  }
}

test "arrow curve model shorten interval on straight line" {
  let options = EdgeOptions::default()
    .with_shape_bezier()
    .with_shorten(10, 20)
  let model = ArrowCurveModel::new(Point::new(0.0, 0.0), Point::new(100.0, 0.0), options)
  let shortened = model.shorten_interval(ArrowCurveInterval::full())

  assert_close_curve(shortened.start_t, 0.1, tolerance=0.02)
  assert_close_curve(shortened.end_t, 0.8, tolerance=0.02)
}

test "arrow curve model loop arc has finite midpoint" {
  let options = EdgeOptions::default()
    .with_shape_arc()
    .with_radius(3)
    .with_angle(45)
  let model = ArrowCurveModel::new(Point::new(0.0, 0.0), Point::new(0.0, 0.0), options)
  let mid = model.point(0.5)
  if mid.x.is_nan() || mid.y.is_nan() {
    abort("midpoint should be finite")
  }
}
