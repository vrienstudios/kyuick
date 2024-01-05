# Collection of UI components ordered vertically.

import kyuickObject

type VerticalGrid* = ref object of RootObj
  x*, y*: cint
  width*, height*: cint
  elements*: seq[KyuickObject]

proc add*(this: VerticalGrid, lines: seq[tuple[obj: typedesc[object], width, height: cint]]) =
  for line in lines:
    case typeof(line.obj):
      of typedesc[Button]:
        break
  return
proc newVerticalGrid*(x, y, width, height: cint): VerticalGrid =
  return nil