local inspect = require('libs.inspect') -- luacheck: ignore
local lume = require('libs.lume')
local utils = require('utils.utils')

local jobManager = require('models.jobManager')

local entityRegistry = require('models.entityRegistry')

local JobSystem = ECS.System({ jobs = { "job" }})

function JobSystem:init()
  self.jobs.onEntityAdded = function(pool, job) --luacheck: ignore
    jobManager.updateJobs(pool)
  end
  self.jobs.onEntityRemoved = function(pool, job) --luacheck: ignore
    jobManager.updateJobs(pool)
  end
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
        local child = entityRegistry.get(childId)
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

local function getChildren(job)
  if job.children then
    return lume.map(job.children.children, function(childId)
      return entityRegistry.get(childId)
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

function JobSystem:startJob(worker, job, jobQueue) -- luacheck: ignore
  print("Starting job", worker, job, job.job.jobType, job.id.id)
  job.job.reserved = worker.id.id
  worker:give("work", job.id.id)
  lume.remove(jobQueue, job)
end

function JobSystem:jobFinished(entity) --luacheck: ignore
  print("Finishing job", entity)

  local worker = entityRegistry.get(entity.job.reserved)
  worker:remove("work")

  local jobComponent = entity.job
  if not jobComponent then
    print("jobFinished but NO jobComponent, something went WRONG")
    return
  end

  jobComponent.finished = true
  jobComponent.reserved = false

  local finishEvent = jobComponent.finishEvent
  print("finishEvent!", finishEvent, entity)
  if finishEvent then
    self:getWorld():emit(finishEvent, entity, self:getWorld())
  end

  entity:remove("job")
end

function JobSystem:cancelConstruction(entities) --luacheck: ignore
  for _, job in ipairs(entities) do
    -- TODO: This is maybe a bit off
    if job.job and job.job.jobType == 'bluePrint' then
      local worker = entityRegistry.get(job.job.reserved)
      if worker then
        worker:remove("work")
      end
    end
  end
end

return JobSystem
