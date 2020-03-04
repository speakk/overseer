local worker = ECS.Component(function(component, available)
  component.available = available or true
end)
function worker:serialize() return { available = self.available } end
function worker:deserialize(data)
  self.available = data.available
end
return worker
