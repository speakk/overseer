local transparent = ECS.Component(function(component, amount)
  component.amount = amount or 0.5
end)
function transparent:serialize() return { amount = self.amount } end
function transparent:deserialize(data)
  self.amount = data.amount
end
return transparent
