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
common.Work = ECS.Component(function(e, job) e.job = job or nil end)
common.Path = ECS.Component(function(e, path, currentIndex)
  e.path = path
  e.currentIndex = currentIndex or 1
end)
common.Job = ECS.Component(function(e, target, reserved, finished)
  e.target = target or nil
  e.reserved = reserved or false
  e.finished = finished or false
end)
common.Worker = ECS.Component(function(e, available) e.available = available or true end)
common.BluePrint = ECS.Component()
common.Inventory = ECS.Component(function(e, contents) e.contents = contents or {} end)

return common


