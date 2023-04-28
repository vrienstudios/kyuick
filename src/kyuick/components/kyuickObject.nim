import sdl2
type
  kyuickObject* = ref object of RootObj
    x*, y*: cint
    render*: proc(renderer: RendererPtr, obj: kyuickObject)

proc render*(renderer: RendererPtr, obj: kyuickObject) =
  obj.render(renderer, obj)