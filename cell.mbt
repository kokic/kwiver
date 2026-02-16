///|
pub struct Cell {
  id : Int
  level : Int
  label : String
  label_colour : Colour
}

///|
pub fn Cell::new(
  id : Int,
  level : Int,
  label : String,
  label_colour : Colour,
) -> Cell {
  { id, level: if level < 0 { 0 } else { level }, label, label_colour }
}

///|
pub struct Vertex {
  cell : Cell
  x : Int
  y : Int
}

///|
pub fn Vertex::new(
  id : Int,
  label : String,
  x : Int,
  y : Int,
  label_colour : Colour,
) -> Vertex {
  { cell: Cell::new(id, 0, label, label_colour), x, y }
}

///|
pub fn Vertex::new_black(id : Int, label : String, x : Int, y : Int) -> Vertex {
  Vertex::new(id, label, x, y, Colour::black())
}

///|
pub struct Edge {
  cell : Cell
  source : Int
  target : Int
  options : EdgeOptions
}

///|
pub fn Edge::new(
  id : Int,
  label : String,
  source : Int,
  target : Int,
  options : EdgeOptions,
  label_colour : Colour,
) -> Edge {
  {
    cell: Cell::new(id, options.level, label, label_colour),
    source,
    target,
    options,
  }
}

///|
pub enum CellData {
  Vertex(Vertex)
  Edge(Edge)
}

///|
pub fn CellData::from_vertex(vertex : Vertex) -> CellData {
  CellData::Vertex(vertex)
}

///|
pub fn CellData::from_edge(edge : Edge) -> CellData {
  CellData::Edge(edge)
}

///|
pub fn CellData::id(self : CellData) -> Int {
  match self {
    CellData::Vertex(vertex) => vertex.cell.id
    CellData::Edge(edge) => edge.cell.id
  }
}

///|
pub fn CellData::level(self : CellData) -> Int {
  match self {
    CellData::Vertex(vertex) => vertex.cell.level
    CellData::Edge(edge) => edge.cell.level
  }
}

///|
pub fn CellData::is_vertex(self : CellData) -> Bool {
  match self {
    CellData::Vertex(_) => true
    CellData::Edge(_) => false
  }
}

///|
pub fn CellData::is_edge(self : CellData) -> Bool {
  match self {
    CellData::Vertex(_) => false
    CellData::Edge(_) => true
  }
}

///|
pub fn Edge::reconnected(
  self : Edge,
  source : Int,
  target : Int,
  level : Int,
) -> Edge {
  {
    cell: Cell::new(
      self.cell.id,
      level,
      self.cell.label,
      self.cell.label_colour,
    ),
    source,
    target,
    options: self.options.with_level(level),
  }
}
