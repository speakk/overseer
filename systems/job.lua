local inspect = require('libs.inspect') -- luacheck: ignore
local lume = require('libs.lume')
local utils = require('utils.utils')

local jobManager = require('models.jobManager')
local jobHandlers = require('models.jobTypes.jobTypes')

local entityManager = require('models.entityManager')

local JobSystem = ECS.System({ECS.c.job, 'jobs'})

local function onJobAdded(self, pool, job)
  -- if not job:has(ECS.c.parent) then
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

local function printJob(job, level, y)
  if not job or not job:has(ECS.c.job) then return nil end
  local name = tostring(job) .. ": " .. job:get(ECS.c.job).jobType
  local isChild = job:has(ECS.c.parent)
  if isChild and level == 1 then return nil end
  if isChild then name = name .. " (child)" end
  local space = 6
  local jobComponent = job:get(ECS.c.job)
  if not jobComponent then return end

  if job:has(ECS.c.children) then
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

  if job:has(ECS.c.bluePrintJob) then
    local bluePrintComponent = job:get(ECS.c.bluePrintJob)
    name = name .. " Consumed: "
    for selector, item in pairs(bluePrintComponent.materialsConsumed) do --luacheck: ignore
      name = name .. "| " .. selector .. " | "
    end
  end

  love.graphics.print(name, 40 + level * space, 40 + y * space, 0, 1.1, 1.1)

  if job:has(ECS.c.children) then
    local childrenIds = job:get(ECS.c.children).children
    --print("Childcomp?", job:get(ECS.c.children).children)

    if childrenIds then
      for _, childId in ipairs(childrenIds) do
        local child = entityManager.get(childId)
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
--     if not job:has(ECS.c.parent) then -- Only go through tree roots
--       local jobComponent = job:get(ECS.c.job)
--       if not jobComponent.reserved and not jobComponent.finished then
--         local firstSubJob = self:getFirstSubJob(job)
--         if firstSubJob then
--           local subJobComponent = firstSubJob:get(ECS.c.job)
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
  if job:get(ECS.c.children) then
    return lume.map(job:get(ECS.c.children).children, function(childId)
      return entityManager.get(childId)
    end)
  end

  return nil
end

function JobSystem:gridUpdated()
  for _, mainJob in ipairs(self.jobs) do
    utils.traverseTree(mainJob, getChildren, function(job)
      if job:has(ECS.c.job) then
        job:get(ECS.c.job).isInaccessible = false
      end
    end)
  end
end

-- function JobSystem:getUnreservedJobs()
--   local unreservedJobs = {}
--   for _, job in ipairs(self.jobs) do
--     if not job:has(ECS.c.parent) and job:has(ECS.c.job) then -- Only go through tree roots
--       local jobComponent = job:get(ECS.c.job)
--       if not jobComponent.reserved and not jobComponent.finished then
--         local firstSubJob = self:getFirstSubJob(job)
--         if firstSubJob then
--           local subJobComponent = firstSubJob:get(ECS.c.job)
--           --return firstSubJob
--           if not subJobComponent.finished then
--             if not subJobComponent.reserved and subJobComponent.canStart then
--               table.insert(unreservedJobs, firstSubJob)
--             end
--           end
--         end
--       end
--     end
--   end
-- 
--   print("Returning", unreservedJobs)
--   return unreservedJobs
-- end

-- function JobSystem:getFirstSubJob(job)
--   local allChildrenFinished = true
-- 
--   if job:has(ECS.c.children) then
--     local childrenIds = job:get(ECS.c.children).children
--     for _, childId in ipairs(childrenIds) do
--       local child = entityManager.get(childId)
--       local firstChildJob = self:getFirstSubJob(child)
--       if firstChildJob then
--         local firstChildJobComponent = firstChildJob:get(ECS.c.job)
--         if firstChildJobComponent then
--           if not firstChildJobComponent.finished then
--             allChildrenFinished = false
--             if not firstChildJobComponent.reserved then
--               return firstChildJob
--             end
--           end
--         end
--       end
--     end
--   end
-- 
--   if allChildrenFinished then
--     local jobComponent = job:get(ECS.c.job)
--     if jobComponent then
--       jobComponent.canStart = true
--     end
--   end
-- 
--   return job
-- end

function JobSystem:jobFinished(job) --luacheck: ignore
  print("Finishing job", job)
  local jobComponent = job:get(ECS.c.job)
  jobComponent.finished = true
  jobComponent.reserved = false
  job:remove(ECS.c.job)
  -- if job:has(ECS.c.parent) then
  --   jobComponent.finished = true
  --   jobComponent.reserved = false
  -- else
  --   job:remove(ECS.c.job)
  -- end

  --self:getWorld():emit("jobQueueUpdated", jobManager.getUnreservedJobs(self.jobs))
end

--function JobSystem:addJob(job)
--  table.insert(self.jobs, job)
--  self:getWorld():emit("jobQueueUpdated", self:getUnreservedJobs())
--end

return JobSystem
