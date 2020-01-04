local Vector = require('libs.brinevector')
local inspect = require('libs.inspect') --luacheck: ignore
local lume = require('libs.lume')
local media = require('utils.media')
local universe = require('models.universe')
local jobManager = require('models.jobManager')
local jobHandlers = require('models.jobTypes.jobTypes')
local entityReferenceManager = require('models.entityReferenceManager')

local settlerSpeed = 200

local SettlerSystem = ECS.System({ECS.Components.settler, ECS.Components.worker,
ECS.Components.position, ECS.Components.velocity}, {ECS.Components.job, 'jobs'})

function SettlerSystem:init()
  self.lastAssigned = 0
  self.assignWaitTime = 0.5

  self.jobs.onEntityAdded = function(pool, entity)
    if self.isEnabled then
      self:assignJobsForSettlers(jobManager.getUnreservedJobs(pool))
    end
  end

  self.disabledCallback = function(callbackName) -- luacheck: ignore
    self.isEnabled = false
  end

self.enabledCallback = function(callbackName) -- luacheck: ignore
  self.isEnabled = true
end


  self.tilesetBatch = love.graphics.newSpriteBatch(media.sprites, 200)
end

function SettlerSystem:update(dt) --luacheck: ignore
  -- local time = love.timer.getTime()
  -- if time - self.lastAssigned > self.assignWaitTime then
  --   self:assignJobsForSettlers()
  --   self.lastAssigned = time
  -- end

  for _, settler in ipairs(self.pool) do
    self:processSettlerUpdate(settler, dt)
  end
end

local function finishWork(self, settler, job)
  settler:remove(ECS.Components.work)
  self:getWorld():emit("jobFinished", job)
end

function SettlerSystem:pathFinished(entity)
end

function SettlerSystem:processSettlerUpdate(settler, dt)
  if not settler:has(ECS.Components.path) then
    if settler:has(ECS.Components.work) then
      self:processSubJob(settler, settler:get(ECS.Components.work).job, dt)
    end
  end
end

function SettlerSystem:gridUpdated()
  for _, settler in ipairs(self.pool) do
    -- Invalidate paths
    if settler:has(ECS.Components.path) then
      local path = settler:get(ECS.Components.path).path
      if not universe.pathStillValid(path) then
        settler:remove(ECS.Components.path)
        settler.searched_for_path = false
        print("Path was not valid, setting 'searched_for_path' to false")
      end
    else
      -- Make sure current location is valid
      local position = settler:get(ECS.Components.position).vector
      local gridCoordinates = universe.pixelsToGridCoordinates(position)
      if not universe.isCellAvailable(gridCoordinates) then
        local newPath = universe.findPathToClosestEmptyCell(gridCoordinates)
        if newPath then
          settler:give(ECS.Components.path, newPath)
        end
      end
    end

  end
end

function SettlerSystem:processSubJob(settler, job, dt)
  local jobType = job:get(ECS.Components.job).jobType
  local jobHandler = jobHandlers[jobType].handle
  if jobHandler then
    jobHandler(self, job, settler, dt, finishWork)
  end
end

function SettlerSystem:initializeTestSettlers()
  for _ = 1,2,1 do
    local settler = ECS.Entity()
    local worldSize = universe.getSize()
    local position
    while true do
      position = universe.clampToWorldBounds(Vector(math.random(worldSize.x), math.random(worldSize.y)))
      if universe.isCellAvailable(position) then
        break
      end
    end

    settler:give(ECS.Components.position, universe.gridPositionToPixels(position))
    --:give(ECS.Components.draw, {1,1,0})
    :give(ECS.Components.sprite, 'characters.settler')
    :give(ECS.Components.id, entityReferenceManager.generateId())
    :give(ECS.Components.serialize)
    :give(ECS.Components.settler)
    :give(ECS.Components.speed, 300)
    :give(ECS.Components.name, "Settler")
    :give(ECS.Components.inventory)
    :give(ECS.Components.worker)
    :give(ECS.Components.velocity)
    self:getWorld():addEntity(settler)
  end
end

function SettlerSystem:startJob(settler, job, jobQueue) -- luacheck: ignore
  job:get(ECS.Components.job).reserved = settler
  settler:give(ECS.Components.work, job)
  lume.remove(jobQueue, job)
end

function SettlerSystem:jobQueueUpdated(jobQueue)
  self:assignJobsForSettlers(jobQueue)
end

-- TODO: Needs to prioritize stuff
function SettlerSystem:assignJobsForSettlers(jobQueue)
  while true do
    local availableWorker = lume.match(self.pool,
    function(potentialSettler)
      return not potentialSettler:has(ECS.Components.work)
    end
    )

    if not availableWorker then break end
    local nextJob = jobQueue[1]
    if not nextJob then break end


    self:startJob(availableWorker, nextJob, jobQueue)
  end
end

function SettlerSystem:cancelConstruction(entities)
  for _, job in ipairs(entities) do
    for _, settler in ipairs(self.pool) do
      if settler:has(ECS.Components.work) then
        local settlerJob = settler:get(ECS.Components.work).job
        if job == settlerJob then
          settler:remove(ECS.Components.work)
          break
        end
      end
    end
  end
end

return SettlerSystem
