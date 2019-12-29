local Vector = require('libs.brinevector')
local inspect = require('libs.inspect') --luacheck: ignore
local lume = require('libs.lume')
local media = require('utils.media')
local universe = require('models.universe')
local jobHandlers = require('models.jobTypes.jobTypes')

local settlerSpeed = 200

local SettlerSystem = ECS.System("settler", {ECS.Components.settler, ECS.Components.worker,
ECS.Components.position, ECS.Components.velocity})

function SettlerSystem:init()
  self.lastAssigned = 0
  self.assignWaitTime = 0.5
  self.workQueue = {}

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

function SettlerSystem:processSettlerUpdate(settler, dt)
  local velocityComponent = settler:get(ECS.Components.velocity)
  velocityComponent.vector = Vector(0, 0)
  if not settler:has(ECS.Components.path) then
    if settler:has(ECS.Components.work) then
      self:processSubJob(settler, settler:get(ECS.Components.work).job, dt)
    end
  else
    self:processSettlerPathFinding(settler)
  end


  velocityComponent.vector = velocityComponent.vector.normalized * settlerSpeed
end

function SettlerSystem:processSettlerPathFinding(settler) --luacheck: ignore
  if not settler:has(ECS.Components.path) then return end

  local pathComponent = settler:get(ECS.Components.path)

  if not pathComponent.path then
    return
  end

  local position = settler:get(ECS.Components.position).vector
  local nextGridPosition

  for node, count in pathComponent.path:nodes() do
    if count == pathComponent.currentIndex then
      nextGridPosition = Vector(node:getX(), node:getY())
      break
    end
  end

  if nextGridPosition then
    local nextPosition = universe.gridPositionToPixels(nextGridPosition, "center")
    local angle = math.atan2(nextPosition.y - position.y, nextPosition.x - position.x)
    local velocityComponent = settler:get(ECS.Components.velocity)
    velocityComponent.vector = Vector(math.cos(angle), math.sin(angle)).normalized

    if universe.pixelsToGridCoordinates(position) == nextGridPosition then
      pathComponent.currentIndex = pathComponent.currentIndex + 1

      if pathComponent.currentIndex == table.getn(pathComponent.path._nodes) then
        if pathComponent.path.finishedCallBack then
          pathComponent.path.finishedCallBack()
        end
        settler:remove(ECS.Components.path)
      end
    end
    velocityComponent.vector = velocityComponent.vector.normalized * settlerSpeed
  end

end

function SettlerSystem:gridUpdated()
  print("Invalidating")
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
  for _ = 1,10,1 do
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
    :give(ECS.Components.settler)
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
  self:getWorld():flush()
  print("Jobqueue!", #jobQueue)

  while true do
    print("settlers pool", #self.pool)
    local availableWorker = lume.match(self.pool,
    function(potentialSettler)
      print("Settler!", potentialSettler, potentialSettler:has(ECS.Components.work))
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
