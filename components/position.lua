local Vector = require('libs.brinevector')

local position = ECS.Component(..., function(component, vector)
  component.vector = vector or Vector(0, 0)
end)

function position:serialize()
  return { x = self.vector.x, y = self.vector.y }
end

function position:deserialize(data)
  self.vector = Vector(data.x, data.y)
end

return position
