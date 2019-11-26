local commonComponents = require('components/common')

-- Create a System class as lovetoys.System subclass.
local MoveSystem = ECS.System({commonComponents.Position, commonComponents.Velocity})

function MoveSystem:update(dt)
  for _, entity in pairs(self.pool.objects) do
    local position = entity:get(commonComponents.Position)
    local velocity = entity:get(commonComponents.Velocity)
    position.vector = position.vector + velocity.vector * dt
  end
end

return MoveSystem
