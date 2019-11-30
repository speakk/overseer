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

  cameraEntity = ECS.Entity()
  cameraEntity:give(commonComponents.Position, Vector(30, 40))
    :give(commonComponents.Velocity, Vector(0, 0))
    :give(commonComponents.PlayerInput)
    :give(commonComponents.Camera)
    :apply()

  instance:addEntity(cameraEntity)

  -- local eventManager = EventManager()
  -- eventManager:initialize();

  -- Finally, we setup an Engine.
   --engine = Engine()
   --engine:addEntity(cameraEntity)

  for i = 1,30,1 do
    settler = ECS.Entity()
    local worldSize = mapSystem:getSize()
    while true do
      position = mapSystem:clampToWorldBounds(Vector(math.random(worldSize.x), math.random(worldSize.y)))
      if mapSystem:isCellAvailable(position) then
        break
      end
    end

    settler:give(commonComponents.Position, mapSystem:gridPositionToPixels(position))
      :give(commonComponents.Draw, {1,1,0})
      :give(commonComponents.Settler)
      :give(commonComponents.Worker)
      :give(commonComponents.Velocity)
      :apply()
    instance:addEntity(settler)
  end



  -- This will be a 'draw' System, so the
  -- Engine will call its draw method.
  instance:addSystem(guiSystem, "keypressed")
  instance:addSystem(guiSystem, "mousepressed")
  instance:addSystem(guiSystem, "mousereleased")
  instance:addSystem(guiSystem, "mousemoved")
  instance:addSystem(guiSystem, "update")
  instance:addSystem(playerInputSystem, "update")
  instance:addSystem(playerInputSystem, "mousepressed")
  instance:addSystem(playerInputSystem, "wheelmoved")
  instance:addSystem(cameraSystem, "update")
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

  -- local profilerSystem = require('systems/profilerSystem')()
  -- instance:addSystem(profilerSystem, "update")
  -- instance:addSystem(profilerSystem, "draw")

   -- for i = 1,90,1 do
   --   local wallBluePrint = ECS.Entity()

   --   local worldSize = mapSystem:getSize()
   --   while true do
   --     position = mapSystem:clampToWorldBounds(Vector(math.random(worldSize.x), math.random(worldSize.y)))
   --     if mapSystem:isCellAvailable(position) then
   --       break
   --     end
   --   end

   --   wallBluePrint:give(commonComponents.Position, mapSystem:gridPositionToPixels(position))
   --   wallBluePrint:give(commonComponents.Draw, {0,0,1,1})
   --   wallBluePrint:give(commonComponents.BluePrint)
   --   wallBluePrint:apply()
   --   instance:addEntity(wallBluePrint)

   --   instance:emit("blueprintActivated", wallBluePrint)

   --   -- eventManager.fireEvent("blueprint_activated"
   -- end
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
