-- VECTRIC LUA SCRIPT
---@diagnostic disable: lowercase-global

require "strict"

g_version = "1.0"
g_title   = "Jigsaw Creator"
---@diagnostic disable-next-line: undefined-global
job       = VectricJob()




--build single edge of length
--left to right
function BuildEdge(jobInfo, startSeed, pieces, length, width)

  math.randomseed(startSeed)

  local tabSize = jobInfo.tabSize

  local edge = {}
  local lastControlAngleEnd = math.rad(math.random(-30, 30))

  local controlLengthShort = (1 - tabSize) * length / 3 * tabSize
  local controlLengthLong = controlLengthShort * 3
  local controlLengthSide = (1 - tabSize) * length / 6

  for i = 1, pieces do
    --direction in which the knob faces
    local direction = math.random(0, 1)
    if direction == 0 then direction = -1 end

    --random x and y offset for edge
    local offset = Vector2D(
      math.random(-length*jobInfo.randomOffsetFactor, length*jobInfo.randomOffsetFactor) *3, 
      math.random(-width * jobInfo.randomOffsetFactor, width * jobInfo.randomOffsetFactor))

    local contour = Contour(0.0)
    contour:AppendPoint(0, 0)

    --bezier points
    local controlAngle1 = math.rad(math.random(0, 35))
    local neck1 = Point2D((1 - tabSize * 1.5) * length / 2, 0) + offset
    contour:BezierTo(
      neck1,
      Point2D(controlLengthSide * math.cos(lastControlAngleEnd), controlLengthSide * math.sin(lastControlAngleEnd)),
      neck1 -
      Vector2D(controlLengthSide * math.cos(controlAngle1), controlLengthSide * math.sin(controlAngle1) * direction))

    local controlAngle2 = math.rad(math.random(90, 150))
    local neck2 = Point2D((1 - tabSize) * length / 2, tabSize * width / 2.3 * direction) + offset
    contour:BezierTo(
      neck2,
      neck1 +
      Vector2D(controlLengthShort * math.cos(controlAngle1), controlLengthShort * math.sin(controlAngle1) * direction),
      neck2 -
      Vector2D(controlLengthShort * math.cos(controlAngle2), controlLengthShort * math.sin(controlAngle2) * direction))

    local controlAngle3 = math.rad(math.random(-20, 20))
    local neck3 = Point2D(length / 2, tabSize * width * direction) + offset
    contour:BezierTo(
      neck3,
      neck2 +
      Vector2D(controlLengthShort * math.cos(controlAngle2), controlLengthShort * math.sin(controlAngle2) * direction),
      neck3 -
      Vector2D(controlLengthLong * math.cos(controlAngle3), controlLengthLong * math.sin(controlAngle3) * direction))

    local controlAngle4 = math.rad(math.random(210, 270))
    local neck4 = Point2D((1 + tabSize) * length / 2, tabSize * width / 2.3 * direction) + offset
    contour:BezierTo(
      neck4,
      neck3 +
      Vector2D(controlLengthLong * math.cos(controlAngle3), controlLengthLong * math.sin(controlAngle3) * direction),
      neck4 -
      Vector2D(controlLengthShort * math.cos(controlAngle4), controlLengthShort * math.sin(controlAngle4) * direction))

    local controlAngle5 = math.rad(math.random(-35, 0))
    local neck5 = Point2D((1 + tabSize * 1.5) * length / 2, 0) + offset
    contour:BezierTo(
      neck5,
      neck4 +
      Vector2D(controlLengthShort * math.cos(controlAngle4), controlLengthShort * math.sin(controlAngle4) * direction),
      neck5 -
      Vector2D(controlLengthShort * math.cos(controlAngle5), controlLengthShort * math.sin(controlAngle5) * direction))

    local controlAngle6 = math.rad(math.random(-30, 30))
    local neck6 = Point2D(length, 0)
    contour:BezierTo(
      neck6,
      neck5 +
      Vector2D(controlLengthSide * math.cos(controlAngle5), controlLengthSide * math.sin(controlAngle5) * direction),
      neck6 -
      Vector2D(controlLengthSide * math.cos(controlAngle6), controlLengthSide * math.sin(controlAngle6) * direction))

    lastControlAngleEnd = controlAngle6 * direction

    edge[i] = contour
  end
  return edge
end

function BuildPuzzlePiece(jobInfo, verticalEdges, horizontalEdges, column, row)
  -- local piece = ContourGroup(true)
  local piece = Contour(0.0)
  -- piece:AppendPoint(0,0)

  --left side
  if column == 1 then
    local edge = Contour(0.0)
    edge:AppendPoint(0, 0)
    edge:LineTo(Point2D(0, jobInfo.pieceHeight))
    piece:AddTail(edge)
  else
    local edge = verticalEdges[column - 1][row]:Clone()
    local rot = RotationMatrix2D(Point2D(0, 0), 90)
    edge:Transform(rot)
    piece:AddTail(edge)
  end

  --top side
  if row == jobInfo.rows then
    local edge = Contour(0.0)
    edge:AppendPoint(0, jobInfo.pieceHeight)
    edge:LineTo(Point2D(jobInfo.pieceWidth, jobInfo.pieceHeight))
    piece:AddTail(edge)
  else
    local edge = horizontalEdges[row][column]:Clone()
    local tr = TranslationMatrix2D(Vector2D(0, jobInfo.pieceHeight))
    edge:Transform(tr)
    piece:AddTail(edge)
  end

  --right side
  if column == jobInfo.columns then
    local edge = Contour(0.0)
    edge:AppendPoint(jobInfo.pieceWidth, jobInfo.pieceHeight)
    edge:LineTo(Point2D(jobInfo.pieceWidth, 0))
    piece:AddTail(edge)
  else
    local edge = verticalEdges[column][row]:Clone()
    local rot = RotationMatrix2D(Point2D(0, 0), 90)
    edge:Transform(rot)
    local tr = TranslationMatrix2D(Vector2D(jobInfo.pieceWidth, 0))
    edge:Transform(tr)
    edge:Reverse()
    piece:AddTail(edge)
  end

  --bottom side
  if row == 1 then
    local edge = Contour(0.0)
    edge:AppendPoint(jobInfo.pieceWidth, 0)
    edge:LineTo(Point2D(0, 0))
    piece:AddTail(edge)
  else
    local edge = horizontalEdges[row - 1][column]:Clone()
    edge:Reverse()
    piece:AddTail(edge)
  end

  return piece
end

function BuildPuzzle(jobInfo)

  math.randomseed(jobInfo.randomseed)

  --edges
  local seedsHorizontal = {}
  for row = 1, jobInfo.rows - 1 do
    seedsHorizontal[row] = math.random(0, 123456789)
  end

  local seedsVertical = {}
  for column = 1, jobInfo.columns - 1 do
    seedsVertical[column] = math.random(0, 123456789)
  end


  local verticalEdges = {}
  local horizontalEdges = {}


  --always build one line at a time, both horizontal and vertical so pieces line up without angles
  --horizontal
  for row = 1, jobInfo.rows - 1 do
    horizontalEdges[row] = BuildEdge(jobInfo, seedsHorizontal[row], jobInfo.columns, jobInfo.pieceWidth,
      jobInfo.pieceHeight)

  end
  --vertical
  for column = 1, jobInfo.columns - 1 do
    verticalEdges[column] = BuildEdge(jobInfo, seedsVertical[column], jobInfo.rows, jobInfo.pieceHeight,
      jobInfo.pieceWidth)

  end


  --assemble the puzzle pieces from the individual contours
  local layer = job.LayerManager:GetLayerWithName("jigsaw")
  for column = 1, jobInfo.columns do
    for row = 1, jobInfo.rows do
      local piece = BuildPuzzlePiece(jobInfo, verticalEdges, horizontalEdges, column, row)

      --transform to correct location on board
      local tr = TranslationMatrix2D(Vector2D(
        (column - 1) * (jobInfo.pieceWidth + jobInfo.pieceClearance),
        (row - 1) * (jobInfo.pieceHeight + jobInfo.pieceClearance)))
      piece:Transform(tr)

      --create cad object
      local cad_object = CreateCadGroup(piece)
      -- and add our object to it
      layer:AddObject(cad_object, true)
    end
  end
  job:Refresh2DView()

end

function OnLuaButton_RandomseedToSystimeButton(dialog)
  dialog:UpdateIntegerField("RandomseedEdit", os.time())

  return true
end

function OnLuaButton_ApplyButton(dialog)
  local jobInfo = {
    rows = dialog:GetIntegerField("RowsEdit"),
    columns = dialog:GetIntegerField("ColumnsEdit"),
    pieceWidth = dialog:GetIntegerField("PieceWidthEdit"),
    pieceHeight = dialog:GetIntegerField("PieceHeightEdit"),

    tabSize = dialog:GetIntegerField("TabSizeEdit") / 100,

    randomOffsetFactor = dialog:GetIntegerField("RandomOffsetFactorEdit") / 100,

    pieceClearance = dialog:GetIntegerField("PieceClearanceEdit"),

    randomseed = dialog:GetIntegerField("RandomseedEdit"),
  }

  BuildPuzzle(jobInfo)

  return true
end

function main(script_path)

  -- Check we have a job loaded
  if not job.Exists then
    DisplayMessageBox("No job open.")
    return false
  end

  local script_html = "file:" .. script_path .. "\\Jigsaw.htm"
  local dialog = HTML_Dialog(false, script_html, 450, 400, g_title)

  dialog:AddLabelField("GadgetTitle", g_title)

  dialog:AddIntegerField("RowsEdit", 3)
  dialog:AddIntegerField("ColumnsEdit", 3)
  dialog:AddIntegerField("PieceWidthEdit", 200)
  dialog:AddIntegerField("PieceHeightEdit", 200)

  dialog:AddIntegerField("TabSizeEdit", 20)

  dialog:AddIntegerField("RandomOffsetFactorEdit", 3)

  dialog:AddIntegerField("PieceClearanceEdit", 0)

  dialog:AddIntegerField("RandomseedEdit", 69)

  -- Show the dialog
  if not dialog:ShowDialog() then
    return false
  end

  return true
end
