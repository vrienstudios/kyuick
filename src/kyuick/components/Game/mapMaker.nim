import ./gameObjects
import ../UI/all
import ../scene
import ../kyuickObject
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
  menuPanel*: Menubar
  leftPanel*: VerticalGrid
  mapPanel*: Scene

proc renderMapEditor*(renderer: RendererPtr, obj: KyuickObject) =
  let editor = MapEditor(obj)
  renderer.render(editor.menuPanel)
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
proc createNewMapPack*(name: string) =
  return
# Fill Screen
proc buildMenuBar(fonts: var FontTracker, w, h: cint): Menubar =
  var menuPanel: Menubar = newMenubar(x = 0, y = 50, width = w, height = 40)
  let font = fonts.getFont("liberation-sans.ttf", cint(18))
  block menuItems:
    var
      lCreate =
        uiGen "Label":
          text "Create"
          foregroundColor [0, 0, 0, 255]
          font font
          fontSize 18
          onLeftClick 
      lOpen = 
        uiGen "Label":
          text "Open"
          foregroundColor [0, 0, 0, 255]
          font font
          fontSize 18
      lSave = 
        uiGen "Label":
          text "Save"
          foregroundColor [0, 0, 0, 255]
          font font
          fontSize 18
    
    lCreate.onLeftClick = createNew
    lCreate.onHoverStatusChange = labelHover
    
    lOpen.onLeftClick = openNow
    lOpen.onHoverStatusChange = labelHover

    lSave.onLeftClick = saveNow
    lSave.onHoverStatusChange = labelHover

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
  editor.children.add editor.menuPanel
  #editor.leftPanel = newVerticalGrid(0, 0, 100, height)

  # Read/Load all assets.
  # While under Dev, assume assets are under ./assets/*
  # Setup UI
  # Load assets OR setup province fields on leftPanel
  # Setup callback
  return editor