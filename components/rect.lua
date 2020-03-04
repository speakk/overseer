local rect = ECS.Component(function(component, x1, y1, x2, y2)
  component.x1 = x1
  component.y1 = y1
  component.x2 = x2
  component.y2 = y2
end)

function rect:serialize() return { x1 = self.x1, y1 = self.y1, x2 = self.x2, y2 = self.y2 } end
function rect:deserialize(data)
  self.x1 = data.x1
  self.y1 = data.y1
  self.x2 = data.x2
  self.y2 = data.y2
end

return rect
