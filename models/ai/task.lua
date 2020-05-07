local Class = require 'libs.hump.class'
local luabt = require 'libs.luabt'

local tasksDir = "model/ai/tasks"
local types = functional.reduce(love.filesystem.getDirectoryItems(tasksDir), function(result, fileName)
  local name = string.gsub(fileName, ".lua", "")
  result[name] = require(string.gsub(tasksDir, "/", "."))
  return result
end, {})

local commonNodesDir = "model/ai/sharedActions"
local commonNodes = functional.reduce(love.filesystem.getDirectoryItems(commonNodesDir), function(result, fileName)
  local name = string.gsub(fileName, ".lua", "")
  result[name] = require(string.gsub(commonNodesDir, "/", "."))
  return result
end, {})

return Class {
  -- STATIC
  types = types,
  init = function(self, actor, world)
    local blackboard = self.initializeBlackboard(actor)
    local nodes = self.initializeNodes(self, actor, world, blackboard)
    local tree = self.initializeTree(commonNodes, nodes)
    self.behaviourTree = luabt.create(tree, blackboard)
  end,
  run = function(self, treeDt)
    return self.behaviourTree(treeDt)
  end
}
