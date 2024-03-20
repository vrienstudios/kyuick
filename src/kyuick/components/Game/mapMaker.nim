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
proc openNow(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) =
  var 
    ourLabel = Label(obj)
    #dad = MapEditor(ourLabel.parent)
    layout = VerticalGrid()
  #dad.aux = Scene()
  for file in walkFiles("./assets/"):
    echo "err"
    var labli = ourLabel.clone(0, 0, file)
    labli.onLeftClick = processOpenning
    layout.add labli
  return
proc saveNow(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) = 
  return
# Fill Screen
proc openMapEditorForTile*(fonts: var FontTracker, width, height: cint): MapEditor =
  echo "1"
  var editor = MapEditor()
  editor.render = renderMapEditor
  editor.tileFolder = "./assets/"
  editor.menuPanel = newHorizontalGrid(0, 50, width, 50)
  editor.menuPanel.backgroundColor = [255, 255, 255, 255]
  let font = fonts.getFont("liberation-sans.ttf", cint(18))
  block menuItems:
    var
      lOpenNew = newLabel(0, 0, "Open", [0, 0, 0, 255], font, cint(18))
      lSave = newLabel(0, 0, "Save", [0, 0, 0, 255], font, cint(18))
    lOpenNew.onLeftClick = openNow
    lOpenNew.canClick = false
    lSave.onLeftClick = saveNow
    lSave.canClick = false
    editor.menuPanel.add lOpenNew
    editor.menuPanel.add lSave
  editor.mainScene = Scene()
  editor.mainScene.add editor.menuPanel
  #editor.leftPanel = newVerticalGrid(0, 0, 100, height)

  # Read/Load all assets.
  # While under Dev, assume assets are under ./assets/*
  # Setup UI
  # Load assets OR setup province fields on leftPanel
  # Setup callback
  return editor