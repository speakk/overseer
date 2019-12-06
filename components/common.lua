local Vector = require('libs/brinevector/brinevector')
local lume = require('libs/lume')
local common = {}

common.Position = ECS.Component(function(e, vector) e.vector = vector or Vector(0, 0) end)
common.Velocity = ECS.Component(function(e, vector) e.vector = vector or Vector(0, 0) end)
common.PlayerInput = ECS.Component()
common.Camera = ECS.Component()
common.Draw = ECS.Component(function(e, color, size)
  e.color = color or { 1, 0, 0 }
  e.size = size or Vector(32, 32)
end)
common.Settler = ECS.Component()
common.Work = ECS.Component(function(e, job) e.job = job or nil end) -- Settler work
common.Path = ECS.Component(function(e, path, currentIndex)
  e.path = path
  e.currentIndex = currentIndex or 1
end)
common.FetchJob = ECS.Component(function(e, target, selector, amount)
  e.target = target or error("Fetch has no target!")
  e.selector = selector or error("Fetch has no selector!")
  e.amount = amount
end)
common.HealingJob = ECS.Component()
common.Job = ECS.Component(function(e, target, reserved, finished, allJobsOrNothing)
  e.target = target or nil -- Not all jobs need targets
  e.reserved = reserved or false
  e.finished = finished or false
  e.allJobsOrNothing = allJobsOrNothing or false
end)
common.Worker = ECS.Component(function(e, available) e.available = available or true end)
common.BluePrintJob = ECS.Component()
common.Inventory = ECS.Component(function(e, inventory)
  e.inventory = inventory or {}
end)
function common.Inventory:getItemBySelector(selector)
  local item = lume.match(self.inventory, function(itemInInv)
    return itemInInv:get(common.Selector).selector == selector end)
  return item
end
common.Selector = ECS.Component(function(e, selector) e.selector = selector or "" end)
common.Item = ECS.Component(function(e, itemData) e.itemData = itemData or {} end)
common.Parent = ECS.Component(function(e, parent)
  e.parent = parent or error("Parent component needs parent entity")
end)

common.Children = ECS.Component(function(e, children)
  e.children = children or error("Children component needs children(list of entities)")
end)
common.Amount = ECS.Component(function(e, amount) e.amount = amount or 0 end)

return common


