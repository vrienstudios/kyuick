# Standard lib
import system

# SDL
import sdl2
import sdl2/ttf

# kyuick objects.
import kyuickObject

# A label object for displaying text at a line of text at a x,y coordinate.
type Label* = ref object of kyuickObject
  text*: string
  color*: array[4, int]
  font*: FontPtr
  fontSize*: cint

proc renderLabel*(renderer: RendererPtr, obj: kyuickObject) =
  let
    label: Label = (Label)obj
    surface = ttf.renderTextSolid(label.font, label.text, color(label.color[0],
      label.color[1], label.color[2], label.color[3]))
    texture = renderer.createTextureFromSurface(surface)
  surface.freeSurface()
  defer: texture.destroy()
  var r = rect(label.x, label.y, label.width, label.height)
  renderer.copy texture, nil, addr r

proc newLabel*(x, y: cint, text: string, color: array[4, int], font: FontPtr, fontSize: cint): Label =
  return Label(x: x, y: y, width: (cint)(len(text) * fontSize),
    height: fontSize, text: text, color: color, font: font, render: renderLabel, fontSize: fontSize)