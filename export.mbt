///| Visualization export is explicitly geometry-only: require caller permission

///|
/// when metadata exists. MSH encode is the metadata-preserving exchange route.
fn Mesh::export_gate(self : Mesh, allow_loss : Bool) -> Unit raise {
  if !allow_loss &&
    (
      !self.fs.is_empty() ||
      !self.names.is_empty() ||
      !self.ents.is_empty() ||
      !self.unknown.is_empty() ||
      self.es.any(e => {
        !e.physical.is_empty() || !e.extra.is_empty() || e.entity != 0
      })
    ) {
    bad("geometry export omits metadata; require allow_loss")
  }
}

///| Legacy ASCII VTK unstructured grid, first-order cells only. Quadratic cells

///|
/// are rejected rather than silently reordered or linearized.
pub fn Mesh::vtk(self : Mesh, allow_loss? : Bool = false) -> String raise {
  self.export_gate(allow_loss)
  let w : Writer = { out: [], binary: false, little: true, width: 8, }
  w.text(
    "# vtk DataFile Version 3.0\nMoonGmsh geometry-only export\nASCII\nDATASET UNSTRUCTURED_GRID\nPOINTS \{self.ns.length()} double\n",
  )
  for n in self.ns {
    w.text("\{n.xyz[0]} \{n.xyz[1]} \{n.xyz[2]}\n")
  }
  let mut total = 0
  let types = []
  for e in self.es {
    let t = match e.kind {
      15 => 1
      1 => 3
      2 => 5
      3 => 9
      4 => 10
      5 => 12
      6 => 13
      7 => 14
      _ => {
        bad("VTK export supports first-order cells only")
        0
      }
    }
    types.push(t)
    total = total + e.nodes.length() + 1
  }
  w.text("CELLS \{self.es.length()} \{total}\n")
  for e in self.es {
    w.text("\{e.nodes.length()}")
    // Legacy vtkWedge (VTK 9.3, meshio 5.3.5) has the opposite base
    // orientation to Gmsh. Do not reuse the Gmsh connectivity verbatim.
    let nodes = if e.kind == 6 {
      [0, 2, 1, 3, 5, 4].map(i => e.nodes[i])
    } else {
      e.nodes
    }
    for n in nodes {
      w.text(" \{self.ni[n]}")
    }
    w.text("\n")
  }
  w.text("CELL_TYPES \{self.es.length()}\n")
  for t in types {
    w.text("\{t}\n")
  }
  @utf8.decode(Bytes::from_array(w.out))
}

///| OBJ lines/surface faces; volume meshes use outward boundary facets at the

///|
/// highest dimension. Nonmanifold volume boundaries are refused.
pub fn Mesh::obj(self : Mesh, allow_loss? : Bool = false) -> String raise {
  self.export_gate(allow_loss)
  let w : Writer = { out: [], binary: false, little: true, width: 8, }
  w.text("# MoonGmsh geometry only; OBJ indices follow stored node order\n")
  for n in self.ns {
    w.text("v \{n.xyz[0]} \{n.xyz[1]} \{n.xyz[2]}\n")
  }
  let mut dim = 0
  for e in self.es {
    let d = element_shape(e.kind).0
    if d > dim {
      dim = d
    }
  }
  if dim == 3 {
    let t = self.topology()
    if !t.nonmanifold.is_empty() {
      bad("nonmanifold volume cannot be exported as an unambiguous boundary")
    }
    for f in t.boundary {
      w.text("f")
      for n in f.nodes {
        w.text(" \{self.ni[n]+1}")
      }
      w.text("\n")
    }
  } else {
    for e in self.es {
      let prefix = match e.kind {
        15 => "p"
        1 => "l"
        2 | 3 => "f"
        _ => {
          bad("OBJ export supports first-order surface cells only")
          ""
        }
      }
      w.text(prefix)
      for n in e.nodes {
        w.text(" \{self.ni[n]+1}")
      }
      w.text("\n")
    }
  }
  @utf8.decode(Bytes::from_array(w.out))
}
