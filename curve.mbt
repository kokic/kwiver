///|
pub const EPSILON : Double = 0.000001

///|
fn sign(x : Double) -> Double {
  if x > 0.0 {
    1.0
  } else if x < 0.0 {
    -1.0
  } else {
    0.0
  }
}

///|
fn mod_double(x : Double, y : Double) -> Double {
  let r = x - y * @math.floor(x / y)
  if r < 0.0 {
    r + y
  } else {
    r
  }
}

///|
fn mod_2pi(x : Double) -> Double {
  mod_double(x, 2.0 * @math.PI)
}

///|
pub struct CurvePoint {
  x : Double
  y : Double
  t : Double
  angle : Double
}

///|
pub fn CurvePoint::new(point : Point, t : Double, angle : Double) -> CurvePoint {
  { x: point.x, y: point.y, t, angle }
}

///|
pub fn CurvePoint::point(self : CurvePoint) -> Point {
  Point::new(self.x, self.y)
}

///|
pub struct Bezier {
  origin : Point
  w : Double
  h : Double
  angle : Double
}

///|
pub fn Bezier::new(
  origin : Point,
  w : Double,
  h : Double,
  angle : Double,
) -> Bezier {
  { origin, w, h, angle }
}

///|
fn Bezier::end(self : Bezier) -> Point {
  self.origin.add(Point::new(self.w, 0.0))
}

///|
fn Bezier::control(self : Bezier) -> Point {
  self.origin.add(Point::new(self.w / 2.0, self.h))
}

///|
pub fn Bezier::point(self : Bezier, t : Double) -> Point {
  self.origin
  .lerp(self.control(), t)
  .lerp(self.control().lerp(self.end(), t), t)
}

///|
pub fn Bezier::tangent(self : Bezier, t : Double) -> Double {
  self
  .control()
  .lerp(self.end(), t)
  .sub(self.origin.lerp(self.control(), t))
  .angle()
}

///|
pub fn Bezier::delineate(
  self : Bezier,
  t : Double,
) -> (Array[(Double, Point)], Double) {
  let precision = 0.25
  let points : Array[(Double, Point)] = [
    (0.0, self.point(0.0)),
    (t, self.point(t)),
  ]
  let mut previous_length = -1.0
  let mut length = 0.0

  while true {
    previous_length = length
    length = 0.0

    let mut i = 0
    while i + 1 < points.length() {
      let (_, p0) = points[i]
      let (_, p1) = points[i + 1]
      length = length + p1.sub(p0).length()
      i = i + 1
    }

    if length - previous_length <= precision {
      break
    }

    i = 0
    while i + 1 < points.length() {
      let (t0, _) = points[i]
      let (t1, _) = points[i + 1]
      let mid_t = (t0 + t1) / 2.0
      points.insert(i + 1, (mid_t, self.point(mid_t)))
      i = i + 2
    }
  }

  (points, length)
}

///|
pub fn Bezier::arc_length(self : Bezier, t : Double) -> Double {
  let (_, length) = self.delineate(t)
  length
}

///|
pub fn Bezier::t_after_length(
  self : Bezier,
  clamp? : Bool = false,
) -> (Double) -> Double {
  let (points, _) = self.delineate(1.0)

  (length : Double) => {
    if length == 0.0 {
      return 0.0
    }
    if length < 0.0 {
      if clamp {
        return 0.0
      }
      abort("length was less than 0")
    }

    let mut distance = 0.0
    let mut i = 0
    while i + 1 < points.length() {
      let (t0, p0) = points[i]
      let (t1, p1) = points[i + 1]
      let seg_len = p1.sub(p0).length()
      if distance + seg_len >= length {
        if seg_len == 0.0 {
          return t0
        }
        return t0 + (t1 - t0) * (length - distance) / seg_len
      }
      distance = distance + seg_len
      i = i + 1
    }

    if clamp {
      1.0
    } else {
      abort("length was greater than arc length")
    }
  }
}

///|
pub fn Bezier::height(self : Bezier) -> Double {
  self.h / 2.0
}

///|
pub fn Bezier::width(self : Bezier) -> Double {
  self.w
}

///|
pub struct Arc {
  origin : Point
  chord : Double
  major : Bool
  radius : Double
  angle : Double
  sagitta : Double
  centre_normalised : Point
  sweep_angle : Double
  centre : Point
  start_angle : Double
}

///|
pub fn Arc::new(
  origin : Point,
  chord : Double,
  major : Bool,
  radius : Double,
  angle : Double,
) -> Arc {
  let inside = radius * radius - chord * chord / 4.0
  let root = @math.pow(if inside < 0.0 { 0.0 } else { inside }, 0.5)
  let sagitta = radius - sign(radius) * root
  let centre_normalised = Point::new(
    chord / 2.0,
    (radius - sagitta) * (if major { -1.0 } else { 1.0 }),
  )
  let start_angle_raw = mod_2pi(centre_normalised.neg().angle())
  let clockwise = if radius >= 0.0 { 1.0 } else { -1.0 }
  let sweep_angle = @math.PI +
    (2.0 * @math.PI - 2.0 * start_angle_raw) * clockwise
  let centre = origin.add(centre_normalised.rotate(angle))
  let start_angle = mod_2pi(start_angle_raw + angle)
  {
    origin,
    chord,
    major,
    radius,
    angle,
    sagitta,
    centre_normalised,
    sweep_angle,
    centre,
    start_angle,
  }
}

///|
pub fn Arc::clockwise(self : Arc) -> Double {
  if self.radius >= 0.0 {
    1.0
  } else {
    -1.0
  }
}

///|
pub fn Arc::point(self : Arc, t : Double) -> Point {
  self.centre_normalised
  .add(self.origin)
  .add(
    Point::new(Double::abs(self.radius), 0.0).rotate(
      self.start_angle - self.angle + t * self.sweep_angle * self.clockwise(),
    ),
  )
}

///|
pub fn Arc::tangent(self : Arc, t : Double) -> Double {
  self.start_angle -
  self.angle +
  (t * self.sweep_angle + @math.PI / 2.0) * self.clockwise()
}

///|
pub fn Arc::arc_length(self : Arc, t : Double) -> Double {
  t * self.sweep_angle * Double::abs(self.radius)
}

///|
pub fn Arc::t_after_length(
  self : Arc,
  clamp? : Bool = false,
) -> (Double) -> Double {
  (length : Double) => {
    if length < 0.0 {
      if clamp {
        return 0.0
      }
      abort("length was less than 0")
    }
    let total = self.arc_length(1.0)
    if length > total {
      if clamp {
        return 1.0
      }
      abort("length was greater than arc length")
    }
    length / (self.sweep_angle * Double::abs(self.radius))
  }
}

///|
pub fn Arc::height(self : Arc) -> Double {
  if self.major {
    Double::abs(self.radius * 2.0 - self.sagitta)
  } else {
    Double::abs(self.sagitta)
  }
}

///|
pub fn Arc::width(self : Arc) -> Double {
  if self.major {
    Double::abs(self.radius) * 2.0
  } else {
    self.chord
  }
}

///|
pub fn Arc::angle_in_arc(self : Arc, angle : Double) -> Bool {
  fn normalise(theta : Double) -> Double {
    let mut out = theta
    while out < -@math.PI {
      out = out + 2.0 * @math.PI
    }
    while out > @math.PI {
      out = out - 2.0 * @math.PI
    }
    out
  }

  let angle1 = normalise(self.start_angle - angle)
  let angle2 = normalise(
    self.start_angle + self.sweep_angle * self.clockwise() - angle,
  )
  (angle1 * angle2 < 0.0 && Double::abs(angle1 - angle2) < @math.PI) !=
  self.major
}
