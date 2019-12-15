local Vector = require('libs/brinevector/brinevector')
local commonComponents = {}

commonComponents.Position = ECS.Component(function(e, vector) e.vector = vector or Vector(0, 0) end)
commonComponents.Velocity = ECS.Component(function(e, vector) e.vector = vector or Vector(0, 0) end)
commonComponents.Name = ECS.Component(function(e, name) e.name = name or "-" end)
commonComponents.PlayerInput = ECS.Component()
commonComponents.Camera = ECS.Component()
commonComponents.Draw = ECS.Component(function(e, color, size)
  e.color = color or { 1, 0, 0 }
  e.size = size or Vector(32, 32)
end)
commonComponents.Settler = ECS.Component(function(e, name)
  e.name = name or "Lucy"
  e.skills = {
    construction = 15
  }
end)
commonComponents.Work = ECS.Component(function(e, job) e.job = job or nil end) -- Settler work
commonComponents.Path = ECS.Component(function(e, path, currentIndex)
  e.path = path or error("No path for Path component!")
  e.currentIndex = currentIndex or 1
end)
commonComponents.FetchJob = ECS.Component(function(e, target, selector, amount, finishedCallBack)
  e.target = target or error("Fetch has no target!")
  e.selector = selector or error("Fetch has no selector!")
  e.amount = amount
  e.finishedCallBack = finishedCallBack
end)
commonComponents.HealingJob = ECS.Component()
commonComponents.Job = ECS.Component(function(e, target, reserved, finished, allJobsOrNothing)
  e.target = target or nil -- Not all jobs need targets
  e.reserved = reserved or false
  e.finished = finished or false
  e.allJobsOrNothing = allJobsOrNothing or false
end)
commonComponents.Worker = ECS.Component(function(e, available) e.available = available or true end)
commonComponents.BluePrintJob = ECS.Component(function(e)
  e.materialsConsumed = {} 
  e.buildProgress = 0 -- 0/100
end)
commonComponents.ConstructionJob = ECS.Component()
commonComponents.Collision = ECS.Component()
commonComponents.Inventory = ECS.Component(function(e, inventory)
  e.inventory = inventory or {}
end)
--commonComponents.Selector = ECS.Component(function(e, selector) e.selector = selector or "" end)
commonComponents.Item = ECS.Component(function(e, itemData, selector)
  e.itemData = itemData or {}
  e.selector = selector or error("Item needs data selector!")
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


