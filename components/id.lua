local id = ECS.Component(function(component, id)
  component.id = id or error("Id needs id")
end)
function id:serialize() return { id = self.id } end
function id:deserialize(data)
  self.id = data.id
end
return id
