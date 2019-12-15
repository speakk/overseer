local Vector = require('libs/brinevector/brinevector')
--local inspect = require('libs/inspect')
local lume = require('libs/lume')
local commonComponents = require('components/common')

local settlerSpeed = 200

local SettlerSystem = ECS.System({commonComponents.Settler, commonComponents.Worker,
commonComponents.Position, commonComponents.Velocity})

function SettlerSystem:init(mapSystem, jobSystem, itemSystem, bluePrintSystem)
  self.mapSystem = mapSystem
  self.jobSystem = jobSystem
  self.itemSystem = itemSystem
  self.bluePrintSystem = bluePrintSystem
  self.lastAssigned = 0
  self.assignWaitTime = 0.5
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
  local velocityComponent = settler:get(commonComponents.Velocity)
  velocityComponent.vector = Vector(0, 0)
  if not settler:has(commonComponents.Path) then
    if settler:has(commonComponents.Work) then
      self:processSubJob(settler, settler:get(commonComponents.Work).job, dt)
    end
  else
    self:processSettlerPathFinding(settler)
  end


  velocityComponent.vector = velocityComponent.vector.normalized * settlerSpeed
end

function SettlerSystem:processSettlerPathFinding(settler)
  if not settler:has(commonComponents.Path) then return end

  local pathComponent = settler:get(commonComponents.Path)

  if not pathComponent.path then
    return
  end

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

      if pathComponent.currentIndex == table.getn(pathComponent.path._nodes) then
        pathComponent.path.finishedCallBack()
        settler:remove(commonComponents.Path)
        settler:apply()
      end
    end
    velocityComponent.vector = velocityComponent.vector.normalized * settlerSpeed
  end

end

function SettlerSystem:invalidatePaths()
  for _, settler in ipairs(self.pool.objects) do
    if settler:has(commonComponents.Path) then
      local path = settler:get(commonComponents.Path).path
      if not self.mapSystem:pathStillValid(path) then
        settler:remove(commonComponents.Path)
        settler:apply()
        settler.searched_for_path = false
      end
    end
  end
end

function SettlerSystem:processSubJob(settler, job, dt)
  -- TODO: Make this logic a map from component type to method (loop through components?)
  if job:has(commonComponents.FetchJob) then
    local fetch = job:get(commonComponents.FetchJob)
    local selector = fetch.selector
    local itemData = job:get(commonComponents.Item).itemData
    local amount = itemData.requirements[selector]
    --local amount = fetch.amount -- TODO: Use this or above?
    local inventoryComponent = settler:get(commonComponents.Inventory)
    local inventory = inventoryComponent.inventory
    settler.searched_for_path = false
    if not settler.searched_for_path then
      local existingItem = self.itemSystem:getInventoryItemBySelector(inventory, selector)
      -- If already have the item, then place item on ground at target site
      if existingItem and existingItem:has(commonComponents.Amount) and
        existingItem:get(commonComponents.Amount).amount >= fetch.amount then
        local path = self.mapSystem:getPath(
        self.mapSystem:pixelsToGridCoordinates(settler:get(commonComponents.Position).vector),
        self.mapSystem:pixelsToGridCoordinates(fetch.target:get(commonComponents.Position).vector)
        )

        settler.searched_for_path = true

        if path then

          path.finishedCallBack = function()
            settler.searched_for_path = false
            settler:remove(commonComponents.Work)
            settler:apply()
            local invItem = self.itemSystem:popInventoryItemBySelector(inventory, selector, amount) -- luacheck: ignore
            job:get(commonComponents.FetchJob).finishedCallBack()
            self.jobSystem:finishJob(job)
            job:apply()
          end
          settler:give(commonComponents.Path, path)
        end
      else
        -- If we don't have item, find closest one and go fetch it
        local itemsOnMap = self.itemSystem:getItemsFromGroundBySelector(selector)
        if itemsOnMap and #itemsOnMap > 0 then
          -- TODO: Get closest item to settler, for now just pick first from list
          local itemOnMap = itemsOnMap[love.math.random(#itemsOnMap)]
          if itemOnMap:has(commonComponents.Position) then
            local path = self.mapSystem:getPath(
            self.mapSystem:pixelsToGridCoordinates(settler:get(commonComponents.Position).vector),
            self.mapSystem:pixelsToGridCoordinates(itemOnMap:get(commonComponents.Position).vector))
            if path then

              path.finishedCallBack = function()
                settler.searched_for_path = false
                settler:remove(commonComponents.Path)
                settler:apply()
                table.insert(inventory, itemOnMap)
                self.itemSystem:takeItemFromGround(itemOnMap, amount)
              end
              settler:give(commonComponents.Path, path)
            end
          end
        end
      end
    end
  end

  if job:has(commonComponents.BluePrintJob) and job:has(commonComponents.Item) then --luacheck: ignore
    local bluePrintComponent = job:get(commonComponents.BluePrintJob)
    local settlerGridPosition = self.mapSystem:pixelsToGridCoordinates(settler:get(commonComponents.Position).vector)
    local bluePrintGridPosition = self.mapSystem:pixelsToGridCoordinates(job:get(commonComponents.Position).vector)
    if self.mapSystem:isInPosition(settlerGridPosition, bluePrintGridPosition, true) then
      if self.bluePrintSystem:isBluePrintReadyToBuild(job) then
        local constructionSkill = settler:get(commonComponents.Settler).skills.construction
        bluePrintComponent.buildProgress = bluePrintComponent.buildProgress + constructionSkill * dt
        if bluePrintComponent.buildProgress >= 100 then
          self.jobSystem:finishJob(job)
          settler:remove(commonComponents.Work)
          settler:apply()
        end
      end
    else
      settler.searched_for_path = false
      if not settler.searched_for_path then -- RIGHT ON THIS IF: Is global cache valid? If not then re-get path
        local path = self.mapSystem:getPath(settlerGridPosition, bluePrintGridPosition)
        settler.searched_for_path = true
        if path then
          path.finishedCallBack = function()
            settler.searched_for_path = false
          end
          settler:give(commonComponents.Path, path)
        end
      end
    end
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
  job:get(commonComponents.Job).reserved = settler
  settler:give(commonComponents.Work, job)
end

-- TODO: Needs to prioritize stuff
function SettlerSystem:assignJobsForSettlers()

  while true do
    local availableWorker = lume.match(self.pool.objects,
    function(potentialSettler)
      return not potentialSettler:has(commonComponents.Work)
    end
    )

    if not availableWorker then break end
    local nextJob = self.jobSystem:getNextUnreservedJob()
    if not nextJob then break end

    self:startJob(availableWorker, nextJob)
  end
end



return SettlerSystem
