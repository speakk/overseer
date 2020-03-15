local inspect = require('libs.inspect') -- luacheck: ignore
local lume = require('libs.lume')
local utils = require('utils.utils')

local jobManager = require('models.jobManager')
local jobHandlers = require('models.jobTypes.jobTypes')

local entityManager = require('models.entityManager')

local JobSystem = ECS.System({ECS.c.job, 'jobs'})

local function onJobAdded(self, pool, job)
  -- if not job.parent then
  --   table.insert(self.jobs, job)
  --   job:getWorld():emit("jobQueueUpdated", self:getUnreservedJobs())
  -- end
  jobManager.updateJobs(pool)
end

local function onJobRemoved(self, pool, job)
  -- if not job.parent then
  --   table.insert(self.jobs, job)
  --   job:getWorld():emit("jobQueueUpdated", self:getUnreservedJobs())
  -- end
  jobManager.updateJobs(pool)
end

function JobSystem:init()
  -- self.jobs = {}
  self.jobs.onEntityAdded = function(pool, job)
    onJobAdded(self, pool, job)
  end
  self.jobs.onEntityRemoved = function(pool, job)
    onJobRemoved(self, pool, job)
  end
  --TODO: onEntityRemoved
end

local function printJob(job, level, y)
  if not job or not job.job or job.job.finished then return nil end
  local name = tostring(job) .. ": " .. job.job.jobType
  local isChild = job.parent
  if isChild and level == 1 then return nil end
  if isChild then name = name .. " (child)" end
  local space = 6
  local jobComponent = job.job
  if not jobComponent then return end

  if job.children then
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

  if job.bluePrintJob then
    local bluePrintComponent = job.bluePrintJob
    name = name .. " Consumed: "
    for selector, item in pairs(bluePrintComponent.materialsConsumed) do --luacheck: ignore
      name = name .. "| " .. selector .. " | "
    end
  end

  love.graphics.print(name, 40 + level * space, 40 + y * space, 0, 1.1, 1.1)

  if job.children then
    local childrenIds = job.children.children
    --print("Childcomp?", job.children.children)

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
--     if not job.parent then -- Only go through tree roots
--       local jobComponent = job.job
--       if not jobComponent.reserved and not jobComponent.finished then
--         local firstSubJob = self:getFirstSubJob(job)
--         if firstSubJob then
--           local subJobComponent = firstSubJob.job
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
  if job.children then
    return lume.map(job.children.children, function(childId)
      return entityManager.get(childId)
    end)
  end

  return nil
end

function JobSystem:gridUpdated()
  for _, mainJob in ipairs(self.jobs) do
    utils.traverseTree(mainJob, getChildren, function(job)
      if job.job then
        job.job.isInaccessible = false
      end
    end)
  end
end

-- function JobSystem:getUnreservedJobs()
--   local unreservedJobs = {}
--   for _, job in ipairs(self.jobs) do
--     if not job.parent and job.job then -- Only go through tree roots
--       local jobComponent = job.job
--       if not jobComponent.reserved and not jobComponent.finished then
--         local firstSubJob = self:getFirstSubJob(job)
--         if firstSubJob then
--           local subJobComponent = firstSubJob.job
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
--   if job.children then
--     local childrenIds = job.children.children
--     for _, childId in ipairs(childrenIds) do
--       local child = entityManager.get(childId)
--       local firstChildJob = self:getFirstSubJob(child)
--       if firstChildJob then
--         local firstChildJobComponent = firstChildJob.job
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
--     local jobComponent = job.job
--     if jobComponent then
--       jobComponent.canStart = true
--     end
--   end
-- 
--   return job
-- end

function JobSystem:jobFinished(job) --luacheck: ignore
  print("Finishing job", job)
  local jobComponent = job.job
  if not jobComponent then
    print("jobFinished but NO jobComponent, something went WRONG")
    return
  end
  jobComponent.finished = true
  jobComponent.reserved = false
  job:remove(ECS.c.job)
  -- if job.parent then
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
