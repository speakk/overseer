local cpml = require('libs/cpml')
--local inspect = require('libs/inspect')
local Vector = require('libs/brinevector/brinevector')
local utils = require('utils/utils')


local components = require('libs/concord').components

local map = {}
local mapColors = {}

local MapSystem = ECS.System("map", {components.collision, "collision"})

function MapSystem:init(camera)
  self.camera = camera

  local grassNoiseScale = 0.05

  for y = 1,self.height,1 do
    local row = {}
    local colorRow = {}
    for x = 1,self.width,1 do
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

  self:recalculateGrid(map, true)

  local generateTileName = function(name) return 'media/tiles/' .. name .. '.png' end
  local tiles = {
    generateTileName('grass01'),
    generateTileName('grass02'),
    generateTileName('dirt01')
  }
  local image = love.graphics.newArrayImage(tiles)
  image:setFilter("nearest", "linear") -- this "linear filter" removes some artifacts if we were to scale the tiles

  self.tilesetBatch = love.graphics.newSpriteBatch(image, 500)

  camera:setWorld(self.cellSize, self.cellSize, self.width * self.cellSize, self.height * self.cellSize)
end


function MapSystem:update(dt) --luacheck: ignore
  if self.gridInvalidated then
    local time = love.timer.getTime()
    if time - self._lastGridUpdateTime > self._gridUpdateInterval then
      self:recalculateGrid(map)
      self.gridInvalidated = false
      self._lastGridUpdateTime = time
    end
  end
end

function MapSystem:getMapColorArray()
  return mapColors
end

-- Window resize
function MapSystem:resize(w, h)
  print("Resize", w, h)
  self.camera:setWindow(0, 0, w, h)
  -- self.lightWorld:refreshScreenSize(w,h)
end

function MapSystem:getMap()
  return map
end

function MapSystem:getSize()
  return Vector(self.width, self.height)
end

function MapSystem:entityAddedTo(entity, pool)
  if pool == self.collision then
    local position = self:pixelsToGridCoordinates(entity:get(components.position).vector)
    map[position.y][position.x] = 1
    self.gridInvalidated = true
  end
end

function MapSystem:entityRemovedFrom(entity, pool)
  if pool == self.collision then
    local position = self:pixelsToGridCoordinates(entity:get(components.position).vector)
    map[position.y][position.x] = 0
    self.gridInvalidated = true
  end
end

function MapSystem:getLastGridUpdateId()
  return self._lastGridUpdateId
end

function MapSystem:pathStillValid(path)
  for node, count in path:iter() do
    if not self.grid:isWalkableAt(node:getX(), node:getY()) then
      return false
    end
  end

  return true
end

function MapSystem:generateSpriteBatch(l, t, w, h)
  self.tilesetBatch:clear()

  local cellSize = self:getCellSize()
  local padding = self:getPadding()
  for rowNum, row in ipairs(map) do
    for cellNum, cellValue in ipairs(row) do --luacheck: ignore
      local drawMargin = cellSize
      local x1 = (cellNum * cellSize)
      local x2 = x1 + cellSize
      local y1 = rowNum * cellSize
      local y2 = y1 + cellSize
      if utils.withinBounds(x1, y1, x2, y2, l, t, l+w, t+h, drawMargin*2) then
        local color = mapColors[rowNum][cellNum]
        local imageArrayIndex = 3
        if color.grass == 1 then
          imageArrayIndex = math.floor(math.random()+0.5)+1
        end
        self.tilesetBatch:addLayer(imageArrayIndex, cellNum*cellSize, rowNum*cellSize, 0, 2, 2)
      end
    end
  end

  return self.tilesetBatch
end

return MapSystem
