import ../../utils/rawFF
import sdl2, sdl2/audio
import os, strformat, times, math, asyncdispatch, locks, times, terminal
import ../kyuickObject
import sugar, threadpool

const frameLim: int = 10
type
    CodecData* = ref object of RootObj
      params*: AVcodecParameters
      codec*: ptr AVCodec
      idx*: int
    PQueue = ref object of RootObj
      frames: seq[ptr AVFrame]
      frames_test: array[frameLim, ptr AVFrame] = [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]
      pos: int = 0
      firstFilled: bool
      # Higher -> More Mem usage
      # Higher values help with not having choppy playback
      # and not having to skip frames to let buffer fill
      limit: int = frameLim
      lock: Lock
      free: bool
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
      resampler*: ptr SwrContext
      drawLock: Lock
      tSpawnd: bool
      fBuffer: Rect
      doResize: bool
      isDone: bool
      destroyed: bool
      returned*: bool
      canWaitThrd: int = 0
      endCallback*: proc(v: Video)
      auddev: ptr AudioDeviceID
      qft: Lock
      vlt: Lock
      alt: Lock
proc `[]`(queue: PQueue, idx: int): var ptr AVFrame =
  if idx < 0:
    return
  return queue.frames_test[idx]
proc `[]=`(queue: PQueue, idx: int, frame: ptr AVFrame) =
  queue.frames_test[idx] = frame
proc del*(queue: PQueue, pos: int) =
  acquire(queue.lock)
  let frame = queue[pos]
  if frame != nil:
    av_frame_free(frame.addr)
    queue[pos] = nil
  if queue.pos != 0:
    dec queue.pos
  var idx = pos
  while idx < queue.limit - 1:
    queue[idx] = queue[idx + 1]
    inc idx
  release(queue.lock)
proc add*(queue: PQueue, frame: ptr AVFrame): int =
  acquire queue.lock
  if queue.pos >= frameLim - 1:
    return -1
  if queue[queue.pos] != nil:
    av_frame_free(queue[queue.pos].addr)
    queue[queue.pos] = frame
  else:
    queue[queue.pos] = frame
  result = queue.pos
  inc queue.pos
  release(queue.lock)
proc destroy*(v: Video) =
  # Stop modifications
  echo "Awaiting Thread Finish"
  acquire(v.qft)
  acquire(v.vlt)
  acquire(v.alt)
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
  if v.aTFrame != nil:
    av_frame_unref(v.aTFrame)
    av_frame_free(v.aTFrame.addr)
  swr_free(v.resampler.addr)
  destroyTexture(v.texture)
  if v.packet != nil:
    av_packet_unref(v.packet)
    av_packet_free(v.packet.addr)
  v.auddev = nil
  av_format_close_input(v.pFormatCtx.addr)
  deinitLock(v.videoQueue.lock)
  deinitLock(v.audioQueue.lock)
  #dealloc(v.videoQueue.addr)
  #dealloc(v.audioQueue.addr)
  release(v.drawLock)
  v.render = nil
  deinitLock(v.drawLock)
  echo "FINISHED DESTROY"
proc updYUVTexture*(texture: TexturePtr, rect: ptr Rect,
    yPlane: ptr uint8, yPitch: cint,
    uPlane: ptr uint8, uPitch: cint,
    vPlane: ptr uint8, vPitch: cint): cint {.cdecl, importc: "SDL_UpdateYUVTexture", dynlib: "libSDL2.so".}
proc parseCodec*(stream: ptr AVStream): CodecData =
  var codecDat = CodecData()
  codecDat.params = stream.codecpar[]
  codecDat.codec = avcodec_find_decoder(stream.codecpar.codec_id)
  return codecDat
proc audioLoop(video: Video) {.thread.} =
  acquire(video.alt)
  while video.isDone == false:
    while video.audioQueue[0] != nil:
      var
        dst_samples = video.audioQueue[0].ch_layout.nb_channels * av_rescale_rnd(swr_get_delay(video.resampler, video.audioQueue[0].sample_rate) + video.audioQueue[0].nb_samples, 44100, video.audioQueue[0].sample_rate, AV_ROUND_DOWN)
        audioBuffer: ptr uint8 = nil
        buf: cint = 1
      if av_samples_alloc(audioBuffer.addr, nil, 1, dst_samples.cint, AV_SAMPLE_FMT_S32, 1) < 0:
        video.audioQueue.del(0)
        break
      dst_samples = video.audioQueue[0].ch_layout.nb_channels * swr_convert(video.resampler, audioBuffer.addr, dst_samples.cint, cast[ptr ptr uint8](video.audioQueue[0].data.addr), video.audioQueue[0].nb_samples)
      if av_samples_fill_arrays(cast[ptr ptr uint8](video.aTFrame[].data.addr), cast[ptr cint](video.aTFrame.linesize.addr), audioBuffer, 1, dst_samples.cint, AV_SAMPLE_FMT_S32, 1) < 0:
        video.audioQueue.del(0)
        #if video.aTFrame != nil:
        #  av_frame_free(video.aTFrame.addr)
        #video.aTFrame = av_frame_alloc()
        break
      if video.aTFrame == nil:
        video.audioQueue.del(0)
        if audioBuffer != nil: # even though it is also likely 0
          av_free(audioBuffer)
        break
      discard video.auddev[].queueAudio(video.aTFrame[].data[0], uint32 video.aTFrame[].linesize[0])
      av_frame_free(video.aTFrame.addr)
      av_free(audioBuffer)
      video.aTFrame = av_frame_alloc()
      video.audioQueue.del(0)
    waitFor sleepAsync(1)
  waitFor sleepAsync(20)
  release(video.alt)
proc videoLoop(video: Video) {.thread.} =
  acquire(video.vlt)
  var aligns: int = 0
  while video.isDone == false:
    while video.videoQueue[0] == nil and video.isDone == false:
      waitFor sleepAsync(1)
    while video.videoQueue[0] != nil:
      if video.startTime == 0:
        break
      #acquire(video.videoQueue.lock)
      let
        frame = video.videoQueue[0]
        bets = (video.fCounter.float64 * video.vidFPS.float64)
        bE = frame.best_effort_timestamp / 10000
        bDiff = -(bets - bE)
        cTime = epochTime() - video.startTime + bDiff
        diff = if bE < cTime: (cTime - bE) else: (cTime - bE)
      var
        output = "dif $#   frame $#|Ots $# vs bts $# COMP $#\tvidTime $# | ECs $#" % [$diff, $video.fCounter, $bE, $bets, $bDiff, $cTime, $aligns]
      #video.startTime = epochTime()
      if diff < -0.01:
        # Track error in time tracking, and continue,
        #          if we're too early for this frame.
        release(video.videoQueue.lock)
        waitFor sleepAsync(1)
        continue
      elif diff > 0 and video.fCounter > 0:
        # Can't fill buffers fast enough; disable buffer thread optimization
        # And skip frameC to try and delay
        output = output & " OOS'd ($#)" % [$diff]
        video.fCounter += 2
        waitFor sleepAsync(10) #(diff * 1000).int
        video.canWaitThrd = 0
        inc aligns
      inc video.fCounter
      #eraseLine(stdout)
      #styledWriteLine(stdout, $output)
      #cursorUp 1
      echo output
      video.videoQueue.del(0)
      release(video.videoQueue.lock)
      waitFor sleepAsync(5)
  release(video.vlt)
proc fillQueues(video: Video) {.thread.} =
  acquire(video.qft)
  while av_read_frame(video.pFormatCtx, video.packet) >= 0:
    while true:
      # AUDIO
      if video.packet.stream_index.int == video.audioInfo.idx:
        if video.audioQueue.pos > video.audioQueue.limit - 2:
          continue
        if avcodec_send_packet(video.audioCtx, video.packet) < 0:
          echo "ERR SENDING PACKET"
          av_packet_free(video.packet.addr)
          video.packet = av_packet_alloc()
          break
        let idx = video.audioQueue.add av_frame_alloc()
        let f = avcodec_receive_frame(video.audioCtx, video.audioQueue[idx])
        if f == -11:
          # READ MORE
          video.videoQueue.del(idx)
          av_packet_free(video.packet.addr)
          video.packet = av_packet_alloc()
          break
        if f < 0:
          video.videoQueue.del(idx)
          av_packet_free(video.packet.addr)
          video.packet = av_packet_alloc()
          continue
        av_packet_free(video.packet.addr)
        video.packet = av_packet_alloc()
        break
      # VIDEO
      if video.packet.stream_index.int == video.videoInfo.idx:
        if video.videoQueue.pos > video.videoQueue.limit - 2:
          continue
        if avcodec_send_packet(video.videoCtx, video.packet) < 0:
          echo "ERR SENDING PACKET"
          av_packet_free(video.packet.addr)
          video.packet = av_packet_alloc()
          break
        #acquire(video.videoQueue.lock)
        let idx = video.videoQueue.add av_frame_alloc()
        #video.videoQueue.frames.add av_frame_alloc()
        let f = avcodec_receive_frame(video.videoCtx, video.videoQueue[idx])
        if f == -11:
          # READ MORE
          video.videoQueue.del(video.videoQueue.pos)
          av_packet_free(video.packet.addr)
          video.packet = av_packet_alloc()
          release(video.videoQueue.lock)
          break
        if f < 0:
          video.videoQueue.del(video.videoQueue.pos)
          av_packet_free(video.packet.addr)
          video.packet = av_packet_alloc()
          release(video.videoQueue.lock)
          continue
        #if video.videoQueue.free == true:
        #  av_frame_free(video.videoQueue.frames[0].addr)
        #  video.videoQueue.frames.delete(0)
        #  video.videoQueue.free = false
        #video.videoQueue.frames.add(vfs)
        #av_frame_free(video.videoQueue.frames[0].addr)
        av_packet_free(video.packet.addr)
        video.packet = av_packet_alloc()
        release(video.videoQueue.lock)
        break
      av_packet_free(video.packet.addr)
      video.packet = av_packet_alloc()
      break
    if video.canWaitThrd > 0:
      waitFor sleepAsync(video.canWaitThrd)
  video.isDone = true
  release(video.qft)
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
  if video.isDone and video.videoQueue[0] == nil:
    release(video.videoQueue.lock)
    destroy(video)
    if video.endCallback != nil: video.endCallback(video)
    video.returned = true
    return
  if video.videoQueue.frames_test.len > 0:
    let frame = video.videoQueue[0]
    if frame != nil:
      discard updYUVTexture(video.texture, video.rect.addr, frame.data[0], frame.linesize[0], frame.data[1], frame.linesize[1], frame.data[2], frame.linesize[2])
  release(video.videoQueue.lock)
  if video.doResize:
    var p: Point = point(0, 0)
    renderer.copyEx video.texture, video.rect.addr, video.fBuffer.addr, cdouble(0), p.addr
    return
  renderer.copy video.texture, nil, video.rect.addr
proc generateVideo*(fileName: string, x, y: cint, w: cint = -1, h: cint = -1, auddev: ptr AudioDeviceID = nil): Video =
  var video: Video = Video()
  video.auddev = auddev
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

  #echo videoCodec.params.width
  #echo videoCodec.params.height
  video.width = videoCodec.params.width
  video.height = videoCodec.params.height
  video.videoCtx = avcodec_alloc_context3(videoCodec.codec)
  video.audioCtx = avcodec_alloc_context3(audioCodec.codec)
  assert avcodec_parameters_to_context(video.videoCtx, videoCodec.params.addr) >= 0
  assert avcodec_parameters_to_context(video.audioCtx, audioCodec.params.addr) >= 0
  assert avcodec_open2(video.videoCtx, videoCodec.codec, nil) >= 0
  assert avcodec_open2(video.audioCtx, audioCodec.codec, nil) >= 0

  #(video.audioCtx.sample_rate.float * 1).cint
  #echo video.audioCtx.sample_rate
  #echo video.audioCtx.channels.uint8
  video.packet = av_packet_alloc()
  video.render = renderVideo
  video.rect = rect(x, y, video.width, video.height)
  video.renderSaved = false
  video.audioInfo = CodecData(idx: 1)
  video.videoInfo = CodecData(idx: 0)
  video.aTFrame = av_frame_alloc()
  if w > -1 or h > -1:
    var
      cW: float = w.float
      cH: float = h.float
    var
      wr: float = w.float / video.width.float
      hr: float = h.float / video.height.float
    dump wr
    dump hr
    if wr < 1 or hr < 1:
      cW = (video.width.float * wr)
      cH = (video.height.float * hr)
      if wr < 1 and hr < 1:
        cW = (video.width.float * hr)
        cH = (video.height.float * wr)
      elif wr < 1:
        cW = cW #- (video.width.float * mRatio)
        cH = (video.height.float * wr)
      elif hr < 1:
        cW = (video.width.float * hr)
        cH = cH #(video.height.float * mRatio)
      dump cW
      dump cH
    elif wr < hr:
      cW = wr * video.width.float
      cH = wr * video.height.float
    else:
      cW = hr * video.width.float
      cH = hr * video.height.float
      dump cW
      dump cH
    var nX = x
    if cW < w.float:
      nX = ((w.float / 2) - (cW / 2)).cint
    video.fBuffer = rect(nX, y, cW.cint, cH.cint)
    video.doResize = true
  #dump video.audioCtx.channel_layout
  dump video.audioCtx.sample_fmt
  dump video.audioCtx.sample_rate
  dump 1.0f / video.vidFPS
  dump video.vidFPS
  discard swr_alloc_set_opts2(video.resampler.addr, video.audioCtx.ch_layout.addr,
    AV_SAMPLE_FMT_S32, 44800, video.audioCtx.ch_layout.addr, video.audioCtx.sample_fmt,
    video.audioCtx.sample_rate, 0, nil)
  discard swr_init(video.resampler)
  initLock(video.drawLock)
  video.audioQueue = PQueue()
  video.videoQueue = PQueue()
  initLock(video.audioQueue.lock)
  initLock(video.videoQueue.lock)
  initLock(video.qft)
  initLock(video.vlt)
  initLock(video.alt)
  spawn fillQueues(video) #fillQueues(video)
  spawn videoLoop(video)
  spawn audioLoop(video)
  return video
