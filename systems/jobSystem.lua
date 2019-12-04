local commonComponents = require('components/common')

local JobSystem = ECS.System({commonComponents.Job})

function JobSystem:init()
  self.jobs = {}
end

function JobSystem:getNextUnreservedJob()
  local unreservedJob = nil

  for index, job in ipairs(self.jobs) do
    local jobComponent = job:get(commonComponents.Job)
    if not jobComponent.reserved and not jobComponent.finished then
      unfinishedJob = job
      break
    end
  end

  return unreservedJob
end

function JobSystem:generateBluePrintJob(gridPosition, itemData)
  local job = ECS.Entity()
  job:give(commonComponent.Job)
  job:give(commonComponent.BluePrintJob)
  job:give(commonComponent.Draw, itemData.color)
  job:give(commonComponent.Item, itemData)
  job:give(commonComponent.Position)

  if itemData.requirements then
    job:give(commonComponent.Children)
    local children = job:get(commonComponent.Children).children
    for selector, amount in pairs(itemData.requirements) do
      local subJob = ECS.Entity()
      subJob:give(commonComponent.Job)
      subJob:give(commonComponent.FetchJob, job, selector, amount)
      subJob:apply()
      table.insert(children, subJob)
    end
  end

  job:apply()

  return job
end

return JobSystem
