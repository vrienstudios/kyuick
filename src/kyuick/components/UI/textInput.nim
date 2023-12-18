import std/math
import std/strutils

import sdl2
import sdl2/ttf

import ../kyuickObject
import ../../utils/rendererUtils
import label

type TextInput* = ref object of kyuickObject
  # Position of cursor in the text sequence.
  cursorPosition: int
  # X-length of where the cursor is | Default is width.
  calcLength: int
  textField: Label
  multiLine: bool
  characterLimit: int
  cLength: seq[cint]

proc renderIndexLine*(renderer: RendererPtr, textInput: TextInput) =
  if textInput.focusChange == true:
    renderer.setDrawColor(textInput.textField.color)
    renderer.drawLine(cint(textInput.x + textInput.calcLength - 3), cint(textInput.textField.height), cint(textInput.x + textInput.calcLength), cint(textInput.textField.height))
proc renderTextInput*(renderer: RendererPtr, obj: kyuickObject) =
  let textInput: TextInput = (TextInput)obj
  renderer.setDrawColor(textInput.backgroundColor)
  if textInput.renderSaved == true:
    renderer.fillRect(textInput.rect)
    renderLabel(renderer, textInput.textField)
    renderIndexLine(renderer, textInput)
    return
  textInput.rect = rect(cint(obj.x), cint(obj.y), cint(obj.width), cint(obj.height))
  renderLabel(renderer, textInput.textField)
  renderer.fillRect(textInput.rect)
  renderIndexLine(renderer, textInput)
  textInput.renderSaved = true
proc add*(this: TextInput, chr: char) =
  if this.textField.width >= this.width - 14:
    return
  if this.cursorPosition > len(this.textField.text):
    this.cursorPosition = len(this.textField.text)
  var w, h: cint = 0
  discard ttf.sizeText(this.textField.font, cstring($chr), addr w, addr h)
  this.calcLength = this.calcLength + w
  var str: string = this.textField.text
  str.insert($chr, this.cursorPosition)
  this.textField.text = str
  this.cLength.insert(w, this.cursorPosition)
  inc this.cursorPosition
proc remove*(this: TextInput) =
  if len(this.textField.text) == 0:
    return
  if this.cursorPosition == 0:
    return
  if this.cursorPosition >= len(this.textField.text):
    this.cursorPosition = len(this.textField.text)
  this.cLength.delete(this.cursorPosition - 1)
  var str: string = this.textField.text
  this.calcLength = this.calcLength - sizeText(this.textField.font, $this.textField.text[this.cursorPosition - 1])[0]
  str.delete(this.cursorPosition - 1..this.cursorPosition - 1)
  this.textField.text = str
  dec this.cursorPosition
proc defaultOnLeftClick*(obj: kyuickObject, mouse: MouseButtonEventPtr) =
  var
    this = (TextInput)obj
    idx = 0
    calcLength = 0
  let relativeX = mouse.x - obj.x
  if len(this.cLength) == 0:
    this.cursorPosition = 0
    return
  while calcLength < int(round(float(relativeX))) and idx < this.cLength.len:
    calcLength = calcLength + this.cLength[idx]
    inc idx
  this.calcLength = calcLength
  this.cursorPosition = idx
  return
proc newTextInput*(x, y, width, height: cint, bg: array[4, int], defaultText: string, color: array[4, int],
  font: FontPtr, fontSize: cint): TextInput =
  var ti: TextInput = TextInput(x: x, y: y, width: width, height: height, backgroundColor: bg, cursorPosition: len(defaultText), multiLine: false,
    characterLimit: 20)
  var tInput: Label = newLabel(x, y, defaultText, color, font, fontSize)
  ti.textField = tInput
  ti.render = renderTextInput
  ti.onLeftClick = defaultOnLeftClick
  var w, h: cint = 0
  for chr in defaultText:
    discard ttf.sizeText(ti.textField.font, cstring($chr), addr w, addr h)
    ti.cLength.add w
  ti.calcLength = tInput.width
  return ti