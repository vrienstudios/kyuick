import os, system, streams, math
import ../kyuickObject
import ../../utils/rendererUtils
import sdl2, sdl2/image, sdl2/gfx
#import yaml

type
  ModifierObject* = object
    ver: string
    years: string
  UnitType* = object
    name, ver: string
    cultureID, religionID: int16
    #maneuver, off_morale, off_shock, off_fire, def_morale, def_shock, def_fire
    pips: array[7, int8]
  WarGoalObject* = object
    name, ver: string
  GovernmentObject* = object
    id: int16
    name: string
  BuildingObject* = object
    id: int16
    predecessorID: int16
    successorID: int16
    icon: string
    cost: int16
    months: int16
  TechnologyObject* = object
    name, ver: string
    unlockYear: int16
    enables: string
  TradeObject* = object
    color: array[4, cint]
    icon: string
    basePrice: int16
  ReligionObject* = object
    name: string
    id: int8
  CultureObject* = object
    name: string
    id: int8
  PopulationObject* = object
    upper, middle, lower: float
  NativeObject* = object
    amount: float 
    ferocity, hostility: int8
  CoreObject* = object
    corerID: int16
    cored: int16
  ClaimObject* = object
    claimerID: int16
    length: int8
  Point2D* = ref object
    x*, y*: cint
    rgb*: tuple[r, g, b: uint8]
    neighbors*: array[4, tuple[r, g, b, t: uint8]]
  ProvinceData* = object
    id*: int16
    ownerID*: int16
    color*: array[3, uint8]
    provinceHistory*: seq[tuple[year, text: string]]
    cultureID*, religionID*, tradegoodID*: int16
    isHRE*: bool
    cores*: seq[CoreObject]
    claims*: seq[ClaimObject]
    population*: PopulationObject
    vectors*: seq[Point2D]
    neighbors*: seq[int16]
    xOffset*: cint
    yOffset*: cint
  Province* = ref object of KyuickObject
    pdat*: ProvinceData
    lastUpdate: uint32
    point: uint32
    builtGFX: TexturePtr
  Nation* = object
    id, capitalID: int16
    cultureID, religionID: int8
    color: array[4, int]
  Map* = object
    # Map name is the name of the map. All components must be labeled.
    # E.g (mymap_color.png, mymap_data.yml, mymap_localization.yml)
    mapName: string
    # Capped for performance reasons.
    provinces: array[10000, Province]
    nations: array[1000, Nation]
    religions: array[100, ReligionObject]
    cultures: array[100, CultureObject]
    tradeGoods: array[500, TradeObject]
    governmentTypes: array[32766, GovernmentObject]
    technologies: array[32766, TechnologyObject]
    buildingObject: array[32766, BuildingObject]
    # Hard-coded.
    wargoalTypes: array[5, WarGoalObject]
#  echo "WHY | $1 $2 $3 | $4 $5 $6" % [$r, $g, $b, $pixel.r, $pixel.g, $pixel.b] 
iterator pointNeighbors(points: seq[Point2D], map: SurfacePtr): array[4, tuple[r, g, b, t: uint8]] =
  var idx: int = 0
  while idx < len(points):
    yield map.getColorDirections(points[idx].x, points[idx].y)
    inc idx
proc buildExampleProvinces*(num: int = 16): seq[ProvinceData] =
  var x: int = 1
  var provinces: seq[ProvinceData] = @[]
  while x < num:
    provinces.add ProvinceData(id: int16(x), ownerID: -1, color: [uint8(100 + x + 10), uint8(100 + x + 4), uint8(100 + x + 2)])
    inc x
  return provinces
proc isIn(list: seq[Point2D], a, b: int): bool =
    for i in list:
        if i.x == a and i.y == b:
            return true
proc seekTrace(orderedBorders: var seq[Point2D], start, current: var Point2D, lastUpd, edTrack: var int): bool =
  if start.x + 1 == current.x and start.y == current.y and (not orderedBorders.isIn(start.x + 1, start.y)):
    orderedBorders.add current
    start = current
    lastUpd = orderedBorders.len
    edTrack = 0
    return true
  if start.x == current.x and start.y + 1 == current.y and (not orderedBorders.isIn(start.x, start.y + 1)):
    orderedBorders.add current
    start = current
    lastUpd = orderedBorders.len
    return true
  if start.x == current.x and start.y - 1 == current.y and (not orderedBorders.isIn(start.x, start.y - 1)):
    orderedBorders.add current
    start = current
    lastUpd = orderedBorders.len
    edTrack = 0
    return true
  if start.x - 1 == current.x and start.y == current.y and (not orderedBorders.isIn(start.x - 1, start.y)):
    orderedBorders.add current
    start = current
    lastUpd = orderedBorders.len
    edTrack = 0
    return true
  # Diagnols
  if start.x + 1 == current.x and start.y + 1 == current.y and (not orderedBorders.isIn(start.x + 1, start.y + 1)):
    orderedBorders.add current
    start = current
    lastUpd = orderedBorders.len
    edTrack = 0
    return true
  if start.x - 1 == current.x and start.y + 1 == current.y and (not orderedBorders.isIn(start.x - 1, start.y + 1)):
    orderedBorders.add current
    start = current
    lastUpd = orderedBorders.len
    edTrack = 0
    return true
  if start.x + 1 == current.x and start.y - 1 == current.y and (not orderedBorders.isIn(start.x + 1, start.y - 1)):
    orderedBorders.add current
    start = current
    lastUpd = orderedBorders.len
    edTrack = 0
    return true
  if start.x - 1 == current.x and start.y - 1 == current.y and (not orderedBorders.isIn(start.x - 1, start.y - 1)):
    orderedBorders.add current
    start = current
    lastUpd = orderedBorders.len
    edTrack = 0
    return true
  return false
proc orderProvinceBorders*(province: ProvinceData): seq[Point2D] =
  var
    idx: cint = 0
    ydx: cint = 0
    idy: cint = 0
    path: seq[Point2D] = @[]
    orderedVectors: seq[Point2D] = province.vectors
    orderedBorders: seq[Point2D] = @[]
  if orderedVectors.len == 0:
    echo "NO GEOMETRY TO TRACE"
    return orderedBorders
  orderedBorders.add orderedVectors[0]
  var lastUpd: int = len(orderedBorders)
  var edTrack: int = 0
  var dTrack: int = 0
  while idx < len(orderedVectors):
    var start = orderedBorders[^1]
    while idy < orderedVectors.len:
      if len(orderedBorders) == len(orderedVectors):
        echo "length: " & $len(orderedBorders)
        return orderedBorders
      var current = orderedVectors[idy]
      block jmp:
        inc idy
        while seekTrace(orderedBorders, start, current, lastUpd, edTrack):
          edTrack = 0
          dTrack = 0
          continue
        if lastUpd != orderedBorders.len and edTrack > 10 and idy == orderedVectors.len - 1:
          if dTrack >= orderedBorders.len:
            echo "BAD GEOMETRY"
            return orderedBorders
          inc dTrack
          start = orderedBorders[^dTrack]
          idy = 0
          break jmp
    if idx mod 10 == 0:
      if lastUpd != orderedBorders.len:
        inc edTrack
        var u = orderedBorders[^1]
        var d = orderedBorders[^2]
        orderedBorders[^1] = d
        orderedBorders[^2] = u
    inc lastUpd
    inc idx
    idy = 0
  return orderedBorders
proc cloneProvinceFull*(xd, yd, xMax, yMax: cint, data: ProvinceData, map: SurfacePtr): seq[Point2D] =
  var 
    x: cint = xd - xMax 
    y: cint = xd - yMax
  if x < 0: x = 0
  if y < 0: y = 0
  var 
    xUpper: cint = xd + xMax
    yUpper: cint = yd + yMax
  var mapData: ptr Surface = (ptr Surface)(map)
  if xUpper > mapData.w: xUpper = mapData.w
  if yUpper > mapData.h: yUpper = mapData.h
  var points: seq[Point2D] = @[]
  while y < yUpper:
    while x < xUpper:
      let cPixel = map.getColorAtPoint(x, y)
      if cPixel == data.color:
        points.add Point2D(x: x, y: y)
      inc x
    x = 0
    inc y
  return points
proc setPointsNeighbors(points: seq[Point2D], map: SurfacePtr) =
  for p in points:
    p.neighbors = map.getColorDirections(p.x, p.y)
proc cloneFullBorder*(xd, yd, xDeltaMax, yDeltaMax: cint, data: ProvinceData, map: SurfacePtr) : seq[Point2D] =
  var knownPoints = cloneProvinceFull(xd, yd, xDeltaMax, yDeltaMax, data, map)
  var borderPoints: seq[Point2D] = @[]
  var idx: int = 0
  for neighbor in pointNeighbors(knownPoints, map):
    if not isUniform(neighbor):
      borderPoints.add(knownPoints[idx])
    inc idx
  return borderPoints
proc getProvinceVectorsFromMap*(color: array[3, uint8], surfaceX: SurfacePtr): seq[Point2D] =
  #echo "getting points for ($1, $2, $3)" % [$color[0], $color[1], $color[2]]
  var x, y: cint
  let 
    r = color[0]
    g = color[1]
    b = color[2]
  var points: seq[Point2D] = @[]
  let surface: ptr Surface = (ptr Surface)(surfaceX)
  while x < surface.w:
    while y < surface.h:
      let cPixel = surfaceX.getColorAtPoint(x, y)
      if isNotEqualSingle(cPixel, color):
        inc y
        continue
      var flg: bool = false
      for pixel in surfaceX.getColorDirections(x, y):
        if isNotEqualSingle(pixel, color):
          points.add Point2D(x: x, y: y)
          break
        #if x == 208 and y == 118:
        #  echo "WHY | $1 $2 $3 | $4 $5 $6" % [$r, $g, $b, $pixel.r, $pixel.g, $pixel.b] 
      inc y
    y = 0
    inc x
  #echo len(points)
  return points
proc generateProvincesFromColorMap*(colorMap: SurfacePtr): seq[ProvinceData] =
  var x, y, dI: cint
  var surface: ptr Surface = (ptr Surface)(colorMap)
  var newProvinces: seq[ProvinceData] = @[]
  while y < surface.h:
    while x < surface.w:
      block pCheck:
        let pixel = colorMap.getColorAtPoint(x, y)
        for data in newProvinces:
          if data.color[0] == pixel.r and data.color[1] == pixel.g and data.color[2] == pixel.b:
            break pCheck
        echo "built $1($2)|$3" % [$newProvinces.len, "-1", $pixel]
        var nProv = ProvinceData(id: int16(newProvinces.len), ownerID: -1, color: [pixel.r, pixel.g, pixel.b])
        nProv.vectors = cloneFullBorder(x, y, 1000, 6400, nProv, colorMap)
        nProv.vectors = orderProvinceBorders(nProv)
        newProvinces.add nProv
        if newProvinces.len > 21: return newProvinces
      inc x
    x = 0
    inc y
  return newProvinces
proc createMap(mapN: string) =
  var provinceColorMap: SurfacePtr = load(mapN & ".png")
  let provinceData: string = readFile("./" & mapN & "_PDAT" & ".yaml")
# SDL_GFX Lib dependent
proc renderProvince*(renderer: RendererPtr, obj: KyuickObject) =
  let this: Province = Province(obj)
  var xS, yS: seq[int16]
  var ls: cint = 0
  while ls < this.pdat.vectors.len:
    let point = this.pdat.vectors[ls]
    xS.add int16(this.pdat.xOffset + point.x)
    yS.add int16(this.pdat.yOffset + point.y)
    inc ls
  renderer.polygonRGBA(cast[ptr int16](addr xS[0]), cast[ptr int16](addr yS[0]), ls, this.pdat.color[0], this.pdat.color[1], this.pdat.color[2], 255)
  renderer.filledpolygonRGBA(cast[ptr int16](addr xS[0]), cast[ptr int16](addr yS[0]), ls, this.pdat.color[0], this.pdat.color[1], this.pdat.color[2], 255)
  return
proc renderProvinceT*(renderer: RendererPtr, obj: KyuickObject) =
  let this: Province = Province(obj)
  var xS, yS: seq[int16]
  var ls: cint = 0
  while ls < this.pdat.vectors.len:
    let point = this.pdat.vectors[ls]
    xS.add int16(this.pdat.xOffset + point.x)
    yS.add int16(this.pdat.yOffset + point.y)
    inc ls
  var surface = load("image_proxy.jpg")
  renderer.texturedPolygon(cast[ptr int16](addr xS[0]), cast[ptr int16](addr yS[0]), ls, surface, 0, 0)
  return
proc renderProvinceTEx*(renderer: RendererPtr, obj: KyuickObject) =
  let this: Province = Province(obj)
  renderer.setDrawColor(this.pdat.color)
  var surface = load("image_proxy.jpg")
  var idx: int = 0
  for point in this.pdat.vectors:
    let rgb = surface.getColorAtPoint(point.x, point.y)
    renderer.setDrawColor(rgb.r, rgb.g, rgb.g)
    renderer.drawPoint(this.pdat.xOffset + point.x, this.pdat.yOffset + point.y)
  #var surface = load("image_proxy.jpg")
  #renderer.texturedPolygon(cast[ptr int16](addr xS[0]), cast[ptr int16](addr yS[0]), ls, surface, 0, 0)
  return
proc renderProvinceEx*(renderer: RendererPtr, obj: KyuickObject) =
  let this: Province = Province(obj)
  renderer.setDrawColor(this.pdat.color)
  var idx: int = 0
  for point in this.pdat.vectors:
    renderer.drawPoint(this.pdat.xOffset + point.x, this.pdat.yOffset + point.y)
    #var xPoints: seq[Point2D] = @[]
    #for rPoint in this.pdat.vectors:
    #  block ch:
    #    if rPoint.y != point.y: continue
    #    if rPoint.x < point.x: continue
        # Quick hack that improves performance slightly.
    #    for p in xPoints:
    #      if rPoint != p and point == p:
    #        continue
    #      break ch
    #    xPoints.add rPoint
    #    xPoints.add point
    #    renderer.drawLine(rPoint.x, rPoint.y, point.x, point.y)
  return
proc renderSlow*(renderer: RendererPtr, obj: KyuickObject) =
  let this: Province = Province(obj)
  renderer.setDrawColor(this.pdat.color)
  var 
    idx: int = 0
    current = getTicks()
    fU = floor(((current - this.lastUpdate).float/1000.0f).float / (1.0f/5.0f))
  if fU > 0:
    inc this.point
  while idx < int(this.point) and idx < this.pdat.vectors.len:
    let point = this.pdat.vectors[idx]
    renderer.drawPoint(this.pdat.xOffset + point.x, this.pdat.yOffset + point.y)
    inc idx
proc dumpProvinceDataToFile*(provinces: seq[ProvinceData], fileName: string) =
  echo "Beginning YAML Dump!"
  var fStream = newFileStream(fileName & ".yaml", fmWrite)
  #Dumper().dump(provinces, fStream)
  fStream.close()
proc genProvincesAndDumpData*(mapN: string) =
  var provinceColorMap: SurfacePtr = load(mapN & ".png")
  var provinces: seq[ProvinceData] = generateProvincesFromColorMap(provinceColorMap)
  dumpProvinceDataToFile(provinces, "US_")
proc getRendererPolys*(pData: seq[ProvinceData]): seq[Province] =
  var provinces: seq[Province] = @[]
  for pDat in pData:
    provinces.add Province(pdat: pDat, render: renderSlow)
  return provinces