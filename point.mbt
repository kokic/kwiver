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
