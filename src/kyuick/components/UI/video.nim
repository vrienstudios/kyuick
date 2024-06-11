# https://github.com/mashingan/nimffmpeg/blob/master/examples/fplay.nim
import ffmpeg
import sdl2, sdl2/audio
import os, strformat, times, math
import ../kyuickObject
import sugar

type 
    CodecData* = ref object of RootObj
        params*: AVcodecParameters
        codec*: ptr AVCodec
    Video* = ref object of KyuickObject
        pFormatCtx*: ptr AVFormatContext
        videoIndex*: int
        delay*: float
        endTime*: float
        vidFPS*: float
        videoCtx*, audioCtx*: ptr AVCodecContext
        videoCodecParams*, audioCodecParams*: ptr AVcodecParameters
        videoCodec*, audioCodec*: ptr AVCodec
        videoFrame*, aFrame*: ptr AVFrame
        videoPacket*, audioPacket*: ptr AVPacket
        videoInfo*: CodecData
        audioInfo*: CodecData
        audioDevice*: AudioDeviceID
        want*, have*: AudioSpec
        parser*: ptr AVCodecParserContext
        window: WindowPtr
        onEnd: proc()

proc updYUVTexture*(texture: TexturePtr, rect: ptr Rect, 
    yPlane: ptr uint8, yPitch: cint, 
    uPlane: ptr uint8, uPitch: cint,
    vPlane: ptr uint8, vPitch: cint): cint {.cdecl, importc: "SDL_UpdateYUVTexture", dynlib: "libSDL2.so".}
proc parseCodec*(stream: ptr AVStream): CodecData =
  var codecDat = CodecData()
  codecDat.params = stream.codecpar[]
  codecDat.codec = avcodec_find_decoder(stream.codecpar.codec_id)
  return codecDat
proc prepareAudioSpec*(spec: var AudioSpec) =
  zeroMem(addr spec, sizeof AudioSpec)
  spec.freq = 44100
  spec.format = AUDIO_F32
  spec.channels = 2
  spec.samples = 4096
proc renderVid(renderer: RendererPtr, obj: KyuickObject) =
  var video = Video(obj)
  if video.delay >= 1:
    let 
      c = cpuTime().float
    if c > video.endTime:
      video.delay = 0
    renderer.copy video.texture, nil, video.rect.addr
    return
  discard av_read_frame(video.pFormatCtx, video.videoPacket)
  if video.renderSaved == false:
    video.texture = createTexture(renderer, uint32 SDL_PIXELFORMAT_IYUV,
      SDL_TEXTUREACCESS_STREAMING or SDL_TEXTUREACCESS_TARGET,
      cint video.width, cint video.height)
  video.renderSaved = true
  if video.videoPacket[].stream_index.int != 0:
    renderer.copy video.texture, nil, video.rect.addr
    return
  let start = cpuTime()
  if avcodec_send_packet(video.videoCtx, video.videoPacket) < 0: return
  if avcodec_receive_frame(video.videoCtx, video.videoFrame) < 0: return
  let frame = video.videoFrame
  discard updYUVTexture(video.texture, video.rect.addr, frame[].data[0], frame[].linesize[0], frame[].data[1], frame[].linesize[1], frame[].data[2], frame[].linesize[2])
  renderer.copy video.texture, nil, video.rect.addr
  let 
    finishTime = cpuTime()
    diff = finishTime - start
  if diff < video.vidFPS:
    let delay = (video.vidFPS - diff)
    video.delay = delay * 1000
    video.endTime = finishTime + delay
  av_packet_unref(video.videoPacket)
proc generateVideo*(fileName: string): Video =
  var video: Video = Video()
  assert avformat_open_input(addr video.pFormatCtx, fileName, nil, nil) == 0
  assert avformat_find_stream_info(video.pFormatCtx, nil) == 0
  var 
    videoStream = getAVStream(video.pFormatCtx, 0)
    audioStream = getAVStream(video.pFormatCtx, 1)
  let 
    codecParam = videoStream.codecpar
    rational = videoStream.avg_frame_rate
  video.vidFPS = 1.0 / (rational.num.float / rational.den.float)
  var 
    videoCodec = parseCodec(videoStream)
    audioCodec = parseCodec(audioStream)

  echo videoCodec.params.width
  echo videoCodec.params.height
  video.width = videoCodec.params.width
  video.height = videoCodec.params.height
  video.videoCtx = avcodec_alloc_context3(videoCodec.codec)
  video.audioCtx = avcodec_alloc_context3(audioCodec.codec)
  assert avcodec_parameters_to_context(video.videoCtx, videoCodec.params.addr) >= 0
  assert avcodec_parameters_to_context(video.audioCtx, audioCodec.params.addr) >= 0
  assert avcodec_open2(video.videoCtx, videoCodec.codec, nil) >= 0
  assert avcodec_open2(video.audioCtx, audioCodec.codec, nil) >= 0
  video.parser = av_parser_init(cint videoCodec.codec.id)
  video.videoFrame = av_frame_alloc()
  video.aFrame = av_frame_alloc()
  video.videoPacket = av_packet_alloc()
  video.audioPacket = av_packet_alloc()
  video.render = renderVid
  video.rect = rect(0, 0, 720, 720)
  video.renderSaved = false
  return video