# https://github.com/mashingan/nimffmpeg/blob/master/examples/fplay.nim
import ffmpeg
import sdl2, sdl2/audio
import os, strformat, times, math, asyncdispatch
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
        delay*: float
        endTime*: float
        vidFPS*: float
        videoCtx*, audioCtx*: ptr AVCodecContext
        videoCodecParams*, audioCodecParams*: ptr AVcodecParameters
        videoCodec*, audioCodec*: ptr AVCodec
        videoFrame*, aFrame*, aTFrame: ptr AVFrame
        videoPacket*, audioPacket*: ptr AVPacket
        videoInfo*: CodecData
        audioInfo*: CodecData
        audioDevice*: AudioDeviceID
        want*, have*: AudioSpec
        resampler*: ptr SwrContext
        window: WindowPtr
        auddev: AudioDeviceID
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
proc sample(ctx: ptr AVCodecContext, pkt: ptr AVPacket, frame: ptr AVFrame, aFrame: ptr AVFrame,
  dev: AudioDeviceID, resampler: ptr SwrContext) {.async.} =
  if avcodec_send_packet(ctx, pkt) < 0: return
  if avcodec_receive_frame(ctx, frame) < 0: return
  var dst_samples = frame.channels * av_rescale_rnd(swr_get_delay(resampler, frame.sample_rate) + frame.nb_samples, 44100, frame.sample_rate, AV_ROUND_DOWN)
  var 
    audioBuf: ptr uint8 = nil
    buf: cint = 1
  discard av_samples_alloc(audioBuf.addr, nil, 1, dst_samples.cint, AV_SAMPLE_FMT_S32, 1)
  dst_samples = frame.channels * swr_convert(resampler, audioBuf.addr, dst_samples.cint, cast[ptr ptr uint8](frame.data.addr), frame.nb_samples)
  discard av_samples_fill_arrays(cast[ptr ptr uint8](aFrame[].data.addr), cast[ptr cint](aFrame.linesize.addr), audioBuf, 1, dst_samples.cint, AV_SAMPLE_FMT_S32, 1)
  discard dev.queueAudio(aFrame[].data[0], uint32 aFrame[].linesize[0])
proc replay(dev: AudioDeviceID, aFrame: ptr AVFrame) =
  discard dev.queueAudio(aFrame[].data[0], uint32 aFrame[].linesize[0])
proc renderVideoFrames(renderer: RendererPtr, video: Video) =
  let 
    current = getTicks().float
    deltaT = (current - video.endTime) / 1000.0f
  let ftU = floor(deltaT / (1.0f / 10))
  if avcodec_send_packet(video.videoCtx, video.videoPacket) < 0: return
  if avcodec_receive_frame(video.videoCtx, video.videoFrame) < 0: return
  let frame = video.videoFrame
  discard updYUVTexture(video.texture, video.rect.addr, frame[].data[0], frame[].linesize[0], frame[].data[1], frame[].linesize[1], frame[].data[2], frame[].linesize[2])
  video.endTime = current
  dump video.endTime
    #delay(100)
  return
proc renderVideo(renderer: RendererPtr, obj: KyuickObject) =
  var video = Video(obj)
  discard av_read_frame(video.pFormatCtx, video.videoPacket)
  if video.renderSaved == false:
    video.texture = createTexture(renderer, uint32 SDL_PIXELFORMAT_IYUV,
      SDL_TEXTUREACCESS_STREAMING or SDL_TEXTUREACCESS_TARGET,
      cint video.width, cint video.height)
    video.renderSaved = true
  if video.videoPacket[].stream_index.int != 0:
    if video.videoPacket[].stream_index.int == video.audioInfo.idx:
      asyncCheck sample(video.audioCtx, video.videoPacket, video.aFrame, video.aTFrame, video.auddev, video.resampler)
  if video.videoPacket[].stream_index.int == 0:
    renderVideoFrames(renderer, video)
  renderer.copy video.texture, nil, video.rect.addr
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
  video.vidFPS = (1.0 / (rational.num.float / rational.den.float))
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
  
  zeroMem(addr video.want, sizeof AudioSpec)
  zeroMem(addr video.have, sizeof AudioSpec)
  video.want.freq = (44100 * 1).cint
  #(video.audioCtx.sample_rate.float * 1).cint
  echo video.audioCtx.sample_rate
  video.want.format = AUDIO_S32
  video.want.channels = video.audioCtx.channels.uint8
  video.auddev = openAudioDevice(getAudioDeviceName(0, 0), 0, addr video.want, addr video.have, 0)
  video.auddev.pauseAudioDevice 0
  video.videoFrame = av_frame_alloc()
  video.aFrame = av_frame_alloc()
  video.aTFrame = av_frame_alloc()
  video.videoPacket = av_packet_alloc()
  video.audioPacket = av_packet_alloc()
  video.render = renderVideo
  video.rect = rect(0, 0, video.width, video.height)
  video.renderSaved = false
  video.audioInfo = CodecData(idx: 1)
  dump video.audioCtx.channel_layout
  dump video.audioCtx.sample_fmt
  dump video.audioCtx.sample_rate
  dump 1.0f / video.vidFPS
  dump video.vidFPS
  video.resampler = swr_alloc_set_opts(nil, video.audioCtx.channel_layout.int64,
    AV_SAMPLE_FMT_S32, 44100, video.audioCtx.channel_layout.int64, video.audioCtx.sample_fmt,
    video.audioCtx.sample_rate, 0, nil)
  discard swr_init(video.resampler)
  return video