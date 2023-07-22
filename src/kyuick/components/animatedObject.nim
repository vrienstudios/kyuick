import sdl2
import sdl2/image

import kyuickObject
import std/math
type
  animatedObject* = ref object of kyuickObject
    animSheetPath: string
    frameBuffer*: Rect
    cFrame*: cint
    tFrames*: cint
    fps*: cint
    lastUpdate: uint32

# TODO: Render a selected
proc renderAnimated*(renderer: RendererPtr, obj: kyuickObject) =
  var this: animatedObject = animatedObject(obj)
  if this.renderSaved != true:
    var surface = load(this.animSheetPath)
    this.tFrames = cint(surface.w / this.width)
    this.texture = renderer.createTextureFromSurface(surface)
    this.frameBuffer = rect(this.cFrame, 0, this.width, this.height)
    this.rect = rect(this.x, this.y, this.width, this.height)
    this.renderSaved = true
  let 
    current = getTicks()
    fU = floor(((current - this.lastUpdate).float/1000.0f).float / (1.0f/this.fps.float))
  var tP: Point = point(this.x, this.y)
  if fU > 0:
    this.frameBuffer = rect(this.cFrame, 0, this.width, this.height)
    renderer.copyEx this.texture, addr this.frameBuffer, addr this.rect, cdouble(0), addr tP
    this.cFrame = this.cFrame + this.width
    if this.cFrame mod (this.width * this.tFrames) == 0:
      this.cFrame = 0
    this.lastUpdate = current
    return
  renderer.copyEx this.texture, addr this.frameBuffer, addr this.rect, cdouble(0), addr tP

proc newAnimatedObject*(x, y, width, height: cint, dirOrSheet: string, fps: cint = 20): animatedObject =
  return animatedObject(x: x, y: y, width: width, height: height, animSheetPath: dirOrSheet,
    render: renderAnimated, fps: fps)