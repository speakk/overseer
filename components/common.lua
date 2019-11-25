local cpml = require('cpml')
local lovetoys = require('lovetoys')
lovetoys.initialize({globals = true, debug = true})

local common = {}

common.Position = Component.create("position", {"x", "y"}, {x = 0, y = 0})
common.Velocity = Component.create("velocity", {"vector"}, { vector = cpml.vec2(0, 0) })
common.PlayerInput = Component.create("playerInput")
common.CameraComponent = Component.create("camera")
common.Draw = Component.create("draw", {"color"}, { color = { 1, 0, 0, 1 } })
common.Settler = Component.create("settler")
common.BluePrint = Component.create("bluePrint")

return common


