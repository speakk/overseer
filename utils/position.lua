local Vector = require('libs.brinevector')
local Gamestate = require("libs.hump.gamestate")
local bresenham = require('libs.bresenham')

local function getPosString(x, y)
  return x .. ":" .. y
end

local function addIfNotExist(existTable, posTable, x, y)
  local posString = getPosString(x, y)
  if not existTable[posString] then
    table.insert(posTable, Vector(x, y))
    existTable[posString] = 1
  end
end

local getOuterBorderCoordinates = function(x1, y1, x2, y2, fill)
  if x1 == x2 and y1 == y2 then
    return { Vector(x1, y1) }
  end

  local topLeftX = x1
  local topLeftY = y1
  local topRightX = x2
  local topRightY = y1
  local bottomLeftX = x2
  local bottomLeftY = y2
  local bottomRightX = x1
  local bottomRightY = y2

  -- Quick & dirty way of checking if coordinate already exists before adding
  local existing = {}

  local sequence = { topLeftX, topLeftY,
  topRightX, topRightY,
  bottomLeftX, bottomLeftY,
  bottomRightX, bottomRightY,
  topLeftX, topLeftY }

  local coordinates = {}
  for i = 1,#sequence-2,2 do
    local startX = sequence[i]
    local startY = sequence[i+1]
    local endX = sequence[i+2]
    local endY = sequence[i+3]

    -- Ensure the coordinates aren't the same as previous one (line width/height 1)

    --print(x, y, "around: ", startX, startY, endX, endY)

    bresenham.los(startX, startY, endX, endY, function(x, y)
      -- Do not add end until the end of sequence, otherwise we'll have duplicates
      if i < #sequence-2 and x == endX and y == endY then
        return false
      end
      --print("Coordinates,", x, y)
      addIfNotExist(existing, coordinates, x, y)
      --table.insert(coordinates, Vector(x, y))
      return true
    end)
  end

  if fill then
    for x = x1+1,x2-1 do
      for y = y1+1,y2-1 do
        addIfNotExist(existing, coordinates, x, y)
        --table.insert(coordinates, Vector(x, y))
      end
    end
  end

  return coordinates
end

local getCoordinatesAround = function(x, y, radius)
  local halfRadius = radius
  local topLeftX = x - halfRadius
  local topLeftY = y - halfRadius
  local bottomRightX = x + halfRadius
  local bottomRightY = y + halfRadius

  return getOuterBorderCoordinates(topLeftX, topLeftY, bottomRightX, bottomRightY)
end


-- Marked for optimization
local gridPositionToPixels = function(gridPosition, positionFlag, entitySize)
  local cellSize = Gamestate.current().mapConfig.cellSize
  positionFlag = positionFlag or "left_top"
  local tilePosition = gridPosition * cellSize

  if positionFlag == "left_top" then return tilePosition end

  if positionFlag == "center" then
    entitySize = entitySize or 10
    return tilePosition + Vector((cellSize-entitySize)/2, (cellSize-entitySize)/2)
  end

  if positionFlag == "right_bottom" then
    return tilePosition + Vector(cellSize,cellSize)
  end

  return tilePosition
end

local pixelsToGridCoordinates = function(pixelPosition)
  local cellSize = Gamestate.current().mapConfig.cellSize
  return Vector(math.floor(pixelPosition.x/cellSize), math.floor(pixelPosition.y/cellSize))
end

local snapPixelToGrid = function(pixelPosition, positionFlag, entitySize)
  return gridPositionToPixels(pixelsToGridCoordinates(pixelPosition), positionFlag, entitySize)
end

local isPositionWithinArea = function(position, l, t, w, h)
  return position.x > l and position.x < l+w and position.y > t and position.y < t+h
end

local isInPosition = function(position, comparePosition, acceptNeighbours)
  if position == comparePosition then return true end

  local grid = Gamestate.pathFindGrid:getGrid()

  if acceptNeighbours then
    local toNode = grid:getNodeAt(comparePosition.x, comparePosition.y)
    for clearance = 1,2 do
      for node in grid:around(toNode, clearance) do
        if Vector(node:getX(), node:getY()) == position then return true end
      end
    end
  end

  return false
end

local isPositionWalkable = function(position)
  local pathFindGrid = Gamestate.current().pathFindGrid
  return pathFindGrid.isGridWalkable(position)
end

return {
  getOuterBorderCoordinates = getOuterBorderCoordinates,
  getCoordinatesAround = getCoordinatesAround,
  gridPositionToPixels = gridPositionToPixels,
  snapPixelToGrid = snapPixelToGrid,
  pixelsToGridCoordinates = pixelsToGridCoordinates,
  isPositionWithinArea = isPositionWithinArea,
  isInPosition = isInPosition,
  isPositionWalkable = isPositionWalkable
}
