local Vector = require('libs.brinevector')
-- Create a System class as lovetoys.System subclass.
local MoveSystem = ECS.System({ECS.c.position, ECS.c.velocity})

function MoveSystem:resetVelocities()
  for _, entity in ipairs(self.pool) do
    entity:get(ECS.c.velocity).vector = Vector(0, 0)
  end
end

function MoveSystem:update(dt)
  for _, entity in ipairs(self.pool) do
    local position = entity:get(ECS.c.position)
    local velocity = entity:get(ECS.c.velocity).vector.copy
    if entity:has(ECS.c.speed) then
      velocity = velocity * entity:get(ECS.c.speed).speed
    end

    position.vector = position.vector + velocity * dt
    self:getWorld():emit("entityMoved", entity, position.vector, velocity)
  end
end

return MoveSystem
