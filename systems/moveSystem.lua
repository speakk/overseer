local components = require('libs/concord').components

-- Create a System class as lovetoys.System subclass.
local MoveSystem = ECS.System("move", {components.position, components.velocity})

function MoveSystem:update(dt)
  for _, entity in pairs(self.pool.objects) do
    local position = entity:get(components.position)
    local velocity = entity:get(components.velocity)
    position.vector = position.vector + velocity.vector * dt

  end
end

return MoveSystem
