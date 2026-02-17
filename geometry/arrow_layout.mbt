///|
pub struct ArrowShapeRoundedRect {
  origin : Point
  width : Double
  height : Double
  radius : Double
}

///|
enum ArrowShapeData {
  Endpoint(Point)
  RoundedRect(ArrowShapeRoundedRect)
}

///|
pub struct ArrowShape {
  data : ArrowShapeData
}

///|
pub fn ArrowShape::endpoint(origin : Point) -> ArrowShape {
  { data: ArrowShapeData::Endpoint(origin) }
}

///|
pub fn ArrowShape::rounded_rect(
  origin : Point,
  width : Double,
  height : Double,
  radius : Double,
) -> ArrowShape {
  { data: ArrowShapeData::RoundedRect({ origin, width, height, radius }) }
}

///|
pub fn ArrowShape::origin(self : ArrowShape) -> Point {
  match self.data {
    ArrowShapeData::Endpoint(origin) => origin
    ArrowShapeData::RoundedRect(rect) => rect.origin
  }
}

///|
fn ArrowShape::contains(self : ArrowShape, point : Point) -> Bool {
  match self.data {
    ArrowShapeData::Endpoint(origin) => point.eq(origin)
    ArrowShapeData::RoundedRect(rect) => {
      let hw = rect.width / 2.0
      let hh = rect.height / 2.0
      let ax = Double::abs(point.x - rect.origin.x)
      let ay = Double::abs(point.y - rect.origin.y)
      if ax > hw || ay > hh {
        return false
      }

      let radius = Double::abs(rect.radius)
      let r = if radius > hw { hw } else if radius > hh { hh } else { radius }

      let dx = ax - (hw - r)
      let dy = ay - (hh - r)
      if dx <= 0.0 || dy <= 0.0 {
        true
      } else {
        dx * dx + dy * dy <= r * r
      }
    }
  }
}

///|
pub struct ArrowLayoutConfig {
  label_padding : Double
  boundary_samples : Int
  boundary_iterations : Int
}

///|
pub fn ArrowLayoutConfig::default() -> ArrowLayoutConfig {
  { label_padding: 8.0, boundary_samples: 256, boundary_iterations: 30 }
}

///|
pub struct ArrowLayoutEndpoints {
  start : CurvePoint
  end : CurvePoint
}

///|
pub struct ArrowLayout {
  source : ArrowShape
  target : ArrowShape
  curve_model : ArrowCurveModel
  options : EdgeOptions
  config : ArrowLayoutConfig
}

///|
pub fn ArrowLayout::new(
  source : ArrowShape,
  target : ArrowShape,
  curve_model : ArrowCurveModel,
  options : EdgeOptions,
) -> ArrowLayout {
  { source, target, curve_model, options, config: ArrowLayoutConfig::default() }
}

///|
pub fn ArrowLayout::with_config(
  source : ArrowShape,
  target : ArrowShape,
  curve_model : ArrowCurveModel,
  options : EdgeOptions,
  config : ArrowLayoutConfig,
) -> ArrowLayout {
  { source, target, curve_model, options, config }
}

///|
fn ArrowLayout::curve_point(self : ArrowLayout, t : Double) -> CurvePoint {
  CurvePoint::new(self.curve_model.point(t), t, self.curve_model.tangent(t))
}

///|
fn ArrowLayout::binary_boundary(
  self : ArrowLayout,
  shape : ArrowShape,
  lo : Double,
  hi : Double,
  source_side : Bool,
) -> Double {
  let mut left = lo
  let mut right = hi
  let iterations = if self.config.boundary_iterations < 1 {
    1
  } else {
    self.config.boundary_iterations
  }

  let mut i = 0
  while i < iterations {
    let mid = (left + right) / 2.0
    let inside = shape.contains(self.curve_model.point(mid))
    if source_side {
      if inside {
        left = mid
      } else {
        right = mid
      }
    } else if inside {
      right = mid
    } else {
      left = mid
    }
    i = i + 1
  }

  if source_side {
    left
  } else {
    right
  }
}

///|
fn ArrowLayout::endpoint_for_shape(
  self : ArrowLayout,
  shape : ArrowShape,
  source_side : Bool,
) -> CurvePoint {
  match shape.data {
    ArrowShapeData::Endpoint(_) => {
      let t = if source_side { 0.0 } else { 1.0 }
      self.curve_point(t)
    }
    ArrowShapeData::RoundedRect(_) => {
      let samples = if self.config.boundary_samples < 2 {
        2
      } else {
        self.config.boundary_samples
      }

      if source_side {
        let mut prev_t = 0.0
        let mut prev_inside = shape.contains(self.curve_model.point(prev_t))
        let mut found : Double? = None
        let mut i = 1
        while i <= samples {
          let t = i.to_double() / samples.to_double()
          let inside = shape.contains(self.curve_model.point(t))
          if prev_inside && !inside {
            found = Some(self.binary_boundary(shape, prev_t, t, true))
            break
          }
          prev_t = t
          prev_inside = inside
          i = i + 1
        }
        let t = match found {
          Some(value) => value
          None => 0.0
        }
        self.curve_point(t)
      } else {
        let mut prev_t = 1.0
        let mut prev_inside = shape.contains(self.curve_model.point(prev_t))
        let mut found : Double? = None
        let mut i = 1
        while i <= samples {
          let t = 1.0 - i.to_double() / samples.to_double()
          let inside = shape.contains(self.curve_model.point(t))
          if prev_inside && !inside {
            found = Some(self.binary_boundary(shape, t, prev_t, false))
            break
          }
          prev_t = t
          prev_inside = inside
          i = i + 1
        }
        let t = match found {
          Some(value) => value
          None => 1.0
        }
        self.curve_point(t)
      }
    }
  }
}

///|
pub fn ArrowLayout::clipped_endpoints(
  self : ArrowLayout,
) -> ArrowLayoutEndpoints {
  {
    start: self.endpoint_for_shape(self.source, true),
    end: self.endpoint_for_shape(self.target, false),
  }
}

///|
pub fn ArrowLayout::clipped_interval(self : ArrowLayout) -> ArrowCurveInterval {
  let endpoints = self.clipped_endpoints()
  if endpoints.end.t < endpoints.start.t {
    let mid = (endpoints.start.t + endpoints.end.t) / 2.0
    ArrowCurveInterval::new(mid, mid)
  } else {
    ArrowCurveInterval::new(endpoints.start.t, endpoints.end.t)
  }
}

///|
pub fn ArrowLayout::shortened_interval(
  self : ArrowLayout,
) -> ArrowCurveInterval {
  self.curve_model.shorten_interval(self.clipped_interval())
}

///|
pub fn ArrowLayout::shortened_endpoints(
  self : ArrowLayout,
) -> ArrowLayoutEndpoints {
  let interval = self.shortened_interval()
  {
    start: self.curve_point(interval.start_t),
    end: self.curve_point(interval.end_t),
  }
}

///|
pub fn ArrowLayout::label_position(
  self : ArrowLayout,
  label_width : Double,
  label_height : Double,
  edge_width? : Double = 1.5,
) -> Point {
  let interval = self.shortened_interval()
  let ratio = self.options.label_position.to_double() / 100.0
  let t = interval.start_t + (interval.end_t - interval.start_t) * ratio
  let centre = self.curve_model.point(t)

  match self.options.label_alignment {
    LabelAlignment::Centre => centre
    LabelAlignment::Over => centre
    LabelAlignment::Left => {
      let offset_angle = self.curve_model.tangent(t) - @math.PI / 2.0
      let distance = self.config.label_padding +
        edge_width / 2.0 +
        @math.hypot(label_width / 2.0, label_height / 2.0)
      centre.add(Point::lendir(distance, offset_angle))
    }
    LabelAlignment::Right => {
      let offset_angle = self.curve_model.tangent(t) + @math.PI / 2.0
      let distance = self.config.label_padding +
        edge_width / 2.0 +
        @math.hypot(label_width / 2.0, label_height / 2.0)
      centre.add(Point::lendir(distance, offset_angle))
    }
  }
}
