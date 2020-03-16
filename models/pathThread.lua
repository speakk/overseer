local channelMain, channelThread = ...
local Grid = require('libs.jumper.grid')
local Pathfinder = require('libs.jumper.pathfinder')

require 'love.math'

local universe = require('models.universe')
local lume = require('libs.lume')


while true do
  local pathFindObject = channelMain:demand()


  grid = Grid(pathFindObject.map)
  finder = Pathfinder(grid, 'JPS', 0)

  local toNode = grid:getNodeAt(pathFindObject.toX, pathFindObject.toY)

  --if pathFindObject.searchNeighbours then
  local toNodesToCheck = grid:getNeighbours(toNode)
    --print("thread, toNodesToCheck", toNodesToCheck)
  --end

  table.insert(toNodesToCheck, 1, toNode)

  local path = nil
  for _, node in ipairs(toNodesToCheck) do
    path = finder:getPath(pathFindObject.fromX, pathFindObject.fromY, node:getX(), node:getY())
    if path then
      path = lume.map(path._nodes, function(node) return { x = node._x, y = node._y } end)
      break
    end
  end

  channelThread:push(path or "Path not found")
end
