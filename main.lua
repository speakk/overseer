require("libs/deepcopy")
local Concord = require("libs/Concord/lib").init({
  useEvents = true,
})

DEBUG = false

ECS = {}
ECS.Component = require("libs/Concord/lib.component")
ECS.System = require("libs/Concord/lib.system")
ECS.Instance = require("libs/Concord/lib.instance")
ECS.Entity = require("libs/Concord/lib.entity")

local instance = ECS.Instance()

local windowWidth = 1000
local windowHeight = 800
love.window.setMode(windowWidth, windowHeight, { resizable=true })

local gamera = require('libs/gamera/gamera')
local camera = gamera.new(0, 0, 1000, 1000)

-- Add the Instance to concord to make it active
Concord.addInstance(instance)

local moveSystem = require('systems/moveSystem')()
local mapSystem = require('systems/mapSystem')(camera)
local itemSystem = require('systems/itemSystem')(mapSystem)
local jobSystem = require('systems/jobSystem')(mapSystem)
local bluePrintSystem = require('systems/bluePrintSystem')(mapSystem, jobSystem)
local overseerSystem = require('systems/overseerSystem')(bluePrintSystem, mapSystem, camera)
local guiSystem = require('systems/guiSystem')(overseerSystem, mapSystem, camera)
local playerInputSystem = require('systems/playerInputSystem')(overseerSystem, mapSystem, camera)
local settlerSystem = require('systems/settlerSystem')(mapSystem, jobSystem, itemSystem, bluePrintSystem)
local drawSystem = require('systems/drawSystem')(mapSystem, jobSystem, camera)

local function load()
  love.graphics.setColor(255, 0, 0)

  instance:addSystem(guiSystem, "keypressed")
  instance:addSystem(guiSystem, "mousepressed")
  instance:addSystem(guiSystem, "mousereleased")
  instance:addSystem(guiSystem, "mousemoved")
  instance:addSystem(guiSystem, "update")
  instance:addSystem(playerInputSystem, "update")
  instance:addSystem(playerInputSystem, "mousepressed")
  instance:addSystem(playerInputSystem, "wheelmoved")
  instance:addSystem(bluePrintSystem, "update")
  instance:addSystem(bluePrintSystem, "bluePrintFinished")
  instance:addSystem(settlerSystem, "update")
  instance:addSystem(settlerSystem, "gridUpdated", "invalidatePaths")
  instance:addSystem(itemSystem)
  instance:addSystem(mapSystem, "resize") -- Window resize event
  instance:addSystem(mapSystem, "update")
  instance:addSystem(mapSystem, "draw")
  instance:addSystem(drawSystem, "draw")
  instance:addSystem(overseerSystem, "update")
  instance:addSystem(overseerSystem, "draw")
  instance:addSystem(jobSystem, "draw")
  instance:addSystem(moveSystem, "update")
  instance:addSystem(guiSystem, "draw")

  settlerSystem:initalizeTestSettlers()
  itemSystem:initializeTestItems()

  -- local profilerSystem = require('systems/profilerSystem')()
  -- instance:addSystem(profilerSystem, "update")
  -- instance:addSystem(profilerSystem, "draw")
end

load()
