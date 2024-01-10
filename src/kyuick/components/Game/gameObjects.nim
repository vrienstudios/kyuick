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
    # In months
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
  Point2D* = object
    x, y: int8
  Province* = object
    id*: int16
    ownerID*: int16
    color*: array[4, cint]
    cultureID*, religionID*, tradegoodID*: int16
    isHRE*: bool
    # Nations this province is cored by
    cores*: array[4, CoreObject]
    # Claims on this province
    claims*: array[10, ClaimObject]
    population*: PopulationObject
    # Province vector directions to determine shape.
    vectors*: array[100, Point2D]
    neighbors*: array[10, int16]
  Nation* = object
    id, capitalID: int16
    cultureID, religionID: int8
    color: array[4, int]
  Map* = object
    # Map name is the name of the map. All components must be labeled.
    # E.g (mymap_color.png, mymap_data.yml, mymap_localization.yml)
    mapName: string
    # Max of 10,000 provinces (incl. sea zones)
    # Capped for performance reasons.
    provinces: array[10000, Province]
    nations: array[1000, Nation]
    religions: array[100, ReligionObject]
    cultures: array[100, CultureObject]
    tradeGoods: array[500, TradeObject]
    # Objects created in code.
    # 0 reserved.
    governmentTypes: array[32766, GovernmentObject]
    technologies: array[32766, TechnologyObject]
    buildingObject: array[32766, BuildingObject]
    # Hard-coded.
    wargoalTypes: array[5, WarGoalObject]
# Load initial province data (id, color, name, etc)
proc createMap(mapN: string): Map =
  return Map()