local luabt = require('libs.luabt')

local positionUtils = require('utils.position')
local entityRegistry = require('models.entityRegistry')
local GotoAction = require('models.ai.sharedActions.goto')

local getNodes = function(blackboard)
  return {
    progressDestruct = function()
      if not blackboard.lastBuildTick then
        blackboard.lastBuildTick = love.timer.getTime()
      end
      local constructionSkill = blackboard.actor.settler.skills.construction
      if blackboard.durability.value > 0 then
        print("Progress destruct!, actor work: ", blackboard.actor.work)
        local time = love.timer.getTime()
        local delta = time - blackboard.lastBuildTick
        print("delta", time, constructionSkill * delta)
        blackboard.world:emit('destructProgress', blackboard.durability, constructionSkill * delta)
        blackboard.lastBuildTick = time
        return true
      else
        print("Destruct finished!", blackboard.durability, "actorid", blackboard.actor, "WORK:", blackboard.actor.work)
        blackboard.finished = true
        print("path component in bp", blackboard.actor, blackboard.actor.path)
        blackboard.actor:remove("path")

        return false, true
      end
    end
  }
end

local function createTree(actor, world, jobType)
  local target = entityRegistry.get(actor.work.jobId)
  print("Setting target", target)
  local durability = target.durability
  local targetGridPosition = positionUtils.pixelsToGridCoordinates(target.position.vector)

  local blackboard = {
    target = target,
    actor = actor,
    durability = durability,
    targetGridPosition = targetGridPosition,
    world = world,
    jobType = jobType
  }

  local commonNodes = {
    gotoAction = GotoAction(blackboard)
  }

  local nodes = getNodes(blackboard)

  local tree = {
    type = "sequence",
    children = {
      commonNodes.gotoAction,
      nodes.progressDestruct
    }
  }

  return luabt.create(tree)
end

return {
  createTree = createTree
}
