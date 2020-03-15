local children = ECS.Component(..., function(component, children)
  component.children = children or {}
end)
function children:serialize()
  local childIds = {}
  for _, entityId in ipairs(self.children) do
    table.insert(childIds, entityId)
  end
  return { childIds = childIds }
end
function children:deserialize(data)
  self.children = {}
  for _, entityId in ipairs(data.childIds) do
    table.insert(self.children, entityId)
  end
end
return children
