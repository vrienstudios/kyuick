import ../components/UI/all
import ../components/scene
import ../components/kyuickObject
# Grids
import ../components/Grids/verticalGrid
import ../components/Grids/horizontalGrid
# Font
import ../utils/fontUtils
# SDL2
import sdl2
import sdl2/ttf
import sdl2/image
# STD
import os

type uiMaker* = ref object of KyuickObject
  mainScene*: Scene
  fontTracker*: FontTracker
  aux*: Scene
  menuPanel*: Menubar
  leftPanel*: VerticalGrid
  mapPanel*: Scene

proc renderuiMaker*(renderer: RendererPtr, obj: KyuickObject) =
  let editor = uiMaker(obj)
  renderer.render(editor.menuPanel)
  render(editor.mainScene, renderer)
  return
proc processOpenning(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) =
  return
proc createNew(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) =
  var 
    ourLabel = Label(obj)
    dad = (uiMaker)ourLabel.parent
    layout =
      uiCon VerticalGrid:
        x 0
        y 140
        width dad.width
        height 200
        backgroundColor [66, 66, 255, 255]
        render renderVert
        rect rect(0, 140, dad.width, 200)
        passthrough true
    font = dad.fontTracker.getFont("liberation-sans.ttf", cint(18))
    tInput =
      uiGen TextInput:
        x 0
        y 140
        width dad.width
        height 20
        font font
        text "ooga booga"
        fontSize 18
    confirm =
      uiGen Button:
        x 0
        y 0
        w 200
        h 100
        text "OK"
        font font
        fontSize 18
        backgroundColor [0, 0, 255, 255]
        foregroundColor [255,255,255,255]
  dad.aux = dad.mainScene
  layout.add tInput
  #layout.add confirm
  dad.children.add layout
proc openNow(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) =
  var 
    ourLabel = Label(obj)
    dad = uiMaker(ourLabel.parent)
    layout = VerticalGrid()
    nScene = Scene()
  dad.aux = dad.mainScene
  for file in walkFiles("./assets/ui/*.ui.yml"):
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
proc buildMenuBar(fonts: var FontTracker, w, h: cint, dada: KyuickObject): Menubar =
  var menuPanel: Menubar = newMenubar(x = 0, y = 100, width = w, height = 40)
  let font = fonts.getFont("liberation-sans.ttf", cint(18))
  block menuItems:
    var
      lCreate =
        uiGen "Label":
          text "Create"
          foregroundColor [0, 0, 0, 255]
          font font
          fontSize 18
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
    lCreate.parent = dada

    lOpen.onLeftClick = openNow
    lOpen.onHoverStatusChange = labelHover
    lOpen.parent = dada

    lSave.onLeftClick = saveNow
    lSave.onHoverStatusChange = labelHover
    lSave.parent = dada

    menuPanel.add lCreate
    menuPanel.add lOpen
    menuPanel.add lSave
  return menuPanel
proc createuiCon*(fonts: var FontTracker, width, height: cint): uiMaker =
  var editor = uiMaker()
  editor.passthrough = true
  editor.width = width
  editor.height = height
  editor.fontTracker = fonts
  editor.render = renderuiMaker
  editor.menuPanel = buildMenuBar(fonts, width, height, editor)
  editor.mainScene = Scene()
  editor.children.add editor.menuPanel
  #editor.leftPanel = newVerticalGrid(0, 0, 100, height)

  # Read/Load all assets.
  # While under Dev, assume assets are under ./assets/*
  # Setup UI
  # Load assets OR setup province fields on leftPanel
  # Setup callback
  return editor