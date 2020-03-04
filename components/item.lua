local item = ECS.Component(function(component, itemData)
  component.itemData = itemData or {}
end)
function item:serialize() return { itemData = self.itemData } end
function item:deserialize(data)
  self.itemData = data.itemData
end
return item
