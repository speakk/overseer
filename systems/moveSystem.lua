-- Create a System class as lovetoys.System subclass.
local MoveSystem = class("MoveSystem", System)

-- Define this System's requirements.
function MoveSystem:requires()
  return {"position", "velocity"}
end

function MoveSystem:update(dt)
  for _, entity in pairs(self.targets) do
    local position = entity:get("position")
    local velocity = entity:get("velocity")
    position.x = position.x + velocity.vector.x * dt
    position.y = position.y + velocity.vector.y * dt
  end
end

return MoveSystem
