#SDL
import sdl2
import sdl2/ttf

# kyuick objects
import kyuickObject
import label

type Button* = ref object of kyuickObject
  # Text
  btnLabel*: Label

proc renderButton*(renderer: RendererPtr, obj: kyuickObject) =
  let button: Button = (Button)obj
  if button.renderSaved:
    renderer.setDrawColor(color(button.backgroundColor[0], button.backgroundColor[1],
      button.backgroundColor[2], button.backgroundColor[3]))
    renderer.fillRect(obj.rect)
    renderLabel(renderer, button.btnLabel)
    return
  var r = rect(button.x, button.y, button.width, button.height)
  renderer.setDrawColor(color(button.backgroundColor[0], button.backgroundColor[1],
    button.backgroundColor[2], button.backgroundColor[3]))
  renderer.fillRect(r)
  button.rect = r
  renderLabel(renderer, button.btnLabel)
  button.renderSaved = true

proc newButton*(x, y, w, h: cint, bColor: array[4, int], text: string,
  font: FontPtr, fontSize: cint, tColor: array[4, int]): Button =
  var label = newLabel(x, y, text, tColor, font, fontSize)
  var btn: Button = Button(x: x, y: y, width: w, height: h,
    btnLabel: label, backgroundColor: bColor, render: renderButton, renderSaved: false)
  return btn