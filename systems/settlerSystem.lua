local Vector = require('libs/brinevector/brinevector')
--local inspect = require('libs/inspect')
local lume = require('libs/lume')
local utils = require('utils/utils')
local bluePrintUtils = require('utils/bluePrintUtils')
local media = require('utils/media')
local components = require('libs/concord').components

local settlerSpeed = 200

local SettlerSystem = ECS.System("settler", {components.settler, components.worker,
components.position, components.velocity})

function SettlerSystem:init()
  self.lastAssigned = 0
  self.assignWaitTime = 0.5
  self.workQueue = {}

  self.tilesetBatch = love.graphics.newSpriteBatch(media.sprites, 200)
end

function SettlerSystem:update(dt) --luacheck: ignore
  local time = love.timer.getTime()
  if time - self.lastAssigned > self.assignWaitTime then
    self:assignJobsForSettlers()
    self.lastAssigned = time
  end

  for _, settler in ipairs(self.pool.objects) do
    self:processSettlerUpdate(settler, dt)
  end
end

function SettlerSystem:processSettlerUpdate(settler, dt)
  local velocityComponent = settler:get(components.velocity)
  velocityComponent.vector = Vector(0, 0)
  if not settler:has(components.path) then
    if settler:has(components.work) then
      self:processSubJob(settler, settler:get(components.work).job, dt)
    end
  else
    self:processSettlerPathFinding(settler)
  end


  velocityComponent.vector = velocityComponent.vector.normalized * settlerSpeed
end

function SettlerSystem:processSettlerPathFinding(settler)
  if not settler:has(components.path) then return end

  local pathComponent = settler:get(components.path)

  if not pathComponent.path then
    return
  end

  local position = settler:get(components.position).vector
  local nextGridPosition

  for node, count in pathComponent.path:nodes() do
    if count == pathComponent.currentIndex then
      nextGridPosition = Vector(node:getX(), node:getY())
      break
    end
  end

  if nextGridPosition then
    local nextPosition = gridUtils.gridPositionToPixels(nextGridPosition, "center")
    local angle = math.atan2(nextPosition.y - position.y, nextPosition.x - position.x)
    local velocityComponent = settler:get(components.velocity)
    velocityComponent.vector = Vector(math.cos(angle), math.sin(angle)).normalized

    if gridUtils.pixelsToGridCoordinates(position) == nextGridPosition then
      pathComponent.currentIndex = pathComponent.currentIndex + 1

      if pathComponent.currentIndex == table.getn(pathComponent.path._nodes) then
        pathComponent.path.finishedCallBack()
        settler:remove(components.path)
        settler:apply()
      end
    end
    velocityComponent.vector = velocityComponent.vector.normalized * settlerSpeed
  end

end

function SettlerSystem:invalidatePaths()
  for _, settler in ipairs(self.pool.objects) do
    if settler:has(components.path) then
      local path = settler:get(components.path).path
      if not gridUtils.pathStillValid(path) then
        settler:remove(components.path)
        settler:apply()
        settler.searched_for_path = false
      end
    end
  end
end

function SettlerSystem:processSubJob(settler, job, dt)
  -- TODO: Make this logic a map from component type to method (loop through components?)
  if job:has(components.fetchJob) then
    local fetch = job:get(components.fetchJob)
    local selector = fetch.selector
    local itemData = job:get(components.item).itemData
    local amount = itemData.requirements[selector]
    --local amount = fetch.amount -- TODO: Use this or above?
    local inventoryComponent = settler:get(components.inventory)
    local inventory = inventoryComponent.inventory
    settler.searched_for_path = false
    if not settler.searched_for_path then
      local existingItem = itemUtils.getInventoryItemBySelector(inventory, selector)
      -- If already have the item, then place item on ground at target site
      if existingItem and existingItem:has(components.amount) and
        existingItem:get(components.amount).amount >= fetch.amount then
        local path = gridUtils.getPath(
        gridUtils.pixelsToGridCoordinates(settler:get(components.position).vector),
        gridUtils.pixelsToGridCoordinates(fetch.target:get(components.position).vector)
        )

        settler.searched_for_path = true

        if path then

          path.finishedCallBack = function()
            settler.searched_for_path = false
            settler:remove(components.work)
            settler:apply()
            local invItem = itemUtils.popInventoryItemBySelector(inventory, selector, amount) -- luacheck: ignore
            job:get(components.fetchJob).finishedCallBack()
            self:getWorld():emit("jobFinished", job)
            job:apply()
          end
          settler:give(components.path, path)
        end
      else
        -- If we don't have item, find closest one and go fetch it
        local itemsOnMap = itemUtils.getItemsFromGroundBySelector(selector)
        if itemsOnMap and #itemsOnMap > 0 then
          -- TODO: Get closest item to settler, for now just pick first from list
          local itemOnMap = itemsOnMap[love.math.random(#itemsOnMap)]
          if itemOnMap:has(components.position) then
            local path = gridUtils.getPath(
            gridUtils.pixelsToGridCoordinates(settler:get(components.position).vector),
            gridUtils.pixelsToGridCoordinates(itemOnMap:get(components.position).vector))
            if path then

              path.finishedCallBack = function()
                settler.searched_for_path = false
                settler:remove(components.path)
                settler:apply()
                table.insert(inventory, itemOnMap)
                itemUtils.takeItemFromGround(itemOnMap, amount)
              end
              settler:give(components.path, path)
            end
          end
        end
      end
    end
  end

  if job:has(components.bluePrintJob) and job:has(components.Item) then --luacheck: ignore
    local bluePrintComponent = job:get(components.bluePrintJob)
    local settlerGridPosition = gridUtils.pixelsToGridCoordinates(settler:get(components.position).vector)
    local bluePrintGridPosition = gridUtils.pixelsToGridCoordinates(job:get(components.position).vector)
    if gridUtils.isInPosition(settlerGridPosition, bluePrintGridPosition, true) then
      if bluePrintUtils.isBluePrintReadyToBuild(job) then
        local constructionSkill = settler:get(components.settler).skills.construction
        bluePrintComponent.buildProgress = bluePrintComponent.buildProgress + constructionSkill * dt
        if bluePrintComponent.buildProgress >= 100 then
          self:getWorld():emit("jobFinished", job)
          settler:remove(components.work)
          settler:apply()
        end
      end
    else
      settler.searched_for_path = false
      if not settler.searched_for_path then -- RIGHT ON THIS IF: Is global cache valid? If not then re-get path
        local path = gridUtils.getPath(settlerGridPosition, bluePrintGridPosition)
        settler.searched_for_path = true
        if path then
          path.finishedCallBack = function()
            settler.searched_for_path = false
          end
          settler:give(components.path, path)
        end
      end
    end
  end


end

function SettlerSystem:initializeTestSettlers()
  for _ = 1,30,1 do
    local settler = ECS.Entity()
    local worldSize = gridUtils.getSize()
    local position
    while true do
      position = gridUtils.clampToWorldBounds(Vector(math.random(worldSize.x), math.random(worldSize.y)))
      if gridUtils.isCellAvailable(position) then
        break
      end
    end

    settler:give(components.position, gridUtils.gridPositionToPixels(position))
    --:give(components.draw, {1,1,0})
    :give(components.sprite, 'characters.settler')
    :give(components.settler)
    :give(components.inventory)
    :give(components.worker)
    :give(components.velocity)
    :apply()
    self:getWorld():addEntity(settler)
  end
end

function SettlerSystem:startJob(settler, job, jobQueue) -- luacheck: ignore
  job:get(components.job).reserved = settler
  settler:give(components.work, job)
  lume.remove(jobQueue, job)
end

function SettlerSystem:jobQueueUpdated(jobQueue)
  self:assignJobsForSettlers(jobQueue)
end

-- TODO: Needs to prioritize stuff
function SettlerSystem:assignJobsForSettlers(jobQueue)

  while true do
    local availableWorker = lume.match(self.pool.objects,
    function(potentialSettler)
      return not potentialSettler:has(components.work)
    end
    )

    if not availableWorker then break end
    local nextJob = jobQueue[1]
    if not nextJob then break end

    self:startJob(availableWorker, nextJob, jobQueue)
  end
end

return SettlerSystem
