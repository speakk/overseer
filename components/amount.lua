local amount = ECS.Component(..., function(component, amount)
  component.amount = amount or 0
end)
function amount:serialize() return { amount = self.amount } end
function amount:deserialize(data) self.amount = data.amount end
return amount
