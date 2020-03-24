local BehaviourTree = require('libs.behaviourtree')
local lume = require('libs.lume')
local Vector = require('libs.brinevector')
local inspect = require('libs.inspect')

local positionUtils = require('models.positionUtils')
local entityManager = require('models.entityManager')
local jobManager = require('models.jobManager')
local UntilDecorator = require('models.ai.decorators.until')
local GotoAction = require('models.ai.sharedActions.goto')
local AtTarget = require('models.ai.sharedActions.atTarget')
local GetTreeDt = require('models.ai.sharedActions.getTreeDt')

local behaviours = {
  fetch = require('models.ai.task.fetch').createTree,
  bluePrint = require('models.ai.task.bluePrint').createTree,
  destruct = require('models.ai.task.destruct').createTree
}

local checkJobs = {
  run = function(task, blackboard)
    local jobs = jobManager.getUnreservedJobs()
    --print("Got unreservedJobs", #jobs)
    if jobs and #jobs > 0 then
      local job = jobs[1]
      print("Actor reserving job", blackboard.actor, job)
      -- TODO: Remove jobs from the startJob signature, probably
      blackboard.world:emit("startJob", blackboard.actor, job, jobs)
      task:success()
    else
      task:fail()
    end
  end
}

local haveWork = {
  run = function(task, blackboard)
    if blackboard.actor.work then
      task:success()
    else
      task:fail()
    end
  end
}

local doWork = {
  start = function(task, blackboard)
    print("Blackboard id", blackboard, blackboard.currentWork)
    local job = entityManager.get(blackboard.actor.work.jobId)
    print("Job", job, blackboard.actor.work.jobId)
    if not job then
      print("Starting job failed! No job")
      --task:fail()
      return
    end
    local jobType = job.job.jobType
    blackboard.currentWork = behaviours[jobType](blackboard.actor, blackboard.world, jobType)
    print("So uh... starting?", blackboard.currentWork)
  end,

  run = function(task, blackboard)
    -- TODO: Properly hceck if the work the succeeded and handle somehow
    if not blackboard.currentWork then
      return task:fail()
    end
    blackboard.currentWork.object.treeDt = blackboard.treeDt
    blackboard.currentWork:run()
    if not blackboard.currentWork.object.finished then
      return task:running()
    else
      print("Work: success")
      local work = blackboard.actor.work
      if not work then return task:success() end
      local job = entityManager.get(work.jobId)
      if not job then return task:success() end
      local jobType = job.job.jobType
      blackboard.world:emit("jobFinished", job)
      return task:success()
    end
  end,

  finish = function(task, blackboard)
    blackboard.currentWork = nil
  end
}

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
        if nextPosition.x < 1 then nextPosition.x = 2 end
        if nextPosition.x > mapConfig.width then nextPosition.x = mapConfig.width-1 end
        if nextPosition.y < 1 then nextPosition.y = 2 end
        if nextPosition.y > mapConfig.height.y then nextPosition.y = mapConfig.height-1 end
        --print("currentPosition, nextPosition", currentPosition, nextPosition)
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

  local haveWork = BehaviourTree.Task:new(haveWork)
  local checkJobs = BehaviourTree.Task:new(checkJobs)
  local doWork = BehaviourTree.Task:new(doWork)
  local idle = BehaviourTree.Task:new(idle)
  local idleTarget = ECS.Entity()

  local getTreeDt = GetTreeDt()

  --local target = entityManager.get(actor.work.jobId)
  local tree = BehaviourTree:new({
    tree = BehaviourTree.Sequence:new({
      nodes = {
        getTreeDt,
        BehaviourTree.Priority:new({
          nodes = {
            BehaviourTree.Sequence:new({
              nodes = {
                haveWork,
                doWork
              }
            }),
            checkJobs,
            BehaviourTree.Sequence:new({
              nodes = {
                idle,
                gotoAction
              }
            }),
          }
        })
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

