import ffmpeg
#SDL
import sdl2
import sdl2/[ttf, image]
# Kyuick Components
import kyuick/components/[kyuickObject, scene]
import kyuick/components/Game/[gameObjects, mapMaker]
import kyuick/components/UI/all
import kyuick/components/Grids/[horizontalGrid, verticalGrid]
import kyuick/utils/[fontUtils, rendererUtils]
# Standard Lib
import std/[math, tables, sequtils, os, strutils, times, sugar, streams, strformat]


const
  WinXPos* = SDL_WINDOWPOS_CENTERED
  WinYPos* = SDL_WINDOWPOS_CENTERED
  WinWidth* = 1920
  WinHeight* = 1080
var
  mainScene*: KyuickObject
  video*: ptr Video
  canvasZoom: cint
  currentFrameRate*: float = 0
  currentFrameTime*: float = 0
  inFocus: KyuickObject
  keyDownTracker = initTable[string, bool]()
  mouseXYTracker: tuple[x, y: cint] = (0, 0)
  fontTracker: FontTracker
proc isDown*(key: string): bool =
  if not keyDownTracker.hasKey(key):
    return false
  return keyDownTracker[key]
proc mousePress(e: MouseButtonEventPtr, isDown: bool = true) =
  if isDown: return
  case e.button:
    of 1:
      var obj = mainScene.getClickable(e.x, e.y)
      if obj == nil: return
      inFocus = obj
      obj.leftClick(e)
      return
    else:
      return
proc showFPS*() =
  var ffont = fontTracker.getFont("liberation-sans.ttf", cint(18))
  var fpsc = 
    newLabel(0, 0, "FPSC", [100, 200, 100, 255], ffont, cint(18))
  fpsc.trackNum = currentFrameRate.addr
  mainScene.children.add fpsc
proc showFrameTime*() =
  var ffont = fontTracker.getFont("liberation-sans.ttf", cint(18))
  var fpsc = 
    newLabel(0, 18, "FPSC", [100, 200, 100, 255], ffont, cint(18))
  fpsc.trackNum = currentFrameTime.addr
  mainScene.children.add fpsc
proc startGameLoop*(name: string, onInit: proc() = nil) =
  sdl2.init(INIT_EVERYTHING)
  ttfInit()
  discard image.init()
  if onInit != nil:
    onInit()
  let window = sdl2.createWindow(name, WinXPos, WinYPos, WinWidth, WinHeight, SDL_WINDOW_SHOWN)
  let renderer = createRenderer(window = window, index = -1, Renderer_Accelerated or Renderer_PresentVsync)
  var startCounter = getPerformanceCounter()
  var endCounter = getPerformanceCounter()
  showFPS()
  showFrameTime()
  while true:
    startCounter = getPerformanceCounter()
    var event = defaultEvent
    while pollEvent(event):
      case event.kind:
        of QuitEvent:
          quit(0)
        of MouseButtonDown:
          mousePress(event.button)
        of MouseButtonUp:
          mousePress(event.button, false)
        of MouseMotion:
          continue
          #mouseMove(event.motion)
        of KeyDown:
          echo event.key.keysym.scancode
          if inFocus != nil and inFocus.onKeyDown != nil:
            inFocus.onKeyDown(inFocus, $event.key.keysym.scancode)
          if inFocus of all.TextInput:
            if $event.key.keysym.scancode == "SDL_SCANCODE_BACKSPACE":
              all.TextInput(inFocus).remove()
          keyDownTracker[$event.key.keysym.scancode] = true
        of KeyUp:
          if isDown("SDL_SCANCODE_LCTRL") and isDown("SDL_SCANCODE_C"):
            quit(0)
          keyDownTracker[$event.key.keysym.scancode] = false
        else:
          continue
    let cB = cpuTime()
    #frameBufferController()
    #renderer.setScale(0.5, 0.5)
    renderer.clear()
    mainScene.render(renderer, mainScene)
    renderer.present()
    currentFrameTime = (cpuTime() - cB) * 1000
    endCounter = getPerformanceCounter()
    currentFrameRate = (1 / ((endCounter - startCounter).float /
      getPerformanceFrequency().float))
    #echo currentFrameRate
    # Cap
    #delay uint32(floor((100.0f - (endCounter.float - startCounter.float)/(getPerformanceFrequency().float * 1000.0f))))
    #echo GC_getStatistics()
    #echo $len(screenObjects)
import macros
proc defTest() =
  var mapC = openMapEditorForTile(fontTracker, WinWidth, WinHeight)
  mainScene = mapC
  mapC.render = defaultRender
proc provinceBuilder*() =
  let data = buildExampleProvinces()
  dumpProvinceDataToFile(data, "pdat1")
proc usProvinceDetectionTest() =
  var provinceColorMap: SurfacePtr = load("France_test.png")
  let pdata = generateProvincesFromColorMap(provinceColorMap)
  var provinces: seq[Province] = getRendererPolys(pdata)
  for n in provinces:
    mainScene.children.add n
proc videoTest() =
  var 
    filename: string = "good.webm"
    tVideo: Video = Video()
  tVideo = generateVideo(filename, 0, 0, WinWidth, WinHeight)
  video = tVideo.addr
  mainScene.children.add tVideo
when isMainModule:
  mainScene = 
    uiCon KyuickObject:
      width WinWidth
      height WinHeight
      backgroundColor [6, 0, 200, 255]
      render defaultRender
  startGameLoop("tester", videoTest)