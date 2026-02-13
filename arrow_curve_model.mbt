pub struct ArrowCurveModelConfig {
  curve_height : Double
  loop_height : Double
  edge_offset_distance : Double
  arc_outer_dis : Double
  arc_inner_dis : Double
  minimum_arc_chord : Double
}

pub fn ArrowCurveModelConfig::default() -> ArrowCurveModelConfig {
  {
    curve_height: 24.0,
    loop_height: 16.0,
    edge_offset_distance: 8.0,
    arc_outer_dis: 96.0,
    arc_inner_dis: 64.0,
    minimum_arc_chord: 0.01,
  }
}

pub struct ArrowCurveInterval {
  start_t : Double
  end_t : Double
}

pub fn ArrowCurveInterval::new(start_t : Double, end_t : Double) -> ArrowCurveInterval {
  { start_t, end_t }
}

pub fn ArrowCurveInterval::full() -> ArrowCurveInterval {
  { start_t: 0.0, end_t: 1.0 }
}

pub struct ArrowCurveModel {
  source_origin : Point
  target_origin : Point
  options : EdgeOptions
  config : ArrowCurveModelConfig
}

pub fn ArrowCurveModel::new(
  source_origin : Point,
  target_origin : Point,
  options : EdgeOptions,
) -> ArrowCurveModel {
  {
    source_origin,
    target_origin,
    options,
    config: ArrowCurveModelConfig::default(),
  }
}

pub fn ArrowCurveModel::with_config(
  source_origin : Point,
  target_origin : Point,
  options : EdgeOptions,
  config : ArrowCurveModelConfig,
) -> ArrowCurveModel {
  { source_origin, target_origin, options, config }
}

fn arrow_curve_model_int_sign(value : Int) -> Double {
  if value > 0 {
    1.0
  } else if value < 0 {
    -1.0
  } else {
    0.0
  }
}

fn arrow_curve_model_deg_to_rad(deg : Double) -> Double {
  deg * @math.PI / 180.0
}

fn ArrowCurveModel::base_angle(self : ArrowCurveModel) -> Double {
  self.target_origin.sub(self.source_origin).angle()
}

fn ArrowCurveModel::chord_length(self : ArrowCurveModel) -> Double {
  let length = self.target_origin.sub(self.source_origin).length()
  let is_arc = match self.options.shape {
    EdgeShape::Arc => true
    _ => false
  }
  if is_arc && length == 0.0 {
    self.config.minimum_arc_chord
  } else {
    length
  }
}

fn ArrowCurveModel::loop_radius_pixels(self : ArrowCurveModel) -> Double {
  let abs_radius = Int::abs(self.options.radius)
  let step = if abs_radius < 2 {
    2.0
  } else if abs_radius < 4 {
    3.0
  } else {
    4.0
  }
  step * arrow_curve_model_int_sign(self.options.radius) * self.config.loop_height
}

fn ArrowCurveModel::bezier_height_pixels(self : ArrowCurveModel) -> Double {
  self.options.curve.to_double() * self.config.curve_height * 2.0
}

priv enum ArrowCurveModelData {
  Bezier(Bezier)
  Arc(Arc)
}

fn ArrowCurveModel::arc_for_chord(self : ArrowCurveModel, chord : Double, loop_radius : Double) -> Arc {
  let outer_dis = self.config.arc_outer_dis
  let inner_dis = self.config.arc_inner_dis
  let semicircle_radius = inner_dis / 2.0
  let boundary_dis = outer_dis - inner_dis
  let sagitta = if chord >= outer_dis {
    EPSILON
  } else {
    semicircle_radius * ((outer_dis - chord) / boundary_dis)
  }
  let r_for_sagitta = sagitta / 2.0 + (chord * chord) / (8.0 * sagitta)
  let r = if chord <= inner_dis {
    semicircle_radius + (inner_dis - chord) / inner_dis * (loop_radius - semicircle_radius)
  } else {
    r_for_sagitta
  }
  Arc::new(Point::zero(), chord, chord <= inner_dis, r, 0.0)
}

fn ArrowCurveModel::curve_data(self : ArrowCurveModel) -> ArrowCurveModelData {
  let chord = self.chord_length()
  match self.options.shape {
    EdgeShape::Bezier => ArrowCurveModelData::Bezier(
      Bezier::new(Point::zero(), chord, self.bezier_height_pixels(), 0.0),
    )
    EdgeShape::Arc => {
      let loop_radius = self.loop_radius_pixels()
      if self.source_origin.eq(self.target_origin) {
        ArrowCurveModelData::Arc(
          Arc::new(
            Point::zero(),
            chord,
            true,
            loop_radius,
            arrow_curve_model_deg_to_rad(self.options.angle.to_double()),
          ),
        )
      } else {
        ArrowCurveModelData::Arc(self.arc_for_chord(chord, loop_radius))
      }
    }
  }
}

fn ArrowCurveModel::curve_point(curve : ArrowCurveModelData, t : Double) -> Point {
  match curve {
    ArrowCurveModelData::Bezier(bezier) => bezier.point(t)
    ArrowCurveModelData::Arc(arc) => arc.point(t)
  }
}

fn ArrowCurveModel::curve_tangent(curve : ArrowCurveModelData, t : Double) -> Double {
  match curve {
    ArrowCurveModelData::Bezier(bezier) => bezier.tangent(t)
    ArrowCurveModelData::Arc(arc) => arc.tangent(t)
  }
}

fn ArrowCurveModel::curve_arc_length(curve : ArrowCurveModelData, t : Double) -> Double {
  match curve {
    ArrowCurveModelData::Bezier(bezier) => bezier.arc_length(t)
    ArrowCurveModelData::Arc(arc) => arc.arc_length(t)
  }
}

fn ArrowCurveModel::curve_t_after_length(
  curve : ArrowCurveModelData,
  length : Double,
  clamp : Bool,
) -> Double {
  match curve {
    ArrowCurveModelData::Bezier(bezier) => bezier.t_after_length(clamp=clamp)(length)
    ArrowCurveModelData::Arc(arc) => arc.t_after_length(clamp=clamp)(length)
  }
}

fn ArrowCurveModel::local_to_world(self : ArrowCurveModel, local_point : Point) -> Point {
  let shifted = local_point.add(Point::new(
    0.0,
    self.options.offset.to_double() * self.config.edge_offset_distance,
  ))
  self.source_origin.add(shifted.rotate(self.base_angle()))
}

pub fn ArrowCurveModel::sample(self : ArrowCurveModel, t : Double) -> CurvePoint {
  let curve = self.curve_data()
  let local_point = ArrowCurveModel::curve_point(curve, t)
  let point = self.local_to_world(local_point)
  let angle = ArrowCurveModel::curve_tangent(curve, t) + self.base_angle()
  CurvePoint::new(point, t, angle)
}

pub fn ArrowCurveModel::point(self : ArrowCurveModel, t : Double) -> Point {
  self.sample(t).point()
}

pub fn ArrowCurveModel::tangent(self : ArrowCurveModel, t : Double) -> Double {
  self.sample(t).angle
}

pub fn ArrowCurveModel::arc_length(self : ArrowCurveModel, t : Double) -> Double {
  ArrowCurveModel::curve_arc_length(self.curve_data(), t)
}

pub fn ArrowCurveModel::t_after_length(
  self : ArrowCurveModel,
  length : Double,
  clamp~ : Bool = false,
) -> Double {
  ArrowCurveModel::curve_t_after_length(self.curve_data(), length, clamp)
}

pub fn ArrowCurveModel::shorten_interval(
  self : ArrowCurveModel,
  interval : ArrowCurveInterval,
) -> ArrowCurveInterval {
  let arc_start = self.arc_length(interval.start_t)
  let arc_end = self.arc_length(interval.end_t)
  let visible = if arc_end > arc_start { arc_end - arc_start } else { 0.0 }
  let shorten_start = visible * self.options.shorten.source.to_double() / 100.0
  let shorten_end = visible * self.options.shorten.target.to_double() / 100.0
  let mut start_t = self.t_after_length(arc_start + shorten_start, clamp=true)
  let mut end_t = self.t_after_length(arc_end - shorten_end, clamp=true)
  if end_t < start_t {
    let mid = (start_t + end_t) / 2.0
    start_t = mid
    end_t = mid
  }
  ArrowCurveInterval::new(start_t, end_t)
}

pub fn ArrowCurveModel::path_points(
  self : ArrowCurveModel,
  interval : ArrowCurveInterval,
  segments~ : Int = 64,
) -> Array[Point] {
  let n = if segments < 2 { 2 } else { segments }
  let points : Array[Point] = []
  for i in 0..=n {
    let ratio = i.to_double() / n.to_double()
    let t = interval.start_t + (interval.end_t - interval.start_t) * ratio
    points.push(self.point(t))
  }
  points
}

pub fn ArrowCurveModel::path_svg(
  self : ArrowCurveModel,
  interval : ArrowCurveInterval,
  segments~ : Int = 64,
) -> String {
  let points = self.path_points(interval, segments=segments)
  if points.is_empty() {
    return ""
  }
  let parts : Array[String] = []
  parts.push("M")
  parts.push("${points[0].x}")
  parts.push("${points[0].y}")
  for i in 1..<points.length() {
    parts.push("L")
    parts.push("${points[i].x}")
    parts.push("${points[i].y}")
  }
  parts.join(" ")
}
