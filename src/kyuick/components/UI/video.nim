import ffmpeg
import sdl2, sdl2/audio
import os, strformat, times, math, asyncdispatch, locks, threadpool, times, terminal
import ../kyuickObject
import sugar

type 
    CodecData* = ref object of RootObj
      params*: AVcodecParameters
      codec*: ptr AVCodec
      idx*: int
    PQueue = ref object of RootObj
      frames: seq[ptr AVFrame]
      # Higher -> More Mem usage
      # Higher values help with not having choppy playback
      # and not having to skip frames to let buffer fill
      limit: int = 10
      lock: Lock
      nb_packets: cint
    Video* = ref object of KyuickObject
      videoQueue: PQueue
      audioQueue: PQueue
      pFormatCtx*: ptr AVFormatContext
      vidFPS*: float
      videoClock*: float64
      startTime*: float64
      fCounter*: int64
      videoCtx*, audioCtx*: ptr AVCodecContext
      videoCodec*, audioCodec*: ptr AVCodec
      aTFrame: ptr AVFrame
      packet*: ptr AVPacket
      videoInfo*, audioInfo*: CodecData
      audioDevice*: AudioDeviceID
      want*, have*: AudioSpec
      resampler*: ptr SwrContext
      auddev: AudioDeviceID
      drawLock: Lock
      tSpawnd: bool
      fBuffer: Rect
      doResize: bool
      isDone: bool
      destroyed: bool
      returned*: bool
      canWaitThrd: int = 1
      endCallback*: proc(v: Video)

proc destroy*(v: Video) =
  # Stop modifications
  echo "DESTROY"
  acquire(v.drawLock)
  if v.destroyed == true:
    release(v.drawLock)
    return
  v.destroyed = true
  v.render = nil
  avcodec_free_context(v.videoCtx.addr)
  avcodec_free_context(v.audioCtx.addr)
  acquire(v.videoQueue.lock)
  acquire(v.audioQueue.lock)
  for f in v.videoQueue.frames:
    av_frame_free(f.addr)
  for f in v.audioQueue.frames:
    av_frame_free(f.addr)
  v.videoQueue.frames = @[]
  v.audioQueue.frames = @[]
  release(v.videoQueue.lock)
  release(v.audioQueue.lock)
  v.videoQueue = nil
  v.audioQueue = nil
  if v.aTFrame != nil:
    av_frame_unref(v.aTFrame)
    av_frame_free(v.aTFrame.addr)
  swr_free(v.resampler.addr)
  av_format_close_input(v.pFormatCtx.addr)
  destroyTexture(v.texture)
  if v.packet != nil:
    av_packet_unref(v.packet)
    av_packet_free(v.packet.addr)
  v.auddev.closeAudioDevice()
  release(v.drawLock)
proc updYUVTexture*(texture: TexturePtr, rect: ptr Rect, 
    yPlane: ptr uint8, yPitch: cint, 
    uPlane: ptr uint8, uPitch: cint,
    vPlane: ptr uint8, vPitch: cint): cint {.cdecl, importc: "SDL_UpdateYUVTexture", dynlib: "libSDL2.so".}
proc parseCodec*(stream: ptr AVStream): CodecData =
  var codecDat = CodecData()
  codecDat.params = stream.codecpar[]
  codecDat.codec = avcodec_find_decoder(stream.codecpar.codec_id)
  return codecDat
proc decodeAudio(dev: AudioDeviceID, resampler: ptr SwrContext, frame: AVFrame, aFrame: ptr AVFrame) =
  var dst_samples = 
    frame.channels * av_rescale_rnd(swr_get_delay(resampler, frame.sample_rate) + frame.nb_samples, 44100, frame.sample_rate, AV_ROUND_DOWN)
  var 
    audioBuf: ptr uint8 = nil
    buf: cint = 1
  discard av_samples_alloc(audioBuf.addr, nil, 1, dst_samples.cint, AV_SAMPLE_FMT_S32, 1)
  dst_samples = frame.channels * swr_convert(resampler, audioBuf.addr, dst_samples.cint, cast[ptr ptr uint8](frame.data.addr), frame.nb_samples)
  discard av_samples_fill_arrays(cast[ptr ptr uint8](aFrame[].data.addr), cast[ptr cint](aFrame.linesize.addr), audioBuf, 1, dst_samples.cint, AV_SAMPLE_FMT_S32, 1)
  if audioBuf == nil: return
  av_free(audioBuf)
proc audioLoop(video: Video) {.thread.} =
  while video.isDone == false:
    while video.audioQueue.frames.len > 0:
      acquire(video.audioQueue.lock)
      if video.videoQueue.frames[0] == nil: continue
      if video.aTFrame == nil: continue
      decodeAudio(video.auddev, video.resampler, video.audioQueue.frames[0][], video.aTFrame)
      discard video.auddev.queueAudio(video.aTFrame[].data[0], uint32 video.aTFrame[].linesize[0])
      if video.audioQueue.frames[0] != nil:
        av_frame_free(video.audioQueue.frames[0].addr)
      if video.aTFrame != nil:
        av_frame_free(video.aTFrame.addr)
        video.aTFrame = av_frame_alloc()
      video.audioQueue.frames.delete(0)
      #echo video.audioQueue.frames.len
      release(video.audioQueue.lock)
    sleep(5)
proc videoLoop(video: Video) {.thread.} =
  var aligns: int = 0
  while video.isDone == false:
    while video.videoQueue.frames.len > 0:
      if video.startTime == 0:
        break
      let 
        frame = video.videoQueue.frames[0]
        bets = (video.fCounter.float64 * video.vidFPS.float64)
        bE = frame.best_effort_timestamp / 10000
        bDiff = -(bets - bE)
        cTime = epochTime() - video.startTime + bDiff
        diff = if bE < cTime: (cTime - bE) else: (cTime - bE)
        output = "dif $#   frame $#|Ots $# vs bts $# COMP $#\tvidTime $# | ECs $#" % [$diff, $video.fCounter, $bE, $bets, $bDiff, $cTime, $aligns]
      #video.startTime = epochTime()
      if diff < -0.01:
        # Track error in time tracking, and continue, 
        #          if we're too early for this frame.
        #eraseLine(stdout)
        #styledWriteLine(stdout, "Compensating for Diff ", fgGreen, $diff)
        #cursorUp 1
        #video.canWaitThrd = true
        sleep(1)
        continue
      elif diff > 0 and video.fCounter > 0:
        # Can't fill buffers fast enough; disable buffer thread optimization
        # And skip frameC to try and delay
        styledWriteLine(stdout, "ALIGN", fgGreen, $bets)
        video.fCounter += 3
        video.canWaitThrd = 0
        inc aligns
      inc video.fCounter
      eraseLine(stdout)
      styledWriteLine(stdout, $output)
      cursorUp 1
      acquire(video.videoQueue.lock)
      av_frame_free(frame.addr)
      video.videoQueue.frames.delete(0)
      release(video.videoQueue.lock)
      #echo video.videoQueue.frames.len
proc fillQueues(video: Video) {.thread.} =
  while av_read_frame(video.pFormatCtx, video.packet) >= 0:
    while true:
      # AUDIO
      if video.packet.stream_index.int == video.audioInfo.idx:
        if video.audioQueue.frames.len > video.audioQueue.limit:
          continue
        if avcodec_send_packet(video.audioCtx, video.packet) < 0:
          echo "ERR SENDING PACKET"
          continue
        var vfs: ptr AVFrame = av_frame_alloc()
        let f = avcodec_receive_frame(video.audioCtx, vfs)
        if f == -11:
          # READ MORE
          av_frame_free(vfs.addr)
          av_packet_free(video.packet.addr)
          video.packet = av_packet_alloc()
          break
        if f < 0:
          av_frame_free(vfs.addr)
          av_packet_free(video.packet.addr)
          video.packet = av_packet_alloc()
          continue
        acquire(video.audioQueue.lock)
        video.audioQueue.frames.add(vfs)
        av_packet_free(video.packet.addr)
        video.packet = av_packet_alloc()
        release(video.audioQueue.lock)
        break
      # VIDEO
      if video.packet.stream_index.int == video.videoInfo.idx:
        if video.videoQueue.frames.len > video.videoQueue.limit:
          continue
        if avcodec_send_packet(video.videoCtx, video.packet) < 0:
          echo "ERR SENDING PACKET"
          continue
        var vfs: ptr AVFrame = av_frame_alloc()
        let f = avcodec_receive_frame(video.videoCtx, vfs)
        if f == -11:
          # READ MORE
          av_frame_free(vfs.addr)
          av_packet_free(video.packet.addr)
          video.packet = av_packet_alloc()
          break
        if f < 0:
          av_frame_free(vfs.addr)
          av_packet_free(video.packet.addr)
          video.packet = av_packet_alloc()
          continue
        #acquire(video.videoQueue.lock)
        video.videoQueue.frames.add(vfs)
        av_packet_free(video.packet.addr)
        video.packet = av_packet_alloc()
        #release(video.videoQueue.lock)
      break
    sleep(video.canWaitThrd)
  video.isDone = true
proc renderVideo(renderer: RendererPtr, obj: KyuickObject) =
  var video = Video(obj)
  if video.renderSaved == false:
    video.videoClock = video.startTime.float64
    video.texture = createTexture(renderer, uint32 SDL_PIXELFORMAT_IYUV,
      SDL_TEXTUREACCESS_STREAMING or SDL_TEXTUREACCESS_TARGET,
      cint video.width, cint video.height)
    video.renderSaved = true
    video.startTime = epochTime()
  acquire(video.videoQueue.lock)
  if video.isDone and video.videoQueue.frames.len == 0:
    release(video.videoQueue.lock)
    destroy(video)
    if video.endCallback != nil: video.endCallback(video)
    video.returned = true
    return
  if video.videoQueue.frames.len > 0:
    let frame = video.videoQueue.frames[0]
    discard updYUVTexture(video.texture, video.rect.addr, frame.data[0], frame.linesize[0], frame.data[1], frame.linesize[1], frame.data[2], frame.linesize[2])
  release(video.videoQueue.lock)
  if video.doResize:
    var p: Point = point(0, 0)
    renderer.copyEx video.texture, video.rect.addr, video.fBuffer.addr, cdouble(0), p.addr
    return
  renderer.copy video.texture, nil, video.rect.addr
proc generateVideo*(fileName: string, x, y: cint, w: cint = -1, h: cint = -1): Video =
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
  video.packet = av_packet_alloc()
  video.render = renderVideo
  video.rect = rect(x, y, video.width, video.height)
  video.renderSaved = false
  video.audioInfo = CodecData(idx: 1)
  video.videoInfo = CodecData(idx: 0)
  video.aTFrame = av_frame_alloc()
  if w > -1 or h > -1:
    video.fBuffer = rect(x, y, w, h)
    video.doResize = true
  dump video.audioCtx.channel_layout
  dump video.audioCtx.sample_fmt
  dump video.audioCtx.sample_rate
  dump 1.0f / video.vidFPS
  dump video.vidFPS
  video.resampler = swr_alloc_set_opts(nil, video.audioCtx.channel_layout.int64,
    AV_SAMPLE_FMT_S32, 44100, video.audioCtx.channel_layout.int64, video.audioCtx.sample_fmt,
    video.audioCtx.sample_rate, 0, nil)
  discard swr_init(video.resampler)
  initLock(video.drawLock)
  video.audioQueue = PQueue()
  video.videoQueue = PQueue()
  initLock(video.audioQueue.lock)
  initLock(video.videoQueue.lock)
  spawn fillQueues(video)
  sleep(10)
  spawn audioLoop(video)
  spawn videoLoop(video)
  return video