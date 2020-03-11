local BehaviourTree = require('libs.behaviourtree')
local lume = require('libs.lume')

local universe = require('models.universe')
local entityManager = require('models.entityManager')
local UntilDecorator = require('models.ai.decorators.until')
local GotoAction = require('models.ai.sharedActions.goto')
local AtTarget = require('models.ai.sharedActions.atTarget')
local GetTreeDt = require('models.ai.sharedActions.getTreeDt')

-- LEAF NODES

local isBluePrintReadyToBuild = {
  run = function(task, blackboard)
    print("isBluePrintReadyToBuild")
    local bluePrint = blackboard.target
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

local isBluePrintFinished = {
  run = function(task, blackboard)
    print("isBluePrintFinished")
    if blackboard.bluePrintComponent.buildProgress >= 100 then
      print("Blue print finished!", blackboard.bluePrintComponent, "actorid", blackboard.actor)
      blackboard.world:emit("treeFinished", blackboard.actor, blackboard.jobType)
      blackboard.world:emit("finishWork", blackboard.actor, blackboard.actor:get(ECS.c.work).jobId)
      blackboard.world:emit("jobFinished", blackboard.target)
      blackboard.finished = true
      print("path component in bp", blackboard.actor, blackboard.actor:get(ECS.c.path))
      blackboard.target:remove(ECS.c.bluePrintJob)
      blackboard.actor:remove(ECS.c.path)
      task:success()
    else
      task:fail()
    end
  end
}

local progressBuilding = {
  run = function(task, blackboard)
    print("rpgoress buidlign")
    local constructionSkill = blackboard.actor:get(ECS.c.settler).skills.construction
    if blackboard.bluePrintComponent.buildProgress < 100 then
      print("Progress building!")
      blackboard.world:emit('bluePrintProgress', blackboard.bluePrintComponent, constructionSkill * blackboard.treeDt)
      task:running()
      return
    else
      task:success()
    end
  end
}

function createTree(actor, world, jobType)
  print("Creating blueprint tree", jobType)
  local isBluePrintReadyToBuild = BehaviourTree.Task:new(isBluePrintReadyToBuild)

  local isBluePrintFinished = BehaviourTree.Task:new(isBluePrintFinished)
  local progressBuilding = BehaviourTree.Task:new(progressBuilding)
  local gotoAction = GotoAction()
  local atTarget = AtTarget()
  local getTreeDt = GetTreeDt()

  local target = entityManager.get(actor:get(ECS.c.work).jobId)
  print("TARGET IS", target)
  local bluePrintComponent = target:get(ECS.c.bluePrintJob)
  local bluePrintGridPosition = universe.pixelsToGridCoordinates(target:get(ECS.c.position).vector)
  local tree = BehaviourTree:new({
    tree = BehaviourTree.Priority:new({
      nodes = {
        getTreeDt,
        isBluePrintFinished,
        progressBuilding,
        gotoAction
      }
    })
  })

  tree:setObject({
    lastTick = love.timer.getTime(),
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
