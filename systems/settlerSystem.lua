local Vector = require('libs/brinevector/brinevector')
--local inspect = require('libs/inspect')
local lume = require('libs/lume')
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

function SettlerSystem:processSettlerUpdate(settler)
  local velocityComponent = settler:get(commonComponents.Velocity)
  velocityComponent.vector = Vector(0, 0)
  if settler:has(commonComponents.Work) then
    self:processSubJob(settler, settler:get(commonComponents.Work).job)
    -- local work = settler:get(commonComponents.Work)
    -- if not work.currentSubJob then
    --   local job = work.job
    --   --local nextSubJob = self.jobSystem:getFirstSubJob(job)
    --   if nextSubJob then work.currentSubJob = nextSubJob end
    -- end

    -- if work.currentSubJob then
    --   self:processSubJob(settler, work.currentSubJob)
    -- end
  end

  if settler:has(commonComponents.Path) then
    self:processSettlerPathFinding(settler)
  end

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

      -- if pathComponent.currentIndex == table.getn(pathComponent.path._nodes)+1 then -- Would be +1 if wanted to reach final always
      if pathComponent.currentIndex == table.getn(pathComponent.path._nodes) then
        pathComponent.path.finishedCallBack()
      end
    end
    velocityComponent.vector = velocityComponent.vector.normalized * settlerSpeed
  end

end

function SettlerSystem:invalidatePaths()
  for _, settler in ipairs(self.pool.objects) do
    settler:remove(commonComponents.Path)
    settler:apply()
    settler.searched_for_path = false
  end
  
  print("Deleted cached paths")

end

function SettlerSystem:processSubJob(settler, job)
  -- TODO: Make this logic a map from component type to method (loop through components?)
  if job:has(commonComponents.FetchJob) then
    local fetch = job:get(commonComponents.FetchJob)
    local selector = fetch.selector
    local inventoryComponent = settler:get(commonComponents.Inventory)
    local inventory = settler:get(commonComponents.Inventory)
    settler.searched_for_path = false
    -- TODO: At some point in the future make sure to invalidate paths if settler task gets canceled
    -- TODO: Add a timer so that path doesn't get fetched too often
    -- Actually, maybe the best idea would be to use events to invalidate the map?
    if not settler:has(commonComponents.Path) and not settler.searched_for_path then -- RIGHT ON THIS IF: Is global cache valid? If not then re-get path
      local existingItem = inventoryComponent:getItemBySelector(selector)
      if existingItem and existingItem:has(commonComponents.Amount) and
        existingItem:get(commonComponents.Amount).amount >= fetch.amount then
        local path = self.mapSystem:getPath(
        self.mapSystem:pixelsToGridCoordinates(settler:get(commonComponents.Position).vector),
        self.mapSystem:pixelsToGridCoordinates(fetch.target:get(commonComponents.Position).vector)
        )

        print("Got path?", path)

        settler.searched_for_path = true

        if path then

          path.finishedCallBack = function()
            print("Finished big")
            settler.searched_for_path = false
            settler:remove(commonComponents.Path)
            settler:remove(commonComponents.Work)
            settler:apply()
            self.itemSystem:placeItemOnGround(existingItem,
            self.mapSystem:pixelsToGridCoordinates(settler:get(commonComponents.Position).vector))
            local itemData = job:get(commonComponents.Item).itemData
            local inventory = settler:get(commonComponents.Inventory)
            for selector, amount in pairs(itemData.requirements) do --luacheck: ignore
              local invItem = inventory:popItemBySelector(selector, amount)
              -- TODO: Add item onto ground again! (remember to check Position gets added)
            end
            job:get(commonComponents.Job).finished = true
            job:get(commonComponents.Job).reserved = false
            job:remove(commonComponents.Job) -- TODO: Experiment with this??
            job:apply()
          end
          settler:give(commonComponents.Path, path)
        end
      else
        local itemsOnMap = self.itemSystem:getItemsFromGroundBySelector(selector)
        if itemsOnMap and #itemsOnMap > 0 then
          -- TODO: Get closest item to settler, for now just pick first from list
          local itemOnMap = itemsOnMap[love.math.random(#itemsOnMap)]
          if itemOnMap:has(commonComponents.Position) then
            local path = self.mapSystem:getPath(
            self.mapSystem:pixelsToGridCoordinates(settler:get(commonComponents.Position).vector),
            self.mapSystem:pixelsToGridCoordinates(itemOnMap:get(commonComponents.Position).vector))

            path.finishedCallBack = function()
              print("Finished mid")
              settler.searched_for_path = false
              settler:remove(commonComponents.Path)
              settler:apply()
              table.insert(inventory.inventory, itemOnMap)
              self.itemSystem:removeItemFromGround(itemOnMap)
              --job.finished = true
            end
            settler:give(commonComponents.Path, path)
          end
        end
      end
    else --luacheck: ignore
      -- TODO: If has path but on fetch, do we need to do anything?
    end
  end

  if job:has(commonComponents.BluePrintJob) and job:has(commonComponents.Item) then --luacheck: ignore
    local itemData = job:get(commonComponents.Item).itemData
    local inventory = settler:get(commonComponents.Inventory)
    for selector, amount in pairs(itemData.requirements) do --luacheck: ignore
      local invItem = inventory:popItemBySelector(selector, amount)
      if not invItem then print("No inv to pop when trying to finish, strange", selector, amount) end 
      -- TODO: Add item onto ground again! (remember to check Position gets added)
    end
    job:get(commonComponents.Job).finished = true
    job:get(commonComponents.Job).reserved = false
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
  job:get(commonComponents.Job).reserved = true
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
