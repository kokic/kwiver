///|
pub struct Colour {
  h : Int
  s : Int
  l : Int
  a : Double
}

///|
pub fn Colour::new(h : Int, s : Int, l : Int, a : Double) -> Colour {
  { h, s, l, a }
}

///|
pub fn Colour::black() -> Colour {
  { h: 0, s: 0, l: 0, a: 1.0 }
}

///|
pub fn Colour::is_not_black(self : Colour) -> Bool {
  self.l > 0
}
