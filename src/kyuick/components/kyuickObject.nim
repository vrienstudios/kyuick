import sdl2
import ../utils/utils
import json
export macroUtils
type
  KyuickObject* = ref object of RootObj
    typ*: string
    id*: string
    parent*: KyuickObject
    children*: seq[KyuickObject]
    # Dimensions
    x*, y*: cint
    width*, height*: cint
    noRen*: bool
    # optionals
    hoverStatus: bool
    enabled*: bool = true
    passthrough*: bool
    autoFocusable*: bool
    focused*: bool
    renderSaved*: bool
    #RenderInfo
    backgroundColor*: array[4, int]
    foregroundColor*: array[4, int]
    rect*: Rect
    texture*: TexturePtr
    # RENDER
    render*: proc(renderer: RendererPtr, obj: KyuickObject)
    hoverRender*: proc(renderer: RendererPtr, obj: KyuickObject)
    # EVENTS
    onLeftClick*: proc(obj: KyuickObject, mouseEvent: MouseButtonEventPtr)
    onKeyDown*: proc(obj: KyuickObject, scancode: string)
    onHoverStatusChange*: proc(obj: KyuickObject, e: tuple[b: bool, mouse: MouseMotionEventPtr])
proc `%`*(r: Rect): JsonNode =
  result = %[r.x, r.y, r.w, r.h]
proc `%`*(r: TexturePtr): JsonNode =
  result = JsonNode(kind: JBool, bval: r != nil)
proc `%`*(r: proc(renderer: RendererPtr, obj: KyuickObject)): JsonNode =
  result = JsonNode(kind: JBool, bval: r != nil)
#proc `%`*(r: proc(renderer: RendererPtr, obj: KyuickObject)): JsonNode =
#  result = %nil
proc `%`*(r: proc(obj: KyuickObject, mouseEvent: MouseButtonEventPtr)): JsonNode =
  result = JsonNode(kind: JBool, bval: r != nil)
proc `%`*(r: proc(obj: KyuickObject, scancode: string)): JsonNode =
  result = JsonNode(kind: JBool, bval: r != nil)
proc `%`*(r: proc(obj: KyuickObject, e: tuple[b: bool, mouse: MouseMotionEventPtr])): JsonNode =
  result = JsonNode(kind: JBool, bval: r != nil)
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
  if this == nil: return
  if e[0] == this.hoverStatus and this.passthrough == false or this.enabled == false:
    return
  #this.renderSaved = false
  #this.texture.destroy()
  this.hoverStatus = e[0]
  this.focused = e[0]
  if this.onHoverStatusChange != nil:
    this.onHoverStatusChange(this, e)
proc defaultRender*(renderer: RendererPtr, this: KyuickObject) =
  if this.renderSaved == false:
    this.renderSaved = true
    return
  var idx: int = 0
  while idx < this.children.len:
    var child = this.children[idx]
    if child.render == nil: 
      inc idx
      continue
    child.render(renderer, child)
    renderer.setDrawColor(this.backgroundColor)
    inc idx
proc newKyuickObject*(x: cint = 0, y: cint = 0, width: cint = 0, 
    height: cint = 0, backgroundColor: array[4, int] = [0, 0, 0, 255], 
    foregroundColor: array[4, int] = [255, 255, 255, 255]): KyuickObject =
  var obj: KyuickObject =
    uiCon KyuickObject:
      x x
      y y
      width width
      height height
      backgroundColor backgroundColor
      rect rect(x, y, width, height)
      render defaultRender
      autoFocusable true
  return obj

proc getClickable*(this: KyuickObject, x, y: cint): KyuickObject =
  #       if obj == nil or obj.enabled == false: return
  for obj in this.children:
    let condX = (x >= obj.x and x <= obj.x + obj.width)
    if not condX: continue
    let condY = (y >= obj.y and y <= obj.y + obj.height)
    if not condY: continue
    if obj.passthrough:
      var childClickable = getClickable(obj, x, y)
      if childClickable == nil: continue
      return childClickable
    if condX and condY: return obj
  return nil