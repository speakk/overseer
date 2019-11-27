local cpml = require('libs/cpml')
local camera = require('camera')
local commonComponents = require('components/common')
local MapSystem = ECS.System()

local Grid = require('libs/jumper.grid')
local Pathfinder = require('libs/jumper.pathfinder')

local map = {}

function MapSystem:init()
  self.width = 100
  self.height = 100
  self.cellSize = 30
  self.padding = 2

  for y = 1,self.height,1 do
    local row = {}
    for x = 1,self.width,1 do
      row[x] = cpml.utils.round(love.math.noise(x + love.math.random(), y + love.math.random())*0.7)
    end
    map[y] = row
  end

  self.grid = Grid(map)
  local walkable = 0
  self.myFinder = Pathfinder(self.grid, 'JPS', walkable) 
end

function MapSystem:getPath(from, to)
  -- from = self:pixelsToGridCoordinates(from)
  -- to = self:pixelsToGridCoordinates(to)
  local path = self.myFinder:getPath(from.x, from.y, to.x, to.y)
  return path
end

function MapSystem:update(dt)
  
end

function MapSystem:getCellSize()
  return self.cellSize
end

function MapSystem:draw()
  camera:set()
  for rowNum, row in ipairs(map) do
    for cellNum, cellValue in ipairs(row) do
      love.graphics.setColor(cellValue*0.7, 0.2, 0.3)
      love.graphics.rectangle("fill", cellNum*self.cellSize, rowNum*self.cellSize, self.cellSize - self.padding, self.cellSize - self.padding)
    end
  end
  camera:unset()
end

function MapSystem:isPositionWithinBounds(position)
  local left_x, left_y, right_x, right_y = self.grid:getBounds()
  return position.x > left_x and position.x < right_x and position.y > left_y and position.y < right_y
end

function MapSystem:getSize()
  return cpml.vec2(self.width, self.height)
end

function MapSystem:clampToWorldBounds(gridPosition)
  return cpml.vec2(cpml.utils.clamp(gridPosition.x, 1, self.width), cpml.utils.clamp(gridPosition.y, 1, self.height)) 
end
 
-- function MapSystem:getSizeInPixels()
--   return cpml.vec2(self.width*self.cellSize, self.height*self.cellSize)
-- end

function MapSystem:gridPositionToPixels(gridPosition, positionFlag, entitySize)
  positionFlag = positionFlag or "corner"
  --local tilePosition = cpml.vec2(math.floor(gridPosition.x / self.cellSize) * self.cellSize, math.floor(gridPosition.y / self.cellSize) * self.cellSize)
  local tilePosition = cpml.vec2(gridPosition.x * self.cellSize, gridPosition.y * self.cellSize)

  if positionFlag == "center" then
    entitySize = entitySize or 10
    return tilePosition + cpml.vec2((self.cellSize-self.padding-entitySize)/2, (self.cellSize-self.padding-entitySize)/2)
  end

  return tilePosition
end

function MapSystem:snapPixelToGrid(pixelPosition, positionFlag, entitySize)
  return self:gridPositionToPixels(self:pixelsToGridCoordinates(pixelPosition, positionFlag, entitySize))
end

function MapSystem:pixelsToGridCoordinates(pixelPosition)
  return cpml.vec2(math.floor(pixelPosition.x/self.cellSize), math.floor(pixelPosition.y/self.cellSize))
end

function MapSystem:isCellAvailable(gridPosition)
  return self.grid:isWalkableAt(gridPosition.x, gridPosition.y)
end

return MapSystem
