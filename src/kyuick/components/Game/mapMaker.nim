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

type MapEditor* = ref object of KyuickObject
  tileFolder*: string
  cMap*: Map
  menuPanel*: HorizontalGrid
  leftPanel*: VerticalGrid
  mapPanel*: Scene

proc renderMapEditor*(renderer: RendererPtr, obj: KyuickObject) =
  let editor = MapEditor(obj)
  renderHor(renderer, editor.menuPanel)
  return
proc openNow(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) =
  return
proc saveNow(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) = 
  return
# Fill Screen
proc openMapEditorForTile*(fonts: var FontTracker, width, height: cint): MapEditor =
  var editor = MapEditor()
  editor.render = renderMapEditor
  editor.tileFolder = "./assets/"
  editor.menuPanel = newHorizontalGrid(0, 0, width, 50)
  let font = fonts.getFont("liberation-sans.ttf", cint(10))
  block menuItems:
    var
      lOpenNew = newLabel(0, 0, "Open", [255, 255, 255, 255], font, cint(10))
      lSave = newLabel(0, 0, "Save", [255, 255, 255, 255], font, cint(10))
    lOpenNew.onLeftClick = openNow
    lSave.onLeftClick = saveNow
    editor.menuPanel.add lOpenNew
    editor.menuPanel.add lSave
  editor.leftPanel = newVerticalGrid(0, 0, 100, height)
  
  
  # Read/Load all assets.
  # While under Dev, assume assets are under ./assets/*
  # Setup UI
  # Load assets OR setup province fields on leftPanel
  # Setup callback
  return nil