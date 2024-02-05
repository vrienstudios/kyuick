# https://github.com/mashingan/nimffmpeg/blob/master/examples/fplay.nim
import ffmpeg
import sdl2, sdl2/audio
import os, strformat, times
import ../kyuickObject
import sugar

type 
    CodecData* = ref object of RootObj
        params*: AVcodecParameters
        codec*: ptr AVCodec
        idx*: int
    Video* = ref object of KyuickObject
        pFormatCtx*: ptr AVFormatContext
        videoIndex*: int
        fpsRendering*: float
        videoCodecCtx*, audioCtx*: ptr AVCodecContext
        videoCodecParams*, audioCodecParams*: ptr AVcodecParameters
        videoCodec*, audioCodec*: ptr AVCodec
        videoFrame*, aFrame*: ptr AVFrame
        videoPacket*, audioPacket*: ptr AVPacket
        videoInfo*: CodecData
        audioInfo*: CodecData
        audioDevice*: AudioDeviceID
        want*, have*: AudioSpec

proc updYUVTexture*(texture: TexturePtr, rect: ptr Rect, 
    yPlane: ptr uint8, yPitch: cint, 
    uPlane: ptr uint8, uPitch: cint,
    vPlane: ptr uint8, vPitch: cint): cint {.cdecl, importc: "SDL_UpdateYUVTexture", dynlib: "libSDL2.so".}
#proc render(context: ptr AVCodecContext, packet: ptr AVPacket, frame: ptr AVFrame,
#    rect: ptr Rect, texture: TexturePtr, renderer: RendererPtr, renderFPS: float): uint32
#proc sample(context: ptr AVCodecContext, packet: ptr AVPacket, frame: ptr AVFrame, audioD: AudioDeviceID): uint32
proc allocContext*(vidctx, audctx: var ptr AVCodecContext,
  vidinfo, audinfo: CodecData) =
  vidctx = avcodec_alloc_context3(vidinfo.codec)
  audctx = avcodec_alloc_context3(audinfo.codec)
  if avcodec_parameters_to_context(vidctx, addr vidinfo.params) < 0:
    quit "avcodec_parameters_to_context fail!"
  if avcodec_open2(vidctx, vidinfo.codec, nil) < 0:
    quit "Couldn't open codec."
  if avcodec_parameters_to_context(audctx, addr audinfo.params) < 0:
    quit "avcodec_parameters_to_context fail!"
  if avcodec_open2(audctx, audinfo.codec, nil) < 0:
    quit "Couldn't open codec.."
proc prepareAudioSpec*(spec: var AudioSpec) =
  zeroMem(addr spec, sizeof AudioSpec)
  spec.freq = 44100
  spec.format = AUDIO_F32
  spec.channels = 2
  spec.samples = 4096