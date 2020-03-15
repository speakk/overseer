local Vector = require('libs.brinevector')
local inspect = require('libs.inspect') --luacheck: ignore
local lume = require('libs.lume')
local media = require('utils.media')
local universe = require('models.universe')
local jobManager = require('models.jobManager')
local jobHandlers = require('models.jobTypes.jobTypes')
local entityManager = require('models.entityManager')

local settlerSpeed = 200

local SettlerSystem = ECS.System({ pool = { "settler", "worker", "position", "velocity" } })

function SettlerSystem:init()
  self.lastAssigned = 0
  self.assignWaitTime = 3.0

  -- self.jobs.onEntityAdded = function(pool, entity)
  --   self:assignJobsForSettlers(jobManager.getUnreservedJobs(pool))
  -- end

  -- self.jobs.onEntityRemoved = function(pool, entity)
  --   self:assignJobsForSettlers(jobManager.getUnreservedJobs(pool))
  -- end

  self.disabledCallback = function(callbackName) -- luacheck: ignore
    self.isEnabled = false
  end

self.enabledCallback = function(callbackName) -- luacheck: ignore
  self.isEnabled = true
end


  --self.tilesetBatch = love.graphics.newSpriteBatch(media.sprites, 200)
end

-- function SettlerSystem:update(dt) --luacheck: ignore
--   local time = love.timer.getTime()
--   --print("SettlerSystem:update", time, self.lastAssigned, self.assignWaitTime)
--   if time - self.lastAssigned > self.assignWaitTime then
--     print("TIMER")
--     self:assignJobsForSettlers(jobManager.getUnreservedJobs(self.jobs))
--     self.lastAssigned = time
--   end
-- 
--   -- for _, settler in ipairs(self.pool) do
--   --   self:processSettlerUpdate(settler, dt)
--   -- end
-- end

function SettlerSystem:finishWork(settler, jobId)
  local job = entityManager.get(jobId)
  settler:remove("work")
  if not job.job then
    print("WTF NO JOB FOR JOB")
    return
  end
  local jobType = job.job.jobType
  print("jobType", jobType)
  if jobHandlers[jobType]["finish"] then
    jobHandlers[jobType].finish(job, self:getWorld())
  end
  --self:getWorld():emit("jobFinished", job)
end

function SettlerSystem:pathFinished(entity)
end

-- function SettlerSystem:processSettlerUpdate(settler, dt)
--   if not settler.path then
--     if settler.work then
--       local jobId = settler.work.jobId
--       print("settler has work, jobId", jobId)
-- 
--       if not entityManager.get(jobId) then
--         settler:remove("work")
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
      if universe.isPositionWalkable(position) then
        break
      end
    end

    settler:give("position", universe.gridPositionToPixels(position))
    --:give("draw", {1,1,0})
    :give("sprite", 'characters.settler1_01')
    :give("id", entityManager.generateId())
    :give("settler")
    :give("ai", 'settler')
    :give("speed", 300)
    :give("name", "Settler")
    :give("inventory")
    :give("worker")
    :give("velocity")
    :give("animation", {
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
  job.job.reserved = settler
  settler:give("work", job.id.id)
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
      if not entity.work then
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
      if settler.work then
        local settlerJob = settler.work.job
        if job == settlerJob then
          settler:remove("work")
          break
        end
      end
    end
  end
end

return SettlerSystem
