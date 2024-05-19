import sdl2
import sdl2/ttf

import ../Grids/horizontalGrid
import ../kyuickObject
import ../../utils/rendererUtils

type Menubar* = ref object of KyuickObject
  panel*: HorizontalGrid

proc renderBar(renderer: RendererPtr, obj: KyuickObject) =
  #echo "B"
  let this: Menubar = Menubar(obj)
  renderer.setDrawColor(this.backgroundColor)
  renderer.fillRect(this.rect)
  renderer.render(this.panel)
proc newMenubar*(x: cint = 0, y: cint = 0, width: cint = 0, height: cint = 0, 
    backgroundColor: array[4, int] = [10, 255, 255, 255]): Menubar =
  var grid =
    uiGen HorizontalGrid:
      x 0
      y y
      width width
      height height
  var obj = 
    uiCon Menubar:
      x 0
      y y
      width width
      height height
      backgroundColor backgroundColor
      rect rect(x, y, width, height)
      panel grid
      render renderBar
      children @[KyuickObject(grid)]
      passthrough true
  return obj
proc add*(this: Menubar, obj: KyuickObject) =
  this.panel.add obj