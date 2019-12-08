--local inspect = require('libs/inspect')
local lume = require('libs/lume')
local commonComponents = require('components/common')

local JobSystem = ECS.System({commonComponents.Job})

function JobSystem:init(mapSystem)
  --self.jobs = {}
  self.mapSystem = mapSystem
end

function JobSystem:getNextUnreservedJob()
  for i, job in ipairs(self.pool.objects) do
    if not job:has(commonComponents.Parent) then -- Only go through tree roots
      local jobComponent = job:get(commonComponents.Job)
      if not jobComponent.reserved and not jobComponent.finished then
        local firstSubJob = self:getFirstSubJob(job)
        if firstSubJob then
          local subJobComponent = firstSubJob:get(commonComponents.Job)
          --return firstSubJob
          if subJobComponent.finished then
            firstSubJob.remove(commonComponents.Job)
          else
            if not subJobComponent.reserved and subJobComponent.canStart then return firstSubJob end
          end
        end
      end
    end
  end
end

function JobSystem:getFirstSubJob(job)
  local allChildrenFinished = true

  if job:has(commonComponents.Children) then
    local children = job:get(commonComponents.Children).children
    for _, child in ipairs(children) do
      local firstChildJob = self:getFirstSubJob(child)
      if firstChildJob then
        local firstChildJobComponent = firstChildJob:get(commonComponents.Job)
        if firstChildJobComponent then
          if not firstChildJobComponent.finished then
            allChildrenFinished = false
            if not firstChildJobComponent.reserved then
              return firstChildJob
            end
          end
        end
      end
    end
  end

  if allChildrenFinished then
    if job:has(commonComponents.Job) then
      local jobComponent = job:get(commonComponents.Job)
      jobComponent.canStart = true
    end
  end

  return job
end

function JobSystem:finishJob(job)
  local jobComponent = job:get(commonComponents.Job)
  jobComponent.finished = true
  jobComponent.reserved = false
end

return JobSystem
