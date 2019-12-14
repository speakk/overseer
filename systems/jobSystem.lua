--local inspect = require('libs/inspect')
local commonComponents = require('components/common')

local JobSystem = ECS.System({commonComponents.Job})

function JobSystem:init(mapSystem)
  self.mapSystem = mapSystem
  self.jobs = {}
end

function printJob(job, level, y)
  local name = job:get(commonComponents.Name).name
  local space = 15
  local jobComponent = job:get(commonComponents.Job)

  if job:has(commonComponents.Children) then
    love.graphics.setColor(0, 1, 0)
  else
    love.graphics.setColor(1, 0, 0)
  end
  if jobComponent.finished then
    love.graphics.setColor(1, 1, 1)
    name = "x " .. name
  end

  if jobComponent.reserved then
    name = name .. " - reserved by " .. tostring(jobComponent.reserved)
  end

  if job:has(commonComponents.BluePrintJob) then
    local bluePrintComponent = job:get(commonComponents.BluePrintJob)
    name = name .. " Consumed: "
    for selector, item in pairs(bluePrintComponent.materialsConsumed) do
      name = name .. "| " .. selector .. " | "
    end
  end

  love.graphics.print(name, 40 + level * space, 40 + y * space, 0, 1.1, 1.1)

  if job:has(commonComponents.Children) then
    local children = job:get(commonComponents.Children).children

    if children then
      for i, child in ipairs(children) do
        printJob(child, level + 1, y + 1)
      end
    else
    end
  else
  end

end

function JobSystem:draw()
  if DEBUG then
    for i, job in ipairs(self.jobs) do
      printJob(job, 0, i*3)
    end
  end
end

function JobSystem:getNextUnreservedJob()
  for _, job in ipairs(self.jobs) do
    if not job:has(commonComponents.Parent) then -- Only go through tree roots
      local jobComponent = job:get(commonComponents.Job)
      if not jobComponent.reserved and not jobComponent.finished then
        local firstSubJob = self:getFirstSubJob(job)
        if firstSubJob then
          local subJobComponent = firstSubJob:get(commonComponents.Job)
          --return firstSubJob
          if not subJobComponent.finished then
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
        if not firstChildJobComponent.finished then
          allChildrenFinished = false
          if not firstChildJobComponent.reserved then
            return firstChildJob
          end
        end
      end
    end
  end

  if allChildrenFinished then
    local jobComponent = job:get(commonComponents.Job)
    jobComponent.canStart = true
  end

  return job
end

function JobSystem:finishJob(job) --luacheck: ignore
  local jobComponent = job:get(commonComponents.Job)
  jobComponent.finished = true
  jobComponent.reserved = false
end

function JobSystem:addJob(job)
  table.insert(self.jobs, job)
end

return JobSystem
