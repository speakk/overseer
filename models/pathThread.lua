local channelMain, channelThread = ...
local Grid = require('libs.jumper.grid')
local Pathfinder = require('libs.jumper.pathfinder')

require 'love.math'

local lume = require('libs.lume')


while true do
  local pathFindObject = channelMain:demand()

  local grid = Grid(pathFindObject.map)
  local finder = Pathfinder(grid, 'JPS', 0)

  local toNode = grid:getNodeAt(pathFindObject.toX, pathFindObject.toY)
  local toNodesToCheck = grid:getNeighbours(toNode)
  table.insert(toNodesToCheck, 1, toNode)

  local path = nil
  for _, nodeToCheck in ipairs(toNodesToCheck) do
    path = finder:getPath(pathFindObject.fromX, pathFindObject.fromY, nodeToCheck:getX(), nodeToCheck:getY())
    if path then
      path = lume.map(path._nodes, function(node) return { x = node._x, y = node._y } end)
      break
    end
  end

  channelThread:push(path or "Path not found")
end
