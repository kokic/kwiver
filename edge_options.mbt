pub enum LabelAlignment {
  Left
  Centre
  Right
  Over
}

pub enum EdgeShape {
  Bezier
  Arc
}

pub struct EdgeShorten {
  source : Int
  target : Int
}

pub struct EdgeAlignment {
  source : Bool
  target : Bool
}

pub struct EdgeEndpointStyle {
  name : String
  side : String
}

pub struct EdgeStyle {
  name : String
  tail : EdgeEndpointStyle
  body : EdgeEndpointStyle
  head : EdgeEndpointStyle
}

pub struct EdgeOptions {
  label_alignment : LabelAlignment
  label_position : Int
  offset : Int
  curve : Int
  radius : Int
  angle : Int
  shorten : EdgeShorten
  level : Int
  shape : EdgeShape
  colour : Colour
  edge_alignment : EdgeAlignment
  style : EdgeStyle
}

pub fn EdgeOptions::default() -> EdgeOptions {
  EdgeOptions::at_level(1)
}

pub fn EdgeOptions::at_level(level : Int) -> EdgeOptions {
  {
    label_alignment: LabelAlignment::Left,
    label_position: 50,
    offset: 0,
    curve: 0,
    radius: 3,
    angle: 0,
    shorten: { source: 0, target: 0 },
    level: if level < 1 { 1 } else { level },
    shape: EdgeShape::Bezier,
    colour: Colour::black(),
    edge_alignment: { source: true, target: true },
    style: {
      name: "arrow",
      tail: { name: "none", side: "" },
      body: { name: "cell", side: "" },
      head: { name: "arrowhead", side: "" },
    },
  }
}

pub fn EdgeOptions::with_level(self : EdgeOptions, level : Int) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: if level < 1 { 1 } else { level },
    shape: self.shape,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: self.style,
  }
}
