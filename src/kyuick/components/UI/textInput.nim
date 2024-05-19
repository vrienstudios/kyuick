import std/math
import std/strutils

import sdl2
import sdl2/ttf

import ../kyuickObject
import ../../utils/rendererUtils
import label

type TextInput* = ref object of KyuickObject
  # Position of cursor in the text sequence.
  cursorPosition: int
  # X-length of where the cursor is | Default is width.
  calcLength: int
  textField*: Label
  multiLine: bool
  characterLimit: int
  cLength: seq[cint]

proc renderIndexLine(renderer: RendererPtr, textInput: TextInput) =
  if textInput.focused == true:
    renderer.setDrawColor(textInput.textField.foregroundColor)
    renderer.drawLine(cint(textInput.x + textInput.calcLength - 3), cint(textInput.textField.height), cint(textInput.x + textInput.calcLength), cint(textInput.textField.height))
proc renderTextInput(renderer: RendererPtr, obj: KyuickObject) =
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
proc updateCalcLength*(this: TextInput) =
  var c: int = 0
  var tL: int = 0
  while c < this.cursorPosition:
    tL = tL + this.cLength[c]
    inc c
  this.calcLength = tL
proc defaultOnLeftClick(obj: KyuickObject, mouse: MouseButtonEventPtr) =
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
proc keyDown*(obj: KyuickObject, scancode: string) =
  var this = TextInput(obj)
  if scancode == "SDL_SCANCODE_LEFT" and this.cursorPosition != 0:
    dec this.cursorPosition
    this.updateCalcLength()
  elif scancode == "SDL_SCANCODE_RIGHT":
    if this.cursorPosition == this.cLength.len: return
    inc this.cursorPosition
    this.updateCalcLength()
  return

proc newTextInput*(x, y, width, height: cint, backgroundColor: array[4, int] = [255, 255, 255, 255], 
    text: string, foregroundColor: array[4, int] = [0, 0, 0, 255],
    font: FontPtr, fontSize: cint): TextInput =
  var tInput: Label =
    uiGen Label:
      x x
      y y
      text text
      foregroundColor foregroundColor
      font font
      fontSize fontSize
  var obj: TextInput = 
    uiCon TextInput:
      backgroundColor backgroundColor
      textField tInput
      render renderTextInput
      onLeftClick defaultOnLeftClick
      onKeyDown keyDown
      cursorPosition len(text)
      multiLine false
      characterLimit 20
  var w, h: cint = 0
  for chr in text:
    discard ttf.sizeText(obj.textField.font, cstring($chr), addr w, addr h)
    obj.cLength.add w
  obj.calcLength = tInput.width
  return obj