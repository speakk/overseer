local speed = ECS.Component(..., function(component, speed)
  component.speed = speed or 0
end)
function speed:serialize() return { speed = self.speed } end
function speed:deserialize(data) self.speed = data.speed end
return speed
