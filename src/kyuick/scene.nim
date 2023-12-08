import components/kyuickObject

# A grouping of elements, which will sometimes have a custom render proc.
# In the case of the main Scene in the engine, all elements are relative to the main element.
type Scene* = ref object of RootObj
  x, y, width*, height*: cint

  elements*: seq[kyuickObject]
  hoverables*: seq[kyuickObject]
  clickables*: seq[kyuickObject]
  isInteractive*: bool
  renderSaved*: bool
  render*: proc(renderer: RendererPtr, scene: Scene)

# Methods to enumerate elements and shift their x/y values.
method `x=`(this: var Scene, x: cint) =
  return
method `y=`(this: var Scene, y: cint) =
  return