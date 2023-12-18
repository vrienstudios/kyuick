# Collection of UI components ordered vertically.

import kyuickObject

type VerticalGrid* = ref object of RootObj
  x*, y*: cint
  width*, height*: cint
  elements*: seq[kyuickObject]

proc add*(this: VerticalGrid, obj: kyuickObject) =
  return