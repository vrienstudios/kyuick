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
proc renderHor*(renderer: RendererPtr, obj: KyuickObject) =
  let hor = HorizontalGrid(obj)
  for el in hor.elements:
    renderer.render(el)
proc newHorizontalGrid*(x, y, width, height: cint): HorizontalGrid =
  var obj: HorizontalGrid = HorizontalGrid(x: x, y: y, width: width, height: height)
  obj.render = renderHor
  return obj