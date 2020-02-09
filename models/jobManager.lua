local entityManager = require('models.entityManager')

local function getFirstSubJob(job)
  local allChildrenFinished = true

  if not job then return nil end
  if job:has(ECS.c.children) then
    local children = job:get(ECS.c.children).children
    for _, childId in ipairs(children) do
      local child = entityManager.get(childId)
      local firstChildJob = getFirstSubJob(child)
      if firstChildJob then
        local firstChildJobComponent = firstChildJob:get(ECS.c.job)
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
    --print("allChildrenFinished")
    local jobComponent = job:get(ECS.c.job)
    if jobComponent then
      jobComponent.canStart = true
    end
  end

  return job
end
-- local function getNextUnreservedJob(allJobs)
--   for _, job in ipairs(jobs) do
--     if not job:has(ECS.c.parent) then -- Only go through tree roots
--       local jobComponent = job:get(ECS.c.job)
--       if not jobComponent.reserved and not jobComponent.finished then
--         local firstSubJob = getFirstSubJob(job)
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

local function getUnreservedJobs(jobs)
  --print("Checking out jobs", #jobs)
  local unreservedJobs = {}
  for _, job in ipairs(jobs) do
    if not job:has(ECS.c.parent) then -- Only go through tree roots
      --print("Root node")
      local jobComponent = job:get(ECS.c.job)
      if not jobComponent.reserved and not jobComponent.finished then
        --print("Root node was not reserved nor finished")
        local firstSubJob = getFirstSubJob(job)
        --print("firstSubJob", firstSubJob)
        if firstSubJob then
          local subJobComponent = firstSubJob:get(ECS.c.job)
          --return firstSubJob
          if not subJobComponent.finished and not subJobComponent.isInaccessible then
            --print("firstSubJob not finished and not isInaccessible", firstSubJob)
            --print("reserved", subJobComponent.reserved, "canStart", subJobComponent.canStart)
            if not subJobComponent.reserved and subJobComponent.canStart then
              --print("firstSubJob not finished and not isInaccessible", firstSubJob)
              table.insert(unreservedJobs, firstSubJob)
            end
          end
        end
      end
    end
  end

  return unreservedJobs
end

return {
  getUnreservedJobs = getUnreservedJobs
}
