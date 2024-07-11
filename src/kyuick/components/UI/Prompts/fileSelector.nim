import ../all
import ../../kyuickObject
import ../../Grids/verticalGrid
import ../../Grids/horizontalGrid

# Window meant for selecting files.
type FileSelector* = ref object of KyuickObject
  path*: string
  tInput: TextInput
  btnSelect: Button
  objSelected: proc(res: string)
  #fileList*: VerticalGrid
  #interactives*: HorizontalGrid
  #[
    fileName*: TextInput
    cancel*: Button
    open*: Button
  ]#
proc onLineHoverTurnBlue*(obj: KyuickObject, e: tuple[b: bool, mouse: MouseMotionEventPtr]) =
  var me = HorizontalGrid(obj)
  me.outline = e.b
proc newFileItem(this: FileSelector, filePath: string): HorizontalGrid =
  var fileInfo: HorizontalGrid =
    uiGen HorizontalGrid:
      height 100
      width this.width
      onHoverStatusChange onLineHoverTurnBlue
  return
#proc buildFileList(this: FileSelector) =
#  for file in walkFiles(this.path):
#    fileList.add newFileItem(file)
proc defaultOnClick*(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) =
  let fs = FileSelector(obj)
  fs.onClick(fs.tInput.textField.text)
proc newFileSelector*(pstr: string, font: FontPtr, fontSize: cint, onClick: proc(res: string)): FileSelector =
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
    text "OK"
    font font
    fontSize fontSize
    foregroundColor [255, 255, 255, 255]
  btn.onLeftClick = defaultOnClick
  var fs = uiCon FileSelector:
    path pstr
    tInput input
    btnSelect btn
    passthrough true
  return fs