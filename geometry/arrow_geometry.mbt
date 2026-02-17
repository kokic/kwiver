///|
pub struct ArrowGeometryConfig {
  curve_height : Double
  loop_height : Double
  edge_offset_distance : Double
  label_padding : Double
  arc_outer_dis : Double
  arc_inner_dis : Double
  minimum_arc_chord : Double
}

///|
pub fn ArrowGeometryConfig::default() -> ArrowGeometryConfig {
  {
    curve_height: 24.0,
    loop_height: 16.0,
    edge_offset_distance: 8.0,
    label_padding: 8.0,
    arc_outer_dis: 96.0,
    arc_inner_dis: 64.0,
    minimum_arc_chord: 0.01,
  }
}

///|
fn ArrowGeometryConfig::curve_model_config(
  self : ArrowGeometryConfig,
) -> ArrowCurveModelConfig {
  {
    curve_height: self.curve_height,
    loop_height: self.loop_height,
    edge_offset_distance: self.edge_offset_distance,
    arc_outer_dis: self.arc_outer_dis,
    arc_inner_dis: self.arc_inner_dis,
    minimum_arc_chord: self.minimum_arc_chord,
  }
}

///|
fn ArrowGeometryConfig::layout_config(
  self : ArrowGeometryConfig,
) -> ArrowLayoutConfig {
  {
    label_padding: self.label_padding,
    boundary_samples: 256,
    boundary_iterations: 30,
  }
}

///|
pub struct ArrowEndpoints {
  start : CurvePoint
  end : CurvePoint
}

///|
pub struct ArrowGeometry {
  source : ArrowShape
  target : ArrowShape
  options : EdgeOptions
  config : ArrowGeometryConfig
}

///|
pub fn ArrowGeometry::new(
  source : ArrowShape,
  target : ArrowShape,
  options : EdgeOptions,
) -> ArrowGeometry {
  { source, target, options, config: ArrowGeometryConfig::default() }
}

///|
pub fn ArrowGeometry::with_config(
  source : ArrowShape,
  target : ArrowShape,
  options : EdgeOptions,
  config : ArrowGeometryConfig,
) -> ArrowGeometry {
  { source, target, options, config }
}

///|
fn ArrowGeometry::curve_model(self : ArrowGeometry) -> ArrowCurveModel {
  ArrowCurveModel::with_config(
    self.source.origin(),
    self.target.origin(),
    self.options,
    self.config.curve_model_config(),
  )
}

///|
fn ArrowGeometry::layout(self : ArrowGeometry) -> ArrowLayout {
  ArrowLayout::with_config(
    self.source,
    self.target,
    self.curve_model(),
    self.options,
    self.config.layout_config(),
  )
}

///|
pub fn ArrowGeometry::endpoints(self : ArrowGeometry) -> ArrowEndpoints {
  let endpoints = self.layout().clipped_endpoints()
  { start: endpoints.start, end: endpoints.end }
}

///|
pub fn ArrowGeometry::path_points(
  self : ArrowGeometry,
  segments? : Int = 64,
) -> Array[Point] {
  let curve_model = self.curve_model()
  let interval = self.layout().shortened_interval()
  curve_model.path_points(interval, segments~)
}

///|
pub fn ArrowGeometry::path_svg(
  self : ArrowGeometry,
  segments? : Int = 64,
) -> String {
  let curve_model = self.curve_model()
  let interval = self.layout().shortened_interval()
  curve_model.path_svg(interval, segments~)
}

///|
pub fn ArrowGeometry::label_position(
  self : ArrowGeometry,
  label_width : Double,
  label_height : Double,
  edge_width? : Double = 1.5,
) -> Point {
  self.layout().label_position(label_width, label_height, edge_width~)
}
