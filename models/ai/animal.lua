local BehaviourTree = require('libs.behaviourtree')
local lume = require('libs.lume')
local Vector = require('libs.brinevector')
local inspect = require('libs.inspect')

local universe = require('models.universe')
local entityManager = require('models.entityManager')
local jobManager = require('models.jobManager')
local UntilDecorator = require('models.ai.decorators.until')
local GotoAction = require('models.ai.sharedActions.goto')
local AtTarget = require('models.ai.sharedActions.atTarget')
local GetTreeDt = require('models.ai.sharedActions.getTreeDt')

local idle = {
  run = function(task, blackboard)
    local currentTime = love.timer.getTime()

    if not blackboard.lastIdleRandomTick then
      blackboard.lastIdleRandomTick = currentTime
    end

    if currentTime - blackboard.lastIdleRandomTick > blackboard.idleRandomDelay then
      if not blackboard.actor.path then
        local universeSize = universe.getSize()
        local currentPosition = universe.pixelsToGridCoordinates(blackboard.actor.position.vector)
        local radius = 10
        local nextPosition = Vector(love.math.random(currentPosition.x - radius, currentPosition.x + radius), love.math.random(currentPosition.y - radius, currentPosition.y + radius))
        if nextPosition.x < 1 then nextPosition.x = 1 end
        if nextPosition.x > universeSize.x then nextPosition.x = universeSize.x end
        if nextPosition.y < 1 then nextPosition.y = 1 end
        if nextPosition.y > universeSize.y then nextPosition.y = universeSize.y end
        blackboard.idleTarget:give("position", universe.gridPositionToPixels(nextPosition))
        blackboard.target = blackboard.idleTarget
        blackboard.lastIdleRandomTick = currentTime
      end
    end
    --print("Idling?!")
    task:success()
  end
}

function createTree(actor, world, jobType)
  local gotoAction = GotoAction()
  local atTarget = AtTarget()

  local idle = BehaviourTree.Task:new(idle)
  local idleTarget = ECS.Entity()

  local getTreeDt = GetTreeDt()

  --local target = entityManager.get(actor.work.jobId)
  local tree = BehaviourTree:new({
    tree = BehaviourTree.Sequence:new({
      nodes = {
        getTreeDt,
        idle,
        gotoAction
      }
    })
  })

  tree:setObject({
    actor = actor,
    world = world,
    idleTarget = idleTarget,
    idleRandomDelay = love.math.random() * 5
  })

  return tree
end

return {
  createTree = createTree
}

