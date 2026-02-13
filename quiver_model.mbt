pub enum DependencyRole {
  Source
  Target
}

pub struct Quiver {
  cells_by_level : Array[@hashmap.HashMap[Int, Bool]]
  cells : @hashmap.HashMap[Int, CellData]
  dependencies : @hashmap.HashMap[Int, @hashmap.HashMap[Int, DependencyRole]]
  reverse_dependencies : @hashmap.HashMap[Int, @hashmap.HashMap[Int, Bool]]
  deleted : @hashmap.HashMap[Int, Int]
}

pub fn Quiver::new() -> Quiver {
  {
    cells_by_level: [],
    cells: @hashmap.new(),
    dependencies: @hashmap.new(),
    reverse_dependencies: @hashmap.new(),
    deleted: @hashmap.new(),
  }
}

fn Quiver::ensure_level(self : Quiver, level : Int) -> Unit {
  let target = if level < 0 { 0 } else { level }
  while self.cells_by_level.length() <= target {
    self.cells_by_level.push(@hashmap.new())
  }
}

fn Quiver::remove_from_level(self : Quiver, level : Int, cell_id : Int) -> Unit {
  if level >= 0 && level < self.cells_by_level.length() {
    self.cells_by_level[level].remove(cell_id)
  }
}

fn Quiver::cell_level_or_default(self : Quiver, cell_id : Int, default~ : Int = 0) -> Int {
  match self.cells.get(cell_id) {
    Some(cell) => cell.level()
    None => default
  }
}

pub fn Quiver::add(self : Quiver, cell : CellData) -> Unit {
  let cell_id = cell.id()
  let level = cell.level()
  self.cells.set(cell_id, cell)
  if !self.deleted.contains(cell_id) {
    self.dependencies.set(cell_id, @hashmap.new())
    self.reverse_dependencies.set(cell_id, @hashmap.new())
  } else {
    self.deleted.remove(cell_id)
  }
  self.ensure_level(level)
  self.cells_by_level[level].set(cell_id, true)
}

pub fn Quiver::remove(self : Quiver, cell_id : Int, when : Int) -> Array[Int] {
  let removed : @hashmap.HashMap[Int, Bool] = @hashmap.new()
  let removal_queue : Array[Int] = [cell_id]
  let mut index = 0
  while index < removal_queue.length() {
    let current = removal_queue[index]
    index = index + 1
    if !self.deleted.contains(current) {
      self.deleted.set(current, when)
      match self.cells.get(current) {
        Some(cell) => self.remove_from_level(cell.level(), current)
        None => ()
      }
      match self.dependencies.get(current) {
        Some(deps) => deps.each((dependency, _) => removal_queue.push(dependency))
        None => ()
      }
      removed.set(current, true)
    }
  }
  Array::from_iter(removed.keys())
}

pub fn Quiver::flush(self : Quiver, when : Int) -> Unit {
  let to_flush : Array[Int] = []
  self.deleted.each((cell_id, deleted_at) => {
    if deleted_at >= when {
      to_flush.push(cell_id)
    }
  })

  for cell_id in to_flush {
    self.dependencies.remove(cell_id)
    match self.reverse_dependencies.get(cell_id) {
      Some(reverse_deps) => reverse_deps.each((reverse_dep, _) => {
        match self.dependencies.get(reverse_dep) {
          Some(deps) => deps.remove(cell_id)
          None => ()
        }
      })
      None => ()
    }
    self.reverse_dependencies.remove(cell_id)
    self.deleted.remove(cell_id)
    self.cells.remove(cell_id)
  }
}

pub fn Quiver::all_cell_ids(self : Quiver) -> Array[Int] {
  let ids : Array[Int] = []
  self.cells.each((cell_id, _) => {
    if !self.deleted.contains(cell_id) {
      ids.push(cell_id)
    }
  })
  ids
}

pub fn Quiver::contains_cell(self : Quiver, cell_id : Int) -> Bool {
  self.cells.contains(cell_id) && !self.deleted.contains(cell_id)
}

pub fn Quiver::dependencies_of(
  self : Quiver,
  cell_id : Int,
) -> @hashmap.HashMap[Int, DependencyRole] {
  let filtered : @hashmap.HashMap[Int, DependencyRole] = @hashmap.new()
  match self.dependencies.get(cell_id) {
    Some(deps) => deps.each((dependency, relationship) => {
      if !self.deleted.contains(dependency) {
        filtered.set(dependency, relationship)
      }
    })
    None => ()
  }
  filtered
}

pub fn Quiver::reverse_dependencies_of(
  self : Quiver,
  cell_id : Int,
) -> @hashmap.HashMap[Int, Bool] {
  let filtered : @hashmap.HashMap[Int, Bool] = @hashmap.new()
  match self.reverse_dependencies.get(cell_id) {
    Some(deps) => deps.each((dependency, _) => {
      if !self.deleted.contains(dependency) {
        filtered.set(dependency, true)
      }
    })
    None => ()
  }
  filtered
}

pub fn Quiver::transitive_dependencies(
  self : Quiver,
  roots : Array[Int],
  exclude_roots~ : Bool = false,
) -> Array[Int] {
  let closure : @hashmap.HashMap[Int, Bool] = @hashmap.new()
  let queue : Array[Int] = []
  for cell_id in roots {
    if !closure.contains(cell_id) {
      closure.set(cell_id, true)
      queue.push(cell_id)
    }
  }
  let mut index = 0
  while index < queue.length() {
    let current = queue[index]
    index = index + 1
    self.dependencies_of(current).each((dependency, _) => {
      if !closure.contains(dependency) {
        closure.set(dependency, true)
        queue.push(dependency)
      }
    })
  }
  if exclude_roots {
    for root in roots {
      closure.remove(root)
    }
  }
  let ordered = Array::from_iter(closure.keys())
  ordered.sort_by((a, b) => self.cell_level_or_default(a) - self.cell_level_or_default(b))
  ordered
}

pub fn Quiver::transitive_reverse_dependencies(
  self : Quiver,
  roots : Array[Int],
) -> Array[Int] {
  let closure : @hashmap.HashMap[Int, Bool] = @hashmap.new()
  let queue : Array[Int] = []
  for cell_id in roots {
    if !closure.contains(cell_id) {
      closure.set(cell_id, true)
      queue.push(cell_id)
    }
  }
  let mut index = 0
  while index < queue.length() {
    let current = queue[index]
    index = index + 1
    self.reverse_dependencies_of(current).each((dependency, _) => {
      if !closure.contains(dependency) {
        closure.set(dependency, true)
        queue.push(dependency)
      }
    })
  }
  let ordered = Array::from_iter(closure.keys())
  ordered.sort_by((a, b) => self.cell_level_or_default(a) - self.cell_level_or_default(b))
  ordered
}

pub fn Quiver::connect(self : Quiver, source : Int, target : Int, edge_id : Int) -> Unit {
  let reverse_deps = self.reverse_dependencies.get_or_init(edge_id, () => @hashmap.new())

  // Clear old reverse dependencies for reconnection.
  let old_reverse = Array::from_iter(reverse_deps.keys())
  for cell_id in old_reverse {
    match self.dependencies.get(cell_id) {
      Some(deps) => deps.remove(edge_id)
      None => ()
    }
  }
  reverse_deps.clear()

  let source_deps = self.dependencies.get_or_init(source, () => @hashmap.new())
  source_deps.set(edge_id, DependencyRole::Source)

  let target_deps = self.dependencies.get_or_init(target, () => @hashmap.new())
  target_deps.set(edge_id, DependencyRole::Target)

  reverse_deps.set(source, true)
  reverse_deps.set(target, true)

  // Update endpoints first, preserving current level for now.
  match self.cells.get(edge_id) {
    Some(CellData::Edge(edge)) =>
      self.cells.set(
        edge_id,
        CellData::Edge(edge.reconnected(source, target, edge.cell.level)),
      )
    _ => ()
  }

  // Recompute levels for the edge and all transitively dependent edges.
  let closure = self.transitive_dependencies([edge_id])
  for cell_id in closure {
    match self.cells.get(cell_id) {
      Some(CellData::Edge(edge)) => {
        let old_level = edge.cell.level
        let new_level = Int::max(
          self.cell_level_or_default(edge.source),
          self.cell_level_or_default(edge.target),
        ) + 1
        if old_level != new_level {
          self.remove_from_level(old_level, cell_id)
          self.ensure_level(new_level)
          self.cells_by_level[new_level].set(cell_id, true)
        }
        self.cells.set(
          cell_id,
          CellData::Edge(edge.reconnected(edge.source, edge.target, new_level)),
        )
      }
      _ => ()
    }
  }
}
