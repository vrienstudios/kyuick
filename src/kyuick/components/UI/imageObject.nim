import sdl2
import sdl2/image

import ../kyuickObject
import std/math
import os
type
  ImageObject* = ref object of KyuickObject
    imagePath: string
    imageloaded: bool
    frameBuffer*: Rect
proc destroy*(this: ImageObject) =
  this.texture.destroyTexture()
proc renderImage*(renderer: RendererPtr, obj: KyuickObject) =
  var this: ImageObject = ImageObject(obj)
  if this.imageloaded == false:
    if fileExists(this.imagePath):
      echo "LOADED $1" % [this.imagePath]
    else: echo "FILE $1 NOT FOUND" % [this.imagePath]
    var surface = load(cstring(this.imagePath))
    this.texture = renderer.createTextureFromSurface(surface)
    surface.freeSurface()
    this.imageloaded = true
  if this.renderSaved != true:
    this.rect = rect(this.x, this.y, this.width, this.height)
  renderer.copy this.texture, nil, addr this.rect
  return

proc newImageObject*(x, y, width, height: cint, dirOrSheet: string): ImageObject =
  return uiCon ImageObject:
    x x
    y y
    width width
    height height
    imagePath dirOrSheet
    render renderImage