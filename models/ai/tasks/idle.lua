local Class = require 'libs.hump.class'
local Gamestate = require("libs.hump.gamestate")
local Vector = require('libs.brinevector')

local positionUtils = require('utils.position')
local Task = require('models.ai.task')

return Class {
  __includes = Task,
  init = function(self, actor, world)
    print("Initializing idle for actor", actor)
    Task.init(self, actor, world)
  end,
  initializeTree = function(commonNodes, nodes)
    return {
      type = "sequence",
      children = {
        nodes.idle,
        commonNodes.goto
      }
    }
  end,
  initializeBlackboard = function(_)
    local idleTarget = ECS.Entity()

    return {
      idleTarget = idleTarget,
      idleRandomDelay = love.math.random() * 5
    }
  end,
  initializeNodes = function(_, actor, _, blackboard)
    return {
      idle = function()
        print("Idlin'!")
        local currentTime = love.timer.getTime()

        if not blackboard.lastIdleRandomTick then
          blackboard.lastIdleRandomTick = currentTime
        end

        if currentTime - blackboard.lastIdleRandomTick > blackboard.idleRandomDelay then
          if not actor.path then
            local mapConfig = Gamestate.current().mapConfig
            local currentPosition = positionUtils.pixelsToGridCoordinates(actor.position.vector)
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
            --print("Giving target", blackboard.target)
            blackboard.lastIdleRandomTick = currentTime
          end
        end
        --print("Idling?!")
        return false, true
      end
    }
  end
}
