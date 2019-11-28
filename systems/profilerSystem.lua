local ProfilerSystem = ECS.System()

function ProfilerSystem:init()
  love.profile = require('profile')
  love.profile.start()
  love.frame = 0
end

function ProfilerSystem:update(dt)
  love.frame = love.frame + 1
  if love.frame%100 == 0 then
    love.report = love.profile.report(20)
    love.profile.reset()
  end
end

function ProfilerSystem:draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(love.report or "Please wait...")
end

return ProfilerSystem
