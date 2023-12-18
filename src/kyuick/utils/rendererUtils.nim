import sdl2
import sdl2/ttf

proc setDrawColor*(renderer: RendererPtr, col: array[4, int]) =
    renderer.setDrawColor(color(col[0], col[1], col[2], col[3]))
proc sizeText*(font: FontPtr, str: string): tuple[w, h: cint] =
    var w, h: cint = 0
    discard ttf.sizeText(font, cstring(str), addr w, addr h)
    return (w, h)