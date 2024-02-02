import os, system, streams
import ../kyuickObject
import ../../utils/rendererUtils
import sdl2, sdl2/image, sdl2/gfx
import yaml

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
  ProvinceData* = object
    id*: int16
    ownerID*: int16
    color*: array[3, uint8]
    cultureID*, religionID*, tradegoodID*: int16
    isHRE*: bool
    cores*: seq[CoreObject]
    claims*: seq[ClaimObject]
    population*: PopulationObject
    vectors*: seq[Point2D]
    pointPairs*: seq[tuple[p1, p2: Point2D]]
    neighbors*: seq[int16]
  Province* = ref object of KyuickObject
    pdat*: ProvinceData
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
proc buildExampleProvinces*(num: int = 16): seq[ProvinceData] =
  var x: int = 1
  var provinces: seq[ProvinceData] = @[]
  while x < num:
    provinces.add ProvinceData(id: int16(x), ownerID: -1, color: [uint8(100 + x + 10), uint8(100 + x + 4), uint8(100 + x + 2)])
    inc x
  return provinces
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
      if cPixel.r != r or cPixel.g != g or cPixel.b != b:
        inc y
        #if x == 208 and y == 118:
        #  echo "WHY | $1 $2 $3 | $4" % [$r, $g, $b, $cPixel.r] 
        continue
      var flg: bool = false
      for pixel in surfaceX.getColorDirections(x, y):
        if pixel.r != r or pixel.g != g or pixel.b != b:
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
        var nProv = ProvinceData(id: int16(newProvinces.len), ownerID: -1, color: [pixel.r, pixel.g, pixel.b])
        nProv.vectors = getProvinceVectorsFromMap(nProv.color, colorMap)
        newProvinces.add nProv
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
    xS.add int16(point.x)
    yS.add int16(point.y)
    inc ls
  renderer.polygonRGBA(cast[ptr int16](addr xS[0]), cast[ptr int16](addr yS[0]), ls, this.pdat.color[0], this.pdat.color[1], this.pdat.color[2], 255)
  return
# Fallback
proc renderProvinceEx*(renderer: RendererPtr, obj: KyuickObject) =
  let this: Province = Province(obj)
  renderer.setDrawColor(this.pdat.color)
  var idx: int = 0
  for point in this.pdat.vectors:
    renderer.drawPoint(point.x, point.y)
    var xPoints: seq[Point2D] = @[]
    for rPoint in this.pdat.vectors:
      block ch:
        if rPoint.y != point.y: continue
        if rPoint.x < point.x: continue
        # Quick hack that improves performance slightly.
        for p in xPoints:
          if rPoint != p and point == p:
            continue
          break ch
        xPoints.add rPoint
        xPoints.add point
        renderer.drawLine(rPoint.x, rPoint.y, point.x, point.y)
  return
proc dumpProvinceDataToFile*(provinces: seq[ProvinceData], fileName: string) =
  echo "Beginning YAML Dump!"
  var fStream = newFileStream(fileName & ".yaml", fmWrite)
  Dumper().dump(provinces, fStream)
  fStream.close()
proc genProvincesAndDumpData*(mapN: string) =
  var provinceColorMap: SurfacePtr = load(mapN & ".png")
  var provinces: seq[ProvinceData] = generateProvincesFromColorMap(provinceColorMap)
  #dumpProvinceDataToFile(provinces, "US_")
proc getRendererPolys*(pData: seq[ProvinceData]): seq[Province] =
  var provinces: seq[Province] = @[]
  for pDat in pData:
    provinces.add Province(pdat: pDat, render: renderProvince)
  return provinces