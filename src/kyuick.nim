#SDL
import sdl2
import sdl2/[ttf, image]
# Kyuick Components
import kyuick/components/[kyuickObject, scene, verticalGrid]
import kyuick/components/UI/[label, button, textInput, imageObject, graphObject, animatedObject]
import kyuick/components/Game/gameObjects
import kyuick/utils/[fontUtils, rendererUtils]
# Standard Lib
import std/[math, tables, sequtils, os, strutils, times]
# Window settings to be set before startGameLoop is called.
const
  WinXPos* = SDL_WINDOWPOS_CENTERED
  WinYPos* = SDL_WINDOWPOS_CENTERED
  WinWidth* = 1920
  WinHeight* = 1080
var
  kinputCallBacks*: seq[proc(key: TextInputEventPtr)]
  minputCallBacks*: seq[proc(mouse: MouseButtonEventPtr)]
  mMovementCallBack*: seq[proc(mouse: MouseMotionEventPtr)]
  mainCanvas*: Scene
  canvasZoom: cint
  currentFrameRate*: float = 0
  currentFrameTime*: float = 0
  canvasMovable: bool
  inFocus: KyuickObject
  fontsLoaded: seq[(string, FontPtr)]
  keyDownTracker = initTable[string, bool]()
  mouseXYTracker: tuple[x, y: cint] = (0, 0)
  # Game Content
  gameFolder*: string
  wrapMap: bool
  fontTracker: FontTracker
proc isDown*(key: string): bool =
  if not keyDownTracker.hasKey(key):
    return false
  return keyDownTracker[key]
proc loadLevelData(folder: string): bool =
  # TODO: load settings and data from file.
  gameFolder = folder
  # Load the province map
  mainCanvas.canvas = newImageObject(0, 0, 3221, 1777, folder / "provMap.png")
  mainCanvas.renderSaved = false
  # Load Level Data
  return true
# Process mouse clicks and calculate object clicked.
proc mousePress(e: MouseButtonEventPtr, isDown: bool = true) =
  if e.button == 2:
    keyDownTracker["SDL_BUTTON_MIDDLE"] = isDown
    mouseXYTracker.x = e.x
    mouseXYTracker.y = e.y
    return
  if isDown == false:
    return
  case e.button:
    of 1:
      for obj in mainCanvas.clickables:
        #echo ("mouse($1, $2) objX($3, $4) objY($5, $6)" % [$e.x, $e.y, $obj.x, $(obj.x + obj.width), $obj.y, $(obj.y + obj.height)])
        if e.x >= obj.x and e.x <= (obj.x + obj.width):
          if e.y >= obj.y and e.y <= (obj.y + obj.height):
            if inFocus != nil:
              inFocus.focusChange = false
            inFocus = obj
            obj.focusChange = true
            obj.leftClick(e)
            return
    else:
      return
proc mouseMove(e: MouseMotionEventPtr) =
  var hoverObjFound: bool = false
  for obj in mainCanvas.hoverables:
    if hoverObjFound == false:
      if e.x >= obj.x and e.x <= (obj.x + obj.width):
        if e.y >= obj.y and e.y <= (obj.y + obj.height):
          obj.hoverStatus = true
          hoverObjFound = true
          if obj.autoFocusable:
            inFocus = obj
            obj.focusChange = true
          continue
    if inFocus == obj:
      inFocus = nil
    obj.hoverStatus = false
    obj.focusChange = false
proc textInput(e: TextInputEventPtr) =
  if not (inFocus of textInput.TextInput):
    return
  textInput.TextInput(inFocus).add(e.text[0])
proc frameBufferController() =
  #if mainCanvas.x + mainCanvas.width > mainCanvas.width:
  if mainCanvas.canvas == nil:
    return
  if isDown("SDL_BUTTON_MIDDLE"):
    var 
      mouseCurrentX, mouseCurrentY: cint
      newX, newY: cint
    discard getMouseState(mouseCurrentX, mouseCurrentY)
    newY = mainCanvas.y - (mouseXYTracker.y - mouseCurrentY)
    newX = mainCanvas.x - (mouseXYTracker.x - mouseCurrentX)
    echo newY
    echo newX
    if newY <= 0 and newY >= WinHeight - mainCanvas.height:
      mainCanvas.y = newY
    if newX <= 0 and newX >= WinWidth - mainCanvas.width:
      mainCanvas.x = newX
    mainCanvas.renderSaved = false
    mouseXYTracker.y = mouseCurrentY
    mouseXYTracker.x = mouseCurrentX
    return
  if isDown("SDL_SCANCODE_W") or isDown("SDL_SCANCODE_UP"):
    if mainCanvas.y <= 0:
      mainCanvas.y = mainCanvas.y + 10
  if isDown("SDL_SCANCODE_S") or isDown("SDL_SCANCODE_DOWN"):
    if (mainCanvas.y + mainCanvas.height) >= WinHeight:
      mainCanvas.y = mainCanvas.y - 10
  if isDown("SDL_SCANCODE_A") or isDown("SDL_SCANCODE_LEFT"):
    if mainCanvas.x <= 0:
      mainCanvas.x = mainCanvas.x + 10
  if isDown("SDL_SCANCODE_D") or isDown("SDL_SCANCODE_RIGHT"):
    if mainCanvas.x + mainCanvas.width >= WinWidth:
      mainCanvas.x = mainCanvas.x - 10
  mainCanvas.renderSaved = false
proc showFPS*() =
  var ffont = fontTracker.getFont("liberation-sans.ttf", cint(18))
  var fpsc = 
    newLabel(0, 0, "FPSC", [255, 255, 255, 255], ffont, cint(18))
  fpsc.trackNum = currentFrameRate.addr
  mainCanvas.elements.add fpsc
proc showFrameTime*() =
  var ffont = fontTracker.getFont("liberation-sans.ttf", cint(18))
  var fpsc = 
    newLabel(0, 18, "FPSC", [255, 255, 255, 255], ffont, cint(18))
  fpsc.trackNum = currentFrameTime.addr
  mainCanvas.elements.add fpsc
# The game loop; everything is rendered and processed here.
proc startGameLoop*(name: string, onInit: proc() = nil) =
  # Init SDL2 and SDL_TTF
  sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)
  ttfInit()
  # Later we can add error handling for init
  discard image.init()
  if onInit != nil:
    onInit()
  # Create the game window.
  let window = sdl2.createWindow(name, WinXPos, WinYPos, WinWidth, WinHeight, SDL_WINDOW_SHOWN)
  #var vlkLib: pointer = vulkanGetVkGetInstanceProcAddr()
  # Create our renderer with V-Sync
  #discard glSetAttribute(GLattr.SDL_GL_DOUBLEBUFFER, 1)
  let renderer = createRenderer(window = window, index = -1, Renderer_Accelerated)
  var startCounter = getPerformanceCounter()
  var endCounter = getPerformanceCounter()
  showFPS()
  showFrameTime()
  # Start the infinite renderer.
  while true:
    startCounter = getPerformanceCounter()
    var event = defaultEvent
    # Check for events.
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
          echo event.key.keysym.scancode
          if inFocus != nil and inFocus.onKeyDown != nil:
            inFocus.onKeyDown(inFocus, $event.key.keysym.scancode)
          if inFocus of textInput.TextInput:
            if $event.key.keysym.scancode == "SDL_SCANCODE_BACKSPACE":
              textInput.TextInput(inFocus).remove()
          keyDownTracker[$event.key.keysym.scancode] = true
        of KeyUp:
          if isDown("SDL_SCANCODE_LCTRL") and isDown("SDL_SCANCODE_C"):
            quit(0)
          keyDownTracker[$event.key.keysym.scancode] = false
        of TextInput:
          textInput(event.text)
        else:
          continue
    let cB = cpuTime()
    renderer.clear()
    #frameBufferController()
    render(mainCanvas, renderer)
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
proc buildCanvasTest*() =
  canvasZoom = 1
  mainCanvas.width = 3221
  mainCanvas.height = 1777
  mainCanvas.canvas = newImageObject(0, 0, 3221, 1777, "./provMap.png")
  var ffont = fontTracker.getFont("liberation-sans.ttf", cint(18))
  var thisTestLabel = 
    newLabel(100, 100, "This is a test Label for object permanence!", [255, 255, 255, 255], ffont, cint(18))
  mainCanvas.elements.add thisTestLabel
proc createTextInput*(x, y, w, h: cint, font: FontPtr, fSize: cint): TextInput =
  return newTextInput(x, y, w, h, [0, 0, 0, 255], "This is some test text.", [255, 255, 255, 255], font, fSize)
proc textEditorTest*() =
  var ffont = fontTracker.getFont("liberation-sans.ttf", cint(18))
  var thisTextInput = createTextInput(0, 0, WinWidth, WinHeight, ffont, cint(18))
  mainCanvas.elements.add thisTextInput
  mainCanvas.clickables.add(thisTextInput)
proc choiceDialogForType*() =
  return
proc gameObjectBuilder*() =
  var prvTest = Province(id: 0, ownerID: 0, color: [255, 255, 255, 255])
  var imgSurface: SurfacePtr = load(cstring("./ff.png"))
  var vectors: seq[tuple[x, y: cint]]
  var x, y: cint
  var r, g, b: int
  while y < 400:
    while x < 400:
      let cPixel = imgSurface.getColorAtPoint(x, y)
      if cPixel.g == 0:
        #r = int(cPixel.r)
        #g = int(cPixel.g)
        #b = int(cPixel.b)
        for pixel in imgSurface.getColorDirections(x, y):
          if pixel.g != 0:
            vectors.add (x, y)
      inc x
    inc y
    x = 0
  var i: int = 0
  while i < vectors.len:
    prvTest.vectors[i] = Point2D(x: vectors[i].x, y: vectors[i].y)
    inc i
  prvTest.render = renderProvince
  prvTest.color = [100, 100, 100, 255]
  mainCanvas.elements.add(prvTest)
  mainCanvas.elements.add(prvTest)
  mainCanvas.elements.add(prvTest)
  mainCanvas.elements.add(prvTest)
  mainCanvas.elements.add(prvTest)
  mainCanvas.elements.add(prvTest)
  mainCanvas.elements.add(prvTest)
  mainCanvas.elements.add(prvTest)
  mainCanvas.elements.add(prvTest)
  mainCanvas.elements.add(prvTest)
  mainCanvas.elements.add(prvTest)
  mainCanvas.elements.add(prvTest)
  mainCanvas.elements.add(prvTest)
  mainCanvas.elements.add(prvTest)
  mainCanvas.elements.add(prvTest)
  mainCanvas.elements.add(prvTest)
  mainCanvas.elements.add(prvTest)
proc engineStressTestInputs*() =
  var ffont = fontTracker.getFont("liberation-sans.ttf", cint(18))
  var items: cint = 20000
  var i: cint = 0
  while i < items:
    inc i
    var thisTestLabel = 
      newLabel(100 + i, 100 + i, "This is a test Label for object permanence!", [255, 255, 255, 255], ffont, cint(18))
    mainCanvas.elements.add thisTestLabel
when isMainModule:
  mainCanvas = Scene()
  mainCanvas.width = WinWidth
  mainCanvas.height = WinHeight
  startGameLoop("tester", gameObjectBuilder)