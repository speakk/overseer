local Class = require 'libs.hump.class'
local luabt = require 'libs.luabt'
local inspect = require 'libs.inspect'

return Class {
  -- STATIC
  init = function(self, actor, world)
    self.tasks = require 'models.ai.taskTypes'
    local blackboard = self.initializeBlackboard(actor)
    local commonNodes = self.initializeCommonNodes(actor, blackboard)
    print("commonNodes in init", commonNodes)
    local nodes = self.initializeNodes(self, actor, world, blackboard)
    local tree = self.initializeTree(commonNodes, nodes)
    --print("Hurp", actor)
    self.behaviourTree = luabt.create(tree, blackboard)
  end,
  run = function(self, treeDt)
    return self.behaviourTree(treeDt)
  end,
  initializeCommonNodes = function(actor, blackboard)
    local commonNodesDir = "models/ai/commonNodes"
    return functional.reduce(love.filesystem.getDirectoryItems(commonNodesDir), function(result, fileName)
      local name = string.gsub(fileName, ".lua", "")
      result[name] = require(string.gsub(commonNodesDir .. "/" .. name, "/", "."))(actor, blackboard)
      print("Added to commonNodes", name, result[name])
      return result
    end, {})
  end
}
