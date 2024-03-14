# Collection of UI components ordered vertically.

import ../kyuickObject
import sdl2

type VerticalGrid* = ref object of KyuickObject
  elements: seq[KyuickObject]
  lineHeight*: cint
  totalW, totalH: cint
  scrollable: bool
  outline: bool

proc add*(this: VerticalGrid, obj: KyuickObject) =
  if this.totalW + obj.width > this.width:
    this.totalH = this.totalH + this.lineHeight
  if this.height + obj.height > this.height and this.scrollable == false:
    return # Refuse to accept anymore.
  obj.y = this.totalH
  this.elements.add obj
proc renderVert*(renderer: RendererPtr, obj: KyuickObject) =
  renderer.render(obj)
proc newVerticalGrid*(x, y, width, height: cint): VerticalGrid =
  var obj: VerticalGrid = VerticalGrid(x: x, y: y, width: width, height: height)
  obj.render = renderVert
  return obj