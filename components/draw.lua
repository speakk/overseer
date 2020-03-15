local Vector = require 'libs.brinevector'
local draw = ECS.Component(..., function(component, color, size)
  component.color = color or { 1, 0, 0 }
  component.size = size or Vector(32, 32)
end)
function draw:serialize() return { color = self.color, size = { x = self.size.x, y = self.size.y } } end
function draw:deserialize(data)
  self.color = data.color
  self.size = Vector(data.size.x, data.size.y)
end
return draw
