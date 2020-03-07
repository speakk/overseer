local Vector = require('libs.brinevector')
local inspect = require('libs.inspect') --luacheck: ignore
local lume = require('libs.lume')
local media = require('utils.media')
local universe = require('models.universe')
local jobManager = require('models.jobManager')
local jobHandlers = require('models.jobTypes.jobTypes')
local entityManager = require('models.entityManager')

local settlerSpeed = 200

local SettlerSystem = ECS.System({ECS.c.settler, ECS.c.worker,
ECS.c.position, ECS.c.velocity}, {ECS.c.job, 'jobs'})

function SettlerSystem:init()
  self.lastAssigned = 0
  self.assignWaitTime = 3.0

  self.jobs.onEntityAdded = function(pool, entity)
    self:assignJobsForSettlers(jobManager.getUnreservedJobs(pool))
  end

  self.jobs.onEntityRemoved = function(pool, entity)
    self:assignJobsForSettlers(jobManager.getUnreservedJobs(pool))
  end

  self.disabledCallback = function(callbackName) -- luacheck: ignore
    self.isEnabled = false
  end

self.enabledCallback = function(callbackName) -- luacheck: ignore
  self.isEnabled = true
end


  --self.tilesetBatch = love.graphics.newSpriteBatch(media.sprites, 200)
end

function SettlerSystem:update(dt) --luacheck: ignore
  local time = love.timer.getTime()
  --print("SettlerSystem:update", time, self.lastAssigned, self.assignWaitTime)
  if time - self.lastAssigned > self.assignWaitTime then
    print("TIMER")
    self:assignJobsForSettlers(jobManager.getUnreservedJobs(self.jobs))
    self.lastAssigned = time
  end

  -- for _, settler in ipairs(self.pool) do
  --   self:processSettlerUpdate(settler, dt)
  -- end
end

function SettlerSystem:finishWork(settler, jobId)
  local job = entityManager.get(jobId)
  settler:remove(ECS.c.work)
  local jobType = job:get(ECS.c.job).jobType
  if jobHandlers[jobType]["finish"] then
    jobHandlers[jobType].finish(job)
  end
  --self:getWorld():emit("jobFinished", job)
end

function SettlerSystem:pathFinished(entity)
end

-- function SettlerSystem:processSettlerUpdate(settler, dt)
--   if not settler:has(ECS.c.path) then
--     if settler:has(ECS.c.work) then
--       local jobId = settler:get(ECS.c.work).jobId
--       print("settler has work, jobId", jobId)
-- 
--       if not entityManager.get(jobId) then
--         settler:remove(ECS.c.work)
--         return
--       end
--     end
--   end
-- end


function SettlerSystem:initializeTestSettlers()
  for _ = 1,20,1 do
    local settler = ECS.Entity()
    local worldSize = universe.getSize()
    local position
    while true do
      position = universe.clampToWorldBounds(Vector(math.random(worldSize.x), math.random(worldSize.y)))
      if universe.isCellAvailable(position) then
        break
      end
    end

    settler:give(ECS.c.position, universe.gridPositionToPixels(position))
    --:give(ECS.c.draw, {1,1,0})
    :give(ECS.c.sprite, 'characters.settler1_01')
    :give(ECS.c.id, entityManager.generateId())
    :give(ECS.c.settler)
    :give(ECS.c.speed, 300)
    :give(ECS.c.name, "Settler")
    :give(ECS.c.inventory)
    :give(ECS.c.worker)
    :give(ECS.c.velocity)
    :give(ECS.c.animation, {
      walk = {
        targetComponent = 'sprite',
        targetProperty = 'selector',
        interpolate = false,
        repeatAnimation = true,
        values = {
          "characters.settler1_01", "characters.settler1_02", "characters.settler1_03"
        },
        currentValueIndex = 1,
        frameLength = 0.2, -- in ms
        lastFrameUpdate = love.timer.getTime(),
        finished = false
      }
    },
    {
      'walk'
    })
    self:getWorld():addEntity(settler)
  end
end

function SettlerSystem:startJob(settler, job, jobQueue) -- luacheck: ignore
  job:get(ECS.c.job).reserved = settler
  settler:give(ECS.c.work, job:get(ECS.c.id).id)
  lume.remove(jobQueue, job)
end

-- function SettlerSystem:jobQueueUpdated(jobQueue)
--   self:assignJobsForSettlers(jobQueue)
-- end

-- TODO: Needs to prioritize stuff
function SettlerSystem:assignJobsForSettlers(jobQueue)
  while true do
    local availableWorker = nil
    for _, entity in ipairs(self.pool) do
      if not entity:has(ECS.c.work) then
        availableWorker = entity
        break
      end
    end

    if not availableWorker then break end
    local nextJob = jobQueue[1]
    if not nextJob then break end


    self:startJob(availableWorker, nextJob, jobQueue)
  end
end

function SettlerSystem:cancelConstruction(entities)
  for _, job in ipairs(entities) do
    for _, settler in ipairs(self.pool) do
      if settler:has(ECS.c.work) then
        local settlerJob = settler:get(ECS.c.work).job
        if job == settlerJob then
          settler:remove(ECS.c.work)
          break
        end
      end
    end
  end
end

return SettlerSystem
