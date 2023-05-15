#SDL
import sdl2
import sdl2/ttf

# Kyuick Components
import kyuick/components/[kyuickObject, label, button, textInput]

# Window settings to be set before startGameLoop is called.
const
  WinXPos* = SDL_WINDOWPOS_CENTERED
  WinYPos* = SDL_WINDOWPOS_CENTERED
  WinWidth* = 980
  WinHeight* = 720

var screenObjects*: seq[kyuickObject] = @[]
var hoverHooked*: seq[kyuickObject] = @[]
var clickHooked*: seq[kyuickObject] = @[]
var inFocus: kyuickObject

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

# Process mouse clicks and calculate object clicked.
proc mousePress(e: MouseButtonEventPtr) =
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

proc textInput(textEvent: TextInputEventPtr) =
  if not (inFocus of textInput.TextInput):
    return
  textInput.TextInput(inFocus).add(textEvent.text[0])
proc textEdit(textEvent: TextEditingEventPtr) =
  if not (inFocus of textInput.TextInput):
    return
  echo "WIP"
proc textEdit(key: KeyboardEventPtr) =
  if not (inFocus of textInput.TextInput):
    return
  case key.keysym.sym:
    of cint(8): # BACKSPACE
      textInput.TextInput(inFocus).remove()
    else:
      return
var currentFrameRate*: int = 0
# The game loop; everything is rendered and processed here.
proc startGameLoop*(name: string, onInit: proc(), cRender: proc(r: RendererPtr)) =
  # Init SDL2 and SDL_TTF
  sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)
  ttfInit()
  if onInit != nil:
    onInit()
  # Create the game window.
  let window = sdl2.createWindow(name, WinXPos, WinYPos, WinWidth, WinHeight, flags = SDL_WINDOW_SHOWN)
  # Create our renderer with V-Sync
  let renderer = createRenderer(window = window, index = -1,
    flags = Renderer_Accelerated or Renderer_TargetTexture)
  var startCounter = getPerformanceCounter()
  var endCounter = getPerformanceCounter()
  # Start the infinite renderer.
  while true:
    startCounter = getPerformanceCounter()
    var ticks = getTicks()
    var event = defaultEvent
    # Check for events.
    while pollEvent(event):
      case event.kind:
        of QuitEvent:
          break
        of MouseButtonDown:
          mousePress(event.button)
        of MouseMotion:
          mouseMove(event.motion)
        of EventType.TextInput:
          textInput(event.text)
        # TODO: Write IME-compatible code.
        of TextEditing:
          textEdit(event.edit)
        of KeyDown:
          textEdit(event.key)
        else:
          continue
    renderer.clear()
    # Render our objects.
    for obj in screenObjects:
      renderer.render(obj)
    if cRender != nil:
      renderer.cRender()
    renderer.present()
    endCounter = getPerformanceCounter()
    currentFrameRate = (int)(1 / ((endCounter - startCounter).float /
      getPerformanceFrequency().float))
    #echo GC_getStatistics()
    #echo $len(screenObjects)

when isMainModule:
  startGameLoop("tester", nil)
