import sdl2
type
  kyuickObject* = ref object of RootObj
    x*, y*: cint
    width*, height*: cint
    # Render-proc for
    render*: proc(renderer: RendererPtr, obj: kyuickObject)

    # Event-related procs.
    onLeftClick*: proc(obj: kyuickObject)

proc render*(renderer: RendererPtr, obj: kyuickObject) =
  obj.render(renderer, obj)
proc leftClick*(obj: kyuickObject) =
  obj.onLeftClick(obj)