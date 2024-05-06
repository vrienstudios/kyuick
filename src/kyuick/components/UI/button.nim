#SDL
import sdl2
import sdl2/ttf

# kyuick objects
import ../kyuickObject
import textAlign
import label

type Button* = ref object of KyuickObject
  # Text
  btnLabel*: Label
  textAlign: textAlignment


proc renderButton*(renderer: RendererPtr, obj: KyuickObject) =
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

proc newButton*(x, y, w, h: cint, backgroundColor: array[4, int], text: string,
  font: FontPtr, fontSize: cint, foregroundColor: array[4, int], textAlign: textAlignment = textAlignment.left): Button =
  var label = newLabel(x, y, text, foregroundColor, font, fontSize)
  var btn: Button = Button(x: x, y: y, width: w, height: h,
    btnLabel: label, backgroundColor: backgroundColor, render: renderButton, renderSaved: false)
  if textAlign == textAlignment.right:
    label.x = (x + w) - label.width
    return btn
  if textAlign == textAlignment.center:
    label.x = (x + cint(w / 2)) - cint(label.width / 2)
    label.y = (y + cint(h / 2)) - cint(label.height / 2)
  return btn