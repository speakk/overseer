local Class = require 'libs.hump.class'
local Pathfinder = require('libs.jumper.pathfinder')
local Grid = require('libs.jumper.grid')
local pathThreadPool = require('models.pathThreadPool')

local walkable = 0

return Class({
  init = function(self, map)
    self:mapUpdated(map)
  end,
  mapUpdated = function(self, map)
    self.grid = Grid(map)
    self.myFinder = Pathfinder(self.grid, 'JPS', walkable)
    pathThreadPool.initializePool(self.grid, self.myFinder)
  end,
  isGridWalkable = function(self, gridPosition)
    return self.grid:isWalkableAt(gridPosition.x, gridPosition.y, walkable)
  end,
  gridIter = function(self, lx, ly, ex, ey)
    return self.grid:iter(lx, ly, ex, ey)
  end,
  gridIterAround = function(self, x, y, radius)
    local node = self.grid:getNodeAt(x, y)
    return self.grid:around(node, radius)
  end,
  pathStillValid = function(self, path)
    for node, _ in path:iter() do
      if not self.grid:isWalkableAt(node:getX(), node:getY()) then
        return false
      end
    end

    return true
  end,
  getGrid = function(self)
    return self.grid
  end,
  getFinder = function(self)
    return self.myFinder
  end
})
