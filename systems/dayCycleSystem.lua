local DayCycleSystem = ECS.System("dayCycle", {})

local daySpeed = 0.001
local currentTime = 0 -- Timer that runs and progresses world time

local lastEmit = 0
local emitInterval = 1

function DayCycleSystem:update(dt) --luacheck: ignore
  currentTime = currentTime + daySpeed
  local time = love.timer.getTime()
  if time - lastEmit > emitInterval then
    self:getWorld():emit('timeOfDayChanged', currentTime)
    self.lastEmit = time
  end
end

-- Range: 0-1, 1 being midnight/morning, 0.5 middle of day
function DayCycleSystem:getTimeOfDay() --luacheck: ignore
  return math.sin(currentTime)
end

return DayCycleSystem


