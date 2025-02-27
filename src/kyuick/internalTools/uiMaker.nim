import ../components/UI/all
import ../components/scene
import ../components/kyuickObject
# Grids
import ../components/Grids/verticalGrid
import ../components/Grids/horizontalGrid
# Font
import ../utils/fontUtils
import ../utils/uiUtil
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
proc confirm_onLeftClick(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) =
  var
    ourBtn = Button(obj)
    dada = ourBtn.parent
  discard saveUIElement(dada, "confirmNameDialog")
proc createNew(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) =
  var 
    ourLabel = Label(obj)
    dad = (uiMaker)ourLabel.parent
    layout =
      uiCon VerticalGrid:
        x cint(dad.width / 2 - 200)
        y cint(dad.height / 2 - 50)
        width 400
        height 60
        backgroundColor [255, 255, 255, 255]
        render renderVert
        rect rect(cint(dad.width / 2 - 200), cint(dad.height / 2 - 50), 400, 60)
        passthrough true
    font = dad.fontTracker.getFont("liberation-sans.ttf", cint(20))
    textLayout =
      uiGen HorizontalGrid:
        x 0
        y 0
        width layout.width
        height 30
    inputHere =
      uiGen "Label":
        x 0
        y 0
        font font
        text "name:"
        fontSize 20
    tInput =
      uiGen TextInput:
        x 0
        y 0
        width textLayout.width - inputHere.width - 10
        height 30
        font font
        text "text here"
        backgroundColor [200, 200, 200, 255]
        fontSize 20
    confirm =
      uiGen Button:
        x 0
        y 0
        w 0
        h 30
        text "OK"
        font font
        fontSize 20
        backgroundColor [40, 40, 40, 255]
        foregroundColor [255,255,255,255]
        textAlign textAlignment.center
  dad.aux = dad.mainScene
  confirm.parent = layout
  layout.add textLayout
  textLayout.add inputHere
  textLayout.add tInput
  tInput.textField.renderSaved = false
  confirm.onLeftClick = confirm_onLeftClick
  layout.add confirm
  confirm.btnLabel.renderSaved = false
  dad.children.add layout
proc elementSelector(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) =
  return
proc uiDesigner(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) =
  return
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
  return editor