local Vector = require('libs.brinevector')

local velocity = ECS.Component(function(component, vector)
  component.vector = vector or Vector(0, 0)
end)

function velocity:serialize() return { x = self.vector.x, y = self.vector.y } end

function velocity:deserialize(data)
  self.vector = Vector(data.x, data.y)
end

return velocity
