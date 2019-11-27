local Grid = require('libs/jumper.grid')
local Pathfinder = require('libs/jumper.pathfinder')

local map, from, to

self.grid = Grid(map)
local walkable = 0
self.myFinder = Pathfinder(self.grid, 'JPS', walkable) 
local path = self.myFinder:getPath(from.x, from.y, to.x, to.y)
