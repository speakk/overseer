local cpml = require('libs/cpml')
--local inspect = require('libs/inspect')
local Vector = require('libs/brinevector/brinevector')
local utils = require('utils/utils')

local Grid = require('libs/jumper.grid')
local Pathfinder = require('libs/jumper.pathfinder')

local commonComponents = require('components/common')

local map = {}
local mapColors = {}

local MapSystem = ECS.System({commonComponents.Collision, "collision"})

function MapSystem:init(camera)
  self.width = 150
  self.height = 150
  self.cellSize = 30
  self.padding = 0
  self.camera = camera

  self._lastGridUpdateId = 0

  local grassNoiseScale = 0.05

  for y = 1,self.height,1 do
    local row = {}
    local colorRow = {}
    for x = 1,self.width,1 do
      --row[x] = cpml.utils.round(love.math.noise(x + love.math.random(), y + love.math.random())*0.60)
      -- Right now just initialize map with no collision
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

  camera:setWorld(self.cellSize, self.cellSize, self.width * self.cellSize, self.height * self.cellSize)
end

function MapSystem:getPath(from, to)
  -- from = self:pixelsToGridCoordinates(from)
  -- to = self:pixelsToGridCoordinates(to)
  local toNode = self.grid:getNodeAt(to.x, to.y)

  local toNodesToCheck = self.grid:getNeighbours(toNode)
  table.insert(toNodesToCheck, toNode)
  for _, node in ipairs(toNodesToCheck) do
    local path = self.myFinder:getPath(from.x, from.y, node:getX(), node:getY())
    if path then return path end
  end

  return nil
end

function MapSystem:update(dt) --luacheck: ignore
end

function MapSystem:getCellSize()
  return self.cellSize
end

-- For documentation:
--https://htmlpreview.github.io/?https://raw.githubusercontent.com/Yonaba/Jumper/master/docs/modules/grid.html#Grid:iter
function MapSystem:iter(lx, ly, ex, ey)
  return self.grid:iter(lx, ly, ex, ey)
end

function MapSystem:draw()
  self.camera:draw(function(l,t,w,h)
    for rowNum, row in ipairs(map) do
      for cellNum, cellValue in ipairs(row) do --luacheck: ignore
        local drawMargin = self.cellSize
        local x1 = (cellNum * self.cellSize)
        local x2 = x1 + self.cellSize
        local y1 = rowNum * self.cellSize
        local y2 = y1 + self.cellSize
        if utils.withinBounds(x1, y1, x2, y2, l, t, l+w, t+h, drawMargin) then
          --if x1 > l-drawMargin and x2 < l+w+drawMargin and y1 > t-drawMargin and y2 < t+h+drawMargin then
          --love.graphics.setColor(cellValue*0.7, 0.2, 0.3)
          local color = mapColors[rowNum][cellNum]
          if color.grass == 1 then
            love.graphics.setColor(0.35, 0.4+(color.c*0.1), 0.1)
          else
            love.graphics.setColor(color.a*0.1+0.5, color.a*0.1+0.3, color.c*0.05+0.15)
          end
          love.graphics.rectangle("fill",
          cellNum*self.cellSize,
          rowNum*self.cellSize,
          self.cellSize - self.padding,
          self.cellSize - self.padding
          )
        end
      end
    end
  end)
end

function MapSystem:isPositionWithinBounds(position)
  local left_x, left_y, right_x, right_y = self.grid:getBounds()
  return position.x > left_x and position.x < right_x and position.y > left_y and position.y < right_y
end

function MapSystem:getSize()
  return Vector(self.width, self.height)
end

function MapSystem:clampToWorldBounds(gridPosition)
  return Vector(cpml.utils.clamp(gridPosition.x, 1, self.width), cpml.utils.clamp(gridPosition.y, 1, self.height))
end

-- Marked for optimization
function MapSystem:gridPositionToPixels(gridPosition, positionFlag, entitySize)
  positionFlag = positionFlag or "corner"
  local tilePosition = gridPosition * self.cellSize

  if positionFlag == "center" then
    entitySize = entitySize or 10
    return tilePosition + Vector((self.cellSize-self.padding-entitySize)/2, (self.cellSize-self.padding-entitySize)/2)
  end

  return tilePosition
end

function MapSystem:snapPixelToGrid(pixelPosition, positionFlag, entitySize)
  return self:gridPositionToPixels(self:pixelsToGridCoordinates(pixelPosition, positionFlag, entitySize))
end

function MapSystem:pixelsToGridCoordinates(pixelPosition)
  return Vector(math.floor(pixelPosition.x/self.cellSize), math.floor(pixelPosition.y/self.cellSize))
end

function MapSystem:isCellAvailable(gridPosition)
  return self.grid:isWalkableAt(gridPosition.x, gridPosition.y, self.walkable)
end

function MapSystem:entityAddedTo(entity, pool)
  if pool == self.collision then
    local position = self:pixelsToGridCoordinates(entity:get(commonComponents.Position).vector)
    map[position.y][position.x] = 1
    self:recalculateGrid(map)
  end
end

function MapSystem:entityRemovedFrom(entity, pool)
  if pool == self.collision then
    local position = self:pixelsToGridCoordinates(entity:get(commonComponents.Position).vector)
    map[position.y][position.x] = 0
    self:recalculateGrid(map)
  end
end

function MapSystem:recalculateGrid(newMap, stopEmit)
  self.map = newMap
  self.grid = Grid(newMap)
  self.walkable = 0
  self.myFinder = Pathfinder(self.grid, 'JPS', self.walkable)
  self.myFinder:setMode('ORTHOGONAL')
  self._lastGridUpdateId = self._lastGridUpdateId + 1

  if not stopEmit then
    self:getInstance():emit('gridUpdated')
  end
end

function MapSystem:getLastGridUpdateId()
  return self._lastGridUpdateId
end

return MapSystem
