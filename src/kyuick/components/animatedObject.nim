import sdl2

import kyuickObject
type
  animatedObject* = ref object of RootObj
    animSheetPath: string
    fps*: cint

# TODO: Render a selected
proc renderAnimated*(renderer: RendererPtr, obj: kyuickObject) =
  return