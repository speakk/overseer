local Class = require 'libs.hump.class'
local positionUtils = require('utils.position')
local entityRegistry = require('models.entityRegistry')
local Task = require('models.ai.task')

return Class {
  __includes = Task,
  init = function(self, actor, world)
    Task.init(self, actor, world)
  end,
  initializeTree = function(commonNodes, nodes)
    return {
      type = "selector",
      children = {
        nodes.isBluePrintFinished,
        nodes.progressBuilding,
        commonNodes.goto,
      }
    }
  end,
  initializeBlackboard = function(actor)
    local target = entityRegistry.get(actor.work.jobId)
    print("TARGET IS", target)
    local bluePrintComponent = target.bluePrintJob
    local bluePrintGridPosition = positionUtils.pixelsToGridCoordinates(target.position.vector)
    return {
      lastTick = love.timer.getTime(),
      target = target,
      bluePrintComponent = bluePrintComponent,
      bluePrintGridPosition = bluePrintGridPosition,
    }
  end,
  initializeNodes = function(_, actor, world, blackboard)
    return {
      isBluePrintReadyToBuild = function()
        print("isBluePrintReadyToBuild")
        local bluePrint = blackboard.target
        if bluePrint.job.finished then
          return false, false
        end

        local requirements = bluePrint.item.itemData.requirements

        for selector, amount in pairs(requirements) do --luacheck: ignore
          local itemId = bluePrint.inventory:findItem(selector)
          local item = entityRegistry.get(itemId)
          if not item or item.amount.amount < amount then
            return false, false
          end
        end

        --print("Success isBluePrintReadyToBuild")
        return false, true
      end,
      isBluePrintFinished = function()
        print("isBluePrintFinished")
        if blackboard.bluePrintComponent.buildProgress >= 100 then
          print("Blue print finished!", blackboard.bluePrintComponent, "actorid", actor)
          -- world:emit("treeFinished", actor, blackboard.jobType)
          -- world:emit("finishWork", actor, actor.work.jobId)
          -- world:emit("jobFinished", blackboard.target)
          blackboard.finished = true
          print("path component in bp", actor, actor.path)
          blackboard.target:remove("bluePrintJob")
          actor:remove("path")
          return false, true
        else
          return false, false
        end
      end,
      progressBuilding = function(treeDt)
        print("rpgoress buidlign")
        local constructionSkill = actor.settler.skills.construction
        if blackboard.bluePrintComponent.buildProgress < 100 then
          print("Progress building!")
          world:emit('bluePrintProgress', blackboard.bluePrintComponent, constructionSkill * treeDt)
          return true
        else
          return false, true
        end
      end
    }
  end
}
