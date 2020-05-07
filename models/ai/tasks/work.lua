local Class = require 'libs.hump.class'
local inspect = require('libs.inspect')

local Task = require('models.ai.task')
local entityRegistry = require('models.entityRegistry')
local jobManager = require('models.jobManager')


return Class {
  __includes = Task,
  init = function(self, actor, world)
    Task.init(self, actor, world)
  end,
  initializeTree = function(commonNodes, nodes)
    return {
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
  end,
  initializeBlackboard = function(_)
    return {}
  end,
  initializeNodes = function(self, actor, world, blackboard)
    return {
      checkJobs = function()
        local jobs = jobManager.getUnreservedJobs()
        --print("Got unreservedJobs", #jobs)
        if jobs and #jobs > 0 then
          local job = jobs[1]
          print("Actor reserving job", actor, job)
          --print(inspect(job, {depth = 2}))
          -- TODO: Remove jobs from the startJob signature, probably
          world:emit("startJob", actor, job, jobs)
          return false, true
        else
          return false, false
        end
      end,
      haveWork = function()
        if actor.work then
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
          local job = entityRegistry.get(actor.work.jobId)
          print("Job", job, actor.work.jobId)
          if not job then
            print("Starting job failed! No job")
            --false, false
            return false, false
          end
          local jobType = job.job.jobType
          blackboard.currentWork = self.types[jobType](actor, world, jobType)
          print("So uh... starting?", jobType, inspect(blackboard.currentWork))
          --return false, false
        end

        local workResult = blackboard.currentWork(blackboard.treeDt)
        print("workResult", workResult)
        if workResult then
          return true
        else
          print("Work: success")
          local work = actor.work
          print("work", work)
          if not work then return false, true end
          local job = entityRegistry.get(work.jobId)
          print("job", job)
          if not job then return false, true end
          local jobType = job.job.jobType
          print("jobType?", jobType, "emitting jobFinished")
          world:emit("jobFinished", job)
          blackboard.currentWork = nil
          return false, true
        end
      end
    }
  end
}
