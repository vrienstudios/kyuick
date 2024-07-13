import ../all
import ../../kyuickObject
import ../../Grids/verticalGrid
import ../../Grids/horizontalGrid

# Window meant for selecting files.
type FileSelector* = ref object of KyuickObject
  path*: string
  tInput: TextInput
  btnSelect: Button
  font: FontPtr
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
  #me.backgroundColor = [25, 25, 255]
proc newFileItem(this: FileSelector, filePath: string): HorizontalGrid =
  var fileInfo: HorizontalGrid =
    uiGen HorizontalGrid:
      height 30
      width this.width
      onHoverStatusChange onLineHoverTurnBlue
  var 
    fileType =
      uiGen Label:
        font this.font
        fontsize 18
        text case filePath.split('.')[^1]:
              of ".pck":
                "ASSET ARCHIVE"
              of ".mvd":
                "MAP DATA"
              of ".natd":
                "NATL DATA"
              of ".pdat":
                "PROV DATA"
              of ".mpk":
                "GAME ARCHIVE"
              else:
                "UKN"
    fileName =
      uiGen Label:
        font this.font
        fontSize 18
        text $filePath.split('.')[0..^1]
    fileInfo.add fileType
    fileInfo.add fileName
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
    passthrough true
  fs.children.add @[input, btn]
  return fs