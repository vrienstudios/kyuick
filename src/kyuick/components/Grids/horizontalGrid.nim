import ../kyuickObject
import ../../utils/rendererUtils
import sdl2
import std/strutils

type HorizontalGrid* = ref object of KyuickObject
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
  this.children.add obj
proc renderHor*(renderer: RendererPtr, obj: KyuickObject) =
  let hor = HorizontalGrid(obj)
  #renderer.setDrawColor(hor.backgroundColor)
  #renderer.fillRect(hor.rect)
  for el in hor.children:
    renderer.render(el)
proc newHorizontalGrid*(x, y, width, height: cint): HorizontalGrid =
  var obj: HorizontalGrid = HorizontalGrid(x: x, y: y, width: width, height: height)
  obj.render = renderHor
  obj.rect = rect(x, y, width, height)
  obj.passthrough = true
  return obj