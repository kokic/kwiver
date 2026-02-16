///|
pub enum LabelAlignment {
  Left
  Centre
  Right
  Over
}

///|
pub enum EdgeShape {
  Bezier
  Arc
}

///|
pub struct EdgeShorten {
  source : Int
  target : Int
}

///|
pub struct EdgeAlignment {
  source : Bool
  target : Bool
}

///|
pub struct EdgeEndpointStyle {
  name : String
  side : String
}

///|
pub struct EdgeStyle {
  name : String
  tail : EdgeEndpointStyle
  body : EdgeEndpointStyle
  head : EdgeEndpointStyle
}

///|
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

///|
pub fn EdgeOptions::default() -> EdgeOptions {
  EdgeOptions::at_level(1)
}

///|
pub fn EdgeOptions::at_level(level : Int) -> EdgeOptions {
  {
    label_alignment: LabelAlignment::Left,
    label_position: 50,
    offset: 0,
    curve: 0,
    radius: 3,
    angle: 0,
    shorten: { source: 0, target: 0 },
    level: if level < 1 {
      1
    } else {
      level
    },
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

///|
pub fn EdgeOptions::with_level(self : EdgeOptions, level : Int) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: if level < 1 {
      1
    } else {
      level
    },
    shape: self.shape,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: self.style,
  }
}

///|
pub fn EdgeOptions::with_label_alignment_left(
  self : EdgeOptions,
) -> EdgeOptions {
  {
    label_alignment: LabelAlignment::Left,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: self.shape,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: self.style,
  }
}

///|
pub fn EdgeOptions::with_label_alignment_centre(
  self : EdgeOptions,
) -> EdgeOptions {
  {
    label_alignment: LabelAlignment::Centre,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: self.shape,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: self.style,
  }
}

///|
pub fn EdgeOptions::with_label_alignment_right(
  self : EdgeOptions,
) -> EdgeOptions {
  {
    label_alignment: LabelAlignment::Right,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: self.shape,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: self.style,
  }
}

///|
pub fn EdgeOptions::with_label_alignment_over(
  self : EdgeOptions,
) -> EdgeOptions {
  {
    label_alignment: LabelAlignment::Over,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: self.shape,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: self.style,
  }
}

///|
pub fn EdgeOptions::with_shape_bezier(self : EdgeOptions) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: EdgeShape::Bezier,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: self.style,
  }
}

///|
pub fn EdgeOptions::with_shape_arc(self : EdgeOptions) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: EdgeShape::Arc,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: self.style,
  }
}

///|
pub fn EdgeOptions::with_label_position(
  self : EdgeOptions,
  label_position : Int,
) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: self.shape,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: self.style,
  }
}

///|
pub fn EdgeOptions::with_offset(
  self : EdgeOptions,
  offset : Int,
) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position: self.label_position,
    offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: self.shape,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: self.style,
  }
}

///|
pub fn EdgeOptions::with_curve(self : EdgeOptions, curve : Int) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position: self.label_position,
    offset: self.offset,
    curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: self.shape,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: self.style,
  }
}

///|
pub fn EdgeOptions::with_radius(
  self : EdgeOptions,
  radius : Int,
) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: self.shape,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: self.style,
  }
}

///|
pub fn EdgeOptions::with_angle(self : EdgeOptions, angle : Int) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle,
    shorten: self.shorten,
    level: self.level,
    shape: self.shape,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: self.style,
  }
}

///|
pub fn EdgeOptions::with_shorten(
  self : EdgeOptions,
  source : Int,
  target : Int,
) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: { source, target },
    level: self.level,
    shape: self.shape,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: self.style,
  }
}

///|
pub fn EdgeOptions::with_colour(
  self : EdgeOptions,
  colour : Colour,
) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: self.shape,
    colour,
    edge_alignment: self.edge_alignment,
    style: self.style,
  }
}

///|
pub fn EdgeOptions::with_edge_alignment(
  self : EdgeOptions,
  source : Bool,
  target : Bool,
) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: self.shape,
    colour: self.colour,
    edge_alignment: { source, target },
    style: self.style,
  }
}

///|
pub fn EdgeOptions::with_edge_alignment_source(
  self : EdgeOptions,
  source : Bool,
) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: self.shape,
    colour: self.colour,
    edge_alignment: { source, target: self.edge_alignment.target },
    style: self.style,
  }
}

///|
pub fn EdgeOptions::with_edge_alignment_target(
  self : EdgeOptions,
  target : Bool,
) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: self.shape,
    colour: self.colour,
    edge_alignment: { source: self.edge_alignment.source, target },
    style: self.style,
  }
}

///|
pub fn EdgeOptions::with_style_name(
  self : EdgeOptions,
  name : String,
) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: self.shape,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: {
      name,
      tail: self.style.tail,
      body: self.style.body,
      head: self.style.head,
    },
  }
}

///|
pub fn EdgeOptions::with_style_tail(
  self : EdgeOptions,
  name : String,
  side? : String = "",
) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: self.shape,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: {
      name: self.style.name,
      tail: { name, side },
      body: self.style.body,
      head: self.style.head,
    },
  }
}

///|
pub fn EdgeOptions::with_style_body(
  self : EdgeOptions,
  name : String,
  side? : String = "",
) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: self.shape,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: {
      name: self.style.name,
      tail: self.style.tail,
      body: { name, side },
      head: self.style.head,
    },
  }
}

///|
pub fn EdgeOptions::with_style_head(
  self : EdgeOptions,
  name : String,
  side? : String = "",
) -> EdgeOptions {
  {
    label_alignment: self.label_alignment,
    label_position: self.label_position,
    offset: self.offset,
    curve: self.curve,
    radius: self.radius,
    angle: self.angle,
    shorten: self.shorten,
    level: self.level,
    shape: self.shape,
    colour: self.colour,
    edge_alignment: self.edge_alignment,
    style: {
      name: self.style.name,
      tail: self.style.tail,
      body: self.style.body,
      head: { name, side },
    },
  }
}
