#SDL
import sdl2
import sdl2/ttf
import sdl2/image

# Kyuick Components
import kyuick/components/[kyuickObject, label, button, textInput, imageObject, graphObject, animatedObject]
import kyuick/scene
import std/math
import std/tables
import std/sequtils
import std/os
import std/strutils

# Window settings to be set before startGameLoop is called.
const
  WinXPos* = SDL_WINDOWPOS_CENTERED
  WinYPos* = SDL_WINDOWPOS_CENTERED
  WinWidth* = 1920
  WinHeight* = 1080

var
  screenObjects*: seq[kyuickObject] = @[]
  hoverHooked*: seq[kyuickObject] = @[]
  clickHooked*: seq[kyuickObject] = @[]
  animatables*: seq[kyuickObject] = @[]

  kinputCallBacks*: seq[proc(key: TextInputEventPtr)]
  minputCallBacks*: seq[proc(mouse: MouseButtonEventPtr)]
  mMovementCallBack*: seq[proc(mouse: MouseMotionEventPtr)]

  scenes*: seq[Scene] = @[]
  mainCanvas*: Scene
  canvasZoom: cint
  canvasMovable: bool
  inFocus: kyuickObject
  fontsLoaded: seq[(string, FontPtr)]
  keyDownTracker = initTable[string, bool]()
  mouseXYTracker: tuple[x, y: cint] = (0, 0)
  # Game Content
  gameFolder*: string
  wrapMap: bool

proc isDown*(key: string): bool =
  if not keyDownTracker.hasKey(key):
    return false
  return keyDownTracker[key]
proc hookHover*(kyuickObj: kyuickObject,
  funct: proc(obj: kyuickObject, status: bool)) =
    kyuickObj.onHoverStatusChange = funct
    hoverHooked.add kyuickObj
proc hookClick*(kyuickObj: kyuickObject,
  funct: proc(obj: kyuickObject, mouseEvent: MouseButtonEventPtr)) =
    kyuickObj.onLeftClick = funct
    clickHooked.add kyuickObj
proc addObject*(obj: kyuickObject) =
  screenObjects.add obj
proc unHookObject*(obj: kyuickObject) =
  obj.texture.destroy()
  if obj.onLeftClick != nil:
    clickHooked.del(find(clickHooked, obj))
  if obj.onHoverStatusChange != nil:
    hoverHooked.del(find(hoverHooked, obj))
proc clearScene*() =
  screenObjects = @[]
  for obj in hoverHooked:
    obj.hoverStatus = false
  hoverHooked = @[]
  clickHooked = @[]
  inFocus = nil
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
  if inFocus != nil:
    inFocus.leftClick(e)
    return
  case e.button:
    of 1:
      for obj in clickHooked:
        #echo ("mouse($1, $2) objX($3, $4) objY($5, $6)" % [$e.x, $e.y, $obj.x, $(obj.x + obj.width), $obj.y, $(obj.y + obj.height)])
        if e.x >= obj.x and e.x <= (obj.x + obj.width):
          if e.y >= obj.y and e.y <= (obj.y + obj.height):
            inFocus = obj
            obj.leftClick(e)
            return
    else:
      return
proc mouseMove(e: MouseMotionEventPtr) =
  var hoverObjFound: bool = false
  for obj in hoverHooked:
    if hoverObjFound == false:
      if e.x >= obj.x and e.x <= (obj.x + obj.width):
        if e.y >= obj.y and e.y <= (obj.y + obj.height):
          obj.hoverStatus = true
          hoverObjFound = true
          if obj.autoFocusable:
            inFocus = obj
          continue
    if inFocus == obj:
      inFocus = nil
    obj.hoverStatus = false
proc frameBufferController() =
  #if mainCanvas.x + mainCanvas.width > mainCanvas.width:
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
proc startGameLoop*(name: string) =
  # Init SDL2 and SDL_TTF
  sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)
  ttfInit()
  var ffont = ttf.openFont("./liberation-sans.ttf", cint(18))
  var thisTestLabel = 
    newLabel(100, 100, "This is a test Label for object permanence!", [255, 255, 255, 255], ffont, cint(18))
  mainCanvas.elements.add thisTestLabel
  # Later we can add error handling for init
  discard image.init()
  # Create the game window.
  let window = sdl2.createWindow(name, WinXPos, WinYPos, WinWidth, WinHeight, flags = SDL_WINDOW_SHOWN)
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
          keyDownTracker[$event.key.keysym.scancode] = true
        of KeyUp:
          echo event.key.keysym.scancode
          keyDownTracker[$event.key.keysym.scancode] = false
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

when isMainModule:
  canvasZoom = 1
  mainCanvas = Scene()
  mainCanvas.width = 3221
  mainCanvas.height = 1777
  mainCanvas.canvas = newImageObject(0, 0, 3221, 1777, "./provMap.png")
  startGameLoop("tester")