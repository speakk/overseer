local BehaviourTree = require('libs.behaviourtree')
local lume = require('libs.lume')

local universe = require('models.universe')
local entityManager = require('models.entityManager')
local UntilDecorator = require('models.ai.decorators.until')

local areWeAtTarget = {
  run = function(task, blackboard)
    print("destruct areWeAtTarget")
    local gridPosition = universe.pixelsToGridCoordinates(blackboard.settler:get(ECS.c.position).vector)

    if universe.isInPosition(gridPosition, blackboard.targetGridPosition, true) then
      print("areWeAtTarget true")
      task:success()
    else
      --print("areWeAtTarget false")
      task:fail()
    end
  end
}

local getPathToTarget = {
  run = function(task, blackboard)
    print("destruct getPathToTarget")
    if blackboard.settler:has(ECS.c.path) then
      if blackboard.settler:get(ECS.c.path).finished then
        print("destruct Path finished, success")
        blackboard.settler:remove(ECS.c.path)
        task:success()
        return
      else
        task:running()
        return
      end
    end

    local path = universe.getPath(
    universe.pixelsToGridCoordinates(blackboard.settler:get(ECS.c.position).vector),
    blackboard.targetGridPosition
    )

    print("To coords", blackboard.targetGridPosition)

    if not path then
      --print("No path, failing")
      task:fail()
      return
    end

    blackboard.settler:give(ECS.c.path, path)
    task:running()
  end
}

local progressDestruct = {
  start = function(task, blackboard)
    blackboard.lastBuildTick = love.timer.getTime()
  end,
  run = function(task, blackboard)
    local constructionSkill = blackboard.settler:get(ECS.c.settler).skills.construction
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
      print("Destruct finished!", blackboard.constructionComponent, "settlerid", blackboard.settler)
      blackboard.world:emit("treeFinished", blackboard.settler, blackboard.jobType)
      --blackboard.world:emit("finishWork", blackboard.settler, blackboard.settler:get(ECS.c.work).jobId)
      --blackboard.world:emit("jobFinished", blackboard.job)
      print("path component in bp", blackboard.settler, blackboard.settler:get(ECS.c.path))
      blackboard.settler:remove(ECS.c.path)

      blackboard.world:emit("immediateDestroy", blackboard.target)

      task:success()
    end
  end
}

function createTree(settler, world, jobType)
  local areWeAtTarget = BehaviourTree.Task:new(areWeAtTarget)

  local getPathToTarget = BehaviourTree.Task:new(getPathToTarget)
  local progressDestruct = BehaviourTree.Task:new(progressDestruct)

  local target = entityManager.get(settler:get(ECS.c.work).jobId)
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
                getPathToTarget,
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
    settler = settler,
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
