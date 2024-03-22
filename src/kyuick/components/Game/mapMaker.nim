import ./gameObjects
import ../kyuickObject
# UI
import ../UI/label
import ../UI/button
import ../UI/textInput
import ../UI/imageObject
import ../scene
# Grids
import ../Grids/verticalGrid
import ../Grids/horizontalGrid
# Font
import ../../utils/fontUtils
# SDL2
import sdl2
import sdl2/ttf
import sdl2/image
# STD
import os

type MapEditor* = ref object of KyuickObject
  tileFolder*: string
  cMap*: Map
  mainScene*: Scene
  aux*: Scene
  menuPanel*: HorizontalGrid
  leftPanel*: VerticalGrid
  mapPanel*: Scene

proc renderMapEditor*(renderer: RendererPtr, obj: KyuickObject) =
  let editor = MapEditor(obj)
  renderHor(renderer, editor.menuPanel)
  return
proc processOpenning(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) =
  return
proc createNew(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) =
  return
proc openNow(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) =
  echo "AA"
  return
  var 
    ourLabel = Label(obj)
    dad = MapEditor(ourLabel.parent)
    layout = VerticalGrid()
    nScene = Scene()
  dad.aux = dad.mainScene
  for file in walkFiles("./assets/kmaps/*.kmap"):
    var labli = ourLabel.clone(0, 0, file)
    labli.onLeftClick = processOpenning
    layout.add labli
  nScene.add layout
  dad.mainScene = nScene
  return
proc saveNow(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) = 
  return
proc labelHover(obj: KyuickObject, e: (bool, MouseMotionEventPtr)) =
  if e[0] == true:
    obj.foregroundColor = [100, 100, 100, 255]
    obj.renderSaved = false
    return
  obj.foregroundColor = [0, 0, 0, 255]
  obj.renderSaved = false
  return
# Fill Screen
proc buildMenuBar(fonts: var FontTracker, w, h: cint): HorizontalGrid =
  var menuPanel = newHorizontalGrid(0, 50, w, 50)
  menuPanel.backgroundColor = [255, 255, 255, 255]
  let font = fonts.getFont("liberation-sans.ttf", cint(18))
  block menuItems:
    var
      lCreate = newLabel(0, 0, "Create", [0, 0, 0, 255], font, cint(18))
      lOpen = newLabel(0, 0, "Open", [0, 0, 0, 255], font, cint(18))
      lSave = newLabel(0, 0, "Save", [0, 0, 0, 255], font, cint(18))
    lCreate.onLeftClick = createNew
    lCreate.canClick = true
    lCreate.onHoverStatusChange = labelHover
    lCreate.canHover = true
    lOpen.onLeftClick = openNow
    lOpen.canClick = true
    lSave.onLeftClick = saveNow
    lSave.canClick = true
    menuPanel.add lCreate
    menuPanel.add lOpen
    menuPanel.add lSave
  return menuPanel
proc openMapEditorForTile*(fonts: var FontTracker, width, height: cint): MapEditor =
  var editor = MapEditor()
  editor.render = renderMapEditor
  editor.tileFolder = "./assets/tiles/"
  editor.menuPanel = buildMenuBar(fonts, width, height)
  editor.mainScene = Scene()
  editor.mainScene.add editor.menuPanel
  #editor.leftPanel = newVerticalGrid(0, 0, 100, height)

  # Read/Load all assets.
  # While under Dev, assume assets are under ./assets/*
  # Setup UI
  # Load assets OR setup province fields on leftPanel
  # Setup callback
  return editor