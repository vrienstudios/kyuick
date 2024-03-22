import ../kyuickObject
import ../../utils/rendererUtils
import sdl2
import std/strutils

type HorizontalGrid* = ref object of KyuickObject
  elements: seq[KyuickObject]
  totalW, totalH: cint
  pad: cint = 10
  topPad: cint = 10
  scrollable: bool
  outline: bool
  focusedObj: KyuickObject

proc add*(this: HorizontalGrid, obj: KyuickObject) =
  if this.totalW + obj.width > this.width:
    return
  obj.x = this.totalW
  obj.y = this.y + this.topPad
  this.totalW = this.totalW + obj.width + this.pad
  this.elements.add obj
proc renderHor*(renderer: RendererPtr, obj: KyuickObject) =
  let hor = HorizontalGrid(obj)
  renderer.setDrawColor(hor.backgroundColor)
  renderer.fillRect(hor.rect)
  for el in hor.elements:
    renderer.render(el)
proc clicked(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) =
  var 
    hor = HorizontalGrid(obj)
    el = hor.elements.seekEl(mouseEvent.x, mouseEvent.y)
  if el == nil: return
  el.leftClick(mouseEvent)
  return
proc hoverme(obj: KyuickObject, e: tuple[b: bool, mouse: MouseMotionEventPtr]) =
  var 
    hor = HorizontalGrid(obj)
    el = hor.elements.seekEl(e[1].x, e[1].y)
  if el == nil:
    if hor.focusedObj == nil: return
    hor.focusedObj.hoverStatus = (false, e.mouse)
    return
  if el != nil and hor.focusedObj != nil: hor.focusedObj.hoverStatus = (false, e.mouse)
  el.hoverStatus = (true, e.mouse)
  hor.focusedObj = el
  return
proc newHorizontalGrid*(x, y, width, height: cint): HorizontalGrid =
  var obj: HorizontalGrid = HorizontalGrid(x: x, y: y, width: width, height: height)
  obj.render = renderHor
  obj.rect = rect(x, y, width, height)
  obj.canClick = true
  obj.onLeftClick = clicked
  obj.canHover = true
  obj.onHoverStatusChange = hoverme
  obj.passthrough = true
  return obj