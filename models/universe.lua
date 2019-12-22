local Vector = require('libs.brinevector')
local Pathfinder = require('libs.jumper.pathfinder')
local Grid = require('libs.jumper.grid')
local cpml = require('libs.cpml')
local inspect = require('libs.inspect')
local utils = require('utils.utils')
local world = nil

local universe = {}

universe.cellSize = 32
local padding = 0
local width = 40
local height = 40
local tilesetBatch = nil
local gridInvalidated = false
local walkable = 0


local map = {}
local mapColors = {}

local _lastGridUpdateId = 0
local _lastGridUpdateTime = 0
local _gridUpdateInterval = 2

local grid
local myFinder

function universe:load(newWorld)
  world = newWorld
  local grassNoiseScale = 0.05

  for y = 1,height,1 do
    local row = {}
    local colorRow = {}
    for x = 1,width,1 do
      row[x] = 0
      colorRow[x] = {
        a = love.math.noise(x + love.math.random(), y + love.math.random()),
        b = love.math.noise(x + love.math.random(), y + love.math.random()),
        c = love.math.noise(x + love.math.random(), y + love.math.random()),
        grass = cpml.utils.round(love.math.noise(x * grassNoiseScale, y * grassNoiseScale)-0.3)
      }
    end
    map[y] = row
    mapColors[y] = colorRow
  end

  self.recalculateGrid(map, true)

  local generateTileName = function(name) return 'media/tiles/' .. name .. '.png' end
  local tiles = {
    generateTileName('grass01'),
    generateTileName('grass02'),
    generateTileName('dirt01')
  }
  local image = love.graphics.newArrayImage(tiles)
  image:setFilter("nearest", "linear") -- this "linear filter" removes some artifacts if we were to scale the tiles

  tilesetBatch = love.graphics.newSpriteBatch(image, 500)
end

function universe.getSize()
  return Vector(width, height)
end

function universe.onCollisionEntityAdded(pool, entity)
  --print("Has pos?", inspect(entity))
  local position = universe.pixelsToGridCoordinates(entity:get(ECS.Components.position).vector)
  map[position.y][position.x] = 1
  gridInvalidated = true
end

function universe.onCollisionEntityRemoved(entity)
    local position = universe.pixelsToGridCoordinates(entity:get(ECS.Components.position).vector)
    map[position.y][position.x] = 0
    gridInvalidated = true
end


function universe.update(dt) --luacheck: ignore
  if gridInvalidated then
    local time = love.timer.getTime()
    if time - _lastGridUpdateTime > _gridUpdateInterval then
      universe.recalculateGrid(map)
      gridInvalidated = false
      _lastGridUpdateTime = time
    end
  end
end

-- Marked for optimization
function universe.gridPositionToPixels(gridPosition, positionFlag, entitySize)
  positionFlag = positionFlag or "corner"
  local tilePosition = gridPosition * universe.cellSize

  if positionFlag == "center" then
    entitySize = entitySize or 10
    return tilePosition + Vector((universe.cellSize-padding-entitySize)/2, (universe.cellSize-padding-entitySize)/2)
  end

  return tilePosition
end

function universe.snapPixelToGrid(pixelPosition, positionFlag, entitySize)
  return universe.gridPositionToPixels(universe.pixelsToGridCoordinates(pixelPosition), positionFlag, entitySize)
end

function universe.pixelsToGridCoordinates(pixelPosition)
  return Vector(math.floor(pixelPosition.x/universe.cellSize), math.floor(pixelPosition.y/universe.cellSize))
end

function universe.getCellSize()
  return universe.cellSize
end

function universe.getPadding()
  return padding
end

function universe.getPath(from, to)
  local toNode = grid:getNodeAt(to.x, to.y)

  local toNodesToCheck = grid:getNeighbours(toNode)
  table.insert(toNodesToCheck, toNode)
  for _, node in ipairs(toNodesToCheck) do
    local path = myFinder:getPath(from.x, from.y, node:getX(), node:getY())
    if path then return path end
  end

  return nil
end

function universe.isInPosition(position, comparePosition, acceptNeighbours)
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

function universe.isPositionWithinBounds(position)
  local left_x, left_y, right_x, right_y = grid:getBounds()
  return position.x > left_x and position.x < right_x and position.y > left_y and position.y < right_y
end


function universe.clampToWorldBounds(gridPosition)
  return Vector(cpml.utils.clamp(gridPosition.x, 1, width), cpml.utils.clamp(gridPosition.y, 1, height))
end


function universe.isCellAvailable(gridPosition)
  return grid:isWalkableAt(gridPosition.x, gridPosition.y, walkable)
end


-- For documentation:
--https://htmlpreview.github.io/?https://raw.githubusercontent.com/Yonaba/Jumper/master/docs/modules/grid.html#Grid:iter
function universe.iter(lx, ly, ex, ey)
  return grid:iter(lx, ly, ex, ey)
end

function universe.recalculateGrid(newMap, stopEmit)
  map = newMap
  grid = Grid(newMap)
  myFinder = Pathfinder(grid, 'JPS', walkable)
  myFinder:setMode('ORTHOGONAL')
  _lastGridUpdateId = _lastGridUpdateId + 1

  if not stopEmit then
    world:emit('gridUpdated')
  end
end

function universe.pathStillValid(path)
  for node, _ in path:iter() do
    if not grid:isWalkableAt(node:getX(), node:getY()) then
      return false
    end
  end

  return true
end

function universe.generateSpriteBatch(l, t, w, h)
  tilesetBatch:clear()

  for rowNum, row in ipairs(map) do
    for cellNum, cellValue in ipairs(row) do --luacheck: ignore
      local drawMargin = universe.cellSize
      local x1 = (cellNum * universe.cellSize)
      local x2 = x1 + universe.cellSize
      local y1 = rowNum * universe.cellSize
      local y2 = y1 + universe.cellSize
      if utils.withinBounds(x1, y1, x2, y2, l, t, l+w, t+h, drawMargin*2) then
        local color = mapColors[rowNum][cellNum]
        local imageArrayIndex = 3
        if color.grass == 1 then
          imageArrayIndex = math.floor(math.random()+0.5)+1
        end
        tilesetBatch:addLayer(imageArrayIndex, cellNum*universe.cellSize, rowNum*universe.cellSize, 0, 2, 2)
      end
    end
  end

  return tilesetBatch
end

return universe
