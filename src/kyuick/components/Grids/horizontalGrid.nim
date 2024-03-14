import ../kyuickObject
import sdl2

type HorizontalGrid* = ref object of KyuickObject
  elements: seq[KyuickObject]
  totalW, totalH: cint
  scrollable: bool
  outline: bool

proc add*(this: HorizontalGrid, obj: KyuickObject) =
  if this.totalW + obj.width > this.width:
    this.totalW = this.totalW + obj.width
  if this.totalW > this.width and this.scrollable == false:
    return # Refuse to accept anymore.
  obj.x = this.totalW
  this.elements.add obj
proc renderVert*(renderer: RendererPtr, obj: KyuickObject) =
  renderer.render(obj)
proc newHorizontalGrid*(x, y, width, height: cint): HorizontalGrid =
  var obj: HorizontalGrid = HorizontalGrid(x: x, y: y, width: width, height: height)
  obj.render = renderVert
  return obj