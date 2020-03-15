local construction = ECS.Component(..., function(component, durability)
  component.durability = durability
end)

function construction:serialize() return { durability = self.durability } end
function construction:deserialize(data)
  self.durability = data.durability
end

return construction
