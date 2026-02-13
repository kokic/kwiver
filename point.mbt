pub struct Point {
  x : Double
  y : Double
}

pub fn Point::new(x : Double, y : Double) -> Point {
  { x, y }
}

pub fn Point::zero() -> Point {
  { x: 0.0, y: 0.0 }
}

pub fn Point::add(self : Point, other : Point) -> Point {
  { x: self.x + other.x, y: self.y + other.y }
}

pub fn Point::sub(self : Point, other : Point) -> Point {
  { x: self.x - other.x, y: self.y - other.y }
}

pub fn Point::neg(self : Point) -> Point {
  { x: -self.x, y: -self.y }
}

pub fn Point::scale(self : Point, w : Double, h : Double) -> Point {
  { x: self.x * w, y: self.y * h }
}

pub fn Point::mul(self : Point, multiplier : Double) -> Point {
  self.scale(multiplier, multiplier)
}

pub fn Point::div(self : Point, divisor : Double) -> Point {
  { x: self.x / divisor, y: self.y / divisor }
}

pub fn Point::rotate(self : Point, theta : Double) -> Point {
  {
    x: self.x * @math.cos(theta) - self.y * @math.sin(theta),
    y: self.y * @math.cos(theta) + self.x * @math.sin(theta),
  }
}

pub fn Point::length(self : Point) -> Double {
  @math.hypot(self.x, self.y)
}

pub fn Point::angle(self : Point) -> Double {
  @math.atan2(self.y, self.x)
}

pub fn Point::lerp(self : Point, other : Point, t : Double) -> Point {
  self.add(other.sub(self).mul(t))
}

pub fn Point::is_zero(self : Point) -> Bool {
  self.x == 0.0 && self.y == 0.0
}
