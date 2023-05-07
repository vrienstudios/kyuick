import sdl2

type
  kyuickObject* = ref object of RootObj
    x*, y*: cint
    width*, height*: cint
    hoverStatus: bool
    # Fields to save render information to memory for performance.
    rect*: Rect
    texture*: TexturePtr
    renderSaved*: bool
    # Render-proc; called every frame.
    render*: proc(renderer: RendererPtr, obj: kyuickObject)
    # A function to render hover-specific content to the control, called every frame when hoverStatus = true
    hoverRender*: proc(renderer: RendererPtr, obj: kyuickObject)
    # Event-related procs.
    onLeftClick*: proc(obj: kyuickObject, mouseEvent: MouseButtonEventPtr)
    # When status is true, the mouse is hovering, when false, the mouse has stopped hovering.
    onHoverStatusChange*: proc(obj: kyuickObject, status: bool)
proc render*(renderer: RendererPtr, obj: kyuickObject) =
  if obj.hoverStatus and obj.hoverRender != nil:
    obj.hoverRender(renderer, obj)
    return
  obj.render(renderer, obj)
proc leftClick*(obj: kyuickObject, mouseEvent: MouseButtonEventPtr) =
  if obj.onLeftClick == nil:
    return
  obj.onLeftClick(obj, mouseEvent)
# Manually trigger the hover function.
proc hover*(obj: kyuickObject, b: bool) =
  obj.onHoverStatusChange(obj, b)
proc hoverStatus*(this: kyuickObject): bool = return this.hoverStatus
proc `hoverStatus=`*(this: kyuickObject, b: bool) =
  if b == this.hoverStatus:
    return
  this.renderSaved = false
  this.texture.destroy()
  this.hoverStatus = b
  if this.onHoverStatusChange != nil:
    this.onHoverStatusChange(this, b)
