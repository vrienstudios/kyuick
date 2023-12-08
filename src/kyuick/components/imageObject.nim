import sdl2
import sdl2/image

import kyuickObject
import std/math
import os
type
  imageObject* = ref object of kyuickObject
    imagePath: string
    imageloaded: bool
    frameBuffer*: Rect

proc renderImage*(renderer: RendererPtr, obj: kyuickObject) =
  var this: imageObject = imageObject(obj)
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

proc newImageObject*(x, y, width, height: cint, dirOrSheet: string): imageObject =
  return imageObject(x: x, y: y, width: width, height: height, imagePath: dirOrSheet,
    render: renderImage)