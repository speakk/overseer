local function getFirstSubJob(job)
  local allChildrenFinished = true

  if job:has(ECS.Components.children) then
    local children = job:get(ECS.Components.children).children
    for _, child in ipairs(children) do
      local firstChildJob = getFirstSubJob(child)
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
local function getNextUnreservedJob(allJobs)
  for _, job in ipairs(jobs) do
    if not job:has(ECS.Components.parent) then -- Only go through tree roots
      local jobComponent = job:get(ECS.Components.job)
      if not jobComponent.reserved and not jobComponent.finished then
        local firstSubJob = getFirstSubJob(job)
        if firstSubJob then
          local subJobComponent = firstSubJob:get(ECS.Components.job)
          --return firstSubJob
          if not subJobComponent.finished and not subJobComponent.isInaccessible then
            if not subJobComponent.reserved and subJobComponent.canStart then return firstSubJob end
          end
        end
      end
    end
  end
end

local function getUnreservedJobs(jobs)
  local unreservedJobs = {}
  for _, job in ipairs(jobs) do
    if not job:has(ECS.Components.parent) then -- Only go through tree roots
      local jobComponent = job:get(ECS.Components.job)
      if not jobComponent.reserved and not jobComponent.finished then
        local firstSubJob = getFirstSubJob(job)
        if firstSubJob then
          local subJobComponent = firstSubJob:get(ECS.Components.job)
          --return firstSubJob
          if not subJobComponent.finished and not subJobComponent.isInaccessible then
            if not subJobComponent.reserved and subJobComponent.canStart then
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
