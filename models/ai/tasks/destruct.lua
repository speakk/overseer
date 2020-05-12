local Class = require 'libs.hump.class'

local positionUtils = require('utils.position')
local entityRegistry = require('models.entityRegistry')
local Task = require('models.ai.task')

return Class {
  __includes = Task,
  init = function(self, actor, world)
    Task.init(self, actor, world)
  end,
  initializeBlackboard = function(actor)
    local target = entityRegistry.get(actor.work.jobId)
    print("Setting target", target)
    local durability = target.durability
    local targetGridPosition = positionUtils.pixelsToGridCoordinates(target.position.vector)

    return {
      target = target,
      durability = durability,
      targetGridPosition = targetGridPosition
    }
  end,
  initializeTree = function(commonNodes, nodes)
    return {
      type = "sequence",
      children = {
        commonNodes.goto,
        nodes.progressDestruct
      }
    }
  end,
  initializeNodes = function(_, actor, world, blackboard)
    return {
      progressDestruct = function()
        if not blackboard.lastBuildTick then
          blackboard.lastBuildTick = love.timer.getTime()
        end
        local constructionSkill = actor.settler.skills.construction
        if blackboard.durability.value > 0 then
          print("Progress destruct!, actor work: ", actor.work)
          local time = love.timer.getTime()
          local delta = time - blackboard.lastBuildTick
          print("delta", time, constructionSkill * delta)
          world:emit('destructProgress', blackboard.durability, constructionSkill * delta)
          blackboard.lastBuildTick = time
          return true
        else
          print("Destruct finished!", blackboard.durability, "actorid", actor, "WORK:", actor.work)
          blackboard.finished = true
          print("path component in bp", actor, actor.path)
          actor:remove("path")

          return false, true
        end
      end
    }
  end
}
