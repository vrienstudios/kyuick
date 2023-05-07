import sdl2

import kyuickObject, label
type TextInput* = ref object of RootObj
  textField: Label
  multiLine: bool
  characterLimit: cint

proc renderTextInput*(renderer: RendererPtr, obj: kyuickObject) =
  let textInput: TextInput = (TextInput)obj
  var r = rect(cint(obj.x), cint(obj.y), cint(obj.width), cint(obj.height))

proc newTextInput*(x, y, width, height: cint, defaultText, color: array[4, int],
  font: FontPtr, fontSize: cint): TextInput =

  var ti: TextInput = TextInput(x: x, y: y, width: width, height: height, multiLine: false)
  var tInput: Label = newLabel(x, y, defaultText, color, font, fontSize)
  ti.textField = tInput
  return ti