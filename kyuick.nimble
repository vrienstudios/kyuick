# Package

version       = "0.1.0"
author        = "VrienCo"
description   = "GSG Game Engine"
license       = "Proprietary"
srcDir        = "src"

requires "nim >= 2.0.0"
requires "sdl2"
requires "yaml"
requires "https://github.com/vrienstudios/zippy"
requires "https://github.com/ShujianDou/nim-epub"

task build "build":
  withDir "src":
    exec "nim c -f --passL:\"-lavcodec -lswresample -lavutil -lavformat -lavdevice -lavfilter\" ./kyuick.nim"