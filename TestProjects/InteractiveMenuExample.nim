import kyuick
import kyuick/scene
import kyuick/components/[kyuickObject, label, textInput, button]

import sdl2
import sdl2/ttf

var frameRate: Label

# Load the TTF font 'liberation-sans.ttf' at fontsize 24.
let fSize: cint = 24
var font: FontPtr
let littleFontSize: cint = 12
var littleFont: FontPtr
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

let centerX = cint(WinWidth / 2)
let centerY = cint(WinHeight / 2)
var mainMenu: scene = scene()
var creditsScene: scene = scene()
var backGround = newKyuickObject(0, 0, WinWidth, WinHeight, [25, 25, 25, 255])

proc loadScene(sc: scene) =
  clearScene()
  screenObjects = sc.elements
  hoverHooked = sc.hoverables
  clickHooked = sc.clickables

proc loadCredits(obj: kyuickObject, mouseEvent: MouseButtonEventPtr) =
  loadScene creditsScene
proc loadMenu(obj: kyuickObject, mouseEvent: MouseButtonEventPtr) =
  loadScene mainMenu

proc loadDefaults*() =
  font = ttf.openFont("../src/liberation-sans.ttf", fSize)
  littleFont = ttf.openFont("../src/liberation-sans.ttf", littleFontSize)
  frameRate = newLabel(10, 10, "FPS: ", [25, 255, 100, 255], font, fSize)
  addObject frameRate

  # Build Main Menu Scene
  var nameLabel: Label = newLabel(0, 50, "Interactive Example", [255, 255, 255, 255], font, fSize)
  nameLabel.x = centerX - cint(nameLabel.width / 2)

  var dummyPlayButton: Button = newButton(centerX - cint(nameLabel.width / 2), 100, nameLabel.width, 50, [25, 100, 100, 255], "Play!",
    font, fSize, [255, 255, 255, 255])
  var creditsButton: Button = newButton(centerX - cint(nameLabel.width / 2), 200, nameLabel.width, 50, [25, 100, 100, 255], "Credits",
    font, fSize, [255, 255, 255, 255])

  dummyPlayButton.onHoverStatusChange = tOHover
  creditsButton.onHoverStatusChange = tOHover
  creditsButton.onLeftClick = loadCredits

  mainMenu.elements = @[background, nameLabel, dummyPlayButton, creditsButton]
  mainMenu.hoverables = @[kyuickObject(dummyPlayButton), kyuickObject(creditsButton)]
  mainMenu.clickables = @[kyuickObject(creditsButton)]

  # Build Credits Scene
  var cnameLabel: Label = newLabel(0, 50, "Engine: Kyuick 0.1", [255, 255, 255, 255], font, fSize)
  cnameLabel.x = centerX - cint(nameLabel.width / 2)
  var descLabel: Label = newLabel(0, 80, "An Engine by Vrien", [255, 255, 255, 255], littleFont, littleFontSize)
  descLabel.x = centerX - cint(nameLabel.width / 2)
  var returnBtn: Button = newButton(centerX - cint(nameLabel.width / 2), 100, nameLabel.width, 50, [25, 100, 100, 255], "Back",
    font, fSize, [255, 255, 255, 255])
  returnBtn.onHoverStatusChange = tOHover
  returnBtn.onLeftClick = loadMenu

  creditsScene.elements = @[background, cnameLabel, descLabel, returnBtn]
  creditsScene.hoverables = @[kyuickObject(returnBtn)]
  creditsScene.clickables = @[kyuickObject(returnBtn)]

proc init() =
  loadDefaults()
  loadScene(creditsScene)

proc sRender(renderer: RendererPtr) =
  frameRate.text = $currentFrameRate

startGameLoop("Interactive Menu Example", init, sRender)