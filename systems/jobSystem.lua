--local inspect = require('libs/inspect')
local commonComponents = require('components/common')

local JobSystem = ECS.System({commonComponents.Job})

function JobSystem:init(mapSystem)
  self.jobs = {}
  self.mapSystem = mapSystem
end

function JobSystem:getNextUnreservedJob()
  for i, job in ipairs(self.jobs) do
    local jobComponent = job:get(commonComponents.Job)
    if not jobComponent.reserved and not jobComponent.finished then
      local firstSubJob = self:getFirstSubJob(job)
      if firstSubJob then
        local subJobComponent = firstSubJob:get(commonComponents.Job)
        --return firstSubJob
        if not subJobComponent.reserved and not subJobComponent.finished then return firstSubJob end
      end
    end
  end
end

function JobSystem:getFirstSubJob(job)
  local jobComponent = job:get(commonComponents.Job)
  if jobComponent.reserved then return nil end
  --if jobComponent.finished then return nil end
  if not job:has(commonComponents.Children) then
    return job 
  -- else
  --   if jobComponent.reserved or jobComponent.finished then return nil end
  end

  local children = job:get(commonComponents.Children).children

  local allChildrenFinished = true

  for _, child in ipairs(children) do
    local firstChildJob = self:getFirstSubJob(child)
    if firstChildJob then
      local firstChildJobComponent = firstChildJob:get(commonComponents.Job)
      if not firstChildJobComponent.finished then allChildrenFinished = false end
      --print("Foundchildjob!", firstChildJob)
      if firstChildJobComponent and not firstChildJobComponent.finished and
        not firstChildJobComponent.reserved then return firstChildJob end
    else
      allChildrenFinished = false
    end
  end

  print("allChildrenFinished", allChildrenFinished, job:has(commonComponents.BluePrintJob))
  if allChildrenFinished then return job end
  return nil
end


function JobSystem:addJob(job)
  print("Adding job", job)
  table.insert(self.jobs, job)
end


function JobSystem:blueprintActivated(bluePrint)
  self:addJob(bluePrint)
end

return JobSystem
