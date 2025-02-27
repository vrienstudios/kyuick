# SDL2
import sdl2
import sdl2/image
import sdl2/ttf

import os, system, math

import ../components/UI/all
import ../components/kyuickObject
import ../components/Grids/horizontalGrid
import ../components/Grids/verticalGrid

import ./utils
import ./macroUtils
import ./fontUtils

import zippy/ziparchives
import json, streams
import std/marshal
#[
 - Into YAML
 --- Top Element
 ---  Members
 ---  Children
 ---   -- REPEAT
 - Use uiCon "Name"
 -- to reconstruct the elements

 -- For UI elements onClick overrides and such, create and include new file (uiProcs.nim)
 --   to be written
]#

type exportable_KO_base = object
  typ: string
  id: string
  pID: string
  cIDs: seq[string]
  x, y: cint
  w, h: cint
  noRen: bool
  enabled: bool
  passthrough: bool
  autoFocusable: bool
  focused: bool
  renderSaved: bool
  backgroundColor: array[4, int]
  foregroundColor: array[4, int]
  rect: array[4, cint]
  texture: string
  render: bool
  hoverRender: bool
  onLeftClick: bool
  onKeyDown: bool
  onHoverStatusChange: bool
# Object type does matter!!!!!!!
proc saveUIElement*(obj: KyuickObject, name: string) =
  var fs = newFileStream("./assets/ui/" & name, fmWrite)
  echo $$(obj)
  #var lks = 
  #  uiCon exportable_KO_base:
  #    typ obj.typ
  #    id obj.id
  #    x obj.x
  #    y obj.y
  #    w obj.width
  #    h obj.height
  #    # SHOULD be in formate id_render etc etc
  #    render if obj.render == nil: false else: true
  #    hoverRender if obj.hoverRender == nil: false else: true
  #    onLeftClick if obj.onLeftClick == nil: false else: true
  #    onKeyDown if obj.onKeyDown == nil: false else: true
  #    onHoverStatusChange if obj.onHoverStatusChange == nil: false else: true
  return

proc getUIElement*(fileName: string): KyuickObject =
  return nil