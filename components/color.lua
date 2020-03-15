local color = ECS.Component(..., function(component, color)
  component.color = color or { 1, 1, 1, 1 }
end)

function color:serialize() return { color = self.color } end
function color:deserialize(data)
  self.color = data.color
end

return color
