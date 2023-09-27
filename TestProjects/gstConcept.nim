import kyuick
import kyuick/scene
import kyuick/components/[kyuickObject, label, textInput, button, textAlign]
import kyuick/components/imageObject

import sdl2
import sdl2/ttf

import system, os

var frameRate: Label

# Load the TTF font 'liberation-sans.ttf' at fontsize 24.
let fSize: cint = 30
var font: FontPtr
let littleFontSize: cint = 20
var littleFont: FontPtr

proc tOHover(obj: kyuickObject, b: bool) =
  let btn: Button = (Button)obj
  if b:
    btn.backgroundColor = [1, 24, 21, 255]
  else:
    btn.backgroundColor = [25, 100, 100, 255]
  return

let centerX = cint(WinWidth / 2)
let centerY = cint(WinHeight / 2)

var mainMenu: scene = scene()
var creditsScene: scene = scene()
var gameScene: scene = scene()

var backGround = newKyuickObject(0, 0, WinWidth, WinHeight, [25, 25, 25, 255])

# Separate UI elements
proc ui_buildProvinceScene(): scene =
  return nil
proc ui_buildCountryScene(): scene =
  return nil
proc ui_buildTechScene(): scene =
  return nil
proc ui_buildArmyScene(): scene =
  return nil

# Grouped UI elements, e.g top bar comprised of manpower, flag, eco, time controls, etc
proc mui_buildFlagScene(): scene =
  return nil
## Should be graph of past 12 months depicting income/deficit
proc mui_buildEconScene(): scene =
  return nil
## Time controls meant, date, +/- for time advancement; upon click, pause.
### Implement similar system to animation, increase calculations per FPS for advancing days.
#### Major calculations should be done every month.
proc mui_buildTimeScene(): scene =
  return nil
## Tech icon + # of current techs in categories.
proc mui_buildTechScene(): scene =
  return nil
## Display number of armies / of number that can be supported. On click open ui_buildArmyScene()
proc mui_buildArmyScene(): scene =
  return nil
proc mui_buildTopScene(): scene =
  return nil


proc loadScene(sc: scene) =
  echo "CLEARING SCENE"
  clearScene()
  screenObjects = sc.elements
  hoverHooked = sc.hoverables
  clickHooked = sc.clickables
  addObject frameRate

proc frameBufferController(l: imageObject) =
  if isDown("SDL_SCANCODE_W") or isDown("SDL_SCANCODE_UP"):
    l.y = l.y + 10
  if isDown("SDL_SCANCODE_A") or isDown("SDL_SCANCODE_LEFT"):
    l.x = l.x + 10
  if isDown("SDL_SCANCODE_S") or isDown("SDL_SCANCODE_DOWN"):
    l.y = l.y - 10
  if isDown("SDL_SCANCODE_D") or isDown("SDL_SCANCODE_RIGHT"):
    l.x = l.x - 10
  if isDown("SDL_SCANCODE_EQUALS"):
    l.width = l.width + 100
    l.height = l.height + 100
  if isDown("SDL_SCANCODE_MINUS"):
    l.width = l.width - 100
    l.height = l.height - 100
  gameScene.elements[0] = kyuickObject(l)
proc mapController*() =
  var l = imageObject(gameScene.elements[0])
  l.renderSaved = false
  frameBuffercontroller(l)
  return
  

proc loadCredits(obj: kyuickObject, mouseEvent: MouseButtonEventPtr) =
  loadScene creditsScene
proc loadMenu(obj: kyuickObject, mouseEvent: MouseButtonEventPtr) =
  loadScene mainMenu
proc loadGame(obj: kyuickObject, mouseEvent: MouseButtonEventPtr) =
  echo "LOADING GAME"
  loadScene gameScene

proc loadDefaults*() =
  font = ttf.openFont("../src/liberation-sans.ttf", fSize)
  littleFont = ttf.openFont("../src/liberation-sans.ttf", littleFontSize)
  frameRate = newLabel(10, 10, "FPS: ", [25, 255, 100, 255], font, fSize)

  # Build Main Menu Scene
  var nameLabel: Label = newLabel(0, 50, "Proj. Everice", [255, 255, 255, 255], font, fSize)
  nameLabel.x = centerX - cint(nameLabel.width / 2)

  var dummyPlayButton: Button = newButton(centerX - cint(nameLabel.width / 2), 100, nameLabel.width, 50, [25, 100, 100, 255], "New Game",
    font, fSize, [255, 255, 255, 255], textAlignment.center)
  var creditsButton: Button = newButton(centerX - cint(nameLabel.width / 2), 200, nameLabel.width, 50, [25, 100, 100, 255], "Credits",
    font, fSize, [255, 255, 255, 255], textAlignment.center)

  dummyPlayButton.onHoverStatusChange = tOHover
  dummyPlayButton.onLeftClick = loadGame
  creditsButton.onHoverStatusChange = tOHover
  creditsButton.onLeftClick = loadCredits

  mainMenu.elements = @[background, nameLabel, dummyPlayButton, creditsButton]
  mainMenu.hoverables = @[kyuickObject(dummyPlayButton), kyuickObject(creditsButton)]
  mainMenu.clickables = @[kyuickObject(creditsButton), kyuickObject(dummyPlayButton)]

  # Build Credits Scene
  var cnameLabel: Label = newLabel(0, 50, "Credits!", [255, 255, 255, 255], font, fSize)
  cnameLabel.x = centerX - cint(nameLabel.width / 2)
  var descLabel: Label = newLabel(0, 100, "Lead Developer: ", [255, 255, 255, 255], littleFont, littleFontSize)
  descLabel.x = centerX - cint(nameLabel.width / 2)
  var pgm: Label = newLabel(0, 120, "Programming: ", [255, 255, 255, 255], littleFont, littleFontSize)
  pgm.x = centerX - cint(nameLabel.width / 2)
  var dsgn: Label = newLabel(0, 140, "Design: ", [255, 255, 255, 255], littleFont, littleFontSize)
  dsgn.x = centerX - cint(nameLabel.width / 2)
  var nD: Label = newLabel(0, WinHeight - 20, "Built with Nim: 1.6.13 | amd64 | 2023-05-22", [255, 255, 255, 255], littleFont, littleFontSize)
  var nDd: Label = newLabel(0, WinHeight - 20, "Kyuick: Everice", [255, 255, 255, 255], littleFont, littleFontSize)
  nDd.x = WinWidth - nDd.width
  var returnBtn: Button = newButton(centerX - cint(nameLabel.width / 2), 500, nameLabel.width, 50, [25, 100, 100, 255], "Back",
    font, fSize, [255, 255, 255, 255])
  returnBtn.onHoverStatusChange = tOHover
  returnBtn.onLeftClick = loadMenu

  creditsScene.elements = @[background, cnameLabel, pgm, dsgn, descLabel, nD, nDd, returnBtn]
  creditsScene.hoverables = @[kyuickObject(returnBtn)]
  creditsScene.clickables = @[kyuickObject(returnBtn)]

proc buildGameScene*() =
    var innerMap = newImageObject(0, 0, 3221, 1777, "./testimage.png")
    innermap.frameBuffer = rect(0, 0, 3221, 1777)
    innermap.renderSaved = false
    gameScene.elements = @[kyuickObject(innerMap)]

#proc(key: TextInputEventPtr)


proc init() =
  loadDefaults()
  buildGameScene()
  loadScene(mainMenu)

proc sRender(renderer: RendererPtr) =
  frameRate.text = $currentFrameRate
  mapController()

startGameLoop("Everice", init, sRender)