local Vector = require('libs/brinevector/brinevector')
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
common.FetchJob = ECS.Component(function(e, target, amount)
  e.target = target or error("Fetch has no target!")
  e.amount = amount
end)
common.HealingJob = ECS.Component(function(e, target) end)
common.Job = ECS.Component(function(e, target, reserved, finished, subJobs)
  e.target = target or nil
  e.reserved = reserved or false
  e.finished = finished or false
  e.subJobs = subJobs or nil
end)
common.Worker = ECS.Component(function(e, available) e.available = available or true end)
common.BluePrintJob = ECS.Component()
common.Inventory = ECS.Component(function(e, contents) e.contents = contents or {} end)
common.Selector = ECS.Component(function(e, selector) e.selector = selector or "" end)
common.Item = ECS.Component(function(e, itemData) e.itemData = itemData or {} end)

return common


