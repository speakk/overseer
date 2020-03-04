local BehaviourTree = require('libs.behaviourtree')
local lume = require('libs.lume')

local universe = require('models.universe')
local entityManager = require('models.entityManager')
local UntilDecorator = require('models.ai.decorators.until')
local GotoAction = require('models.ai.sharedActions.goto')

-- LEAF NODES

local isBluePrintReadyToBuild = {
  run = function(task, blackboard)
    --print("isBluePrintReadyToBuild")
    local bluePrint = blackboard.target
    if bluePrint:get(ECS.c.target).finished then return false end

    local bluePrintComponent = bluePrint:get(ECS.c.bluePrintJob)
    local requirements = bluePrint:get(ECS.c.item).itemData.requirements

    for selector, amount in pairs(requirements) do --luacheck: ignore
      local itemId = bluePrint:get(ECS.c.inventory):findItem(selector)
      local item = entityManager.get(itemId)
      --local itemInv = itemUtils.getInventoryItemBySelector(bluePrint:get(ECS.c.inventory).inventory, selector)
      -- print("Blueprint pos", universe.pixelsToGridCoordinates(bluePrint:get(ECS.c.position).vector))
      -- local itemInPosition = itemUtils.getItemFromGround(selector, universe.pixelsToGridCoordinates(bluePrint:get(ECS.c.position).vector))
      if not item or item:get(ECS.c.amount).amount < amount then
        --print("Didn't have no!", selector)
        --print("Failing isBluePrintReadyToBuild")
        task:fail()
        return
      end
    end

    --print("Success isBluePrintReadyToBuild")
    task:success()
  end
}

local areWeAtTarget = {
  run = function(task, blackboard)
    --print("bluePrint areWeAtTarget")
    local gridPosition = universe.pixelsToGridCoordinates(blackboard.actor:get(ECS.c.position).vector)
    local targetPosition = universe.pixelsToGridCoordinates(blackboard.target:get(ECS.c.position).vector)

    if universe.isInPosition(gridPosition, targetPosition, true) then
      --print("areWeAtTarget true")
      task:success()
    else
      --print("areWeAtTarget false")
      task:fail()
    end
  end
}

local isBluePrintFinished = {
  run = function(task, blackboard)
    --print("isBluePrintFinished")
    if blackboard.bluePrintComponent.buildProgress >= 100 then
      print("Blue print finished!", blackboard.bluePrintComponent, "actorid", blackboard.actor)
      blackboard.world:emit("treeFinished", blackboard.actor, blackboard.jobType)
      blackboard.world:emit("finishWork", blackboard.actor, blackboard.actor:get(ECS.c.work).jobId)
      blackboard.world:emit("targetFinished", blackboard.target)
      print("path component in bp", blackboard.actor, blackboard.actor:get(ECS.c.path))
      blackboard.actor:remove(ECS.c.path)
      task:success()
    else
      task:fail()
    end
  end
}

local progressBuilding = {
  start = function(task, blackboard)
    blackboard.lastBuildTick = love.timer.getTime()
  end,
  run = function(task, blackboard)
    local constructionSkill = blackboard.actor:get(ECS.c.actor).skills.construction
    if blackboard.bluePrintComponent.buildProgress < 100 then
      print("Progress building!")
      local time = love.timer.getTime()
      local delta = time - blackboard.lastBuildTick
      print("delta", time, constructionSkill * delta)
      blackboard.world:emit('bluePrintProgress', blackboard.bluePrintComponent, constructionSkill * delta)
      blackboard.lastBuildTick = time
      task:running()
      return
    else
      task:success()
    end
  end
}

function createTree(actor, world, jobType)
  local isBluePrintReadyToBuild = BehaviourTree.Task:new(isBluePrintReadyToBuild)
  local areWeAtTarget = BehaviourTree.Task:new(areWeAtTarget)

  local isBluePrintFinished = BehaviourTree.Task:new(isBluePrintFinished)
  local progressBuilding = BehaviourTree.Task:new(progressBuilding)
  local gotoAction = GotoAction()

  local target = entityManager.get(actor:get(ECS.c.work).jobId)
  local bluePrintComponent = target:get(ECS.c.bluePrintJob)
  local bluePrintGridPosition = universe.pixelsToGridCoordinates(target:get(ECS.c.position).vector)
  local tree = BehaviourTree:new({
    tree = BehaviourTree.Priority:new({
      nodes = {
        BehaviourTree.Sequence:new({
          nodes = {
            BehaviourTree.Priority:new({
              nodes = {
                areWeAtTarget,
              }
            }),
            -- isBluePrintReadyToBuild, -- Commented this out for now... Why would this task be running if it's not ready?
            BehaviourTree.Priority:new({
              nodes = {
                isBluePrintFinished,
                progressBuilding,
                gotoAction
              }
            })
          }
        }),
      }
    })

  })

  tree:setObject({
    target = target,
    actor = actor,
    inventory = inventory,
    bluePrintComponent = bluePrintComponent,
    bluePrintGridPosition = bluePrintGridPosition,
    world = world,
    jobType = jobType
  })

  return tree
end

return {
  createTree = createTree
}
