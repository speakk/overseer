local luabt = require('libs.luabt')
local Gamestate = require("libs.hump.gamestate")
local Vector = require('libs.brinevector')

local positionUtils = require('utils.position')
local GotoAction = require('models.ai.sharedActions.goto')
local AtTarget = require('models.ai.sharedActions.atTarget')
local GetTreeDt = require('models.ai.sharedActions.getTreeDt')

local getNodes = function(blackboard)
  return {
    idle = function()
      local currentTime = love.timer.getTime()

      if not blackboard.lastIdleRandomTick then
        blackboard.lastIdleRandomTick = currentTime
      end

      if currentTime - blackboard.lastIdleRandomTick > blackboard.idleRandomDelay then
        if not blackboard.actor.path then
          local mapConfig = Gamestate.current().mapConfig
          local currentPosition = positionUtils.pixelsToGridCoordinates(blackboard.actor.position.vector)
          local radius = 10
          local nextPosition = Vector(
            love.math.random(currentPosition.x - radius, currentPosition.x + radius),
            love.math.random(currentPosition.y - radius, currentPosition.y + radius)
            )
          if nextPosition.x < 1 then nextPosition.x = 1 end
          if nextPosition.x > mapConfig.width then nextPosition.x = mapConfig.width-1 end
          if nextPosition.y < 1 then nextPosition.y = 1 end
          if nextPosition.y > mapConfig.height then nextPosition.y = mapConfig.height-1 end
          --print("currentPosition, nextPosition", currentPosition, nextPosition)
          blackboard.idleTarget:give("position", positionUtils.gridPositionToPixels(nextPosition))
          blackboard.target = blackboard.idleTarget
          blackboard.lastIdleRandomTick = currentTime
        end
      end
      --print("Idling?!")
      return false, true
    end
  }
end

local function createTree(actor, world, _)
  local idleTarget = ECS.Entity()

  local blackboard = {
    actor = actor,
    world = world,
    idleTarget = idleTarget,
    idleRandomDelay = love.math.random() * 5
  }

  local commonNodes = {
    gotoAction = GotoAction(blackboard),
    atTarget = AtTarget(blackboard),
    getTreeDt = GetTreeDt(blackboard)
  }

  local nodes = getNodes(blackboard)

  local tree = {
    type = "sequence",
    children = {
      commonNodes.getTreeDt,
      nodes.idle,
      commonNodes.gotoAction
    }
  }

  local bt = luabt.create(tree)

  return function(treeDt)
    blackboard.treeDt = treeDt
    return bt()
  end
end

return {
  createTree = createTree
}
