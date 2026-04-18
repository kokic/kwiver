///|
pub struct QuiverReconnectPreviewPlan {
  edge_id : Int
  edges : Array[Edge]
}

///|
priv struct QuiverEdgeSuggestionCandidate {
  label_alignment : LabelAlignment
  offset : Int?
  curve : Int?
}

///|
fn quiver_preview_level_or_committed(
  preview_levels : @hashmap.HashMap[Int, Int],
  quiver : Quiver,
  cell_id : Int,
) -> Int {
  match preview_levels.get(cell_id) {
    Some(level) => level
    None => quiver.cell_level_or_default(cell_id)
  }
}

///|
fn quiver_preview_root_shape(
  committed : Edge,
  source_id : Int,
  target_id : Int,
) -> EdgeShape {
  if committed.source == committed.target && source_id == target_id {
    EdgeShape::Arc
  } else {
    EdgeShape::Bezier
  }
}

///|
fn quiver_preview_edge_with_shape(edge : Edge, shape : EdgeShape) -> Edge {
  let options = match shape {
    EdgeShape::Bezier => edge.options.with_shape_bezier()
    EdgeShape::Arc => edge.options.with_shape_arc()
  }
  Edge::new(
    edge.cell.id,
    edge.cell.label,
    edge.source,
    edge.target,
    options.with_level(edge.cell.level),
    edge.cell.label_colour,
  )
}

///|
fn quiver_preview_count_value(
  counts : @hashmap.HashMap[Int, Int],
  value : Int,
) -> Unit {
  match counts.get(value) {
    Some(count) => counts.set(value, count + 1)
    None => counts.set(value, 1)
  }
}

///|
fn quiver_preview_count_lookup(
  counts : @hashmap.HashMap[Int, Int],
  value : Int,
) -> Int {
  match counts.get(value) {
    Some(count) => count
    None => 0
  }
}

///|
fn quiver_preview_singleton_key(
  counts : @hashmap.HashMap[Int, Int],
) -> Int? {
  let keys = Array::from_iter(counts.keys())
  if keys.length() == 1 {
    Some(keys[0])
  } else {
    None
  }
}

///|
fn quiver_preview_alignment_key(alignment : LabelAlignment) -> Int {
  match alignment {
    LabelAlignment::Left => 0
    LabelAlignment::Centre => 1
    LabelAlignment::Right => 2
    LabelAlignment::Over => 3
  }
}

///|
fn quiver_preview_alignment_from_key(key : Int) -> LabelAlignment {
  match key {
    0 => LabelAlignment::Left
    1 => LabelAlignment::Centre
    2 => LabelAlignment::Right
    _ => LabelAlignment::Over
  }
}

///|
fn quiver_preview_options_with_label_alignment(
  options : EdgeOptions,
  alignment : LabelAlignment,
) -> EdgeOptions {
  match alignment {
    LabelAlignment::Left => options.with_label_alignment_left()
    LabelAlignment::Centre => options.with_label_alignment_centre()
    LabelAlignment::Right => options.with_label_alignment_right()
    LabelAlignment::Over => options.with_label_alignment_over()
  }
}

///|
fn quiver_preview_flip_label_alignment(
  alignment : LabelAlignment,
) -> LabelAlignment {
  match alignment {
    LabelAlignment::Left => LabelAlignment::Right
    LabelAlignment::Centre => LabelAlignment::Centre
    LabelAlignment::Right => LabelAlignment::Left
    LabelAlignment::Over => LabelAlignment::Over
  }
}

///|
fn quiver_preview_preserve_candidate(
  options : EdgeOptions,
) -> QuiverEdgeSuggestionCandidate {
  {
    label_alignment: options.label_alignment,
    offset: Some(options.offset),
    curve: Some(options.curve),
  }
}

///|
fn quiver_preview_flip_candidate(
  options : EdgeOptions,
) -> QuiverEdgeSuggestionCandidate {
  {
    label_alignment: quiver_preview_flip_label_alignment(options.label_alignment),
    offset: Some(-options.offset),
    curve: Some(-options.curve),
  }
}

///|
fn quiver_preview_conserve_candidate(
  candidate : QuiverEdgeSuggestionCandidate,
  parallel : Bool,
) -> QuiverEdgeSuggestionCandidate {
  if parallel {
    candidate
  } else {
    { label_alignment: candidate.label_alignment, offset: None, curve: None }
  }
}

///|
fn quiver_preview_normalize_loop_angle(angle : Int) -> Int {
  let mut normalized = (angle + 360) % 360
  if normalized < 0 {
    normalized += 360
  }
  normalized - 180
}

///|
fn quiver_preview_edge_options(quiver : Quiver, edge_id : Int) -> EdgeOptions? {
  match quiver.cells.get(edge_id) {
    Some(CellData::Edge(edge)) => Some(edge.options)
    _ => None
  }
}

///|
pub fn Quiver::preview_reconnect_plan(
  self : Quiver,
  edge_id : Int,
  source_id : Int,
  target_id : Int,
) -> QuiverReconnectPreviewPlan? {
  if !self.contains_cell(edge_id) ||
    !self.contains_cell(source_id) ||
    !self.contains_cell(target_id) {
    return None
  }

  let root_edge = match self.cells.get(edge_id) {
    Some(CellData::Edge(edge)) => edge
    _ => return None
  }
  let closure = self.transitive_dependencies([edge_id])
  let preview_levels : @hashmap.HashMap[Int, Int] = @hashmap.new()
  let preview_edges : @hashmap.HashMap[Int, Edge] = @hashmap.new()

  for cell_id in closure {
    match self.cells.get(cell_id) {
      Some(CellData::Edge(edge)) => {
        let preview_source = if cell_id == edge_id { source_id } else { edge.source }
        let preview_target = if cell_id == edge_id { target_id } else { edge.target }
        let preview_level = Int::max(
            quiver_preview_level_or_committed(preview_levels, self, preview_source),
            quiver_preview_level_or_committed(preview_levels, self, preview_target),
          ) +
          1
        let mut preview_edge = edge.reconnected(
          preview_source,
          preview_target,
          preview_level,
        )
        if cell_id == edge_id {
          preview_edge = quiver_preview_edge_with_shape(
            preview_edge,
            quiver_preview_root_shape(root_edge, source_id, target_id),
          )
        }
        preview_levels.set(cell_id, preview_level)
        preview_edges.set(cell_id, preview_edge)
      }
      _ => ()
    }
  }

  let ordered = closure.copy()
  ordered.sort_by((left, right) => {
    let left_level = quiver_preview_level_or_committed(preview_levels, self, left)
    let right_level = quiver_preview_level_or_committed(preview_levels, self, right)
    if left_level != right_level {
      left_level - right_level
    } else {
      left - right
    }
  })

  let edges : Array[Edge] = []
  for cell_id in ordered {
    match preview_edges.get(cell_id) {
      Some(edge) => edges.push(edge)
      None => ()
    }
  }
  Some({ edge_id, edges })
}

///|
pub fn Quiver::suggest_edge_options(
  self : Quiver,
  source_id : Int,
  target_id : Int,
  default_label_alignment? : LabelAlignment = LabelAlignment::Left,
) -> EdgeOptions? {
  if !self.contains_cell(source_id) || !self.contains_cell(target_id) {
    return None
  }

  let source_level = self.cell_level_or_default(source_id)
  let target_level = self.cell_level_or_default(target_id)
  let level = Int::max(source_level, target_level) + 1
  let mut options = quiver_preview_options_with_label_alignment(
    EdgeOptions::at_level(level),
    default_label_alignment,
  )
  options = options.with_shorten(
    if source_level == 0 { 0 } else { 20 },
    if target_level == 0 { 0 } else { 20 },
  )

  if source_id == target_id {
    options = options.with_shape_arc()

    let angles : @hashmap.HashMap[Int, Int] = @hashmap.new()
    self.dependencies_of(source_id).each((edge_id, _) => {
      match self.cells.get(edge_id) {
        Some(CellData::Edge(edge)) => {
          if edge.source == edge.target {
            let angle = quiver_preview_normalize_loop_angle(
              edge.options.angle +
              180 +
              (if edge.options.radius < -1 { -180 } else { 0 }),
            )
            let radius = Int::abs(edge.options.radius)
            angles.set(angle, radius)
            if Int::abs(angle) == 180 {
              angles.set(-angle, radius)
            }
          }
        }
        _ => ()
      }
    })

    let mut found_space = false
    for angle in [0, 45, 90, 135, 180, 225, 270, 315] {
      let attempt_angle = quiver_preview_normalize_loop_angle(180 - angle)
      if !angles.contains(attempt_angle) {
        options = options.with_angle(attempt_angle)
        found_space = true
        break
      }
    }
    if !found_space {
      let default_radius = Int::abs(EdgeOptions::default().radius)
      for angle in [0, 45, 90, 135, 180, 225, 270, 315] {
        let attempt_angle = quiver_preview_normalize_loop_angle(180 - angle)
        match angles.get(attempt_angle) {
          Some(radius) => {
            if radius != default_radius {
              options = options.with_angle(attempt_angle)
              break
            }
          }
          None => {
            options = options.with_angle(attempt_angle)
            break
          }
        }
      }
    }
    return Some(options)
  }

  let align : @hashmap.HashMap[Int, Int] = @hashmap.new()
  let offset : @hashmap.HashMap[Int, Int] = @hashmap.new()
  let curve : @hashmap.HashMap[Int, Int] = @hashmap.new()
  let offset_only : @hashmap.HashMap[Int, Int] = @hashmap.new()
  let mut balance = 0

  let source_dependencies = self.dependencies_of(source_id)
  let target_dependencies = self.dependencies_of(target_id)

  source_dependencies.each((edge_id, relationship) => {
    match quiver_preview_edge_options(self, edge_id) {
      Some(committed_options) => {
        let candidate = quiver_preview_conserve_candidate(
          match relationship {
            DependencyRole::Source => quiver_preview_flip_candidate(committed_options)
            DependencyRole::Target => quiver_preview_preserve_candidate(committed_options)
          },
          target_dependencies.contains(edge_id),
        )
        quiver_preview_count_value(
          align,
          quiver_preview_alignment_key(candidate.label_alignment),
        )
        match candidate.offset {
          Some(value) => {
            quiver_preview_count_value(offset, value)
            match candidate.curve {
              Some(curve_value) => {
                if curve_value == 0 {
                  quiver_preview_count_value(offset_only, value)
                }
              }
              None => quiver_preview_count_value(offset_only, value)
            }
          }
          None => ()
        }
        match candidate.curve {
          Some(value) => quiver_preview_count_value(curve, value)
          None => ()
        }
        balance -= 1
      }
      None => ()
    }
  })

  target_dependencies.each((edge_id, relationship) => {
    match quiver_preview_edge_options(self, edge_id) {
      Some(committed_options) => {
        let candidate = quiver_preview_conserve_candidate(
          match relationship {
            DependencyRole::Source => quiver_preview_preserve_candidate(committed_options)
            DependencyRole::Target => quiver_preview_flip_candidate(committed_options)
          },
          source_dependencies.contains(edge_id),
        )
        quiver_preview_count_value(
          align,
          quiver_preview_alignment_key(candidate.label_alignment),
        )
        match candidate.offset {
          Some(value) => {
            quiver_preview_count_value(offset, value)
            match candidate.curve {
              Some(curve_value) => {
                if curve_value == 0 {
                  quiver_preview_count_value(offset_only, value)
                }
              }
              None => quiver_preview_count_value(offset_only, value)
            }
          }
          None => ()
        }
        match candidate.curve {
          Some(value) => quiver_preview_count_value(curve, value)
          None => ()
        }
        balance += 1
      }
      None => ()
    }
  })

  match quiver_preview_singleton_key(align) {
    Some(key) =>
      options = quiver_preview_options_with_label_alignment(
        options,
        quiver_preview_alignment_from_key(key),
      )
    None => {
      if Array::from_iter(align.keys()).length() > 0 &&
        quiver_preview_count_lookup(align, quiver_preview_alignment_key(LabelAlignment::Left)) ==
          quiver_preview_count_lookup(
            align,
            quiver_preview_alignment_key(LabelAlignment::Right),
          ) &&
        balance == 0 {
        options = options.with_label_alignment_centre()
      }
    }
  }

  match quiver_preview_singleton_key(offset) {
    Some(value) => options = options.with_offset(value)
    None => ()
  }
  match quiver_preview_singleton_key(curve) {
    Some(value) => options = options.with_curve(value)
    None => ()
  }

  if options.offset == 0 {
    for attempt in [0, -3, 3, -5, 5, -1, 1, -2, 2, -4, 4] {
      if !offset_only.contains(-attempt) {
        options = options.with_offset(attempt)
        break
      }
    }
  }

  Some(options.with_shape_bezier())
}
