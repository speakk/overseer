local lume = require 'libs.lume'
local Path = require('libs.jumper.core.path')
local Node = require('libs.jumper.core.node')

-- TODO: Add the fromX stuff
local path = ECS.Component(function(component, path, currentIndex, fromX, fromY, toX, toY)
  print("path component", fromX, fromY, toX, toY)
  component.path = path
  component.fromX = fromX
  component.fromY = fromY
  component.toX = toX
  component.toY = toY
  component.currentIndex = currentIndex or 1
end)
function path:serialize()
  return {
    pathNodes = lume.map(self.path._nodes, function(node) return { x = node._x, y = node._y } end),
    currentIndex = self.currentIndex
  }
end
function path:deserialize(data)
  local gridPath = Path()
  for _, node in ipairs(data.pathNodes) do
    gridPath:addNode(Node(node.x, node.y))
  end

  self.path = gridPath
  self.currentIndex = data.currentIndex
  --return path:__initialize(gridPath, data.currentIndex)
end

return path
