local Vector = require('libs/brinevector/brinevector')
--local inspect = require('libs/inspect')
local lume = require('libs/lume')
local inspect = require('libs/inspect')
local commonComponents = require('components/common')

local settlerSpeed = 200

local SettlerSystem = ECS.System({commonComponents.Settler, commonComponents.Worker,
commonComponents.Position, commonComponents.Velocity})

function SettlerSystem:init(mapSystem, jobSystem, itemSystem)
  self.mapSystem = mapSystem
  self.jobSystem = jobSystem
  self.itemSystem = itemSystem
  self.lastAssigned = 0
  self.assignWaitTime = 0.5
end

function SettlerSystem:update(dt) --luacheck: ignore
  if love.timer.getTime() - self.lastAssigned > self.assignWaitTime then
    self:assignJobsForSettlers()
    self.lastAssigned = love.timer.getTime()
  end

  for _, settler in ipairs(self.pool.objects) do
    self:processSettlerUpdate(settler)
  end
end

local function getFirstSubJob(job)
  local jobComponent = job:get(commonComponents.Job)
  if jobComponent.reserved then return nil end
  if not job:has(commonComponents.Children) then return job end

  local children = job:get(commonComponents.Children).children

  for _, child in ipairs(children) do
    local firstChildJob = getFirstSubJob(child)
    if firstChildJob then return firstChildJob end
  end
end

function SettlerSystem:processSettlerUpdate(settler)
  if settler:has(commonComponents.Work) then
    local work = settler:get(commonComponents.Work)
    if not work.currentSubJob then
      local job = work.job
      local nextSubJob = getFirstSubJob(job)
      if nextSubJob then work.currentSubJob = getFirstSubJob(job) end
    end

    if work.currentSubJob then
      self:processSubJob(settler, work.currentSubJob)
    end
  end

  if settler:has(commonComponents.Path) then
    self:processSettlerPathFinding(settler)
  end

  local velocityComponent = settler:get(commonComponents.Velocity)
  velocityComponent.vector = velocityComponent.vector.normalized * settlerSpeed
end

function SettlerSystem:processSettlerPathFinding(settler)
  if not settler:has(commonComponents.Path) then return end

  local pathComponent = settler:get(commonComponents.Path)

  local position = settler:get(commonComponents.Position).vector
  local nextGridPosition

  for node, count in pathComponent.path:nodes() do
    if count == pathComponent.currentIndex then
      nextGridPosition = Vector(node:getX(), node:getY())
      break
    end
  end

  if nextGridPosition then
    local nextPosition = self.mapSystem:gridPositionToPixels(nextGridPosition, "center")
    local angle = math.atan2(nextPosition.y - position.y, nextPosition.x - position.x)
    local velocityComponent = settler:get(commonComponents.Velocity)
    velocityComponent.vector = Vector(math.cos(angle), math.sin(angle)).normalized

    if self.mapSystem:pixelsToGridCoordinates(position) == nextGridPosition then
      pathComponent.currentIndex = pathComponent.currentIndex + 1

      if pathComponent.currentIndex == table.getn(pathComponent.path._nodes)+1 then
        pathComponent.finishedCallBack()
      end
    end
  end
end

function SettlerSystem:processSubJob(settler, job)
  -- TODO: Make this logic a map from component type to method (loop through components?)
  if job:has(commonComponents.FetchJob) then
    local fetch = job:get(commonComponents.FetchJob)
    local selector = fetch.selector
    local inventoryComponent = settler:get(commonComponents.Inventory)
    local inventory = settler:get(commonComponents.Inventory)
    -- TODO: At some point in the future make sure to invalidate paths if settler task gets canceled
    if not settler:has(commonComponents.Path) then
      local existingItem = inventoryComponent:getItemBySelector(selector)
      if existingItem and existingItem:has(commonComponents.Amount) and
        existingItem:get(commonComponents.Amount).amount >= fetch.amount then
        local path = self.mapSystem.getPath(
        settler:get(commonComponents.Position).vector,
        fetch.target:get(commonComponents.Position).vector
        )

        path.finishedCallBack = function()
          settler:remove(commonComponents.Path)
        end
        settler:give(commonComponents.Path, path)
      else
        local itemsOnMap = self.itemSystem:getItemsFromGroundBySelector(selector)
        if itemsOnMap and #itemsOnMap > 0 then
          -- TODO: Get closest item to settler, for now just pick first from list
          local itemOnMap = itemsOnMap[1]
          local path = self.mapSystem:getPath(
          settler:get(commonComponents.Position).vector,
          itemOnMap:get(commonComponents.Position).vector
          )
          path.finishedCallBack = function()
            settler:remove(commonComponents.Path)
            table.insert(inventory.contents, itemOnMap)
            self.itemSystem:removeItemFromGround(itemOnMap)
            job.finished = true
          end
          settler:give(commonComponents.Path, path)
        end
      end
    else --luacheck: ignore
      -- TODO: If has path but on fetch, do we need to do anything?
    end
  end

  if job:has(commonComponents.BluePrintJob) then --luacheck: ignore

  end
end

function SettlerSystem:initalizeTestSettlers()
  for _ = 1,30,1 do
    local settler = ECS.Entity()
    local worldSize = self.mapSystem:getSize()
    local position
    while true do
      position = self.mapSystem:clampToWorldBounds(Vector(math.random(worldSize.x), math.random(worldSize.y)))
      if self.mapSystem:isCellAvailable(position) then
        break
      end
    end

    settler:give(commonComponents.Position, self.mapSystem:gridPositionToPixels(position))
    :give(commonComponents.Draw, {1,1,0})
    :give(commonComponents.Settler)
    :give(commonComponents.Inventory)
    :give(commonComponents.Worker)
    :give(commonComponents.Velocity)
    :apply()
    self:getInstance():addEntity(settler)
  end
end

function SettlerSystem:startJob(settler, job) -- luacheck: ignore
  settler:give(commonComponents.Work, job)
end

-- TODO: Needs to prioritize stuff
function SettlerSystem:assignJobsForSettlers()
  local availableWorkers = lume.filter(self.pool.objects,
  function(potentialSettler)
    return not potentialSettler:has(commonComponents.Work)
  end
  )

  for _, availableWorker in ipairs(availableWorkers) do
    local nextJob = self.jobSystem:getNextUnreservedJob()
    if not nextJob then return end

    self:startJob(availableWorker, nextJob)
  end
end



return SettlerSystem
