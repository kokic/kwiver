///|
pub struct QuiverReconnectPreviewPlan {
  edge_id : Int
  edges : Array[Edge]
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
