local name = ECS.Component(function(component, name)
  component.name = name or "-"
end)
function name:serialize() return { name = self.name } end
function name:deserialize(data)
  self.name = data.name
end
return name


