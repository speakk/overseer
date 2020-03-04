local parent = ECS.Component(function(component, parentId)
  component.parentId = parentId
end)
function parent:serialize() return { parentId = self.parentId } end
function parent:deserialize(data)
  self.parentId = data.parentId
end
return parent
