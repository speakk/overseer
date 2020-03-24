local settings = require 'settings'
local DayCycleSystem = ECS.System()

local daySpeed = 0.5
local currentTime = 0 -- Timer that runs and progresses world time
local hour = 1 -- Derived from currentTime in timeChanged

local lastEmit = 0
local emitInterval = 0.01

local cycleCanvas = love.graphics.newCanvas(100, 100)
local cycleImage = love.graphics.newImage('media/misc/daycycle.png')

function DayCycleSystem:update(dt) --luacheck: ignore
  currentTime = currentTime + daySpeed * dt
  local time = love.timer.getTime()
  if time - lastEmit > emitInterval then
    --print("Emit?", time)
    self:getWorld():emit('timeChanged', currentTime, self:getTimeOfDay(currentTime))
    lastEmit = time
  end
end

function DayCycleSystem:timeChanged(time, timeOfDay) -- luacheck: ignore
  hour = math.ceil(timeOfDay * 24)

  local rotation = timeOfDay * math.pi*2 - math.pi
  love.graphics.push('all')
  love.graphics.setBlendMode('alpha')
  love.graphics.setCanvas({cycleCanvas, stencil = true})
  love.graphics.setColor(1,1,1,1)
  love.graphics.clear(0,0,0,0)
  love.graphics.stencil(function()
    love.graphics.setColor(1,1,1,1)
    love.graphics.circle('fill', 50, 50, 50)
  end, "replace", 1, false)
  love.graphics.setStencilTest("greater", 0)
  love.graphics.setScissor(0, 0, 100, 50)
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(cycleImage, 50, 50, rotation, 1, 1, 50, 50)
  love.graphics.setStencilTest()
  love.graphics.setCanvas()
  love.graphics.pop()
end

function DayCycleSystem:generateGUIDraw() -- luacheck: ignore
  local w, h = love.graphics.getDimensions()
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(cycleCanvas, w-120, h-settings.actions_bar_height-50)

  love.graphics.print("H: " .. tostring(hour), w-85, h-settings.actions_bar_height-70)
end

-- Range: 0-1, 1 being midnight/morning, 0.5 middle of day
function DayCycleSystem:getTimeOfDay(currentTime) --luacheck: ignore
  --print(currentTime % 1)
  return currentTime * 0.1 % 1
end

return DayCycleSystem
