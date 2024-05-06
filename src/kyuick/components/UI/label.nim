# Standard lib
import system

# SDL
import sdl2
import sdl2/ttf

# kyuick objects.
import ../kyuickObject

# A label object for displaying text at a line of text at a x,y coordinate.
type Label* = ref object of KyuickObject
  text: string
  font*: FontPtr
  fontSize*: cint
  trackNum*: ptr float

proc text*(this: Label): string = return this.text
proc `text=`*(this: var Label, text: string) = 
  this.text = text
  var w, h: cint = 0
  discard ttf.sizeText(this.font, text, addr w, addr h)
  this.width = w
  this.height = h
  this.renderSaved = false
proc renderLabel*(renderer: RendererPtr, obj: KyuickObject) =
  var label: Label = (Label)obj
  if label.trackNum != nil: `text=`(label, $repr(label.trackNum))
  if label.renderSaved:
    renderer.copy label.texture, nil, addr label.rect
    return
  let
    surface = ttf.renderTextBlended(label.font, cstring(label.text), color(label.foregroundColor[0],
      label.foregroundColor[1], label.foregroundColor[2], label.foregroundColor[3]))
    texture = renderer.createTextureFromSurface(surface)
  surface.freeSurface()
  label.texture = texture
  var r = rect(label.x, label.y, label.width, label.height)
  label.rect = r
  renderer.copy texture, nil, addr r
  label.renderSaved = true

proc newLabel*(x: cint = 0, y: cint = 0, text: string = "", color: array[4, int] = [0, 0, 0, 255], font: FontPtr = nil, fontSize: cint = 18): Label =
  var w, h: cint = 0
  discard ttf.sizeText(font, text, addr w, addr h)
  return Label(x: x, y: y, width: w,
    height: h, text: text, foregroundColor: color, font: font, render: renderLabel, renderSaved: false, fontSize: fontSize)
proc clone*(label: Label, x, y: cint, text: string): Label =
  return newLabel(x, y, text, label.foregroundColor, label.font, label.fontSize)