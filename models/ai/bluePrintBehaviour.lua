local BehaviourTree = require('libs.behaviourtree')
local lume = require('libs.lume')

local universe = require('models.universe')
local entityManager = require('models.entityManager')
local UntilDecorator = require('models.ai.decorators.until')

-- LEAF NODES

local isBluePrintReadyToBuild = {
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
}

local areWeAtTarget = {
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
}

local isBluePrintFinished = {
  run = function(task, blackboard)
    --print("isBluePrintFinished")
    if blackboard.bluePrintComponent.buildProgress >= 100 then
      print("Blue print finished!", blackboard.bluePrintComponent, "settlerid", blackboard.settler)
      blackboard.world:emit("treeFinished", blackboard.settler, blackboard.jobType)
      blackboard.world:emit("finishWork", blackboard.settler, blackboard.settler:get(ECS.c.work).jobId)
      blackboard.world:emit("jobFinished", blackboard.job)
      print("path component in bp", blackboard.settler, blackboard.settler:get(ECS.c.path))
      blackboard.settler:remove(ECS.c.path)
      task:success()
    else
      task:fail()
    end
  end
}

local getPathToTarget = {
  run = function(task, blackboard)
    print("bluePrint getPathToTarget")
    if blackboard.settler:has(ECS.c.path) then
      if blackboard.settler:get(ECS.c.path).finished then
        print("bluePrint Path finished, success")
        blackboard.settler:remove(ECS.c.path)
        task:success()
        return
      else
        task:running()
        return
      end
    end

    -- local path = universe.getPath(
    -- universe.pixelsToGridCoordinates(blackboard.settler:get(ECS.c.position).vector),
    -- blackboard.bluePrintGridPosition
    -- )

    -- print("To coords", blackboard.bluePrintGridPosition)

    -- if not path then
    --   --print("No path, failing")
    --   task:fail()
    --   return
    -- end

    local from = universe.pixelsToGridCoordinates(blackboard.settler:get(ECS.c.position).vector)
    local to = blackboard.bluePrintGridPosition
    blackboard.settler:give(ECS.c.path, nil, nil, from.x, from.y, to.x, to.y)
    task:running()
  end
}

local progressBuilding = {
  start = function(task, blackboard)
    blackboard.lastBuildTick = love.timer.getTime()
  end,
  run = function(task, blackboard)
    local constructionSkill = blackboard.settler:get(ECS.c.settler).skills.construction
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

function createTree(settler, world, jobType)
  local isBluePrintReadyToBuild = BehaviourTree.Task:new(isBluePrintReadyToBuild)
  local areWeAtTarget = BehaviourTree.Task:new(areWeAtTarget)

  local isBluePrintFinished = BehaviourTree.Task:new(isBluePrintFinished)
  local getPathToTarget = BehaviourTree.Task:new(getPathToTarget)
  local progressBuilding = BehaviourTree.Task:new(progressBuilding)

  local job = entityManager.get(settler:get(ECS.c.work).jobId)
  local bluePrintComponent = job:get(ECS.c.bluePrintJob)
  local bluePrintGridPosition = universe.pixelsToGridCoordinates(job:get(ECS.c.position).vector)
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
            -- isBluePrintReadyToBuild, -- Commented this out for now... Why would this task be running if it's not ready?
            BehaviourTree.Priority:new({
              nodes = {
                isBluePrintFinished,
                progressBuilding
              }
            })
          }
        }),
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
