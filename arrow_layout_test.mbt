fn assert_close_layout(actual : Double, expected : Double, tolerance~ : Double = 0.001) -> Unit {
  if Double::abs(actual - expected) > tolerance {
    abort("values are not close")
  }
}

test "arrow layout clips source rounded rectangle" {
  let source = ArrowShape::rounded_rect(Point::new(0.0, 0.0), 20.0, 20.0, 4.0)
  let target = ArrowShape::endpoint(Point::new(100.0, 0.0))
  let options = EdgeOptions::default()
  let model = ArrowCurveModel::new(source.origin(), target.origin(), options)
  let layout = ArrowLayout::new(source, target, model, options)
  let endpoints = layout.clipped_endpoints()

  if endpoints.start.x < 8.0 || endpoints.start.x > 12.0 {
    abort("unexpected clipped source x")
  }
  assert_close_layout(endpoints.end.x, 100.0)
}

test "arrow layout shortened interval uses edge shorten" {
  let source = ArrowShape::endpoint(Point::new(0.0, 0.0))
  let target = ArrowShape::endpoint(Point::new(100.0, 0.0))
  let options = EdgeOptions::default().with_shorten(10, 20)
  let model = ArrowCurveModel::new(source.origin(), target.origin(), options)
  let layout = ArrowLayout::new(source, target, model, options)
  let shortened = layout.shortened_interval()

  assert_close_layout(shortened.start_t, 0.1, tolerance=0.02)
  assert_close_layout(shortened.end_t, 0.8, tolerance=0.02)
}

test "arrow layout label left-right differs" {
  let source = ArrowShape::endpoint(Point::new(0.0, 0.0))
  let target = ArrowShape::endpoint(Point::new(100.0, 0.0))

  let options_left = EdgeOptions::default().with_label_alignment_left()
  let model_left = ArrowCurveModel::new(source.origin(), target.origin(), options_left)
  let layout_left = ArrowLayout::new(source, target, model_left, options_left)
  let left = layout_left.label_position(20.0, 10.0)

  let options_right = EdgeOptions::default().with_label_alignment_right()
  let model_right = ArrowCurveModel::new(source.origin(), target.origin(), options_right)
  let layout_right = ArrowLayout::new(source, target, model_right, options_right)
  let right = layout_right.label_position(20.0, 10.0)

  if !(left.y < 0.0 && right.y > 0.0) {
    abort("unexpected label offset directions")
  }
}
