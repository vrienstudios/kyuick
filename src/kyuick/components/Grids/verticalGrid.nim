# Collection of UI components ordered vertically.

import ../kyuickObject
import ../../utils/rendererUtils
import sdl2

type VerticalGrid* = ref object of KyuickObject
  lineHeight*: cint
  totalW, totalH: cint
  yPad: cint = 10
  xPad: cint = 10
  scrollable: bool
  outline: bool
  focusedObj: KyuickObject

proc add*(this: VerticalGrid, obj: KyuickObject) =
  if this.totalH + obj.height > this.height:
    return
  obj.x = obj.x + this.xPad
  obj.y = this.totalH
  this.totalH = this.totalH + obj.y + this.yPad
  this.children.add obj
proc renderVert*(renderer: RendererPtr, obj: KyuickObject) =
  let vrrr = VerticalGrid(obj)
  renderer.setDrawColor(vrrr.backgroundColor)
  renderer.fillRect(vrrr.rect)
  for el in vrrr.children:
    renderer.render(el)
proc newVerticalGrid*(x, y, width, height: cint): VerticalGrid =
  var obj: VerticalGrid = VerticalGrid(x: x, y: y, width: width, height: height)
  obj.render = renderVert
  obj.passthrough = true
  return obj