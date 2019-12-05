local inspect = require('libs/inspect')
local commonComponents = require('components/common')

local JobSystem = ECS.System({commonComponents.Job})

function JobSystem:init(mapSystem)
  self.jobs = {}
  self.mapSystem = mapSystem
end

function JobSystem:getNextUnreservedJob()
  local unreservedJob = nil

  for _, job in ipairs(self.jobs) do
    local jobComponent = job:get(commonComponents.Job)
    if not jobComponent.reserved and not jobComponent.finished then
      unreservedJob = job
      break
    end
  end

  return unreservedJob
end

function JobSystem:addJob(job)
  print("Adding job", job)
  table.insert(self.jobs, job)
end


function JobSystem:blueprintActivated(bluePrint)
  self:addJob(bluePrint)
end

return JobSystem
