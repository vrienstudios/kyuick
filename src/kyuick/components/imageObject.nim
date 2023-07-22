import sdl2
import sdl2/image

import kyuickObject
import std/math
type
  imageObject* = ref object of kyuickObject
    imagePath: string
    frameBuffer*: Rect

# TODO: Render a selected
proc renderImage*(renderer: RendererPtr, obj: kyuickObject) =
  var this: animatedObject = imageObject(obj)
  if this.renderSaved != true:
    var surface = load(this.imagePath)
    this.tFrames = cint(surface.w / this.width)
    this.texture = renderer.createTextureFromSurface(surface)
    this.frameBuffer = rect(this.cFrame, 0, this.width, this.height)
    this.renderSaved = true
  renderer.copyEx this.texture, addr this.frameBuffer, addr this.rect, cdouble(0), addr tP

proc newImageObject*(x, y, width, height: cint, dirOrSheet: string): imageObject =
  return imageObject(x: x, y: y, width: width, height: height, imagePath: dirOrSheet,
    render: renderImage)