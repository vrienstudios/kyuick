type
  Matrix[W, H: static[int]] =
    array[1..W, array[1..H, int]]

proc `+`[W, H](a, b: Matrix[W, H]): Matrix[W, H] =
    for i in 1..high(a):
        for j in 1..high(a[0]):
            result[i][j] = a[i][j] + b[i][j]
proc `-`[W, H](a, b: Matrix[W, H]): Matrix[W, H] =
    for i in 1..high(a):
        for j in 1..high(a[0]):
            result[i][j] = a[i][j] - b[i][j]
proc `*`[W, H](a, b: Matrix[W, H]): Matrix[W, H] =
    for i in 1..high(a):
        return

