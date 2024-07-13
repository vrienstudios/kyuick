import ../all
import ../../kyuickObject
import ../../Grids/verticalGrid
import ../../Grids/horizontalGrid
# Window meant for getting user inputted text.
type TextPrompt* = ref object of KyuickObject
  path*: string
  font: FontPtr
  onSelect*: proc(text: string)
proc defLeftClick*(obj: KyuickObject, mouseEvent: MoustButtonEventPtr) =
  return
proc newFileSelector*(font: FontPtr, fontSize: cint, onSelect: proc(text: string)): FileSelector =
  var input = uiGen TextInput:
    x 0
    y 0
    width 100
    height 20
    font font
    fontSize fontSize
  var btn = uiGen Button =
    x 30
    y 25
    w 30
    h 30
    backgroundColor [0, 0, 0, 255]
    text "CONF"
    font font
    fontSize fontSize
    foregroundColor [255, 255, 255, 255]
  btn.onLeftClick = defLeftClick
  var tc = uiCon TextPrompt:
    passthrough true
  tc.children.add @[input, btn]
  return tc