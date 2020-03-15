local light = ECS.Component(..., function(component, color, power)
  component.color = color or { 1, 1, 1 }
  component.power = power or 64
end)
function light:serialize() return { color = self.color, power = self.power } end
function light:deserialize(data)
  self.color = data.color
  self.power = data.power
end
return light
