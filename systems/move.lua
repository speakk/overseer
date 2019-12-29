-- Create a System class as lovetoys.System subclass.
local MoveSystem = ECS.System({ECS.Components.position, ECS.Components.velocity})

function MoveSystem:update(dt)
  for _, entity in ipairs(self.pool) do
    local position = entity:get(ECS.Components.position)
    local velocity = entity:get(ECS.Components.velocity)
    position.vector = position.vector + velocity.vector * dt

  end
end

return MoveSystem
