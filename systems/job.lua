local inspect = require('libs.inspect') -- luacheck: ignore
local lume = require('libs.lume')
local utils = require('utils.utils')

local entityReferenceManager = require('models.entityReferenceManager')

local JobSystem = ECS.System({ECS.Components.job, 'jobs'})

local function onJobAdded(self, pool, job)
  -- if not job:has(ECS.Components.parent) then
  --   table.insert(self.jobs, job)
  --   job:getWorld():emit("jobQueueUpdated", self:getUnreservedJobs())
  -- end
end

function JobSystem:init()
  -- self.jobs = {}
  -- self.pool.onEntityAdded = function(pool, job)
  --   onJobAdded(self, pool, job)
  -- end
  --TODO: onEntityRemoved
end

local function printJob(job, level, y, isChild)
  if not job:has(ECS.Components.job) then return nil end
  local name = tostring(job) .. ": " .. job:get(ECS.Components.job).jobType
  if isChild then name = name .. " (child)" end
  local space = 15
  local jobComponent = job:get(ECS.Components.job)
  if not jobComponent then return end

  if job:has(ECS.Components.children) then
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

  if job:has(ECS.Components.bluePrintJob) then
    local bluePrintComponent = job:get(ECS.Components.bluePrintJob)
    name = name .. " Consumed: "
    for selector, item in pairs(bluePrintComponent.materialsConsumed) do --luacheck: ignore
      name = name .. "| " .. selector .. " | "
    end
  end

  love.graphics.print(name, 40 + level * space, 40 + y * space, 0, 1.1, 1.1)

  if job:has(ECS.Components.children) then
    local childrenIds = job:get(ECS.Components.children).children
    --print("Childcomp?", job:get(ECS.Components.children).children)

    if childrenIds then
      for _, childId in ipairs(childrenIds) do
        local child = entityReferenceManager.getEntity(childId)
        printJob(child, level + 1, y + 1, true)
      end
    end
  end

end

function JobSystem:draw()
  if DEBUG then
    for i, job in ipairs(self.jobs) do
      printJob(job, 0, i*3)
    end
  end
end

-- function JobSystem:getNextUnreservedJob()
--   for _, job in ipairs(self.jobs) do
--     if not job:has(ECS.Components.parent) then -- Only go through tree roots
--       local jobComponent = job:get(ECS.Components.job)
--       if not jobComponent.reserved and not jobComponent.finished then
--         local firstSubJob = self:getFirstSubJob(job)
--         if firstSubJob then
--           local subJobComponent = firstSubJob:get(ECS.Components.job)
--           --return firstSubJob
--           if not subJobComponent.finished and not subJobComponent.isInaccessible then
--             if not subJobComponent.reserved and subJobComponent.canStart then return firstSubJob end
--           end
--         end
--       end
--     end
--   end
-- end

local function getChildren(job)
  if job:get(ECS.Components.children) then
    return lume.map(job:get(ECS.Components.children).children, function(childId)
      return entityReferenceManager.getEntity(childId)
    end)
  end

  return nil
end

function JobSystem:gridUpdated()
  for _, mainJob in ipairs(self.jobs) do
    utils.traverseTree(mainJob, getChildren, function(job)
      if job:has(ECS.Components.job) then
        job:get(ECS.Components.job).isInaccessible = false
      end
    end)
  end
end

function JobSystem:getUnreservedJobs()
  local unreservedJobs = {}
  for _, job in ipairs(self.jobs) do
    if not job:has(ECS.Components.parent) and job:has(ECS.Components.job) then -- Only go through tree roots
      local jobComponent = job:get(ECS.Components.job)
      if not jobComponent.reserved and not jobComponent.finished then
        local firstSubJob = self:getFirstSubJob(job)
        if firstSubJob then
          local subJobComponent = firstSubJob:get(ECS.Components.job)
          --return firstSubJob
          if not subJobComponent.finished then
            if not subJobComponent.reserved and subJobComponent.canStart then
              table.insert(unreservedJobs, firstSubJob)
            end
          end
        end
      end
    end
  end

  print("Returning", unreservedJobs)
  return unreservedJobs
end

function JobSystem:getFirstSubJob(job)
  local allChildrenFinished = true

  if job:has(ECS.Components.children) then
    local childrenIds = job:get(ECS.Components.children).children
    for _, childId in ipairs(childrenIds) do
      local child = entityReferenceManager.getEntity(childId)
      local firstChildJob = self:getFirstSubJob(child)
      if firstChildJob then
        local firstChildJobComponent = firstChildJob:get(ECS.Components.job)
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
    local jobComponent = job:get(ECS.Components.job)
    if jobComponent then
      jobComponent.canStart = true
    end
  end

  return job
end

function JobSystem:jobFinished(job) --luacheck: ignore
  local jobComponent = job:get(ECS.Components.job)
  if job:has(ECS.Components.parent) then
    jobComponent.finished = true
    jobComponent.reserved = false
  else
    job:remove(ECS.Components.job)
  end

  self:getWorld():emit("jobQueueUpdated", self:getUnreservedJobs())
end

--function JobSystem:addJob(job)
--  table.insert(self.jobs, job)
--  self:getWorld():emit("jobQueueUpdated", self:getUnreservedJobs())
--end

return JobSystem
