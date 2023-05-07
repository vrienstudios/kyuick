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

# Fill screen with gray texture.
proc draw(renderer: RendererPtr) =
  renderer.setDrawColor 50,50,50,255
  var r = rect(0, 0, 980, 720)
  renderer.fillRect(r)

var screenObjects: seq[kyuickObject] = @[]
var hoverHooked: seq[kyuickObject] = @[]
var clickHooked: seq[kyuickObject] = @[]
var inFocus: kyuickObject

proc hookHover*(kyuickObj: kyuickObject,
  funct: proc(obj: kyuickObject, status: bool)) =
    kyuickObj.onHoverStatusChange = funct
    hoverHooked.add kyuickObj
proc hookClick*(kyuickObj: kyuickObject,
  funct: proc(obj: kyuickObject, mouseEvent: MouseButtonEventPtr)) =
    kyuickObj.onLeftClick = funct
    clickHooked.add kyuickObj
proc unHookObject*(obj: kyuickObject) =
  obj.texture.destroy()
  if obj.onLeftClick != nil:
    clickHooked.del(find(clickHooked, obj))
  if obj.onHoverStatusChange != nil:
    hoverHooked.del(find(hoverHooked, obj))

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
var frameRate: Label
var memLabel: Label

# Load the TTF font 'liberation-sans.ttf' at fontsize 24.
let fSize: cint = 24
var font: FontPtr

# Test proc, to be deleted.
proc clicked(obj: kyuickObject, mouseEvent: MouseButtonEventPtr) =
  #echo "Clicked object at ($1, $2)" % [$obj.x, $obj.y]
  screenObjects.add newLabel((cint)(obj.x + 20), (cint)obj.y, "pow!", [100, 100, 100, 255], font, fSize)
proc tOHover(obj: kyuickObject, b: bool) =
  let btn: Button = (Button)obj
  if b:
    btn.foreColor = [1, 24, 21, 255]
  else:
    btn.foreColor = [25, 100, 100, 255]
  return
proc testRendering*() =
  font = ttf.openFont("liberation-sans.ttf", fSize)
  # Create our white label at (100,100) with our font.
  screenObjects.add newLabel(100, 100, "Lorem Ipsum Dollarunis",
    [255, 255, 255, 255], font, fSize)
  frameRate = newLabel(10, 10, "FPS: ", [25, 255, 100, 255], font, fSize)
  memLabel = newLabel(10, 30, "Occ. Mem: ", [25, 255, 100, 255], font, fSize)
  screenObjects.add frameRate
  screenObjects.add memLabel
  var btn = newButton(100, 150, 250, 50, [25, 100, 100, 255], "Button",
    font, fSize, [255, 255, 255, 255])
  btn.onLeftClick = clicked
  screenObjects.add btn
  hookHover(btn, tOHover)

  var textInput = newTextInput(100, 300, 250, 30, [0, 0, 0, 255],
    "default", [255, 255, 255, 255], font, fSize)
  screenObjects.add textInput
  hoverHooked.add textInput

# The game loop; everything is rendered and processed here.
proc startGameLoop*(name: string) =
  # Init SDL2 and SDL_TTF
  sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)
  ttfInit()
  # Create the game window.
  let window = sdl2.createWindow(name, WinXPos, WinYPos, WinWidth, WinHeight, flags = SDL_WINDOW_SHOWN)
  # Create our renderer with V-Sync
  let renderer = createRenderer(window = window, index = -1,
    flags = Renderer_Accelerated or Renderer_TargetTexture)

  testRendering()

  var startCounter = getPerformanceCounter()
  var endCounter = getPerformanceCounter()
  # Start the infinite renderer.
  while true:
    var ticks = getTicks()
    startCounter = getPerformanceCounter()
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
    # Render our objects.
    renderer.draw()
    for obj in screenObjects:
      renderer.render(obj)
    renderer.present()
    endCounter = getPerformanceCounter()
    frameRate.text = "FPS: " & $(int)(1 / ((endCounter - startCounter).float /
      getPerformanceFrequency().float))
    memLabel.text = "Res. Mem: " & $(getTotalMem().float / 1000.0f) & " KB" & " | Used: " & $int((getOccupiedMem().float / 1000.0f)) & " KB"
    #echo GC_getStatistics()
    #echo $len(screenObjects)

when isMainModule:
  startGameLoop("tester")
