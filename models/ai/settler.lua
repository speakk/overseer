local BehaviourTree = require('libs.behaviourtree')
local luabt = require('libs.luabt.luabt')
local Gamestate = require("libs.hump.gamestate")
local lume = require('libs.lume') --luacheck: ignore
local Vector = require('libs.brinevector')
local inspect = require('libs.inspect')

local positionUtils = require('utils.position')
local entityRegistry = require('models.entityRegistry')
local jobManager = require('models.jobManager')
local UntilDecorator = require('models.ai.decorators.until')
local GotoAction = require('models.ai.sharedActions.goto')
local AtTarget = require('models.ai.sharedActions.atTarget')
local GetTreeDt = require('models.ai.sharedActions.getTreeDt')

-- local behaviours = {
--   fetch = require('models.ai.tasks.fetch').createTree,
--   bluePrint = require('models.ai.tasks.bluePrint').createTree,
--   destruct = require('models.ai.tasks.destruct').createTree
-- }

local getNodes = function(blackboard)
  return {
    checkJobs = function()
      local jobs = jobManager.getUnreservedJobs()
      --print("Got unreservedJobs", #jobs)
      if jobs and #jobs > 0 then
        local job = jobs[1]
        print("Actor reserving job", blackboard.actor, job)
        print(inspect(job, {depth = 2}))
        -- TODO: Remove jobs from the startJob signature, probably
        blackboard.world:emit("startJob", blackboard.actor, job, jobs)
        return false, true
      else
        return false, false
      end
    end,
    haveWork = function()
      if blackboard.actor.work then
        return false, true
      else
        return false, false
      end
    end,
    doWork = function()
      -- TODO: Properly hceck if the work the succeeded and handle somehow
      if not blackboard.currentWork then
        print("Blackboard id", blackboard, blackboard.currentWork)
        local job = entityRegistry.get(blackboard.actor.work.jobId)
        print("Job", job, blackboard.actor.work.jobId)
        if not job then
          print("Starting job failed! No job")
          --false, false
          return
        end
        local jobType = job.job.jobType
        blackboard.currentWork = behaviours[jobType](blackboard.actor, blackboard.world, jobType)
        print("So uh... starting?", blackboard.currentWork)
        return false, false
      end

      blackboard.currentWork.object.treeDt = blackboard.treeDt
      blackboard.currentWork:run()
      if not blackboard.currentWork.object.finished then
        return true
      else
        print("Work: success")
        local work = blackboard.actor.work
        print("work", work)
        if not work then return false, true end
        local job = entityRegistry.get(work.jobId)
        print("job", job)
        if not job then return false, true end
        local jobType = job.job.jobType
        print("jobType?", jobType, "emitting jobFinished")
        blackboard.world:emit("jobFinished", job)
        blackboard.currentWork = nil
        return false, true
      end
    end,
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
          local nextPosition = Vector(love.math.random(currentPosition.x - radius, currentPosition.x + radius), love.math.random(currentPosition.y - radius, currentPosition.y + radius))
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

local function createTree(actor, world, jobType)
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
      {
        type = "selector",
        children = {
          {
            type = "sequence",
            children = {
              nodes.haveWork,
              nodes.doWork
            }
          },
          nodes.checkJobs,
          {
            type = "sequence",
            children = {
              nodes.idle,
              commonNodes.gotoAction
            }
          }
        }
      }
    }
  }

  return luabt.create(tree)

  -- local tree = BehaviourTree:new({
  --   tree = BehaviourTree.Sequence:new({
  --     nodes = {
  --       getTreeDt,
  --       weightNode
  --       BehaviourTree.Priority:new({
  --         nodes = {
  --           BehaviourTree.Sequence:new({
  --             nodes = {
  --               haveWork,
  --               doWork
  --             }
  --           }),
  --           checkJobs,
  --           BehaviourTree.Sequence:new({
  --             nodes = {
  --               idle,
  --               gotoAction
  --             }
  --           }),
  --         }
  --       })
  --     }
  --   })
  -- })

  -- tree:setObject({
  --   actor = actor,
  --   world = world,
  --   idleTarget = idleTarget,
  --   idleRandomDelay = love.math.random() * 5
  -- })

  -- return tree
end


local function createWeightRunner()
  local trees = {
    eatTree = luabt.create({
      type = 'sequence',
      children = {
        function()
          print("EAT EAT")
          return love.math.random() < 0.1, true
        end
      }
    }),
    workTree = luabt.create({
      type = 'sequence',
      children = {
        function()
          print("WORKY")
          return love.math.random() < 0.1, true
        end
      }
    }),
    idleTree = luabt.create({
      type = 'sequence',
      children = {
        function()
          print("Idlydoo")
          return love.math.random() < 0.1, true
        end
      }
    })
  }

  local weightTasks = {
    {
      behaviourTree = trees.eatTree,
      getPoints = function(entity)
        return 100 - entity.satiety.value
      end
    },
    {
      behaviourTree = trees.workTree,
      points = 120
    },
    {
      behaviourTree = trees.idleTree,
      points = 150
    }
  }

  return {
    run = function(entity, dt)
      local highestScoring = functional.reduce(weightTasks, function(result, task)
        local points = task.points or task.getPoints(entity)
        if points > result.points then
          result.points = points
          result.tree = task.behaviourTree
        end

        return result
      end,
      { points = 0, tree = nil })

      -- TODO: Consider if we need to save "currentlyRunning", and then recreate and destroy trees as they're being switched to!
      highestScoring.tree()
    end
  }
end

return {
  createWeightRunner = createWeightRunner
}
