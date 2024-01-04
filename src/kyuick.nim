#SDL
import sdl2
import sdl2/[ttf, image]
# Kyuick Components
import kyuick/components/[kyuickObject, scene]
import kyuick/components/UI/[label, button, textInput, imageObject, graphObject, animatedObject]
# Standard Lib
import std/[math, tables, sequtils, os, strutils]
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
  canvasMovable: bool
  inFocus: KyuickObject
  fontsLoaded: seq[(string, FontPtr)]
  keyDownTracker = initTable[string, bool]()
  mouseXYTracker: tuple[x, y: cint] = (0, 0)
  # Game Content
  gameFolder*: string
  wrapMap: bool
  # Default Font and size
  fontTracker: array[6, tuple[name: string, font: FontPtr, size: cint]]
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
proc loadFont(fontPath: string, fontSize: cint): FontPtr =
  var ffont = ttf.openFont(fontPath, fontSize)
  fontsLoaded.add((path: fontPath, font: ffont))
  return ffont
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
proc getFont(name: string, size: cint): int8 =
  var index: int8 = 0
  while index < len(fontTracker):
    let currentTrack = fontTracker[index]
    inc index
    if currentTrack.font == nil: continue
    if currentTrack.size == size and currentTrack.name == name:
      echo "Got font ($1) | ($2) | ($3)pt" % [$index, $currentTrack.name, $size]
      return index
  # Look in local directory for fonts of same name.
  index = 0
  while index < len(fontTracker):
    let currentTrack = fontTracker[index]
    if currentTrack.font == nil:
      # Loop through *.ttf files in current directory
      for file in walkFiles("./*.ttf"):
        if file.split('/')[^1] == name:
          fontTracker[index] = (name, openFont(file, size), size)
          echo "Loaded font ($1) | ($2) | ($3)pt" % [$index, $file, $size]
      return index
    echo "Fonts Full"
    return -1
  echo "Font Not Loaded"
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
var currentFrameRate*: int = 0
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
  let window = sdl2.createWindow(name, WinXPos, WinYPos, WinWidth, WinHeight, flags = SDL_WINDOW_SHOWN or SDL_WINDOW_VULKAN)
  # Create our renderer with V-Sync
  let renderer = createRenderer(window = window, index = -1,
    flags = Renderer_Accelerated or Renderer_PresentVSync)
  var startCounter = getPerformanceCounter()
  var endCounter = getPerformanceCounter()
  # Start the infinite renderer.
  while true:
    startCounter = getPerformanceCounter()
    var event = defaultEvent
    # Check for events.
    while pollEvent(event):
      case event.kind:
        of QuitEvent:
          break
        of MouseButtonDown:
          mousePress(event.button)
        of MouseButtonUp:
          mousePress(event.button, false)
        of MouseMotion:
          mouseMove(event.motion)
        of KeyDown:
          echo event.key.keysym.scancode
          if inFocus of textInput.TextInput:
            if $event.key.keysym.scancode == "SDL_SCANCODE_BACKSPACE":
              textInput.TextInput(inFocus).remove()
          keyDownTracker[$event.key.keysym.scancode] = true
        of KeyUp:
          echo event.key.keysym.scancode
          keyDownTracker[$event.key.keysym.scancode] = false
        of TextInput:
          textInput(event.text)
        else:
          continue
    renderer.clear()
    frameBufferController()
    render(mainCanvas, renderer)
    renderer.present()
    endCounter = getPerformanceCounter()
    currentFrameRate = (int)(1 / ((endCounter - startCounter).float /
      getPerformanceFrequency().float))
    # Cap
    #delay uint32(floor((100.0f - (endCounter.float - startCounter.float)/(getPerformanceFrequency().float * 1000.0f))))
    #echo GC_getStatistics()
    #echo $len(screenObjects)
proc buildCanvasTest*() =
  canvasZoom = 1
  mainCanvas.width = 3221
  mainCanvas.height = 1777
  mainCanvas.canvas = newImageObject(0, 0, 3221, 1777, "./provMap.png")
  var ffont = fontTracker[getFont("liberation-sans.ttf", cint(18))].font
  var thisTestLabel = 
    newLabel(100, 100, "This is a test Label for object permanence!", [255, 255, 255, 255], ffont, cint(18))
  mainCanvas.elements.add thisTestLabel
proc createTextInput*(x, y, w, h: cint, font: FontPtr, fSize: cint): TextInput =
  return newTextInput(x, y, w, h, [0, 0, 0, 255], "This is some test text.", [255, 255, 255, 255], font, fSize)
proc textEditorTest*() =
  mainCanvas.width = WinWidth
  mainCanvas.height = WinHeight
  var ffont = fontTracker[getFont("liberation-sans.ttf", cint(18))].font
  var thisTextInput = createTextInput(0, 0, WinWidth, WinHeight, ffont, cint(18))
  mainCanvas.elements.add thisTextInput
  mainCanvas.clickables.add(thisTextInput)
proc choiceDialogForType*() =
  mainCanvas.width = WinWidth
  mainCanvas.height = WinHeight
  return
proc gameObjectBuilder*() =
  return
when isMainModule:
  mainCanvas = Scene()
  startGameLoop("tester", textEditorTest)