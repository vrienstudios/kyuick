import sdl2

type
  KyuickObject* = ref object of RootObj
    x*, y*: cint
    width*, height*: cint
    hoverStatus: bool
    autoFocusable*: bool
    focusChange*: bool
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
    onHoverStatusChange*: proc(obj: KyuickObject, status: bool)
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
proc hover*(obj: KyuickObject, b: bool) =
  obj.onHoverStatusChange(obj, b)
proc hoverStatus*(this: KyuickObject): bool = return this.hoverStatus
proc `hoverStatus=`*(this: KyuickObject, b: bool) =
  if b == this.hoverStatus:
    return
  this.renderSaved = false
  this.texture.destroy()
  this.hoverStatus = b
  if this.onHoverStatusChange != nil:
    this.onHoverStatusChange(this, b)
proc defaultRender*(renderer: RendererPtr, this: KyuickObject) =
  renderer.setDrawColor(color(this.backgroundColor[0], this.backgroundColor[1],
        this.backgroundColor[2], this.backgroundColor[3]))
  renderer.fillRect(this.rect)
proc newKyuickObject*(x, y, width, height: cint, background: array[4, int]): KyuickObject =
  var obj: KyuickObject = KyuickObject(x: x, y: y, width: width, height: height, backgroundColor: background)
  obj.rect = rect(x, y, width, height)
  obj.render = defaultRender
  return obj