import sdl2
import sdl2/ttf

proc setDrawColor*(renderer: RendererPtr, col: array[4, int]) =
    renderer.setDrawColor(color(col[0], col[1], col[2], col[3]))
proc sizeText*(font: FontPtr, str: string): tuple[w, h: cint] =
    var w, h: cint = 0
    discard ttf.sizeText(font, cstring(str), addr w, addr h)
    return (w, h)
proc getColorAtPoint*(pixelData: SurfacePtr, xT, yT: int): tuple[r, g, b: uint8] =
    let x: uint32 = uint32(xT)
    let y: int32 = int32(yT)
    let pixel: uint32 = cast[ptr uint32](cast[uint](pixelData.pixels) + cast[uint]((pixelData.pitch * y + cast[int32](pixelData.format.BytesPerPixel * x))))[]
    var r, g, b: uint8
    getRGB(pixel, pixelData.format, r, g, b)
    return (r, g, b)
proc getColorDirections*(pixelData: SurfacePtr, xT, yT: int): array[4, tuple[r, g, b: uint8]] =
    let bpp = pixelData.format.BytesPerPixel
    let x: uint32 = uint32(xT)
    let y: int32 = int32(yT)
    let leftE: uint32 = 
        cast[ptr uint32](cast[uint](pixelData.pixels) + 
        cast[uint]((pixelData.pitch * y + cast[int32](bpp * (x - 1)))))[]
    let upE: uint32 = 
        cast[ptr uint32](cast[uint](pixelData.pixels) + 
        cast[uint]((pixelData.pitch * (y + 1) + cast[int32](bpp * x))))[]
    let rightE: uint32 = 
        cast[ptr uint32](cast[uint](pixelData.pixels) + 
        cast[uint]((pixelData.pitch * y + cast[int32](bpp * (x + 1)))))[]
    let downE: uint32 = 
        cast[ptr uint32](cast[uint](pixelData.pixels) + 
        cast[uint]((pixelData.pitch * (y - 1) + cast[int32](bpp * x))))[]
    var 
        l1, l2, l3, u1, u2, u3, r1, r2, r3, d1, d2, d3,: uint8
    getRGB(leftE, pixelData.format, l1, l2, l3)
    getRGB(upE, pixelData.format, u1, u2, u3)
    getRGB(rightE, pixelData.format, r1, r2, r3)
    getRGB(downE, pixelData.format, d1, d2, d3)
    return [(l1, l2, l3), (u1, u2, u3), (r1, r2, r3), (d1, d2, d3)]
    #var x: cint = 0
    #var y: cint = 0
    #while y < pixelData.h:
    #    while x < pixelData.w:
