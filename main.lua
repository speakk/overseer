--local lovetoys = require('libs/lovetoys')
local Concord = require("libs/Concord/lib").init({
  useEvents = true,
})

M = require ("libs/Moses/moses")

DEBUG = false

--load main ECS libs
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

local Vector = require('libs/brinevector/brinevector')

local commonComponents = require('components/common')

local cameraSystem = require('systems/cameraSystem')(camera)
local moveSystem = require('systems/moveSystem')()
local mapSystem = require('systems/mapSystem')(camera)
local bluePrintSystem = require('systems/bluePrintSystem')(mapSystem)
local overseerSystem = require('systems/overseerSystem')(bluePrintSystem)
local guiSystem = require('systems/guiSystem')(overseerSystem, mapSystem, camera)
local playerInputSystem = require('systems/playerInputSystem')(overseerSystem, mapSystem, camera)
local settlerSystem = require('systems/settlerSystem')(mapSystem)
local drawSystem = require('systems/drawSystem')(mapSystem, camera)


--lovetoys.initialize({globals = true, debug = true})


x = 5.0
speed = 25

mod_a = 0.0

height = 60
width = 60

function load()
  love.graphics.setColor(255, 0, 0)

  instance:addSystem(guiSystem, "keypressed")
  instance:addSystem(guiSystem, "mousepressed")
  instance:addSystem(guiSystem, "mousereleased")
  instance:addSystem(guiSystem, "mousemoved")
  instance:addSystem(guiSystem, "update")
  instance:addSystem(playerInputSystem, "update")
  instance:addSystem(playerInputSystem, "mousepressed")
  instance:addSystem(playerInputSystem, "wheelmoved")
  instance:addSystem(cameraSystem, "resize")
  instance:addSystem(bluePrintSystem, "update")
  instance:addSystem(bluePrintSystem, "bluePrintFinished")
  instance:addSystem(settlerSystem, "update")
  instance:addSystem(settlerSystem, "blueprintActivated")
  instance:addSystem(moveSystem, "update")
  instance:addSystem(mapSystem, "update")
  instance:addSystem(mapSystem, "draw")
  instance:addSystem(drawSystem, "draw")
  instance:addSystem(overseerSystem, "update")
  instance:addSystem(guiSystem, "draw")

  settlerSystem:initalizeTestSettlers()

  -- local profilerSystem = require('systems/profilerSystem')()
  -- instance:addSystem(profilerSystem, "update")
  -- instance:addSystem(profilerSystem, "draw")
end

load()
