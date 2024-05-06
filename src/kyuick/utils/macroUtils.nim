import macros
import strutils




  #obj.x = x
  #obj.y = y
  #obj.width = width
  #obj.height = height
  #obj.canClick = canClick
  #obj.canHover = canHover
  #obj.autoFocusable = autoFocusable
  #obj.backgroundColor = backgroundColor
  #obj.foregroundColor = foregroundColor
  #obj.texture = texture
  #obj.render = render
  #obj.hoverRender = hoverRender
  #obj.onLeftClick = onLeftClick
  #obj.onKeyDown = onKeyDown
  #obj.onHoverStatusChange = onHoverStatusChange
  #obj.parent = parent
  #obj.passthrough = passthrough
macro constructKyuickDefaults*(x: typed): untyped =
  echo "------------------------"
  result = newLit(x.getTypeImpl.treeRepr)
  echo result
  var objType = x.getType()
  while objType[1].kind == nnkSym:
    objType = getType(objType[1])
  echo treeRepr(objType)
  error "stop"
macro uiCon*(uiType, body: untyped): untyped =
  var uiName: string = ""
  if uiType.kind == nnkStrLit or uiType.kind == nnkIdent:
    uiName = $uiType
  else: error "UI NOT SET"
  result = newStmtList()
  var construct = newNimNode(nnkObjConstr)
  construct.add newIdentNode(uiName)
  for node in body.children:
    if node.kind != nnkCommand: error "only accepts nnkCommand"
    var expreq = newNimNode(nnkExprColonExpr)
    expreq.add newIdentNode($node[0])
    expreq.add node[1]
    construct.add expreq
  result.add construct
macro uiGen*(uiType, body: untyped): untyped =
  var uiName: string = ""
  if uiType.kind == nnkStrLit or uiType.kind == nnkIdent:
    uiName = $uiType
  else: error "UI NOT SET | $#" % [$uiType.kind]
  result = newStmtList()
  var call = newNimNode(nnkCall)
  call.add newIdentNode("new" & uiName)
  for node in body.children:
    if node.kind != nnkCommand: error "\nGot \n$#\nOnly accepts Command" % [treerepr(node)]
    var expreq = newNimNode(nnkExprEqExpr)
    expreq.add newIdentNode($node[0])
    expreq.add node[1]
    call.add expreq
  result.add call
  echo call.astGenRepr()
macro hGrid*(gridType, body: untyped): untyped =
  result = newStmtList()
  var gridCall = newNimNode(nnkCall)
  gridCall.add newIdentNode("newHorizontalGrid")
  var otherEl: seq[NimNode] = @[]
  for n in body.children:
    if n.kind != nnkAsgn:
        otherEl.add n
        continue
    var expreq = newNimNode(nnkExprEqExpr)
    expreq.add newIdentNode($n[0])
    expreq.add n[1]
    gridCall.add expreq
  # TODO: FINISH
  for n in otherEl:
    continue