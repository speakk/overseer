--local inspect = require('libs/inspect')
local components = require('libs/concord').components

local JobSystem = ECS.System("job", {components.job})

function JobSystem:init()
  self.jobs = {}
end

local function printJob(job, level, y)
  local name = job:get(components.name).name
  local space = 15
  local jobComponent = job:get(components.job)

  if job:has(components.children) then
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

  if job:has(components.bluePrintJob) then
    local bluePrintComponent = job:get(components.bluePrintJob)
    name = name .. " Consumed: "
    for selector, item in pairs(bluePrintComponent.materialsConsumed) do
      name = name .. "| " .. selector .. " | "
    end
  end

  love.graphics.print(name, 40 + level * space, 40 + y * space, 0, 1.1, 1.1)

  if job:has(components.children) then
    local children = job:get(components.children).children

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
    if not job:has(components.parent) then -- Only go through tree roots
      local jobComponent = job:get(components.job)
      if not jobComponent.reserved and not jobComponent.finished then
        local firstSubJob = self:getFirstSubJob(job)
        if firstSubJob then
          local subJobComponent = firstSubJob:get(components.job)
          --return firstSubJob
          if not subJobComponent.finished then
            if not subJobComponent.reserved and subJobComponent.canStart then return firstSubJob end
          end
        end
      end
    end
  end
end

function JobSystem:getUnreservedJobs()
  local unreservedJobs = {}
  for _, job in ipairs(self.jobs) do
    if not job:has(components.parent) then -- Only go through tree roots
      local jobComponent = job:get(components.job)
      if not jobComponent.reserved and not jobComponent.finished then
        local firstSubJob = self:getFirstSubJob(job)
        if firstSubJob then
          local subJobComponent = firstSubJob:get(components.job)
          --return firstSubJob
          if not subJobComponent.finished then
            if not subJobComponent.reserved and subJobComponent.canStart then table.insert(unreservedJobs, firstSubJob) end
          end
        end
      end
    end
  end

  return unreservedJobs
end

function JobSystem:getFirstSubJob(job)
  local allChildrenFinished = true

  if job:has(components.children) then
    local children = job:get(components.children).children
    for _, child in ipairs(children) do
      local firstChildJob = self:getFirstSubJob(child)
      if firstChildJob then
        local firstChildJobComponent = firstChildJob:get(components.job)
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
    local jobComponent = job:get(components.job)
    jobComponent.canStart = true
  end

  return job
end

function JobSystem:finishJob(job) --luacheck: ignore
  local jobComponent = job:get(components.job)
  jobComponent.finished = true
  jobComponent.reserved = false
end

function JobSystem:addJob(job)
  table.insert(self.jobs, job)
  self:getWorld:emit("jobQueueUpdated", self.getUnreservedJobs())
end

return JobSystem
