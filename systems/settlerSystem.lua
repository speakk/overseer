local cpml = require('libs/cpml')
local inspect = require('inspect')
local commonComponents = require('components/common')

local settlerSpeed = 200
local workQueue = {}

local SettlerSystem = ECS.System({commonComponents.Settler, commonComponents.Worker, commonComponents.Position, commonComponents.Velocity}, {commonComponents.BluePrint, "blueprints"})

function SettlerSystem:init(eventManager)
  -- self.eventManager = eventManager
  -- System.initialize(self)
  -- eventManager:addListener("blueprint_activated", self, self.blueprintActivated)
end

function SettlerSystem:update(dt)
  self:assignJobForNextAvailable()
  for _, entity in ipairs(self.pool.objects) do
    local velocity = entity:get(commonComponents.Velocity)
    local position = entity:get(commonComponents.Position)

    --print("Position", position.vector.x, position.vector.y)

    velocity.vector = cpml.vec2(0, 0)

    if entity:has(commonComponents.Work) then
      local work = entity:get(commonComponents.Work)
      local jobEntity = work.job
      local job = jobEntity:get(commonComponents.Job)
      if job.target and not job.finished then
        if job.target:has(commonComponents.Position) then
          local targetPosition = job.target:get(commonComponents.Position)
          local angle = math.atan2(targetPosition.vector.y - position.vector.y, targetPosition.vector.x - position.vector.x)
          velocity.vector = cpml.vec2(math.cos(angle), math.sin(angle)):normalize()

          local distance = cpml.vec2.dist(position.vector, targetPosition.vector)
          if distance < 2 then
            job.finished = true
            entity:get(commonComponents.Worker).available = true
            for i, v in ipairs(workQueue) do
              if v == jobEntity then
                table.remove(workQueue, i)
                break
              end
            end
          end
        end
      end
    end

    velocity.vector = velocity.vector:normalize() * settlerSpeed
  end
end

function SettlerSystem:getAvailableWorkers()
  local availableWorkers = {}

  for _, entity in ipairs(self.pool.objects) do
    if entity:get(commonComponents.Worker).available then
      table.insert(availableWorkers, entity)
    end
  end

  return availableWorkers
end

function SettlerSystem:blueprintActivated(bluePrint)
  local job = ECS.Entity()
  job:give(commonComponents.Job, bluePrint, false, false)
  --bluePrint:give(commonComponents.WorkTarget, false, true)
  table.insert(workQueue, job)
  print("Inserted", job)
  print("Self here", self)

  --self:assignJobForNextAvailable()
end

function SettlerSystem:getNextJob()
  local unfinishedJob = nil
  for _, job in ipairs(workQueue) do
    local jobComponent = job:get(commonComponents.Job)
    if not jobComponent.reserved and not jobComponent.finished then
      unfinishedJob = job
      break
    end
  end

  return unfinishedJob
end

function SettlerSystem:assignJobForNextAvailable()
  local nextJob = self:getNextJob()
  --print("NextJob?", nextJob)

  if nextJob then
    local jobComponent = nextJob:get(commonComponents.Job)
    local availableWorkers = self:getAvailableWorkers()
    if table.getn(availableWorkers) > 0 then
      -- availableWorkers[1]:give(commonComponents.Job, jobComponent.target, jobComponent.reserved, jobComponent.finished)
      if not jobComponent.reserved then
        print("Giving job", nextJob)
        jobComponent.reserved = true
        availableWorkers[1]:give(commonComponents.Work, nextJob)
        availableWorkers[1]:get(commonComponents.Worker).available = false
      end
    end
  end
end

-- function SettlerSystem.blueprintActivated(table, event)
--   print("Activated", table, event)
-- end

return SettlerSystem

