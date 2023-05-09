import std/math
import std/strutils

import sdl2
import sdl2/ttf

import kyuickObject, label

type TextInput* = ref object of kyuickObject
  cursorPosition: int
  textField: Label
  multiLine: bool
  characterLimit: int
  cLength: seq[cint]

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
  if this.cursorPosition > len(this.textField.text):
    this.cursorPosition = len(this.textField.text)
  this.renderSaved = false
  var w, h: cint = 0
  discard ttf.sizeText(this.textField.font, $chr, addr w, addr h)
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
  if this.cursorPosition > len(this.textField.text):
    this.cursorPosition = len(this.textField.text)
  this.renderSaved = false
  this.cLength.delete(this.cursorPosition)
  var str: string = this.textField.text
  str.delete(this.cursorPosition - 1..this.cursorPosition - 1)
  this.textField.text = str
  dec this.cursorPosition
proc defaultOnLeftClick*(obj: kyuickObject, mouse: MouseButtonEventPtr) =
  var
    this = (TextInput)obj
    idx = 0
    calcLength = 0
  let relativeX = mouse.x - obj.x
  echo relativeX
  if len(this.cLength) == 0:
    this.cursorPosition = 0
    return
  while calcLength < int(round(float(relativeX))) and idx < this.cLength.len:
    calcLength = calcLength + this.cLength[idx]
    inc idx
  echo idx
  this.cursorPosition = idx
  echo this.cLength
  echo calcLength
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
    discard ttf.sizeText(ti.textField.font, $chr, addr w, addr h)
    ti.cLength.add w
  return ti