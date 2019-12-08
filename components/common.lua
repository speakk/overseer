local Vector = require('libs/brinevector/brinevector')
local lume = require('libs/lume')
local commonComponents = {}

commonComponents.Position = ECS.Component(function(e, vector) e.vector = vector or Vector(0, 0) end)
commonComponents.Velocity = ECS.Component(function(e, vector) e.vector = vector or Vector(0, 0) end)
commonComponents.PlayerInput = ECS.Component()
commonComponents.Camera = ECS.Component()
commonComponents.Draw = ECS.Component(function(e, color, size)
  e.color = color or { 1, 0, 0 }
  e.size = size or Vector(32, 32)
end)
commonComponents.Settler = ECS.Component()
commonComponents.Work = ECS.Component(function(e, job) e.job = job or nil end) -- Settler work
commonComponents.Path = ECS.Component(function(e, path, currentIndex)
  e.path = path
  e.currentIndex = currentIndex or 1
end)
commonComponents.FetchJob = ECS.Component(function(e, target, selector, amount)
  e.target = target or error("Fetch has no target!")
  e.selector = selector or error("Fetch has no selector!")
  e.amount = amount
end)
commonComponents.HealingJob = ECS.Component()
commonComponents.Job = ECS.Component(function(e, target, reserved, finished, allJobsOrNothing)
  e.target = target or nil -- Not all jobs need targets
  e.reserved = reserved or false
  e.finished = finished or false
  e.allJobsOrNothing = allJobsOrNothing or false
end)
commonComponents.Worker = ECS.Component(function(e, available) e.available = available or true end)
commonComponents.BluePrintJob = ECS.Component()
commonComponents.ConstructionJob = ECS.Component()
commonComponents.Collision = ECS.Component()
commonComponents.Inventory = ECS.Component(function(e, inventory)
  e.inventory = inventory or {}
end)
function commonComponents.Inventory:getItemBySelector(selector)
  local itemEnt = lume.match(self.inventory, function(itemInInv)
    return itemInInv:get(commonComponents.Item).selector == selector end)
  return itemEnt
end
-- TODO: Add "Amount" parameter, split the item as needed
function commonComponents.Inventory:popItemBySelector(selector, amount)
  print("selector", selector)
  local item = self:getItemBySelector(selector)
  if item then
    local currentAmount = item:get(commonComponents.Amount).amount
    local diff = currentAmount - amount
    if diff <= 0 then
      lume.remove(self.inventory, item)
      return item
    end

    item:give(commonComponents.Amount, diff)
    local itemCopy = table.deepcopy(item)
    itemCopy:give(commonComponents.Amount, amount)
    return itemCopy
  end
end
--commonComponents.Selector = ECS.Component(function(e, selector) e.selector = selector or "" end)
commonComponents.Item = ECS.Component(function(e, itemData, selector)
  e.itemData = itemData or {}
  e.selector = selector or ""
end)
-- This method is supposed to be maybe overriden at will to answer the question
-- "How unique is unique enough?" for combining items
function commonComponents.Item:getUniqueId()
  return self.selector
end
commonComponents.Parent = ECS.Component(function(e, parent)
  e.parent = parent or error("Parent component needs parent entity")
end)

commonComponents.Children = ECS.Component(function(e, children)
  e.children = children or error("Children component needs children(list of entities)")
end)
commonComponents.Amount = ECS.Component(function(e, amount) e.amount = amount or 0 end)

return commonComponents


