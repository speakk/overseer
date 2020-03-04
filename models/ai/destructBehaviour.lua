local BehaviourTree = require('libs.behaviourtree')
local lume = require('libs.lume')

local universe = require('models.universe')
local entityManager = require('models.entityManager')
local UntilDecorator = require('models.ai.decorators.until')
local GotoAction = require('models.ai.sharedActions.goto')

local areWeAtTarget = {
  run = function(task, blackboard)
    print("destruct areWeAtTarget")
    local gridPosition = universe.pixelsToGridCoordinates(blackboard.actor:get(ECS.c.position).vector)

    if universe.isInPosition(gridPosition, blackboard.targetGridPosition, true) then
      print("areWeAtTarget true")
      task:success()
    else
      --print("areWeAtTarget false")
      task:fail()
    end
  end
}

local progressDestruct = {
  start = function(task, blackboard)
    blackboard.lastBuildTick = love.timer.getTime()
  end,
  run = function(task, blackboard)
    local constructionSkill = blackboard.actor:get(ECS.c.actor).skills.construction
    if blackboard.constructionComponent.durability > 0 then
      print("Progress destruct!")
      local time = love.timer.getTime()
      local delta = time - blackboard.lastBuildTick
      print("delta", time, constructionSkill * delta)
      blackboard.world:emit('destructProgress', blackboard.constructionComponent, constructionSkill * delta)
      blackboard.lastBuildTick = time
      task:running()
      return
    else
      print("Destruct finished!", blackboard.constructionComponent, "actorid", blackboard.actor)
      blackboard.world:emit("treeFinished", blackboard.actor, blackboard.jobType)
      --blackboard.world:emit("finishWork", blackboard.actor, blackboard.actor:get(ECS.c.work).jobId)
      --blackboard.world:emit("jobFinished", blackboard.job)
      print("path component in bp", blackboard.actor, blackboard.actor:get(ECS.c.path))
      blackboard.actor:remove(ECS.c.path)

      blackboard.world:emit("immediateDestroy", blackboard.target)

      task:success()
    end
  end
}

function createTree(actor, world, jobType)
  local areWeAtTarget = BehaviourTree.Task:new(areWeAtTarget)

  local getPathToTarget = BehaviourTree.Task:new(getPathToTarget)
  local progressDestruct = BehaviourTree.Task:new(progressDestruct)
  local gotoAction = GotoAction()

  local target = entityManager.get(actor:get(ECS.c.work).jobId)
  local constructionComponent = target:get(ECS.c.construction)
  local targetGridPosition = universe.pixelsToGridCoordinates(target:get(ECS.c.position).vector)
  local tree = BehaviourTree:new({
    tree = BehaviourTree.Priority:new({
      nodes = {
        BehaviourTree.Sequence:new({
          nodes = {
            BehaviourTree.Priority:new({
              nodes = {
                areWeAtTarget,
                "goto",
              }
            }),
            progressDestruct
          }
        }),
      }
    })

  })

  tree:setObject({
    target = target,
    actor = actor,
    inventory = inventory,
    constructionComponent = constructionComponent,
    targetGridPosition = targetGridPosition,
    world = world,
    jobType = jobType
  })

  return tree
end

return {
  createTree = createTree
}
