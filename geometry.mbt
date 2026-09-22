///|
pub(all) struct Quality {
  tag : Int
  kind : Int
  measure : Double
  signed_volume : Double
  quality : Double
  degenerate : Bool
  inverted : Bool
} derive(ToJson)

///|
pub extend Quality with ToJson::{to_json}

///|
pub(all) struct Diagnostics {
  isolated : Array[Int]
  duplicate_nodes : Array[Array[Int]]
  repeated_connectivity : Array[Int]
  qualities : Array[Quality]
  unsupported_quality : Array[Int]
} derive(ToJson)

///|
pub extend Diagnostics with ToJson::{to_json}

///|
fn dot(a : Array[Double], b : Array[Double]) -> Double {
  a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
}

///|
/// Scaled norm avoids squaring a small nonzero cross product to zero.
fn norm(a : Array[Double]) -> Double {
  let mut scale = 0.0
  for x in a {
    if x.abs() > scale {
      scale = x.abs()
    }
  }
  if scale == 0.0 {
    return 0.0
  }
  let b = a.map(x => x / scale)
  dot(b, b).sqrt() * scale
}

///|
fn sub(a : Array[Double], b : Array[Double]) -> Array[Double] {
  [a[0] - b[0], a[1] - b[1], a[2] - b[2]]
}

///|
fn cross(a : Array[Double], b : Array[Double]) -> Array[Double] {
  [
    a[1] * b[2] - a[2] * b[1],
    a[2] * b[0] - a[0] * b[2],
    a[0] * b[1] - a[1] * b[0],
  ]
}

///| Triangle quality = 4 sqrt(3) A / sum(edge^2); tetrahedron quality =

///| 12 (3 |V|)^(2/3) / sum(edge^2). Both are 1 for a regular simplex.

///| Normalize coordinates before products to avoid avoidable overflow.

///|
/// Degeneracy is scale-relative; triangle orientation in 3D is not "inverted".
pub fn Mesh::quality(
  self : Mesh,
  tag : Int,
  tolerance? : Double = 1.0e-12,
) -> Quality raise {
  if !finite(tolerance) || tolerance < 0.0 || tolerance >= 1.0 {
    bad("tolerance must be in [0,1)")
  }
  let e = match self.ei.get(tag) {
    Some(i) => self.es[i]
    None => {
      bad("unknown element tag")
      self.es[0]
    }
  }
  if e.kind != 2 && e.kind != 4 {
    bad("geometric quality supports linear triangles/tetrahedra only")
  }
  let pts = e.nodes.map(t => self.ns[self.ni[t]].xyz)
  let delta = pts.map(p => sub(p, pts[0]))
  let mut scale = 0.0
  for p in delta {
    for v in p {
      if !finite(v) {
        bad("coordinate difference overflow")
      }
      if v.abs() > scale {
        scale = v.abs()
      }
    }
  }
  if scale == 0.0 {
    return {
      tag,
      kind: e.kind,
      measure: 0.0,
      signed_volume: 0.0,
      quality: 0.0,
      degenerate: true,
      inverted: false,
    }
  }
  let p = delta.map(v => v.map(x => x / scale))
  let mut edges = 0.0
  for i in 0..<p.length() {
    for j in 0..<i {
      let v = sub(p[i], p[j])
      edges = edges + dot(v, v)
    }
  }
  let normal = cross(p[1], p[2])
  let normalized = if e.kind == 2 {
    norm(normal) / 2.0
  } else {
    dot(normal, p[3]) / 6.0
  }
  let measure = if e.kind == 2 {
    normalized.abs() * scale * scale
  } else {
    normalized.abs() * scale * scale * scale
  }
  if !finite(measure) || (normalized != 0.0 && measure == 0.0) {
    bad("geometric measure outside representable Double range")
  }
  let q = if edges == 0.0 {
    0.0
  } else if e.kind == 2 {
    4.0 * 3.0.sqrt() * normalized.abs() / edges
  } else {
    12.0 * @math.pow(3.0 * normalized.abs(), 2.0 / 3.0) / edges
  }
  {
    tag,
    kind: e.kind,
    measure,
    signed_volume: if e.kind == 4 {
      if normalized < 0.0 {
        -measure
      } else {
        measure
      }
    } else {
      0.0
    },
    quality: if q > 1.0 {
      1.0
    } else {
      q
    },
    degenerate: q <= tolerance,
    inverted: e.kind == 4 && normalized < 0.0,
  }
}

///| Duplicate means exactly equal coordinates, including +0 == -0. No hidden

///|
/// epsilon merges; diagnostics do not mutate geometry or call it CAD-valid.
pub fn Mesh::diagnostics(
  self : Mesh,
  tolerance? : Double = 1.0e-12,
) -> Diagnostics raise {
  if !finite(tolerance) || tolerance < 0.0 || tolerance >= 1.0 {
    bad("invalid tolerance")
  }
  let used : Map[Int, Bool] = Map([])
  let repeated = []
  for e in self.es {
    let ids : Map[Int, Bool] = Map([])
    let mut duplicate = false
    for n in e.nodes {
      if ids.contains(n) {
        duplicate = true
      }
      ids[n] = true
      used[n] = true
    }
    if duplicate {
      repeated.push(e.tag)
    }
  }
  let grouped : Map[String, Array[Int]] = Map([])
  let order = []
  for n in self.ns {
    let key = n.xyz
      .map(x => if x == 0.0 { "0" } else { x.to_string() })
      .join(",")
    match grouped.get(key) {
      Some(a) => a.push(n.tag)
      None => {
        grouped[key] = [n.tag]
        order.push(key)
      }
    }
  }
  let duplicates = []
  for key in order {
    if grouped[key].length() > 1 {
      duplicates.push(grouped[key])
    }
  }
  let qualities = []
  let unsupported = []
  for e in self.es {
    if e.kind == 2 || e.kind == 4 {
      qualities.push(self.quality(e.tag, tolerance~))
    } else {
      unsupported.push(e.tag)
    }
  }
  {
    isolated: self.ns.filter(n => !used.contains(n.tag)).map(n => n.tag),
    duplicate_nodes: duplicates,
    repeated_connectivity: repeated,
    qualities,
    unsupported_quality: unsupported,
  }
}
