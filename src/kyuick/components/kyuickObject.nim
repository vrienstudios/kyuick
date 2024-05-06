import sdl2
import ../utils/rendererUtils

type
  KyuickObject* = ref object of RootObj
    x*, y*: cint
    width*, height*: cint
    hoverStatus: bool
    canClick*: bool
    canHover*: bool
    autoFocusable*: bool = true
    focused*: bool
    # Fields to save render information to memory for performance.
    backgroundColor*: array[4, int]
    foregroundColor*: array[4, int]
    rect*: Rect
    texture*: TexturePtr
    renderSaved*: bool
    # Render-proc; called every frame.
    render*: proc(renderer: RendererPtr, obj: KyuickObject)
    # A function to render hover-specific content to the control, called every frame when hoverStatus = true
    hoverRender*: proc(renderer: RendererPtr, obj: KyuickObject)
    # Event-related procs.
    onLeftClick*: proc(obj: KyuickObject, mouseEvent: MouseButtonEventPtr)
    onKeyDown*: proc(obj: KyuickObject, scancode: string)
    # When status is true, the mouse is hovering, when false, the mouse has stopped hovering.
    onHoverStatusChange*: proc(obj: KyuickObject, e: tuple[b: bool, mouse: MouseMotionEventPtr])
    parent*: KyuickObject
    passthrough*: bool
proc render*(renderer: RendererPtr, obj: KyuickObject) =
  if obj.hoverStatus and obj.hoverRender != nil:
    obj.hoverRender(renderer, obj)
    return
  obj.render(renderer, obj)
proc leftClick*(obj: KyuickObject, mouseEvent: MouseButtonEventPtr) =
  if obj.onLeftClick == nil:
    return
  obj.onLeftClick(obj, mouseEvent)
# Manually trigger the hover function.
proc hover*(obj: KyuickObject, e: tuple[b: bool, mouse: MouseMotionEventPtr]) =
  obj.onHoverStatusChange(obj, e)
proc hoverStatus*(this: KyuickObject): bool = return this.hoverStatus
proc `hoverStatus=`*(this: KyuickObject, e: tuple[b: bool, mouse: MouseMotionEventPtr]) =
  if e[0] == this.hoverStatus and this.passthrough == false or this.canHover == false:
    return
  this.renderSaved = false
  this.texture.destroy()
  this.hoverStatus = e[0]
  this.focused = e[0]
  if this.onHoverStatusChange != nil:
    this.onHoverStatusChange(this, e)
proc defaultRender*(renderer: RendererPtr, this: KyuickObject) =
  renderer.setDrawColor(this.backgroundColor)
  renderer.fillRect(this.rect)
proc newKyuickObject*(x: cint = 0, y: cint = 0, width: cint = 0, 
    height: cint = 0, background: array[4, int]): KyuickObject =
  var obj: KyuickObject = KyuickObject(x: x, y: y, width: width, height: height, 
    backgroundColor: background)
  obj.rect = rect(x, y, width, height)
  obj.render = defaultRender
  return obj
proc seekEl*(els: seq[KyuickObject], x, y: cint): KyuickObject =
  for obj in els:
    if not (x >= obj.x and x <= obj.x + obj.width): continue
    if not (y >= obj.y and y <= obj.y + obj.height): continue
    return obj