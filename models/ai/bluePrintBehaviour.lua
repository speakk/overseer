local BehaviourTree = require('libs.behaviourtree')
local lume = require('libs.lume')

local universe = require('models.universe')
local entityManager = require('models.entityManager')
local UntilDecorator = require('models.ai.decorators.until')

-- LEAF NODES

local isBluePrintReadyToBuild = BehaviourTree.Task:new({
  run = function(task, blackboard)
    --print("isBluePrintReadyToBuild")
    local bluePrint = blackboard.job
    if bluePrint:get(ECS.c.job).finished then return false end

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
})

local areWeAtTarget = BehaviourTree.Task:new({
  run = function(task, blackboard)
    --print("bluePrint areWeAtTarget")
    local gridPosition = universe.pixelsToGridCoordinates(blackboard.settler:get(ECS.c.position).vector)
    local targetPosition = universe.pixelsToGridCoordinates(blackboard.job:get(ECS.c.position).vector)

    if universe.isInPosition(gridPosition, targetPosition, true) then
      --print("areWeAtTarget true")
      task:success()
    else
      --print("areWeAtTarget false")
      task:fail()
    end
  end
})

local isBluePrintFinished = BehaviourTree.Task:new({
  run = function(task, blackboard)
    --print("isBluePrintFinished")
    if blackboard.bluePrintComponent.buildProgress >= 100 then
      --print("Blue print finished!")
      blackboard.world:emit("treeFinished", blackboard.settler, blackboard.jobType)
      blackboard.world:emit("finishWork", blackboard.settler, blackboard.settler:get(ECS.c.work).jobId)
      blackboard.world:emit("jobFinished", blackboard.job)
      task:success()
    else
      task:fail()
    end
  end
})

local getPathToTarget = BehaviourTree.Task:new({
  run = function(task, blackboard)
    --print("bluePrint getPathToTarget")
    if blackboard.settler:has(ECS.c.path) then
      if blackboard.settler:get(ECS.c.path).finished then
        --print("Path finished, success")
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
    blackboard.bluePrintGridPosition
    )

    if not path then
      --print("No path, failing")
      task:fail()
      return
    end

    blackboard.settler:give(ECS.c.path, path)
    task:running()
  end
})

local progressBuilding = BehaviourTree.Task:new({
  run = function(task, blackboard)
    local constructionSkill = blackboard.settler:get(ECS.c.settler).skills.construction
    --print("bluePrint progressBuilding")
    blackboard.world:emit('bluePrintProgress', blackboard.bluePrintComponent, constructionSkill)
    task:success()
  end
})


function createTree(settler, world, jobType)
  local job = entityManager.get(settler:get(ECS.c.work).jobId)
  local bluePrintComponent = job:get(ECS.c.bluePrintJob)
  local bluePrintGridPosition = universe.pixelsToGridCoordinates(job:get(ECS.c.position).vector)
  local tree = BehaviourTree:new({
    tree = BehaviourTree.Priority:new({
      nodes = {
        BehaviourTree.Sequence:new({
          nodes = {
            areWeAtTarget,
            isBluePrintReadyToBuild,
            BehaviourTree.Priority:new({
              nodes = {
                isBluePrintFinished,
                progressBuilding
              }
            })
          }
        }),
        getPathToTarget,
      }
    })

  })

  tree:setObject({
    job = job,
    settler = settler,
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
