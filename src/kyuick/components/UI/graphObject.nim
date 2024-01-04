# Standard lib
import system, math

# SDL
import sdl2, sdl2/ttf

# kyuick objects.
import ../kyuickObject, textAlign, label

type Graph* = ref object of KyuickObject
  textLabel*: Label
  # How much space between inner and outer borders;
  paddingAlongX*: cint
  # If Y is below 10, no text will appear, even if it's set
  paddingAlongY*: cint
  textAlign*: textAlignment
  dataPoints: seq[float]
  savedLines: seq[(cint, cint, cint, cint)]
  graphBounds: Rect

proc renderGraph(renderer: RendererPtr, obj: KyuickObject) =
  var graph: Graph = Graph obj
  renderer.setDrawColor(color(graph.foregroundColor[0], graph.foregroundColor[1],
        graph.foregroundColor[2], graph.foregroundColor[3]))
  if graph.renderSaved:
    for line in graph.savedLines:
      renderer.drawLine(line[0], line[1], line[2], line[3])
    return
  var highestPoint: float = 0
  var idx: int = 0
  # Grab highest point to compare everything else to it
  block pointCheckLoop:
    var currPoint: float = 0
    while idx < len(graph.dataPoints):
      currPoint = graph.dataPoints[idx]
      if currPoint < 0: currPoint = currPoint * -1
      if currPoint > highestPoint: highestPoint = currPoint
      inc idx
    idx = 1
  # high = 1 ; low = -1 ; scaled based on width/height
  let 
    widthDelta: float = floor(graph.graphBounds.w / (len(graph.dataPoints) - 1))
    midPoint: float = float(graph.graphBounds.y) + graph.graphBounds.h / 2
    heightDelta: float = float(graph.graphBounds.h) / 2
  while idx < len(graph.dataPoints):
    let 
      delta: float = 
        if graph.dataPoints[idx - 1] == 0: 0
        else: (graph.dataPoints[idx - 1] / highestPoint)
      delta2: float = 
        if graph.dataPoints[idx] == 0: 0
        else: (graph.dataPoints[idx] / highestPoint)
      x1: cint = graph.graphBounds.x + cint widthDelta * float idx - 1
      y1: cint = cint(midPoint) - cint(delta * heightDelta)
      x2: cint = graph.graphBounds.x + cint widthDelta * float (idx)
      y2: cint = cint(midPoint) - cint(delta2 * heightDelta)
    renderer.drawLine(x1, y1, x2, y2)
    graph.savedLines.add (x1, y1, x2, y2)
    inc idx

proc renderGraphWithText(renderer: RendererPtr, obj: KyuickObject) =
  var this: Graph = Graph obj
  # Centered by default for now.
  this.textLabel.x = this.x + cint(this.width / 2 - this.textLabel.width / 2)
  let
    thisX: cint = this.x + this.paddingAlongX
    thisY: cint = this.y + this.paddingAlongY
    thisWidth: cint = this.width - this.paddingAlongX * 2
    thisHeight: cint = this.height - this.paddingAlongY * 2 
  this.graphBounds = rect(thisX, thisY, thisWidth, thisHeight)
  # Render
  drawRect(renderer, this.rect)
  drawRect(renderer, this.graphBounds)
  renderLabel(renderer, this.textLabel)
  renderGraph(renderer, this)
  this.renderSaved = true
  
proc dataPoints*(this: Graph): seq[float] = return this.dataPoints
proc `dataPoints=`*(this: var Graph, data: seq[float]) =
  this.dataPoints = data
  this.renderSaved = false
proc add*(this: var Graph, data: float) =
  this.dataPoints.add data
  this.renderSaved = false
proc len*(this: Graph): int = return len(this.dataPoints)

proc newGraph*(x, y, width, height: cint, dataPoints: seq[float], padX: cint = 0, padY: cint = 0, font: FontPtr = nil, fontSize: cint = 0, text: string = ""): Graph =
  var 
    graph: Graph = 
      Graph(x: x, y: y, width: width, height: height, dataPoints: dataPoints,
        paddingAlongX: padX, paddingAlongY: padY)
    label: Label =
      newLabel(0, y + 5, text, [255, 255, 255, 255], font, fontSize)
  graph.textLabel = label
  graph.rect = rect(x, y, width, height)
  if text == "":
    graph.textLabel.text = text
    graph.render = renderGraph
    return graph
  graph.render = renderGraphWithText
  return graph