local BehaviourTree = require('libs.behaviourtree')
local lume = require('libs.lume')

local positionUtils = require('models.positionUtils')
local entityManager = require('models.entityManager')
local UntilDecorator = require('models.ai.decorators.until')
local GotoAction = require('models.ai.sharedActions.goto')
local AtTarget = require('models.ai.sharedActions.atTarget')

-- LEAF NODES

local isBluePrintReadyToBuild = {
  run = function(task, blackboard)
    print("isBluePrintReadyToBuild")
    local bluePrint = blackboard.target
    if bluePrint.job.finished then
      return task:fail()
    end

    local bluePrintComponent = bluePrint.bluePrintJob
    local requirements = bluePrint.item.itemData.requirements

    for selector, amount in pairs(requirements) do --luacheck: ignore
      local itemId = bluePrint.inventory:findItem(selector)
      local item = entityManager.get(itemId)
      if not item or item.amount.amount < amount then
        return task:fail()
      end
    end

    --print("Success isBluePrintReadyToBuild")
    return task:success()
  end
}

local isBluePrintFinished = {
  run = function(task, blackboard)
    print("isBluePrintFinished")
    if blackboard.bluePrintComponent.buildProgress >= 100 then
      print("Blue print finished!", blackboard.bluePrintComponent, "actorid", blackboard.actor)
      -- blackboard.world:emit("treeFinished", blackboard.actor, blackboard.jobType)
      -- blackboard.world:emit("finishWork", blackboard.actor, blackboard.actor.work.jobId)
      -- blackboard.world:emit("jobFinished", blackboard.target)
      blackboard.finished = true
      print("path component in bp", blackboard.actor, blackboard.actor.path)
      blackboard.target:remove("bluePrintJob")
      blackboard.actor:remove("path")
      task:success()
    else
      task:fail()
    end
  end
}

local progressBuilding = {
  run = function(task, blackboard)
    print("rpgoress buidlign")
    local constructionSkill = blackboard.actor.settler.skills.construction
    if blackboard.bluePrintComponent.buildProgress < 100 then
      print("Progress building!")
      blackboard.world:emit('bluePrintProgress', blackboard.bluePrintComponent, constructionSkill * blackboard.treeDt)
      return task:running()
    else
      return task:success()
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

  local target = entityManager.get(actor.work.jobId)
  print("TARGET IS", target)
  local bluePrintComponent = target.bluePrintJob
  local bluePrintGridPosition = positionUtils.pixelsToGridCoordinates(target.position.vector)
  local tree = BehaviourTree:new({
    tree = BehaviourTree.Priority:new({
      nodes = {
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
