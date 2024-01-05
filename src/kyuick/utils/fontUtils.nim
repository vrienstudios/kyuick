import sdl2/ttf
import std/[os, strutils]

type FontTracker* = array[10, tuple[name: string, font: FontPtr, size: cint]]

proc getFontEx*(this: var FontTracker, name: string, size: cint): int8 =
  var index: int8 = 0
  while index < len(this):
    let currentTrack = this[index]
    inc index
    if currentTrack.font == nil: continue
    if currentTrack.size == size and currentTrack.name == name:
      echo "Got font ($1) | ($2) | ($3)pt" % [$index, $currentTrack.name, $size]
      return index
  # Look in local directory for fonts of same name.
  index = 0
  while index < len(this):
    let currentTrack = this[index]
    if currentTrack.font == nil:
      # Loop through *.ttf files in current directory
      for file in walkFiles("./*.ttf"):
        if file.split('/')[^1] == name:
          this[index] = (name, openFont(file, size), size)
          echo "Loaded font ($1) | ($2) | ($3)pt" % [$index, $file, $size]
      return index
    echo "Fonts Full"
    return -1
  echo "Font Not Loaded"
proc getFont*(this: var FontTracker, name: string, size: cint): FontPtr =
    return this[getFontEx(this, name, size)].font