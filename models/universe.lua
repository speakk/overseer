local Vector = require('libs.brinevector')
local bresenham = require('libs.bresenham')
local Pathfinder = require('libs.jumper.pathfinder')
local Grid = require('libs.jumper.grid')
local cpml = require('libs.cpml')
local lume = require('libs.lume')
local inspect = require('libs.inspect') --luacheck: ignore
local utils = require('utils.utils')
local itemUtils = require('utils.itemUtils')
local world = nil

local universe = {}

local cellSize = 32
local padding = 0
local width = 100
local height = 100
local tilesetBatch = nil
local gridInvalidated = false
local walkable = 0

local cachedCanvas = nil


local map = {}
local entityPosMap = {}
local entitySelectorMap = {}
local occluderMap = {}
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

  mapColors[1][1].grass = 1
  mapColors[2][2].grass = 1
  mapColors[3][3].grass = 1

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

function universe.getPositionString(entity)
  local pixelPosition = entity:get(ECS.c.position).vector
  local position = universe.pixelsToGridCoordinates(pixelPosition)
  local posString = position.x .. ":" .. position.y

  return posString
end

function universe.onOnMapEntityAdded(pool, entity)
  local posString = universe.getPositionString(entity)
  if not entityPosMap[posString] then
    entityPosMap[posString] = {}
  end

  table.insert(entityPosMap[posString], entity)
end


function universe.onOnMapEntityRemoved(pool, entity)
  if not entity:has(ECS.c.position) then return end
  local posString = universe.getPositionString(entity)

  if not entityPosMap[posString] then
    error("Trying to remove nonExistent entity from pos: " .. posString)
  end

  lume.remove(entityPosMap[posString], entity)
end

function universe.onOccluderEntityAdded(pool, entity)
  local posString = universe.getPositionString(entity)

  occluderMap[posString] = 1
end

function universe.onOccluderEntityRemoved(pool, entity)
  if not entity:has(ECS.c.position) then return end
  local posString = universe.getPositionString(entity)

  occluderMap[posString] = 0
end

function universe.isPositionOccluded(gridPosition)
  local posString = gridPosition.x .. ":" .. gridPosition.y

  if occluderMap[posString] == 1 then
    return true
  end

  return false
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
  local tilePosition = gridPosition * cellSize

  if positionFlag == "left_top" then return tilePosition end

  if positionFlag == "center" then
    entitySize = entitySize or 10
    return tilePosition + Vector((cellSize-padding-entitySize)/2, (cellSize-padding-entitySize)/2)
  end

  if positionFlag == "right_bottom" then
    return tilePosition + Vector(cellSize,cellSize)
  end

  return tilePosition
end

function universe.snapPixelToGrid(pixelPosition, positionFlag, entitySize)
  return universe.gridPositionToPixels(universe.pixelsToGridCoordinates(pixelPosition), positionFlag, entitySize)
end

function universe.pixelsToGridCoordinates(pixelPosition)
  return Vector(math.floor(pixelPosition.x/cellSize), math.floor(pixelPosition.y/cellSize))
end

function universe.getCellSize()
  return cellSize
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
function universe.gridIter(lx, ly, ex, ey)
  return grid:iter(lx, ly, ex, ey)
end

function universe.gridIterAround(x, y, radius)
  local node = grid:getNodeAt(x, y)
  return grid:around(node, radius)
end

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

function universe.getOuterBorderCoordinates(x1, y1, x2, y2, fill)
  print("fill", fill)
  if x1 == x2 and y1 == y1 then
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

  local sequence = { topLeftX, topLeftY, topRightX, topRightY, bottomLeftX, bottomLeftY, bottomRightX, bottomRightY, topLeftX, topLeftY }
  --print("sequence", topLeftX, topLeftY, topRightX, topRightY, bottomLeftX, bottomLeftY, bottomRightX, bottomRightY)

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

function universe.getCoordinatesAround(x, y, radius)
  local halfRadius = radius
  local topLeftX = x - halfRadius
  local topLeftY = y - halfRadius
  local bottomRightX = x + halfRadius
  local bottomRightY = y + halfRadius

  return universe.getOuterBorderCoordinates(topLeftX, topLeftY, bottomRightX, bottomRightY)
end

function universe.recalculateGrid(newMap, stopEmit)
  map = newMap
  grid = Grid(newMap)
  cachedCanvas = nil
  myFinder = Pathfinder(grid, 'JPS', walkable)
  --myFinder:setMode('ORTHOGONAL')
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

function universe.draw(l, t, w, h)
  if cachedCanvas then
    return cachedCanvas
  else
    tilesetBatch:clear()
    love.graphics.push()
    love.graphics.origin()
    local scissorX, scissorY, scissorW, scissorH = love.graphics.getScissor()
    love.graphics.setScissor()
    --love.graphics.replaceTransform(transform)
    --love.graphics.translate(-600, -600)
    --love.graphics.setShader()

    for rowNum, row in ipairs(map) do
      for cellNum, cellValue in ipairs(row) do --luacheck: ignore
        -- local drawMargin = cellSize
        -- local x1 = (cellNum * cellSize)
        -- local x2 = x1 + cellSize
        -- local y1 = rowNum * cellSize
        -- local y2 = y1 + cellSize
        -- if utils.withinBounds(x1, y1, x2, y2, l, t, l+w, t+h, drawMargin*2) then
          local color = mapColors[rowNum][cellNum]
          local imageArrayIndex = 3
          if color.grass == 1 then
            imageArrayIndex = math.floor(math.random()+0.5)+1
          end
          local randColor = 0.97+color.a*0.03
          tilesetBatch:setColor(randColor, randColor, randColor, 1)
          tilesetBatch:addLayer(imageArrayIndex, cellNum*cellSize-cellSize, rowNum*cellSize-cellSize, 0, 2, 2)
        -- end
      end
    end


    local canvas = love.graphics.newCanvas(width*cellSize, height*cellSize, { type = "array" })
    love.graphics.setCanvas(canvas, 1)
    local shader = love.graphics.getShader()
    love.graphics.setShader()
    love.graphics.clear()
    love.graphics.draw(tilesetBatch)
    love.graphics.setCanvas()
    cachedCanvas = canvas
    love.graphics.setShader(shader)
    love.graphics.pop()
    love.graphics.setScissor(scissorX, scissorY, scissorW, scissorH)
    return canvas
    --return tilesetBatch
  end
end

function universe.getItemsOnGround(selector)
  print("getItemsOnGround!!!", selector, #entitySelectorMap[selector])
  return entitySelectorMap[selector]
end

function universe.getItemFromGround(itemSelector, gridPosition) --luacheck: ignore
  local items = universe.getItemsOnGround(itemSelector)
  print("Any items anywhere?", itemSelector, items, #items)
  if not items then return nil end

  for _, item in ipairs(items) do
    local position = universe.pixelsToGridCoordinates(item:get(ECS.c.position).vector)
    --print("Position", inspect(position))
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
