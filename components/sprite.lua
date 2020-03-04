local sprite = ECS.Component(function(component, selector)
  component.selector = selector or error("Sprite needs sprite selector")
end)
function sprite:serialize() return { selector = self.selector } end
function sprite:deserialize(data)
  self.selector = data.selector
end

return sprite
