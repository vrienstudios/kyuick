#SDL
import sdl2
import sdl2/ttf

# Kyuick Components
import kyuick/components/label
import kyuick/components/kyuickObject

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

# The game loop; everything is rendered and processed here.
proc startGameLoop*(name: string) =
  # Init SDL2 and SDL_TTF
  sdl2.init(INIT_VIDEO or INIT_TIMER or INIT_EVENTS)
  ttfInit()
  # Create the game window.
  let window = sdl2.createWindow(name, WinXPos, WinYPos, WinWidth, WinHeight, flags = SDL_WINDOW_SHOWN)
  # Create our renderer with V-Sync
  let renderer = createRenderer(window = window, index = -1,
    flags = Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)
  # Load the TTF font 'liberation-sans.ttf' at fontsize 20.
  let font = ttf.openFont("liberation-sans.ttf", (cint)20)
  # Create our white label at (100,100) with our font.
  screenObjects.add newLabel(100, 100, "Lorem Ipsum Dollarunis",
    [255, 255, 255, 255], font)
  var frameRate = newLabel(10, 10, "FPS: ", [25, 255, 100, 255], font)
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
        else:
          continue
    # Render our objects.
    renderer.draw()
    renderer.render(frameRate)
    for obj in screenObjects:
      renderer.render(obj)
    renderer.present()
    endCounter = getPerformanceCounter()
    frameRate.text = "FPS: " & $(int)(1 / ((endCounter - startCounter).float /
      getPerformanceFrequency().float))

when isMainModule:
  startGameLoop("tester")