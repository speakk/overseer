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
      row[x] = cpml.utils.round(math.random(2)-1)
    end
    map[y] = row
  end

  self.grid = Grid(map)
  local walkable = 0
  self.myFinder = Pathfinder(self.grid, 'JPS', walkable) 
end

function MapSystem:getPath(from, to)
  local path = self.myFinder:getPath(from.x, from.y, to.x, to.y)
  if path then
    print(('Path found! Length: %.2f'):format(path:getLength()))
    for node, count in path:nodes() do
      print(('Step: %d - x: %d - y: %d'):format(count, node:getX(), node:getY()))
    end
  end
end

function MapSystem:update(dt)
  
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

function MapSystem:snapToGridCorner(position)
  return cpml.vec2(cpml.utils.round(position.x / self.cellSize) * self.cellSize, cpml.utils.round(position.y / self.cellSize) * self.cellSize)
end

function MapSystem:snapToGridCenter(position, size)
  size = size or 10
  return self:snapToGridCorner(position) + cpml.vec2((self.cellSize-self.padding-size)/2, (self.cellSize-self.padding-size)/2)
end

function MapSystem:getSizeInPixels()
  return cpml.vec2(self.width*self.cellSize, self.height*self.cellSize)
end

return MapSystem
