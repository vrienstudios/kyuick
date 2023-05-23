import kyuick
import kyuick/components/[kyuickObject, animatedObject, label, textInput, button]

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
  # Create our white label at (100,100) with our font.
  var lbl = newLabel(100, 100, "Lorem Ipsum Dollarunis",
    [255, 255, 255, 255], font, fSize)
  addObject lbl

  frameRate = newLabel(10, 10, "FPS: ", [25, 255, 100, 255], font, fSize)
  addObject frameRate

  var btn = newButton(100, 150, 250, 50, [25, 100, 100, 255], "Button",
    font, fSize, [255, 255, 255, 255])
  addObject btn
  hookClick(btn, clicked)
  hookHover(btn, tOHover)

  var textInput = newTextInput(100, 300, 250, 30, [0, 0, 0, 255],
    "default", [255, 255, 255, 255], font, fSize)

  addObject textInput
  clickHooked.add textInput

# proc newAnimatedObject*(x, y, width, height: cint, dirOrSheet: string): animatedObject
  var animTest = newAnimatedObject(200, 400, 64, 205, "./foo.png")
  animatables.add animTest
proc init() =
  testRendering()
proc sRender(renderer: RendererPtr) =
  frameRate.text = $currentFrameRate

startGameLoop("Rendering aand Input Tests", init, sRender)

#var startCounter = getPerformanceCounter()
#var endCounter = getPerformanceCounter()

#    endCounter = getPerformanceCounter()
#     frameRate.text = "FPS: " & $(int)(1 / ((endCounter - startCounter).float /
#       getPerformanceFrequency().float))
#     memLabel.text = "Res. Mem: " & $(getTotalMem().float / 1000.0f) & " KB" & " | Used: " & $int((getOccupiedMem().float / 1000.0f)) & " KB"