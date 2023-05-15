import components/kyuickObject

# This is useful for grouping UI-elements for ease of use.
type scene* = ref object of RootObj
  # TODO: simplify this to only use one sequence or one proc to add objects.
  elements*: seq[kyuickObject]
  hoverables*: seq[kyuickObject]
  clickables*: seq[kyuickObject]
  # When false, this means that the 'scene' acts as a single Object rather than many, so
  #   it will use its own onClick/onHover callbacks, instead of these events being passed.
  isInteractive*: bool