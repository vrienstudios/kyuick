import kyuickObject
import UI/imageObject

import sdl2

# A grouping of elements, which will sometimes have a custom render proc.
# In the case of the main Scene in the engine, all elements are relative to the main element.
type Scene* = ref object of RootObj
  x, y, width*, height*: cint
  canvas*: ImageObject
  elements*: seq[KyuickObject]
  hoverables*: seq[KyuickObject]
  clickables*: seq[KyuickObject]
  isInteractive*: bool
  renderSaved*: bool

# Methods to enumerate elements and shift their x/y values.
method `x=`*(this: var Scene, x: cint) =
  for elem in this.elements:
    elem.x = elem.x - (this.x - x)
  this.x = x
  this.canvas.x = x
  return
method `y=`*(this: var Scene, y: cint) =
  for elem in this.elements:
    elem.y = elem.y - (this.y - y)
  this.y = y
  this.canvas.y = y
  return
method x*(this: Scene): cint =
  return this.x
method y*(this: Scene): cint =
  return this.y
proc add*(this: Scene, kyuickObj: KyuickObject) =
  this.elements.add kyuickObj
proc del*(this: Scene, kyuickObj: KyuickObject) =
  this.elements.delete(this.elements.find(kyuickObj))
proc render*(this: Scene, renderer: RendererPtr) =
  if this.canvas != nil: renderer.render(this.canvas)
  for el in this.elements:
    renderer.render(el)