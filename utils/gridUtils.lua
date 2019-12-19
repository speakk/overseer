local Vector = require('libs/brinevector/brinevector')
local Pathfinder = require('libs/jumper.pathfinder')
local Grid = require('libs/jumper.grid')

local cellSize = 32
local padding = 0
local width = 80
local height = 60

local mapUtils = {}

_lastGridUpdateId = 0
_lastGridUpdateTime = 0
_gridUpdateInterval = 2

local grid

-- Marked for optimization
function mapUtils.gridPositionToPixels(gridPosition, positionFlag, entitySize)
  positionFlag = positionFlag or "corner"
  local tilePosition = gridPosition * cellSize

  if positionFlag == "center" then
    entitySize = entitySize or 10
    return tilePosition + Vector((cellSize-padding-entitySize)/2, (cellSize-padding-entitySize)/2)
  end

  return tilePosition
end

function mapUtils.snapPixelToGrid(pixelPosition, positionFlag, entitySize)
  return gridPositionToPixels(pixelsToGridCoordinates(pixelPosition), positionFlag, entitySize)
end

function mapUtils.pixelsToGridCoordinates(pixelPosition)
  return Vector(math.floor(pixelPosition.x/cellSize), math.floor(pixelPosition.y/cellSize))
end

function mapUtils.getCellSize()
  return cellSize
end

function mapUtils.getPadding()
  return padding
end

function mapUtils.getPath(from, to)
  print("Getting path", from, to)
  local toNode = grid:getNodeAt(to.x, to.y)

  local toNodesToCheck = grid:getNeighbours(toNode)
  table.insert(toNodesToCheck, toNode)
  for _, node in ipairs(toNodesToCheck) do
    local path = myFinder:getPath(from.x, from.y, node:getX(), node:getY())
    if path then return path end
  end

  return nil
end

function mapUtils.isInPosition(position, comparePosition, acceptNeighbours)
  if position == comparePosition then return true end

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

function mapUtils.isPositionWithinBounds(position)
  local left_x, left_y, right_x, right_y = grid:getBounds()
  return position.x > left_x and position.x < right_x and position.y > left_y and position.y < right_y
end


function mapUtils.clampToWorldBounds(gridPosition)
  return Vector(cpml.utils.clamp(gridPosition.x, 1, width), cpml.utils.clamp(gridPosition.y, 1, height))
end


function mapUtils.isCellAvailable(gridPosition)
  return grid:isWalkableAt(gridPosition.x, gridPosition.y, walkable)
end


-- For documentation:
--https://htmlpreview.github.io/?https://raw.githubusercontent.com/Yonaba/Jumper/master/docs/modules/grid.html#Grid:iter
function mapUtils.iter(lx, ly, ex, ey)
  return grid:iter(lx, ly, ex, ey)
end

function mapUtils.recalculateGrid(newMap, stopEmit)
  map = newMap
  grid = Grid(newMap)
  walkable = 0
  myFinder = Pathfinder(self.grid, 'JPS', self.walkable)
  myFinder:setMode('ORTHOGONAL')
  _lastGridUpdateId = _lastGridUpdateId + 1

  if not stopEmit then
    world:emit('gridUpdated')
  end
end



return mapUtils
