local reserved = ECS.Component(function(component, reservedById, amount)
  component.reservedById = reservedById
  component.amount = amount
end)
function reserved:serialize() return { reservedById = self.reservedById } end
function reserved:deserialize(data)
  self.reservedById = data.reservedById
  self.amount = data.amount
end
return reserved
