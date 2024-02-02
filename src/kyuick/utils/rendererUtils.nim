import sdl2
import sdl2/image
import sdl2/ttf

proc setDrawColor*(renderer: RendererPtr, col: array[4, int]) =
    renderer.setDrawColor(color(col[0], col[1], col[2], col[3]))
proc setDrawColor*(renderer: RendererPtr, col: array[3, int]) =
    renderer.setDrawColor(color(col[0], col[1], col[2], 255))
proc setDrawColor*(renderer: RendererPtr, col: array[4, uint8]) =
    renderer.setDrawColor(color(col[0], col[1], col[2], col[3]))
proc setDrawColor*(renderer: RendererPtr, col: array[3, uint8]) =
    renderer.setDrawColor(color(col[0], col[1], col[2], 255))
proc sizeText*(font: FontPtr, str: string): tuple[w, h: cint] =
    var w, h: cint = 0
    discard ttf.sizeText(font, cstring(str), addr w, addr h)
    return (w, h)
proc getColorAtPoint*(pixelData: SurfacePtr, xT, yT: cint): tuple[r, g, b: uint8] =
    let x: uint32 = uint32(xT)
    let y: int32 = int32(yT)
    let pixel: uint32 = cast[ptr uint32](cast[uint](pixelData.pixels) + cast[uint]((pixelData.pitch * y + cast[int32](pixelData.format.BytesPerPixel * x))))[]
    var r, g, b: uint8
    getRGB(pixel, pixelData.format, r, g, b)
    return (r, g, b)
proc getColorDirections*(pixelData: SurfacePtr, xT, yT: cint): array[4, tuple[r, g, b, t: uint8]] =
    let sptr: ptr Surface = cast[ptr Surface](pixelData)
    let bpp = pixelData.format.BytesPerPixel
    let x: uint32 = uint32(xT)
    let y: int32 = int32(yT)
    let 
        leftE: uint32 = 
            if x == 0: 4294967295'u32
            else:
                cast[ptr uint32](cast[uint](pixelData.pixels) + 
                cast[uint]((pixelData.pitch * y + cast[int32](bpp * (x - 1)))))[]
        upE: uint32 =
            if y == 0: 4294967295'u32
            else:
                cast[ptr uint32](cast[uint](pixelData.pixels) + 
                cast[uint]((pixelData.pitch * (y - 1) + cast[int32](bpp * x))))[]
        rightE: uint32 = 
            if x == uint32(sptr.w - 1): 4294967295'u32
            else:
                cast[ptr uint32](cast[uint](pixelData.pixels) + 
                cast[uint]((pixelData.pitch * y + cast[int32](bpp * (x + 1)))))[]
        downE: uint32 =
            if y == sptr.h - 1: 4294967295'u32
            else: cast[ptr uint32](cast[uint](pixelData.pixels) + cast[uint]((pixelData.pitch * (y + 1) + cast[int32](bpp * x))))[]
    var 
        l1, l2, l3, lt, u1, u2, u3, ut, r1, r2, r3, rt, d1, d2, d3, dt,: uint8
    
    getRGB(leftE, pixelData.format, l1, l2, l3)
    getRGB(upE, pixelData.format, u1, u2, u3)
    getRGB(rightE, pixelData.format, r1, r2, r3)
    getRGB(downE, pixelData.format, d1, d2, d3)
    if leftE == 4294967295'u32: lt = 1'u8
    if upE == 4294967295'u32: ut = 1'u8
    if rightE == 4294967295'u32: rt = 1'u8
    if downE == 4294967295'u32: dt = 1'u8
    let tpl = [(l1, l2, l3, lt), (u1, u2, u3, ut), (r1, r2, r3, rt), (d1, d2, d3, dt)]
    if x == 454 and y == 561:
        echo "$1, $2\n\n" % [$x, $y]
        echo $tpl
        echo "\n\n"
    return tpl
    #var x: cint = 0
    #var y: cint = 0
    #while y < pixelData.h:
    #    while x < pixelData.w: