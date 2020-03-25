local BehaviourTree = require('libs.behaviourtree')
local Gamestate = require("libs.hump.gamestate")
local lume = require('libs.lume')
local Vector = require('libs.brinevector')
local inspect = require('libs.inspect')

local positionUtils = require('utils.position')
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
        local mapConfig = Gamestate.current().mapConfig
        local currentPosition = positionUtils.pixelsToGridCoordinates(blackboard.actor.position.vector)
        local radius = 10
        local nextPosition = Vector(love.math.random(currentPosition.x - radius, currentPosition.x + radius), love.math.random(currentPosition.y - radius, currentPosition.y + radius))
        if nextPosition.x < 1 then nextPosition.x = 1 end
        if nextPosition.x > mapConfig.width then nextPosition.x = mapConfig.width-1 end
        if nextPosition.y < 1 then nextPosition.y = 1 end
        if nextPosition.y > mapConfig.height then nextPosition.y = mapConfig.height-1 end
        blackboard.idleTarget:give("position", positionUtils.gridPositionToPixels(nextPosition))
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

