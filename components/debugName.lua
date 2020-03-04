local debugName = ECS.Component(function(component, name)
  component.name = name or error("Debugname needs name")
end)
function debugName:serialize() return { name = self.name } end
function debugName:deserialize(data)
  self.name = data.name
end
return debugName


