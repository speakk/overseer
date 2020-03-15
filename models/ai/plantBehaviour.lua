local BehaviourTree = require('libs.behaviourtree')
local lume = require('libs.lume')

local universe = require('models.universe')
local entityManager = require('models.entityManager')
local UntilDecorator = require('models.ai.decorators.until')
local GotoAction = require('models.ai.sharedActions.goto')
local AtTarget = require('models.ai.sharedActions.atTarget')
local GetTreeDt = require('models.ai.sharedActions.getTreeDt')

local findEmptySpot = {
  run = function(task, blackboard)
    local emptySpot = zoneUtils.findEmptySpot(blackboard.targetZone)
    blackboard.target = emptySpot
  end
}

local progressPlanting = {
  run = function(task, blackboard)
    print("rpgoress buidlign")
    local skill = blackboard.actor:get(ECS.c.settler).skills.planting
    local bluePrintComponent = blackboard.target:get(ECS.c.components).
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
  local gotoAction = GotoAction()
  local atTarget = AtTarget()
  local getTreeDt = GetTreeDt()

  local findEmptySpot = BehaviourTree.Task:new(findEmptySpot)

  --local target = entityManager.get(actor:get(ECS.c.work).jobId)
  local targetZone = entityManager.get(actor:get(ECS.c.work).jobId)
  local constructionComponent = target:get(ECS.c.construction)
  local targetGridPosition = universe.pixelsToGridCoordinates(target:get(ECS.c.position).vector)
  local tree = BehaviourTree:new({
    tree = BehaviourTree.Priority:new({
      nodes = {
        BehaviourTree.Sequence:new({
          nodes = {
            findEmptySpot,
            "goto",
            plant
          }
        }),
      }
    })

  })

  tree:setObject({
    lastTick = love.timer.getTime(),
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

