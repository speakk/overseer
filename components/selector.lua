local selector = ECS.Component(function(component, selector)
  component.selector = selector or "-"
end)
function selector:serialize() return { selector = self.selector } end
function selector:deserialize(data)
  self.selector = data.selector
end
return selector


