local Vector = require('libs.brinevector')
local inspect = require('libs.inspect')
local lume = require('libs.lume')
local itemUtils = require('utils.itemUtils')
local bluePrintUtils = require('utils.bluePrintUtils')
local media = require('utils.media')
local universe = require('models.universe')

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
        pathComponent.path.finishedCallBack()
        settler:remove(ECS.Components.path)
      end
    end
    velocityComponent.vector = velocityComponent.vector.normalized * settlerSpeed
  end

end

function SettlerSystem:invalidatePaths()
  for _, settler in ipairs(self.pool) do
    if settler:has(ECS.Components.path) then
      local path = settler:get(ECS.Components.path).path
      if not universe.pathStillValid(path) then
        settler:remove(ECS.Components.path)
        settler.searched_for_path = false
      end
    end
  end
end

local function handleFetchJob(self, job, settler, dt)
  local fetch = job:get(ECS.Components.fetchJob)
  local selector = fetch.selector
  local itemData = job:get(ECS.Components.item).itemData
  local amount = itemData.requirements[selector]
  --local amount = fetch.amount -- TODO: Use this or above?
  local inventoryComponent = settler:get(ECS.Components.inventory)
  local inventory = inventoryComponent.inventory
  settler.searched_for_path = false
  if not settler.searched_for_path then
    local existingItem = itemUtils.getInventoryItemBySelector(inventory, selector)
    -- If already have the item, then place item on ground at target site
    if existingItem and existingItem:has(ECS.Components.amount) and
      existingItem:get(ECS.Components.amount).amount >= fetch.amount then
      local path = universe.getPath(
      universe.pixelsToGridCoordinates(settler:get(ECS.Components.position).vector),
      universe.pixelsToGridCoordinates(fetch.target:get(ECS.Components.position).vector)
      )

      settler.searched_for_path = true

      if path then

        path.finishedCallBack = function()
          settler.searched_for_path = false
          settler:remove(ECS.Components.work)
          local invItem = itemUtils.popInventoryItemBySelector(inventory, selector, amount) -- luacheck: ignore
          job:get(ECS.Components.fetchJob).finishedCallBack()
          self:getWorld():emit("jobFinished", job)
        end
        settler:give(ECS.Components.path, path)
      end
    else
      -- If we don't have item, find closest one and go fetch it
      local itemsOnMap = itemUtils.getItemsFromGroundBySelector(selector)
      if itemsOnMap and #itemsOnMap > 0 then
        -- TODO: Get closest item to settler, for now just pick first from list
        local itemOnMap = itemsOnMap[love.math.random(#itemsOnMap)]
        if itemOnMap:has(ECS.Components.position) then
          local path = universe.getPath(
          universe.pixelsToGridCoordinates(settler:get(ECS.Components.position).vector),
          universe.pixelsToGridCoordinates(itemOnMap:get(ECS.Components.position).vector))
          if path then

            path.finishedCallBack = function()
              settler.searched_for_path = false
              settler:remove(ECS.Components.path)
              table.insert(inventory, itemOnMap)
              itemUtils.takeItemFromGround(itemOnMap, amount)
            end
            settler:give(ECS.Components.path, path)
          end
        end
      end
    end
  end
end

local function handleBluePrintJob(self, job, settler, dt)
  local bluePrintComponent = job:get(ECS.Components.bluePrintJob)
  local settlerGridPosition = universe.pixelsToGridCoordinates(settler:get(ECS.Components.position).vector)
  local bluePrintGridPosition = universe.pixelsToGridCoordinates(job:get(ECS.Components.position).vector)
  if universe.isInPosition(settlerGridPosition, bluePrintGridPosition, true) then
    if bluePrintUtils.isBluePrintReadyToBuild(job) then
      local constructionSkill = settler:get(ECS.Components.settler).skills.construction
      bluePrintComponent.buildProgress = bluePrintComponent.buildProgress + constructionSkill * dt
      if bluePrintComponent.buildProgress >= 100 then
        self:getWorld():emit("jobFinished", job)
        settler:remove(ECS.Components.work)
      end
    end
  else
    settler.searched_for_path = false
    if not settler.searched_for_path then -- RIGHT ON THIS IF: Is global cache valid? If not then re-get path
      local path = universe.getPath(settlerGridPosition, bluePrintGridPosition)
      settler.searched_for_path = true
      if path then
        path.finishedCallBack = function()
          settler.searched_for_path = false
        end
        settler:give(ECS.Components.path, path)
      end
    end
  end
end

local jobHandlers = {
  fetchJob = handleFetchJob,
  bluePrintJob = handleBluePrintJob
}

function SettlerSystem:processSubJob(settler, job, dt)
  for component in pairs(job:getComponents()) do
    local jobHandler = jobHandlers[component:getName()]
    if jobHandler then
      jobHandler(self, job, settler, dt)
    end
  end
end

function SettlerSystem:initializeTestSettlers()
  for _ = 1,30,1 do
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
    print(self)
    print("world", self:getWorld())
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

return SettlerSystem
