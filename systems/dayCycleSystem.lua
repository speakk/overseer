local DayCycleSystem = ECS.System({})

local daySpeed = 0.001
local currentTime = 0 -- Timer that runs and progresses world time

function DayCycleSystem:init()
end

function DayCycleSystem:update(dt)
  currentTime = currentTime + daySpeed
end

-- Range: 0-1, 1 being midnight/morning, 0.5 middle of day
function DayCycleSystem:getTimeOfDay()
  return math.sin(currentTime)
end

return DayCycleSystem


