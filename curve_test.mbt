fn assert_close(actual : Double, expected : Double, tolerance~ : Double = 0.0001) -> Unit {
  if Double::abs(actual - expected) > tolerance {
    abort("values are not close")
  }
}

test "bezier basic geometry" {
  let bezier = Bezier::new(Point::zero(), 10.0, 4.0, 0.0)
  let p0 = bezier.point(0.0)
  let pm = bezier.point(0.5)
  let p1 = bezier.point(1.0)

  assert_close(p0.x, 0.0)
  assert_close(p0.y, 0.0)
  assert_close(pm.x, 5.0)
  assert_close(pm.y, 2.0)
  assert_close(p1.x, 10.0)
  assert_close(p1.y, 0.0)

  let total = bezier.arc_length(1.0)
  let half = bezier.arc_length(0.5)
  if !(total > half && half > 0.0) {
    abort("unexpected bezier arc length ordering")
  }
}

test "bezier t_after_length" {
  let bezier = Bezier::new(Point::zero(), 10.0, 4.0, 0.0)
  let total = bezier.arc_length(1.0)
  let t_for = bezier.t_after_length()
  assert_close(t_for(0.0), 0.0)
  assert_close(t_for(total), 1.0, tolerance=0.02)
}

test "arc endpoints and parameter by length" {
  let arc = Arc::new(Point::zero(), 10.0, false, 8.0, 0.0)
  let p0 = arc.point(0.0)
  let p1 = arc.point(1.0)

  assert_close(p0.x, 0.0, tolerance=0.01)
  assert_close(p0.y, 0.0, tolerance=0.01)
  assert_close(p1.x, 10.0, tolerance=0.01)
  assert_close(p1.y, 0.0, tolerance=0.01)

  let total = arc.arc_length(1.0)
  let t_for = arc.t_after_length()
  assert_close(t_for(0.0), 0.0)
  assert_close(t_for(total), 1.0, tolerance=0.0001)
}

test "arc angle membership sanity" {
  let arc = Arc::new(Point::zero(), 10.0, false, 8.0, 0.0)
  // Reconstruct the radial angle at t = 0.5 from tangent direction.
  let mid_angle = arc.tangent(0.5) - @math.PI / 2.0 * arc.clockwise()
  if !arc.angle_in_arc(mid_angle) {
    abort("mid angle should be in arc")
  }
  if arc.angle_in_arc(mid_angle + @math.PI) {
    abort("opposite angle should not be in arc")
  }
}
