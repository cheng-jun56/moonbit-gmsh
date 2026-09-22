///|
extern "js" fn fail_string(message : String) -> String =
  #| (message) => { throw new Error(message); }

///|
extern "js" fn fail_bytes(message : String) -> Bytes =
  #| (message) => { throw new Error(message); }

///|
fn object(text : String) -> Map[String, Json] raise {
  if text.length() > 8000000 {
    raise Failure("options exceed 8M characters")
  }
  match @json.parse(text) {
    Object(o) => o
    _ => raise Failure("expected JSON object")
  }
}

///|
fn[T : @json.FromJson] req(o : Map[String, Json], key : String) -> T raise {
  match o.get(key) {
    Some(j) => @json.from_json(j)
    None => raise Failure("missing option: " + key)
  }
}

///|
fn[T : @json.FromJson] opt(
  o : Map[String, Json],
  key : String,
  fallback : T,
) -> T raise {
  match o.get(key) {
    Some(j) => @json.from_json(j)
    None => fallback
  }
}

///|
fn dict(j : Json) -> Map[String, Json] raise {
  match j {
    Object(o) => o
    _ => raise Failure("expected object in array")
  }
}

///|
fn model(o : Map[String, Json]) -> @lib.Mesh raise {
  let ns : Array[Json] = req(o, "nodes")
  let es : Array[Json] = req(o, "elements")
  let ents : Array[Json] = opt(o, "entities", [])
  let names : Array[Json] = opt(o, "names", [])
  let fs : Array[Json] = opt(o, "fields", [])
  let unknown : Array[Json] = opt(o, "unknown", [])
  let nodes = ns.map(j => {
    let x = dict(j)
    @lib.Node::{
      tag: req(x, "tag"),
      xyz: req(x, "xyz"),
      dim: opt(x, "dim", -1),
      entity: opt(x, "entity", 0),
      parameters: opt(x, "parameters", []),
    }
  })
  let elements = es.map(j => {
    let x = dict(j)
    @lib.Element::{
      tag: req(x, "tag"),
      kind: req(x, "kind"),
      nodes: req(x, "nodes"),
      entity: opt(x, "entity", 0),
      physical: opt(x, "physical", []),
      extra: opt(x, "extra", []),
    }
  })
  let entities = ents.map(j => {
    let x = dict(j)
    @lib.Entity::{
      dim: req(x, "dim"),
      tag: req(x, "tag"),
      bounds: req(x, "bounds"),
      physical: opt(x, "physical", []),
      boundary: opt(x, "boundary", []),
    }
  })
  let names = names.map(j => {
    let x = dict(j)
    @lib.PhysicalName::{
      dim: req(x, "dim"),
      tag: req(x, "tag"),
      name: req(x, "name"),
    }
  })
  let fields = fs.map(j => {
    let x = dict(j)
    let data : Array[Json] = req(x, "entries")
    @lib.Field::{
      location: req(x, "location"),
      strings: req(x, "strings"),
      reals: req(x, "reals"),
      integers: req(x, "integers"),
      entries: data.map(j => {
        let d = dict(j)
        @lib.Datum::{ tag: req(d, "tag"), values: req(d, "values"), }
      }),
    }
  })
  let sections = unknown.map(j => {
    let x = dict(j)
    @lib.Section::{ name: req(x, "name"), body: req(x, "body"), }
  })
  @lib.mesh(
    nodes,
    elements,
    entities~,
    names~,
    fields~,
    unknown=sections,
    version=opt(o, "source_version", "2.2"),
  )
}

///|
fn encode(m : @lib.Mesh, o : Map[String, Json]) -> Bytes raise {
  let m = if opt(o, "drop_unknown", false) { m.without_unknown() } else { m }
  m.encode(
    version=opt(o, "version", m.source_version()),
    binary=opt(o, "binary", false),
    little=opt(o, "little", true),
    size_width=opt(o, "size_width", 8),
    allow_loss=opt(o, "allow_loss", false),
  )
}

///|
fn do_report(data : Bytes, options : String) -> String raise {
  let o = object(options)
  let m = @lib.decode(data)
  let command : String = opt(o, "command", "inspect")
  let result : Json = match command {
    "inspect" =>
      {
        "version": m.source_version().to_json(),
        "nodes": m.nodes().length().to_json(),
        "elements": m.elements().length().to_json(),
        "entities": m.entities().length().to_json(),
        "physical_names": m.physical_names().to_json(),
        "fields": m.fields().map(f => f.strings).to_json(),
        "unknown_sections": m.unknown_sections().map(s => s.name).to_json(),
      }
    "dump" =>
      {
        "version": m.source_version().to_json(),
        "nodes": m.nodes().to_json(),
        "elements": m.elements().to_json(),
        "entities": m.entities().to_json(),
        "names": m.physical_names().to_json(),
        "fields": m.fields().to_json(),
        "unknown": m.unknown_sections().to_json(),
      }
    "validate" =>
      m.diagnostics(tolerance=opt(o, "tolerance", 1.0e-12)).to_json()
    "quality" =>
      m.quality(req(o, "tag"), tolerance=opt(o, "tolerance", 1.0e-12)).to_json()
    "topology" => m.topology(dimension=opt(o, "dimension", -1)).to_json()
    "components" => m.components().to_json()
    "vtk" => { "text": m.vtk(allow_loss=opt(o, "allow_loss", false)).to_json() }
    "obj" => { "text": m.obj(allow_loss=opt(o, "allow_loss", false)).to_json() }
    _ => raise Failure("unknown report command: " + command)
  }
  result.stringify()
}

///|
pub fn report(data : Bytes, options : String) -> String {
  do_report(data, options) catch {
    e => fail_string(@debug.to_string(e))
  }
}

///|
fn do_transform(data : Bytes, options : String) -> Bytes raise {
  let o = object(options)
  let m = @lib.decode(data)
  let m = if opt(o, "drop_unknown", false) { m.without_unknown() } else { m }
  let command : String = opt(o, "command", "copy")
  let m = match command {
    "copy" | "convert" => m
    "subset" => m.subset(req(o, "tags"))
    "physical" => m.select_physical(req(o, "dimension"), req(o, "group"))
    "compact" => m.compact()
    _ => raise Failure("unknown transform command: " + command)
  }
  encode(m, o)
}

///|
pub fn transform(data : Bytes, options : String) -> Bytes {
  do_transform(data, options) catch {
    e => fail_bytes(@debug.to_string(e))
  }
}

///|
pub fn new_file(options : String) -> Bytes {
  try {
    let o = object(options)
    encode(model(o), o)
  } catch {
    e => fail_bytes(@debug.to_string(e))
  }
}

///|
fn main {

}
