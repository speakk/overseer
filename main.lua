--local lovetoys = require('libs/lovetoys')
local Concord = require("libs/Concord/lib").init({
  useEvents = true,
})


--load main ECS libs
ECS = {}
ECS.Component = require("libs/Concord/lib.component")
ECS.System = require("libs/Concord/lib.system")
ECS.Instance = require("libs/Concord/lib.instance")
ECS.Entity = require("libs/Concord/lib.entity")

local instance = ECS.Instance()

-- Add the Instance to concord to make it active
Concord.addInstance(instance)

local cpml = require('libs/cpml')

local commonComponents = require('components/common')

local drawSystem = require('systems/drawSystem')()
local guiSystem = require('systems/guiSystem')()
local playerInputSystem = require('systems/playerInputSystem')()
local cameraSystem = require('systems/cameraSystem')()
local moveSystem = require('systems/moveSystem')()
local bluePrintSystem = require('systems/bluePrintSystem')()
local mapSystem = require('systems/mapSystem')()
local settlerSystem = require('systems/settlerSystem')(mapSystem)

--lovetoys.initialize({globals = true, debug = true})

local windowWidth = 1000
local windowHeight = 800

x = 5.0
speed = 25

mod_a = 0.0

height = 60
width = 60

function load()
  love.graphics.setColor(255, 0, 0)
  love.window.setMode(windowWidth, windowHeight, { resizable=true })

  cameraEntity = ECS.Entity()
  cameraEntity:give(commonComponents.Position, cpml.vec2(30, 40))
    :give(commonComponents.Velocity, cpml.vec2(0, 0))
    :give(commonComponents.PlayerInput)
    :give(commonComponents.Camera)
    :apply()

  instance:addEntity(cameraEntity)

  -- local eventManager = EventManager()
  -- eventManager:initialize();

  -- Finally, we setup an Engine.
   --engine = Engine()
   --engine:addEntity(cameraEntity)

  for i = 1,10,1 do
    settler = ECS.Entity()
    settler:give(commonComponents.Position, cpml.vec2(math.random(windowWidth), math.random(windowHeight)))
      :give(commonComponents.Draw, {1,1,0})
      :give(commonComponents.Settler)
      :give(commonComponents.Worker)
      :give(commonComponents.Velocity)
      :apply()
    instance:addEntity(settler)
  end



  -- This will be a 'draw' System, so the
  -- Engine will call its draw method.
  instance:addSystem(playerInputSystem, "update")
  instance:addSystem(cameraSystem, "update")
  instance:addSystem(bluePrintSystem, "update")
  instance:addSystem(bluePrintSystem, "bluePrintFinished")
  instance:addSystem(settlerSystem, "update")
  instance:addSystem(settlerSystem, "blueprintActivated")
  instance:addSystem(moveSystem, "update")
  instance:addSystem(mapSystem, "update")
  instance:addSystem(mapSystem, "draw")
  instance:addSystem(drawSystem, "draw")
  instance:addSystem(guiSystem, "mousepressed")
  instance:addSystem(guiSystem, "mousereleased")
  instance:addSystem(guiSystem, "update")
  instance:addSystem(guiSystem, "draw")

  for i = 1,90,1 do
    local wallBluePrint = ECS.Entity()
    local mapSize = mapSystem:getSizeInPixels()
    local location = mapSystem:snapToGridCenter(cpml.vec2(math.random(mapSize.x), math.random(mapSize.y)))
    wallBluePrint:give(commonComponents.Position, location)
    wallBluePrint:give(commonComponents.Draw, {0,0,1,1})
    wallBluePrint:give(commonComponents.BluePrint)
    wallBluePrint:apply()
    instance:addEntity(wallBluePrint)

    instance:emit("blueprintActivated", wallBluePrint)

    -- eventManager.fireEvent("blueprint_activated"
  end
end

load()
-- 
-- function love.update(dt)
--   x = x + speed * dt
--   mod_a = math.sin(x*0.1)*0.3+0.7
--   engine:update(dt)
-- end
-- 
-- function love.draw()
--   -- love.graphics.setColor(mod_a, mod_a, math.sin(x*0.07)*255)
--   love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
--   --love.graphics.ellipse("fill", x, 200, width, mod_a*height, 100)
--   engine:draw()
-- end
