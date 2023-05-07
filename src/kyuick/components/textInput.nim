import sdl2
import sdl2/ttf

import kyuickObject, label

type TextInput* = ref object of kyuickObject
  backgroundColor: array[4, int]
  cursorPosition: int
  textField: Label
  multiLine: bool
  characterLimit: int

proc renderTextInput*(renderer: RendererPtr, obj: kyuickObject) =
  let textInput: TextInput = (TextInput)obj
  if textInput.renderSaved == true:
    renderer.setDrawColor(color(textInput.backgroundColor[0], textInput.backgroundColor[1],
      textInput.backgroundColor[2], textInput.backgroundColor[3]))
    renderer.fillRect(textInput.rect)
    renderLabel(renderer, textInput.textField)
    return
  textInput.rect = rect(cint(obj.x), cint(obj.y), cint(obj.width), cint(obj.height))
  renderLabel(renderer, textInput.textField)
  renderer.setDrawColor(color(textInput.backgroundColor[0], textInput.backgroundColor[1],
    textInput.backgroundColor[2], textInput.backgroundColor[3]))
  renderer.fillRect(textInput.rect)
  textInput.renderSaved = true
proc add*(this: TextInput, chr: char) =
  if this.textField.width >= this.width - 14:
    return
  this.renderSaved = false
  this.textField.text = this.textField.text & chr
proc remove*(this: TextInput) =
  if len(this.textField.text) == 0:
    return
  this.renderSaved = false
  this.textField.text = this.textField.text[0..^2]
proc defaultOnLeftClick*(obj: kyuickObject, event: MouseButtonEventPtr) =
  return
proc newTextInput*(x, y, width, height: cint, bg: array[4, int], defaultText: string, color: array[4, int],
  font: FontPtr, fontSize: cint): TextInput =
  var ti: TextInput = TextInput(x: x, y: y, width: width, height: height, backgroundColor: bg, multiLine: false,
    characterLimit: 20)
  var tInput: Label = newLabel(x, y, defaultText, color, font, fontSize)
  ti.textField = tInput
  ti.render = renderTextInput
  return ti