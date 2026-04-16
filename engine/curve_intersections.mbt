///|
pub struct RoundedRectangle {
  centre : Point
  width : Double
  height : Double
  radius : Double
}

///|
pub fn RoundedRectangle::new(
  centre : Point,
  width : Double,
  height : Double,
  radius : Double,
) -> RoundedRectangle {
  { centre, width, height, radius }
}

///|
const CURVE_INV_EPSILON : Double = 1000000.0

///|
fn curve_round_to_epsilon(x : Double) -> Double {
  if x >= 0.0 {
    @math.floor(x * CURVE_INV_EPSILON + 0.5) / CURVE_INV_EPSILON
  } else {
    -@math.floor(-x * CURVE_INV_EPSILON + 0.5) / CURVE_INV_EPSILON
  }
}

///|
fn curve_points_equalish(a : Point, b : Point) -> Bool {
  Double::abs(a.x - b.x) <= EPSILON && Double::abs(a.y - b.y) <= EPSILON
}

///|
fn curve_add_intersection(intersections : Array[Point], point : Point) -> Unit {
  let rounded = Point::new(
    curve_round_to_epsilon(point.x),
    curve_round_to_epsilon(point.y),
  )
  for existing in intersections {
    if existing.eq(rounded) {
      return
    }
  }
  intersections.push(rounded)
}

///|
fn curve_polygon_displacement(
  base : Point,
  end : Point,
  point : Point,
) -> Double {
  let delta = end.sub(base)
  let offset = point.sub(base)
  delta.x * offset.y - delta.y * offset.x
}

///|
fn curve_point_inside_polygon(point : Point, points : Array[Point]) -> Bool {
  if points.is_empty() {
    return false
  }

  let mut winding_number = 0
  for i in 0..<points.length() {
    let current = points[i]
    let next = points[if i + 1 < points.length() { i + 1 } else { 0 }]
    if (current.y <= point.y) != (next.y <= point.y) {
      let displacement = curve_polygon_displacement(current, next, point)
      if displacement > 0.0 {
        winding_number = winding_number + 1
      } else if displacement < 0.0 {
        winding_number = winding_number - 1
      }
    }
  }

  winding_number != 0
}

///|
fn curve_check_for_containment(
  origin : Point,
  rect : RoundedRectangle,
  permit_containment : Bool,
) -> Array[CurvePoint] {
  let sharp_rect = RoundedRectangle::new(rect.centre, rect.width, rect.height, 0.0)
  if curve_point_inside_polygon(origin, sharp_rect.points()) {
    if permit_containment {
      return [CurvePoint::new(rect.centre, 0.0, 0.0)]
    } else {
      abort("curve was entirely contained by rounded rectangle")
    }
  }
  []
}

///|
fn curve_normalised_bezier_x_intersections_with_nonvertical_line(
  m : Double,
  c : Double,
) -> Array[Double] {
  let determinant = m * m - 4.0 * m + 4.0 - 8.0 * c
  if determinant > 0.0 {
    let root = @math.pow(determinant, 0.5)
    [(2.0 - m + root) / 4.0, (2.0 - m - root) / 4.0]
  } else if determinant == 0.0 {
    [(2.0 - m) / 4.0]
  } else {
    []
  }
}

///|
fn curve_normalised_bezier_y_intersection_with_vertical_line(a : Double) -> Double {
  2.0 * a * (1.0 - a)
}

///|
pub fn RoundedRectangle::points(
  self : RoundedRectangle,
  max_segment_length? : Double = 5.0,
) -> Array[Point] {
  let points : Array[Point] = []

  let n = if self.radius != 0.0 {
    @math.PI / @math.atan(max_segment_length / (2.0 * self.radius))
  } else {
    0.0
  }
  let sides = @math.ceil(n).to_int()
  let polygon_radius = if sides == 0 {
    0.0
  } else {
    self.radius / @math.cos(@math.PI / sides.to_double())
  }
  let quarter_steps = @math.ceil(sides.to_double() / 4.0).to_int()
  let half_size = Point::new(self.width / 2.0, self.height / 2.0)
  let radius_point = Point::new(self.radius, self.radius)

  fn add_corner_points(
    points : Array[Point],
    rect : RoundedRectangle,
    half_size : Point,
    radius_point : Point,
    polygon_radius : Double,
    quarter_steps : Int,
    sx : Double,
    sy : Double,
    angle_offset : Double,
  ) -> Double {
    let corner_centre = rect.centre.add(half_size.sub(radius_point).scale(sx, sy))
    points.push(corner_centre.add(Point::lendir(rect.radius, angle_offset)))
    for i in 0..<quarter_steps {
      let angle = (i.to_double() + 0.5) / sides.to_double() * 2.0 * @math.PI + angle_offset
      points.push(corner_centre.add(Point::lendir(polygon_radius, angle)))
    }
    let next_angle = angle_offset + @math.PI / 2.0
    points.push(corner_centre.add(Point::lendir(rect.radius, next_angle)))
    next_angle
  }

  let mut angle_offset = 0.0
  angle_offset = add_corner_points(
    points,
    self,
    half_size,
    radius_point,
    polygon_radius,
    quarter_steps,
    1.0,
    1.0,
    angle_offset,
  )
  angle_offset = add_corner_points(
    points,
    self,
    half_size,
    radius_point,
    polygon_radius,
    quarter_steps,
    -1.0,
    1.0,
    angle_offset,
  )
  angle_offset = add_corner_points(
    points,
    self,
    half_size,
    radius_point,
    polygon_radius,
    quarter_steps,
    -1.0,
    -1.0,
    angle_offset,
  )
  ignore(
    add_corner_points(
      points,
      self,
      half_size,
      radius_point,
      polygon_radius,
      quarter_steps,
      1.0,
      -1.0,
      angle_offset,
    ),
  )

  if points.is_empty() {
    return points
  }

  let deduped : Array[Point] = [points[0]]
  for i in 1..<points.length() {
    if !curve_points_equalish(points[i], deduped[deduped.length() - 1]) {
      deduped.push(points[i])
    }
  }
  deduped
}

///|
pub fn Bezier::intersections_with_rounded_rectangle(
  self : Bezier,
  rect : RoundedRectangle,
  permit_containment : Bool,
) -> Array[CurvePoint] {
  let h = if self.h == 0.0 { 1.0 } else { self.h }
  let points : Array[Point] = []
  for point in rect.points() {
    let translated = point.sub(self.origin).rotate(-self.angle)
    points.push(Point::new(translated.x / self.w, translated.y / h))
  }

  let intersections : Array[Point] = []

  fn line_m_c(p0 : Point, p1 : Point) -> (Double, Double) {
    let m = (p1.y - p0.y) / (p1.x - p0.x)
    (m, p0.y - m * p0.x)
  }

  for i in 0..<points.length() {
    let p0 = points[i]
    let p1 = points[if i + 1 < points.length() { i + 1 } else { 0 }]

    if self.h == 0.0 {
      if Double::abs(p0.x - p1.x) <= EPSILON {
        if p0.x >= 0.0 &&
          p0.x <= 1.0 &&
          Double::min(p0.y, p1.y) <= 0.0 &&
          Double::max(p0.y, p1.y) >= 0.0 {
          curve_add_intersection(intersections, Point::new(p0.x, 0.0))
        }
      } else {
        let (m, c) = line_m_c(p0, p1)
        if Double::abs(m) > EPSILON {
          let x = -c / m
          if x >= 0.0 &&
            x <= 1.0 &&
            x >= Double::min(p0.x, p1.x) - EPSILON &&
            x <= Double::max(p0.x, p1.x) + EPSILON {
            curve_add_intersection(intersections, Point::new(x, 0.0))
          }
        } else if Double::abs(p0.y) <= EPSILON {
          let min_x = Double::min(p0.x, p1.x)
          let max_x = Double::max(p0.x, p1.x)
          if min_x <= 1.0 && max_x >= 0.0 {
            curve_add_intersection(
              intersections,
              Point::new(Double::max(min_x, 0.0), 0.0),
            )
            curve_add_intersection(
              intersections,
              Point::new(Double::min(max_x, 1.0), 0.0),
            )
          }
        }
      }
    } else if Double::abs(p0.x - p1.x) <= EPSILON {
      let y = curve_normalised_bezier_y_intersection_with_vertical_line(p0.x)
      if y >= 0.0 &&
        y >= Double::min(p0.y, p1.y) &&
        y <= Double::max(p0.y, p1.y) {
        curve_add_intersection(intersections, Point::new(p0.x, y))
      }
    } else {
      let (m, c) = line_m_c(p0, p1)
      for x in curve_normalised_bezier_x_intersections_with_nonvertical_line(m, c) {
        if x >= 0.0 &&
          x <= 1.0 &&
          x >= Double::min(p0.x, p1.x) &&
          x <= Double::max(p0.x, p1.x) {
          curve_add_intersection(intersections, Point::new(x, m * x + c))
        }
      }
    }
  }

  if intersections.is_empty() {
    return curve_check_for_containment(self.origin, rect, permit_containment)
  }

  let out : Array[CurvePoint] = []
  for point in intersections {
    out.push(
      CurvePoint::new(
        point.scale(self.w, h),
        point.x,
        @math.atan2((2.0 - 4.0 * point.x) * h, self.w),
      ),
    )
  }
  out
}

///|
pub fn Arc::intersections_with_rounded_rectangle(
  self : Arc,
  rect : RoundedRectangle,
  permit_containment : Bool,
) -> Array[CurvePoint] {
  if !self.major && Double::abs(self.sagitta) <= 1.0 {
    return Bezier::new(self.origin, self.chord, 0.0, self.angle)
    .intersections_with_rounded_rectangle(rect, permit_containment)
  }

  let rect_points = rect.points()
  let points : Array[Point] = []
  for point in rect_points {
    let shifted = point.sub(self.centre)
    points.push(
      Point::new(
        curve_round_to_epsilon(shifted.x),
        curve_round_to_epsilon(shifted.y),
      ),
    )
  }

  let iteration_points : Array[Point] = []
  if self.radius < 0.0 {
    let mut i = points.length() - 1
    while i >= 0 {
      iteration_points.push(points[i])
      i = i - 1
    }
  } else {
    for point in points {
      iteration_points.push(point)
    }
  }

  let intersections : Array[Point] = []
  for i in 0..<iteration_points.length() {
    let p0 = iteration_points[i]
    let p1 = iteration_points[if i + 1 < iteration_points.length() { i + 1 } else { 0 }]
    let delta = p1.sub(p0)
    let determinant = p0.x * p1.y - p1.x * p0.y
    let line_square = delta.length() * delta.length()
    let discriminant = self.radius * self.radius * line_square -
      determinant * determinant
    if sign(discriminant) < 0.0 {
      continue
    }

    let roots = if Double::abs(discriminant) <= EPSILON { [0.0] } else { [1.0, -1.0] }
    let root = @math.pow(if discriminant < 0.0 { 0.0 } else { discriminant }, 0.5)
    let y_sign = if delta.y < 0.0 { -1.0 } else { 1.0 }
    for s in roots {
      let x = curve_round_to_epsilon(
        (determinant * delta.y + s * delta.x * root * y_sign) / line_square,
      )
      let y = curve_round_to_epsilon(
        (-determinant * delta.x + s * root * Double::abs(delta.y)) / line_square,
      )
      if x >= Double::min(p0.x, p1.x) &&
        x <= Double::max(p0.x, p1.x) &&
        y >= Double::min(p0.y, p1.y) &&
        y <= Double::max(p0.y, p1.y) &&
        self.angle_in_arc(@math.atan2(y, x)) {
        curve_add_intersection(intersections, Point::new(x, y))
      }
    }
  }

  if intersections.is_empty() {
    return curve_check_for_containment(self.origin, rect, permit_containment)
  }

  let out : Array[CurvePoint] = []
  for point in intersections {
    let t = mod_2pi((@math.atan2(point.y, point.x) - self.start_angle) * self.clockwise()) /
      self.sweep_angle
    out.push(
      CurvePoint::new(
        point.add(self.centre).sub(self.origin).rotate(-self.angle),
        t,
        self.tangent(t),
      ),
    )
  }
  out
}
