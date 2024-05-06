# Collection of UI components ordered vertically.

import ../kyuickObject
import ../../utils/rendererUtils
import sdl2

type VerticalGrid* = ref object of KyuickObject
  elements: seq[KyuickObject]
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
  this.elements.add obj
proc renderVert*(renderer: RendererPtr, obj: KyuickObject) =
  let vrrr = VerticalGrid(obj)
  renderer.setDrawColor(vrrr.backgroundColor)
  renderer.fillRect(vrrr.rect)
  for el in vrrr.elements:
    renderer.render(el)
proc clicked(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) =
  var 
    hor = VerticalGrid(obj)
    el = hor.elements.seekEl(mouseEvent.x, mouseEvent.y)
  if el == nil: return
  el.leftClick(mouseEvent)
  return
proc hoverme(obj: KyuickObject, e: tuple[b: bool, mouse: MouseMotionEventPtr]) =
  var 
    ver = VerticalGrid(obj)
    el = ver.elements.seekEl(e[1].x, e[1].y)
  if el == nil:
    if ver.focusedObj == nil: return
    ver.focusedObj.hoverStatus = (false, e.mouse)
    return
  if el != nil and ver.focusedObj != nil: ver.focusedObj.hoverStatus = (false, e.mouse)
  el.hoverStatus = (true, e.mouse)
  ver.focusedObj = el
  return
proc newVerticalGrid*(x, y, width, height: cint): VerticalGrid =
  var obj: VerticalGrid = VerticalGrid(x: x, y: y, width: width, height: height)
  obj.render = renderVert
  obj.canClick = true
  obj.onLeftClick = clicked
  return obj