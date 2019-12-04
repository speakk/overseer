local Vector = require('libs/brinevector/brinevector')
local inspect = require('libs/inspect')
local lume = require('libs/lume')
local commonComponents = require('components/common')

local settlerSpeed = 200

local SettlerSystem = ECS.System(
{commonComponents.Settler, commonComponents.Worker, commonComponents.Position, commonComponents.Velocity},
{commonComponents.BluePrint, "blueprints"}
)

function SettlerSystem:init(mapSystem)
  self.mapSystem = mapSystem
  self.workQueue = {}
  self.lastAssigned = 0
  self.assignWaitTime = 0.5
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
    --print("Self", self)
    self:getInstance():addEntity(settler)
  end

end

-- What is a job?
--  Job can have properties like:
--    What happens when the job is finished
--    What does the job require for it to be finished
--      Job can have subjobs
--    Sometimes these subjobs need to be in order, sometimes not?
--    Examples of jobs:
--      - Fetch job (get x amount if items from a, bring them to b).
--        - Even one fetch job can be split into multiple,
--          if settlers can't carry everything at once.
--          Or is it one job for each material type?
--        - Maybe when a fetch-material job is taken by a settler who can't complete it fully, the job is split:
--          - Fetch job requires 50 wood. Settler "reserves" 30 wood knowing where to find those.
--            - This get added as a split job?? Parallel to original fetch job or as a subJob?
--              If this attempt gets invalidated, what happens? There's no easy way to merge these jobs together again?
--              This hints at a need to model "fetch-job requires x amount" maybe separately from the concept of job?
--        - Or should jobs be created based on a Need?
--          - Need = "These materials need to be here"
--          - Job would be created in real time in update "Hey, I can get some of these materials"
--          - Could this be modeled as sub-jobs instead?
--      - Build job (once stuff is fetched, construct the thing)
--        - This sounds like "Need" is not maybe needed, maybe the "main job" is the need, and
--          sub jobs are the way they get done
--      - Heal someone (consists of: fetch healing material, then heal)

function SettlerSystem:findNextTarget(settler)
  --print ("Finding for", inspect(settler))
  local path = nil
  local work = settler:get(commonComponents.Work)
  local jobEntity = work.job
  local job = jobEntity:get(commonComponents.Job)
  if job.target and not job.finished then
    local jobTarget = job.target
    local itemData = jobTarget:get(commonComponents.Item).itemData
    if itemData.requirements then
      local inventory = settler:get(commonComponents.Inventory).contents
      -- Loop through requirements. If requirement not in inventory,
      -- mark it in the missing variable
      local missingSelector = nil
      for key, amount in pairs(itemData.requirements) do
        local match = lume.match(inventory,
        function(invItem) return invItem:get(commonComponents.Selector).selector == key end)
        if not match then
          missingSelector = key
          break
        end
      end

      if missingSelector then
        local itemsOnMap = self.itemSystem:getItemsFromGroundBySelector(missingSelector)
        if itemsOnMap then
          -- TODO: Get closest item to settler, for now just pick first from list
          local itemOnMap = itemsOnMap[1]
          path = self.mapSystem:getPath(
          settler:get(commonComponents.Position).vector,
          itemOnMap:get(commonComponents.Position).vector
          )
        end
      else
        path = self:findDirectPathForJobTarget(settler, job)
      end
    else
      path = self:findDirectPathForJobTarget(settler, job)
    end
  end

  if path then
    job.reserved = true
    settler:give(commonComponents.Work, job)
    settler:set(commonComponents.Path, path)
  end

  return path
end

function SettlerSystem:findDirectPathForJobTarget(settler, job)
  local position = self.mapSystem:pixelsToGridCoordinates(settler:get(commonComponents.Position).vector)
  local targetPosition = self.mapSystem:pixelsToGridCoordinates(job.target:get(commonComponents.Position).vector)
  local path = self.mapSystem:getPath(position, targetPosition)

  if not path then
    return false
  end

  return true
end

-- Marked for optimization
function SettlerSystem:update(dt) --luacheck: ignore
  if love.timer.getTime() - self.lastAssigned > self.assignWaitTime then
    self:assignJobForNextAvailable()
    self.lastAssigned = love.timer.getTime()
  end

  for _, entity in ipairs(self.pool.objects) do
    local velocity = entity:get(commonComponents.Velocity)
    local position = entity:get(commonComponents.Position)

    velocity.vector = Vector(0, 0)

    if entity:has(commonComponents.Work) then
      local work = entity:get(commonComponents.Work)
      local jobEntity = work.job
      local job = jobEntity:get(commonComponents.Job)
      if job.target and not job.finished then
        if job.target:has(commonComponents.Position) and entity:has(commonComponents.Path) then
          local pathComponent = entity:get(commonComponents.Path)

          if not pathComponent.path then
            -- Oops no valid path!!
            print("No valid path")
            job.reserved = false
            entity:remove(commonComponents.Path)
            entity:remove(commonComponents.Work)
          else
            local nextGridPosition

            for node, count in pathComponent.path:nodes() do
              --print("currentIndex", pathComponent.currentIndex, "count", count)
              if count == pathComponent.currentIndex then
                nextGridPosition = Vector(node:getX(), node:getY())
                break
              end
            end

            if nextGridPosition then
              local nextPosition = self.mapSystem:gridPositionToPixels(nextGridPosition, "center")
              local angle = math.atan2(nextPosition.y - position.vector.y, nextPosition.x - position.vector.x)
              velocity.vector = Vector(math.cos(angle), math.sin(angle)).normalized

              if self.mapSystem:pixelsToGridCoordinates(position.vector) == nextGridPosition then
                pathComponent.currentIndex = pathComponent.currentIndex + 1

                if pathComponent.currentIndex == table.getn(pathComponent.path._nodes)+1 then
                  job.finished = true
                  entity:remove(commonComponents.Path)
                  entity:remove(commonComponents.Work):apply()
                  self:getInstance():emit("bluePrintFinished", job.target)
                  for i, v in ipairs(self.workQueue) do
                    if v == jobEntity then
                      table.remove(self.workQueue, i)
                      break
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    velocity.vector = velocity.vector.normalized * settlerSpeed
  end
end

function SettlerSystem:getAvailableWorkers()
  local availableWorkers = {}

  for _, entity in ipairs(self.pool.objects) do
    if not entity:has(commonComponents.Work) then
      table.insert(availableWorkers, entity)
    end
  end

  return availableWorkers
end

function SettlerSystem:blueprintActivated(bluePrint)
  local job = ECS.Entity()
  job:give(commonComponents.Job, bluePrint, false, false)
  table.insert(self.workQueue, job)
end

function SettlerSystem:getNextJob()
  local unfinishedJob = nil

  for _, job in ipairs(self.workQueue) do
    local jobComponent = job:get(commonComponents.Job)
    if not jobComponent.reserved and not jobComponent.finished then
      unfinishedJob = job
      break
    end
  end

  if unfinishedJob then unfinishedJob.reserved = true end
  return unfinishedJob
end

-- Marked for optimization
function SettlerSystem:assignJobForNextAvailable()
  local nextJob = self:getNextJob()

  if nextJob then
    local jobComponent = nextJob:get(commonComponents.Job)
    local availableWorkers = self:getAvailableWorkers()
    if table.getn(availableWorkers) > 0 then
      local availableWorker = availableWorkers[math.random(1, #availableWorkers)]
      self:findNextTarget(availableWorker)
      -- local position = self.mapSystem:pixelsToGridCoordinates(availableWorker:get(commonComponents.Position).vector)
      -- local targetPosition = self.mapSystem:pixelsToGridCoordinates(
      -- jobComponent.target:get(commonComponents.Position).vector
      -- )
      -- local path = self.mapSystem:getPath(position, targetPosition)

      -- if not path then
      --   return
      -- end

      -- jobComponent.reserved = true
      -- availableWorker:give(commonComponents.Work, nextJob)
      -- availableWorker:give(commonComponents.Path, path)
    else
      jobComponent.reserved = false

      -- Move job to the last position
      for i, v in ipairs(self.workQueue) do
        if v == nextJob then
          table.remove(self.workQueue, i)
          break
        end
      end
      table.insert(self.workQueue, nextJob)
    end
  end
end

return SettlerSystem

