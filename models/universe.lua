local Vector = require('libs.brinevector')
local Pathfinder = require('libs.jumper.pathfinder')
local Grid = require('libs.jumper.grid')
local cpml = require('libs.cpml')
local lume = require('libs.lume')
local inspect = require('libs.inspect') --luacheck: ignore
local utils = require('utils.utils')
local itemUtils = require('utils.itemUtils')
local world = nil

local universe = {}

universe.cellSize = 32
local padding = 0
local width = 100
local height = 100
local tilesetBatch = nil
local gridInvalidated = false
local walkable = 0


local map = {}
local entityPosMap = {}
local entitySelectorMap = {}
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

function universe.onCollisionEntityAdded(pool, entity) --luacheck: ignore
  local position = universe.pixelsToGridCoordinates(entity:get(ECS.c.position).vector)
  map[position.y][position.x] = 1
  gridInvalidated = true
end

function universe.onCollisionEntityRemoved(pool, entity)
    local position = universe.pixelsToGridCoordinates(entity:get(ECS.c.position).vector)
    map[position.y][position.x] = 0
    gridInvalidated = true
end

function universe.onOnMapEntityAdded(pool, entity)
  local pixelPosition = entity:get(ECS.c.position).vector
  local position = universe.pixelsToGridCoordinates(pixelPosition)
  local posString = position.x .. ":" .. position.y
  if not entityPosMap[posString] then
    entityPosMap[posString] = {}
  end

  table.insert(entityPosMap[posString], entity)
end

function universe.onOnMapItemAdded(pool, entity)
  local itemComponent = entity:get(ECS.c.item)
  local selector = itemComponent.selector
  if not entitySelectorMap[selector] then
    entitySelectorMap[selector] = {}
  end

  table.insert(entitySelectorMap[selector], entity)
end

function universe.onOnMapItemRemoved(pool, entity)
  local itemComponent = entity:get(ECS.c.item)
  local selector = itemComponent.selector

  local items = entitySelectorMap[selector]
  if items then
    lume.remove(items, entity)
  end
end

function universe.onOnMapEntityRemoved(pool, entity)
  if not entity:has(ECS.c.position) then return end
  local positionComponent = entity:get(ECS.c.position)
  local positionPixels = positionComponent.vector
  local position = universe.pixelsToGridCoordinates(positionPixels)
  local posString = position.x .. ":" .. position.y

  if not entityPosMap[posString] then
    error("Trying to remove nonExistent entity from pos: " .. posString)
  end

  lume.remove(entityPosMap[posString], entity)
end

function universe.getEntitiesInLocation(gridPosition)
  local posString = gridPosition.x .. ":" .. gridPosition.y

  if not entityPosMap[posString] then
    return {}
  end

  return entityPosMap[posString]
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
  positionFlag = positionFlag or "left_top"
  local tilePosition = gridPosition * universe.cellSize

  if positionFlag == "left_top" then return tilePosition end

  if positionFlag == "center" then
    entitySize = entitySize or 10
    return tilePosition + Vector((universe.cellSize-padding-entitySize)/2, (universe.cellSize-padding-entitySize)/2)
  end

  if positionFlag == "right_bottom" then
    return tilePosition + Vector(universe.cellSize,universe.cellSize)
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

function universe.findPathToClosestEmptyCell(gridPosition)
  local node = grid:getNodeAt(gridPosition.x, gridPosition.y)

  if not universe.isCellAvailable(gridPosition) then
    local radius = 1
    while radius < 10 do
      for nodeAround in grid:around(node, radius) do
        if universe.isCellAvailable(Vector(nodeAround:getX(), nodeAround:getY())) then
          node = nodeAround
          break
        end
        if node then break end
      end

      radius = radius +1
    end
  end

  return universe.getPath(gridPosition, Vector(node:getX(), node:getY()))
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

function universe.getItemsOnGround(selector)
  return entitySelectorMap[selector]
end

function universe.getItemFromGround(itemSelector, gridPosition) --luacheck: ignore
  local items = universe.getItemsOnGround(itemSelector)
  if not items then return nil end

  for _, item in ipairs(items) do
    local position = universe.pixelsToGridCoordinates(item:get(ECS.c.position).vector)
    if universe.isInPosition(gridPosition, position, true) then
      return item
    end
  end

  return nil -- Could not find item on ground
end

function universe.takeItemFromGround(originalItem, amount)
  local selector = originalItem:get(ECS.c.item).selector
  local item, wasSplit = itemUtils.splitItemStackIfNeeded(originalItem, amount)

  if not wasSplit then
    lume.remove(entitySelectorMap[selector], originalItem)
    originalItem:remove(ECS.c.position)
    originalItem:remove(ECS.c.onMap)
  end

  return item
end


return universe
