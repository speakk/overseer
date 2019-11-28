--local cpml = require('libs/cpml')
local Vector = require('libs/brinevector/brinevector')
local inspect = require('libs/inspect')
local commonComponents = require('components/common')

local settlerSpeed = 200

local SettlerSystem = ECS.System({commonComponents.Settler, commonComponents.Worker, commonComponents.Position, commonComponents.Velocity}, {commonComponents.BluePrint, "blueprints"})

function SettlerSystem:init(mapSystem)
  self.mapSystem = mapSystem
  self.workQueue = {}
  self.lastAssigned = 0
  self.assignWaitTime = 0.5
end

function SettlerSystem:update(dt)
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
          local finalPosition = job.target:get(commonComponents.Position)
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
              nextPosition = self.mapSystem:gridPositionToPixels(nextGridPosition, "center")
              local angle = math.atan2(nextPosition.y - position.vector.y, nextPosition.x - position.vector.x)
              velocity.vector = Vector(math.cos(angle), math.sin(angle)).normalized

              if self.mapSystem:pixelsToGridCoordinates(position.vector) == nextGridPosition then
                --local distance = Vector.dist(position.vector, nextPosition)
                --if distance < 1.5 then
                pathComponent.currentIndex = pathComponent.currentIndex + 1

                if pathComponent.currentIndex == table.getn(pathComponent.path._nodes)+1 then
                  job.finished = true
                  --entity:get(commonComponents.Worker).available = true
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

  -- while true do
  --   local job = self.workQueue[math.random(1, #self.workQueue)]
  --   unfinishedJob = job
  --   break
  -- end

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

function SettlerSystem:assignJobForNextAvailable()
  local nextJob = self:getNextJob()

  if nextJob then
    local jobComponent = nextJob:get(commonComponents.Job)
    local availableWorkers = self:getAvailableWorkers()
    if table.getn(availableWorkers) > 0 then
      local availableWorker = availableWorkers[math.random(1, #availableWorkers)]
      local position = self.mapSystem:pixelsToGridCoordinates(availableWorker:get(commonComponents.Position).vector)
      local targetPosition = self.mapSystem:pixelsToGridCoordinates(jobComponent.target:get(commonComponents.Position).vector)
      local path = self.mapSystem:getPath(position, targetPosition)

      if not path then
        return
      end

      jobComponent.reserved = true
      availableWorker:give(commonComponents.Work, nextJob)
      --availableWorker:get(commonComponents.Worker).available = false

      availableWorker:give(commonComponents.Path, path)
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

