local Vector = require('libs.brinevector')
-- Create a System class as lovetoys.System subclass.
local MoveSystem = ECS.System({ECS.Components.position, ECS.Components.velocity})

function MoveSystem:resetVelocities()
  for _, entity in ipairs(self.pool) do
    entity:get(ECS.Components.velocity).vector = Vector(0, 0)
  end
end

function MoveSystem:update(dt)
  for _, entity in ipairs(self.pool) do
    local position = entity:get(ECS.Components.position)
    local velocity = entity:get(ECS.Components.velocity).vector.copy
    if entity:has(ECS.Components.speed) then
      velocity = velocity * entity:get(ECS.Components.speed).speed
    end

    position.vector = position.vector + velocity * dt
  end
end

return MoveSystem
