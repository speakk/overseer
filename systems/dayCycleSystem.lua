local DayCycleSystem = ECS.System("dayCycle", {})

local daySpeed = 0.001
local currentTime = 0 -- Timer that runs and progresses world time

local lastEmit = 0
local emitInterval = 1

function DayCycleSystem:init()
end

function DayCycleSystem:update(dt)
  currentTime = currentTime + daySpeed
  self:getWorld:emit('timeOfDayChanged', currentTime)
end

-- Range: 0-1, 1 being midnight/morning, 0.5 middle of day
function DayCycleSystem:getTimeOfDay()
  return math.sin(currentTime)
end

return DayCycleSystem


