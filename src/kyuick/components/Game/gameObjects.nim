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
    cost: int16
    # In months
    months: int16
  TechnologyObject* = object
    name, ver: string
    unlockYear: int16
    enables: string
  TradeObject* = object
    color: array[4, int]
    icon: string
    basePrice: int16
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
  Province* = object
    id: int16
    ownderID: int16
    cultureID, religionID, tradegoodID: int16
    isHRE: bool
    # Nations this province is cored by
    cores: array[4, CoreObject]
    # Claims on this province
    claims: array[10, ClaimObject]
    population: PopulationObject
  Nation* = object
    id, capitalID: int16
    cultureID, religionID: int8
    color: array[4, int]