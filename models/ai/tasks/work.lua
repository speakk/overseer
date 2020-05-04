local luabt = require('libs.luabt')
local inspect = require('libs.inspect')

local entityRegistry = require('models.entityRegistry')
local jobManager = require('models.jobManager')
local GotoAction = require('models.ai.sharedActions.goto')
local AtTarget = require('models.ai.sharedActions.atTarget')
local GetTreeDt = require('models.ai.sharedActions.getTreeDt')

local getNodes = function(blackboard)
  local tasks = {
    work = require('models.ai.tasks.work').createTree,
    idle = require('models.ai.tasks.idle').createTree,
    fetch = require('models.ai.tasks.fetch').createTree,
    bluePrint = require('models.ai.tasks.bluePrint').createTree,
    destruct = require('models.ai.tasks.destruct').createTree
  }

  return {
    checkJobs = function()
      local jobs = jobManager.getUnreservedJobs()
      --print("Got unreservedJobs", #jobs)
      if jobs and #jobs > 0 then
        local job = jobs[1]
        print("Actor reserving job", blackboard.actor, job)
        --print(inspect(job, {depth = 2}))
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
      print("doWork")
      -- TODO: Properly hceck if the work the succeeded and handle somehow
      if not blackboard.currentWork then
        print("Blackboard id", blackboard, blackboard.currentWork)
        local job = entityRegistry.get(blackboard.actor.work.jobId)
        print("Job", job, blackboard.actor.work.jobId)
        if not job then
          print("Starting job failed! No job")
          --false, false
          return false, false
        end
        local jobType = job.job.jobType
        blackboard.currentWork = tasks[jobType](blackboard.actor, blackboard.world, jobType)
        print("So uh... starting?", jobType, inspect(blackboard.currentWork))
        --return false, false
      end

      -- TODO: Figure out how to put the treeDt into the blackboard
      --blackboard.currentWork.object.treeDt = blackboard.treeDt 
      local workResult = blackboard.currentWork(blackboard.treeDt)
      print("workResult", workResult)
      if workResult then
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
    end
  }
end

local function createTree(actor, world, _)
  local blackboard = {
    actor = actor,
    world = world
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
          nodes.checkJobs
        }
      }
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
