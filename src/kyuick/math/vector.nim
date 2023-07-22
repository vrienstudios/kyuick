type
  Vector* =
    array[3, int]

proc newVector*(a, b, c: int): Vector =
  return [a, b, c]
proc cross*(a, b: Vector): Vector =
    result = [a[0]*b[0], -a[1]*b[1], a[2]*b[2]]
proc dot*(a, b: Vector): int =
  result = a[0]*b[0] + a[1]*b[1] + a[2]*b[2]
proc `*`*(a: int, b: Vector): Vector =
  result = [a*b[0], a*b[1], a*b[2]]