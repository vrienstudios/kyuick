import kyuick/utils/rawFF
#SDL
import sdl2
import sdl2/[ttf, image, audio]
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
  WinWidth* = 2560
  WinHeight* = 1440
var
  mainScene*: KyuickObject
  mainAuddev*: AudioDeviceID
  numAudioDev*: cint
  audwant*, audhave*: AudioSpec
  video*: ptr Video
  canvasZoom: cint
  currentFrameRate*: float = 0
  currentFrameTime*: float = 0
  currentTotalMem*: float = 0
  currentOccMem*: float = 0
  currentFreeMem*: float = 0
  inFocus: KyuickObject
  keyDownTracker = initTable[string, bool]()
  mouseXYTracker: tuple[x, y: cint] = (0, 0)
  fontTracker: FontTracker
const manualVersion: uint8 = 1
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
proc mouseMove(e: MouseMotionEventPtr) =
  var obj = mainScene.getClickable(e.x, e.y)
  if obj == nil:
    if inFocus != nil:
      inFocus.hoverStatus = (false, e)
    return
  if inFocus != nil:
    if inFocus == obj:
      inFocus.hoverStatus = (true, e)
      return
  obj.hoverStatus = (true, e)
  inFocus.hoverStatus = (false, e)
  inFocus = obj
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
proc showTotalMem*() =
  var ffont = fontTracker.getFont("liberation-sans.ttf", cint(18))
  var fpsc =
    newLabel(0, 36, "FPSC", [100, 200, 100, 255], ffont, cint(18))
  fpsc.trackNum = currentTotalMem.addr
  mainScene.children.add fpsc
proc showOccMem*() =
  var ffont = fontTracker.getFont("liberation-sans.ttf", cint(18))
  var fpsc =
    newLabel(0, 52, "FPSC", [100, 200, 100, 255], ffont, cint(18))
  fpsc.trackNum = currentOccMem.addr
  mainScene.children.add fpsc
proc showFreeMem*() =
  var ffont = fontTracker.getFont("liberation-sans.ttf", cint(18))
  var fpsc =
    newLabel(0, 70, "FPSC", [100, 200, 100, 255], ffont, cint(18))
  fpsc.trackNum = currentFreeMem.addr
  mainScene.children.add fpsc
proc initEngine*() =
  echo "Init Kyuick (v." & $manualVersion & ") Engine"
  sdl2.init(INIT_EVERYTHING)
  ttfInit()
  discard image.init()
  echo "Setting Audio Device"
  block setupAud:
    numAudioDev = getNumAudioDevices(0)
    echo "Audio Devices: " & $numAudioDev
    zeroMem(addr audwant, sizeof AudioSpec)
    zeroMem(addr audhave, sizeof AudioSpec)
    audwant.freq = (44800).cint
    audwant.format = AUDIO_S32
    audwant.channels = 2
    # learned that passing nil values will choose default.
    mainAuddev = openAudioDevice(nil, 0, addr audwant, addr audhave, 0)
    mainAuddev.pauseAudioDevice 0
proc startGameLoop*(name: string, onInit: proc() = nil) =
  if onInit != nil:
    onInit()
  let window = sdl2.createWindow(name, WinXPos, WinYPos, WinWidth, WinHeight, SDL_WINDOW_SHOWN or SDL_WINDOW_FULLSCREEN)
  let renderer = createRenderer(window = window, index = -1, Renderer_Accelerated or Renderer_PresentVsync)
  var startCounter = getPerformanceCounter()
  var endCounter = getPerformanceCounter()
  #window.setFullscren(SDL_WINDOW_FULLSCREEN)
  when defined(perf):
    showFPS()
    showFrameTime()
    showTotalMem()
    showOccMem()
    showFreeMem()
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
          mouseMove(event.motion)
        of KeyDown:
          echo $event.key.keysym
          if inFocus != nil and inFocus.onKeyDown != nil and not (inFocus of all.TextInput):
            inFocus.onKeyDown(inFocus, $event.key.keysym.scancode)
          if inFocus of all.TextInput:
            if $event.key.keysym.scancode == "SDL_SCANCODE_BACKSPACE":
              all.TextInput(inFocus).remove()
            # quick hack to reimplement text input to text fields
            elif event.key.keysym.sym > 0 and event.key.keysym.sym < 255:
              inFocus.onKeyDown(inFocus, (if event.key.keysym.modstate == 1 or event.key.keysym.modstate == 2: ($(chr)event.key.keysym.sym).toUpper() else: $(chr)event.key.keysym.sym))
          keyDownTracker[$event.key.keysym.scancode] = true
        of KeyUp:
          if isDown("SDL_SCANCODE_LCTRL") and isDown("SDL_SCANCODE_C"):
            quit(0)
          keyDownTracker[$event.key.keysym.scancode] = false
        else:
          continue
    let cB = cpuTime()
    renderer.clear()
    mainScene.render(renderer, mainScene)
    renderer.present()
    currentFrameTime = (cpuTime() - cB) * 1000
    endCounter = getPerformanceCounter()
    currentFrameRate = (1 / ((endCounter - startCounter).float /
      getPerformanceFrequency().float))
    currentTotalMem = getTotalMem().float
    currentOccMem = getOccupiedMem().float
    currentFreeMem = getFreeMem().float
import macros
when defined(Create):
  #INTERNALS
  import kyuick/internalTools/uiMaker
  proc defTest() =
    var uic = createuiCon(fontTracker, WinWidth, WinHeight)
    mainScene = uic
    uic.render = defaultRender
else:
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
proc videoTest(file: string, newCall: bool = false)
var
  vSel: cint = 0
  dstr: seq[string] = @[]
  repl: bool = true
  finished = false
proc onVidEnd(video: Video) =
  echo video.returned
  if video.returned == true:
    return
  var idx: int = 0
  while idx < mainScene.children.len:
    if mainScene.children[idx] == video: break
    inc idx
  mainScene.children.delete(idx)
  mainScene.renderSaved = false
  echo "deleted video"
  inc vSel
  if vSel >= dstr.len:
    if repl: vSel = 0
    else:
      finished = true
      return
  if finished != true: videoTest(dstr[vSel], true)
proc genVideo(fn: string) =
  var tVideo: Video = Video()
  tVideo = generateVideo(fn, 0, 0, WinWidth, WinHeight, addr mainAuddev)
  tVideo.endCallback = onVidEnd
  video = tVideo.addr
  mainScene.children.add tVideo
proc videoTest(file: string, newCall: bool = false) =
  if newCall:
    echo "Continuing to Next Queued Video"
    genVideo(file)
    return
  echo "Loading Video Test"
  if file.contains('*'):
    repl = false
    for i in walkFiles(file):
      echo i
      dstr.add i
    genVideo(dstr[0])
  else:
    echo file
    genVideo(file)

when isMainModule:
  let nowStr = $now()
  var logFile =open("/dev/null")#fmt"{getAppDir()}/logs/{nowStr}.txt", fmWrite)
  echo fmt"See ./logs/{nowStr}.txt for log details"
  #stdout = logFile
  echo fmt"Compiled Nim Version: {NimVersion} ran on {nowStr}"
  initEngine()
  mainScene =
    uiCon KyuickObject:
      width WinWidth
      height WinHeight
      backgroundColor [6, 0, 200, 255]
      render defaultRender
  let paramCount: int = paramCount() + 1
  # 1 is directory
  var pidx: int = 0
  while pidx < paramCount:
    defer: inc pidx
    let str = paramStr(pidx)
    case str:
      of "video":
        inc pidx
        videoTest(paramStr(pidx))
      else:
        defTest()
        continue
  startGameLoop("tester")
