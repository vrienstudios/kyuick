import sdl2
import sdl2/image

import kyuickObject
import ../math/vector
import std/math

type
  zObject* = ref object of kyuickObject
    z*: cint
    depth*: cint
    # Sequence of points to follow to generate the item.
    vertices*: seq[Vector]

# Proof of concept and place holder for openGL functions.
proc renderZ*(renderer: RendererPtr, obj: kyuickObject) =
  let zObj: zObject = (zObject)(obj)
  renderer.setDrawColor(color(0, 0, 222, 255))
  var
    x, y, z: cint = 0
  x = zObj.x
  y = zObj.y
  z = zObj.z
  for vector in zObj.vertices:
    var i: cint = x
    x = x + cint(vector[0])
    y = y + cint(vector[1])
    z = z + cint(vector[2])
    renderer.drawPoint(x, y)
    
proc newZObject*(x, y, z: cint, vertices: seq[Vector]): zObject =
  return zObject(x: x, y: y, z: z, render: renderZ, vertices: vertices)
