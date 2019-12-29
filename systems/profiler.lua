local ProfilerSystem = ECS.System()

function ProfilerSystem:init() --luacheck: ignore
  love.profile = require('profile')
  love.profile.start()
  love.frame = 0
end

function ProfilerSystem:update(dt) --luacheck: ignore
  love.frame = love.frame + 1
  if love.frame%100 == 0 then
    love.report = love.profile.report(20)
    love.profile.reset()
  end
end

function ProfilerSystem:draw() --luacheck: ignore
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(love.report or "Please wait...")
end

return ProfilerSystem
