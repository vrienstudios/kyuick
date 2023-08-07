import sdl2
import sdl2/image

import kyuickObject
import std/math
type
  imageObject* = ref object of kyuickObject
    imagePath: string
    imageloaded: bool
    frameBuffer*: Rect

proc renderImage*(renderer: RendererPtr, obj: kyuickObject) =
  var this: imageObject = imageObject(obj)
  if this.imageloaded == false:
    var surface = load(this.imagePath)
    this.texture = renderer.createTextureFromSurface(surface)
    surface.freeSurface()
    this.imageloaded = true
  if this.renderSaved != true:
    this.rect = rect(this.x, this.y, this.width, this.height)
    this.renderSaved = true
  renderer.copy this.texture, addr this.frameBuffer, addr this.rect

proc newImageObject*(x, y, width, height: cint, dirOrSheet: string): imageObject =
  return imageObject(x: x, y: y, width: width, height: height, imagePath: dirOrSheet,
    render: renderImage)