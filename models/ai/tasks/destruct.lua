local BehaviourTree = require('libs.behaviourtree')
local lume = require('libs.lume')

local positionUtils = require('utils.position')
local entityRegistry = require('models.entityRegistry')
local UntilDecorator = require('models.ai.decorators.until')
local GotoAction = require('models.ai.sharedActions.goto')

local progressDestruct = {
  start = function(task, blackboard)
    blackboard.lastBuildTick = love.timer.getTime()
  end,
  run = function(task, blackboard)
    local constructionSkill = blackboard.actor.settler.skills.construction
    if blackboard.durability.value > 0 then
      print("Progress destruct!, actor work: ", blackboard.actor.work)
      local time = love.timer.getTime()
      local delta = time - blackboard.lastBuildTick
      print("delta", time, constructionSkill * delta)
      blackboard.world:emit('destructProgress', blackboard.durability, constructionSkill * delta)
      blackboard.lastBuildTick = time
      task:running()
      return
    else
      print("Destruct finished!", blackboard.durability, "actorid", blackboard.actor, "WORK:", blackboard.actor.work)
      blackboard.finished = true
      print("path component in bp", blackboard.actor, blackboard.actor.path)
      blackboard.actor:remove("path")

      task:success()
    end
  end
}

local function createTree(actor, world, jobType)
  local progressDestruct = BehaviourTree.Task:new(progressDestruct)
  local gotoAction = GotoAction()

  local target = entityRegistry.get(actor.work.jobId)
  print("Setting target", target)
  local durability = target.durability
  local targetGridPosition = positionUtils.pixelsToGridCoordinates(target.position.vector)
  local tree = BehaviourTree:new({
    tree = BehaviourTree.Sequence:new({
      nodes = {
        gotoAction,
        progressDestruct
      }
    })
  })

  tree:setObject({
    target = target,
    actor = actor,
    inventory = inventory,
    durability = durability,
    targetGridPosition = targetGridPosition,
    world = world,
    jobType = jobType
  })

  return tree
end

return {
  createTree = createTree
}
