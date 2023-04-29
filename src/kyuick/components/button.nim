#SDL
import sdl2
import sdl2/ttf

# kyuick objects
import kyuickObject
import label

type Button* = ref object of kyuickObject
  # Text
  btnLabel*: label
  foreColor*: array[4, int]

proc renderButton*(renderer: RendererPtr, obj: kyuickObject) =
  let button: Button = (Button)obj
  surface = ttf.renderTextSolid(button.btnLabel.font, button.btnLabel.text, color(button.btnLabel.color[0],
    button.btnLabel.color[1], button.btnLabel.color[2], button.btnLabel.color[3]))
  texture = renderer.createTextureFromSurface(surface)

  surface.freeSurface()
  defer: texture.destroy()

  var r = rect(cint(button.x), cint(button.y), cint(button.width), cint(button.height))
  renderer.copy texture, nil, addr r
  renderer.setDrawColor(button.foreColor[0], button.foreColor[1], button.foreColor[2], button.foreColor[3])
  renderer.fillRect(r)

proc newButton*(x, y, w, h: cint, bColor: array[4, int], text: string,
  font: FontPtr, fontSize: cint, tColor: array[4, int]) =
  var label = newLabel(x, y, text, tColor, font, fontSize)
