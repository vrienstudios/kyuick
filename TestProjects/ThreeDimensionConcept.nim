import kyuick
import kyuick/components/[kyuickObject, animatedObject, label, textInput, button, zObject]
import kyuick/math/vector

import sdl2
import sdl2/ttf

var frameRate: Label
var memLabel: Label

# Load the TTF font 'liberation-sans.ttf' at fontsize 24.
let fSize: cint = 24
var font: FontPtr

proc clicked(obj: kyuickObject, mouseEvent: MouseButtonEventPtr) =
  #echo "Clicked object at ($1, $2)" % [$obj.x, $obj.y]
  addObject newLabel((cint)(obj.x + 20), (cint)obj.y, "pow!", [100, 100, 100, 255], font, fSize)
proc tOHover(obj: kyuickObject, b: bool) =
  let btn: Button = (Button)obj
  if b:
    btn.backgroundColor = [1, 24, 21, 255]
  else:
    btn.backgroundColor = [25, 100, 100, 255]
  return

proc testRendering*() =
  var backGround = newKyuickObject(0, 0, WinWidth, WinHeight, [25, 25, 25, 255])
  addObject backGround

  font = ttf.openFont("../src/liberation-sans.ttf", fSize)
  frameRate = newLabel(10, 10, "FPS: ", [25, 255, 100, 255], font, fSize)
  addObject frameRate

  var vertices: seq[Vector] = @[]
  vertices.add newVector(100, 0, 3)
  vertices.add newVector(0, 20, 0)
  vertices.add newVector(-100, 0, 0)
  vertices.add newVector(0,-20, -3)
  var zobject: zObject = newZObject(100, 30, 0, vertices)
  addObject zobject

proc init() =
  testRendering()
proc sRender(renderer: RendererPtr) =
  frameRate.text = $currentFrameRate

startGameLoop("3d cube test", init, sRender)

#var startCounter = getPerformanceCounter()
#var endCounter = getPerformanceCounter()

#    endCounter = getPerformanceCounter()
#     frameRate.text = "FPS: " & $(int)(1 / ((endCounter - startCounter).float /
#       getPerformanceFrequency().float))
#     memLabel.text = "Res. Mem: " & $(getTotalMem().float / 1000.0f) & " KB" & " | Used: " & $int((getOccupiedMem().float / 1000.0f)) & " KB"