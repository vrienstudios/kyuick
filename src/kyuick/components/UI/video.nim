# https://github.com/mashingan/nimffmpeg/blob/master/examples/fplay.nim
import ffmpeg

import sdl2, sdl2/audio

import os, strformat, times
import sugar

type 
    CodecData = (ptr AVcodecParameters, ptr AVCodec, int)


proc updYUVTexture*(texture: TexturePtr, rect: ptr Rect, 
    yPlane: ptr uint8, yPitch: cint, 
    uPlane: ptr uint8, uPitch: cint,
    vPlane: ptr uint8, vPitch: cint): cint {.cdecl, importc: "SDL_UpdateYUVTexture", dynlib: "libSDL2.so".}
