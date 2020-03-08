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

local behaviours = {
  --idle = require('models.ai.idleBehaviour').createTree,
  fetch = require('models.ai.fetchBehaviour').createTree,
  bluePrint = require('models.ai.bluePrintBehaviour').createTree,
  destruct = require('models.ai.destructBehaviour').createTree
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
    if blackboard.actor:has(ECS.c.work) then
      task:success()
    else
      task:fail()
    end
  end
}

local doWork = {
  start = function(task, blackboard)
    print("Blackboard id", blackboard, blackboard.currentWork)
    local job = entityManager.get(blackboard.actor:get(ECS.c.work).jobId)
    local jobType = job:get(ECS.c.job).jobType
    blackboard.currentWork = behaviours[jobType](blackboard.actor, blackboard.world, jobType)
    print("So uh... starting?", blackboard.currentWork)
  end,

  run = function(task, blackboard)
    --local job = entityManager.get(blackboard.actor:get(ECS.c.work).jobId)
    --local jobType = job:get(ECS.c.job).jobType
    --print("Running work!", jobType)
    -- TODO: Properly hceck if the work the succeeded and handle somehow
    blackboard.currentWork:run()
    print("started?", blackboard.currentWork.object.finished)
    if not blackboard.currentWork.object.finished then
      print("Work: running")
      return task:running()
    else
      print("Work: success")
      return task:success()
    end
  end,

  finish = function(task, blackboard)
    --blackboard.currentWork = nil
  end
}

local idle = {
  run = function(task, blackboard)
    local currentTime = love.timer.getTime()

    if not blackboard.lastIdleRandomTick then
      blackboard.lastIdleRandomTick = currentTime
    end

    if currentTime - blackboard.lastIdleRandomTick > blackboard.idleRandomDelay then
      if not blackboard.target then
        local universeSize = universe.getSize()
        local currentPosition = universe.pixelsToGridCoordinates(blackboard.actor:get(ECS.c.position).vector)
        local radius = 10
        local nextPosition = Vector(love.math.random(currentPosition.x - radius, currentPosition.x + radius), love.math.random(currentPosition.y - radius, currentPosition.y + radius))
        if nextPosition.x < 0 then nextPosition.x = 0 end
        if nextPosition.x > universeSize.x then nextPosition.x = universeSize.x end
        if nextPosition.y < 1 then nextPosition.y = 1 end
        if nextPosition.y > universeSize.y then nextPosition.y = universeSize.y end
        blackboard.idleTarget:give(ECS.c.position, universe.gridPositionToPixels(nextPosition))
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

  --local target = entityManager.get(actor:get(ECS.c.work).jobId)
  local tree = BehaviourTree:new({
    tree = BehaviourTree.Priority:new({
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

