local luabt = require('libs.luabt')

local positionUtils = require('utils.position')
local entityRegistry = require('models.entityRegistry')

local GotoAction = require('models.ai.sharedActions.goto')

-- LEAF NODES

local getNodes = function(blackboard)
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
        print("Blue print finished!", blackboard.bluePrintComponent, "actorid", blackboard.actor)
        -- blackboard.world:emit("treeFinished", blackboard.actor, blackboard.jobType)
        -- blackboard.world:emit("finishWork", blackboard.actor, blackboard.actor.work.jobId)
        -- blackboard.world:emit("jobFinished", blackboard.target)
        blackboard.finished = true
        print("path component in bp", blackboard.actor, blackboard.actor.path)
        blackboard.target:remove("bluePrintJob")
        blackboard.actor:remove("path")
        return false, true
      else
        return false, false
      end
    end,
    progressBuilding = function()
      print("rpgoress buidlign")
      local constructionSkill = blackboard.actor.settler.skills.construction
      if blackboard.bluePrintComponent.buildProgress < 100 then
        print("Progress building!")
        blackboard.world:emit('bluePrintProgress', blackboard.bluePrintComponent, constructionSkill * blackboard.treeDt)
        return true
      else
        return false, true
      end
    end
  }
end


local function createTree(actor, world, jobType)
  print("Creating blueprint tree", jobType)


  local target = entityRegistry.get(actor.work.jobId)
  print("TARGET IS", target)
  local bluePrintComponent = target.bluePrintJob
  local bluePrintGridPosition = positionUtils.pixelsToGridCoordinates(target.position.vector)
  local blackboard = {
    lastTick = love.timer.getTime(),
    target = target,
    actor = actor,
    bluePrintComponent = bluePrintComponent,
    bluePrintGridPosition = bluePrintGridPosition,
    world = world,
    jobType = jobType
  }

  local commonNodes = {
    gotoAction = GotoAction(blackboard)
  }

  local nodes = getNodes(blackboard)

  local tree = {
    type = "selector",
    children = {
      nodes.isBluePrintFinished,
      nodes.progressBuilding,
      commonNodes.gotoAction,
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
