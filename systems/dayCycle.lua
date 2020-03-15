local DayCycleSystem = ECS.System()

local daySpeed = 0.5
local currentTime = 0 -- Timer that runs and progresses world time

local lastEmit = 0
local emitInterval = 0.01

function DayCycleSystem:update(dt) --luacheck: ignore
  currentTime = currentTime + daySpeed * dt
  local time = love.timer.getTime()
  if time - lastEmit > emitInterval then
    --print("Emit?", time)
    self:getWorld():emit('timeOfDayChanged', self:getTimeOfDay(currentTime))
    lastEmit = time
  end
end

-- Range: 0-1, 1 being midnight/morning, 0.5 middle of day
function DayCycleSystem:getTimeOfDay() --luacheck: ignore
  return math.sin(currentTime)
end

return DayCycleSystem


