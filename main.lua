local lovetoys = require('libs/lovetoys')
local cpml = require('libs/cpml')

local commonComponents = require('components/common')

local DrawSystem = require('systems/drawSystem')
local PlayerInputSystem = require('systems/playerInputSystem')
local CameraSystem = require('systems/cameraSystem')
local MoveSystem = require('systems/moveSystem')
local SettlerSystem = require('systems/settlerSystem')
local BluePrintSystem = require('systems/bluePrintSystem')

lovetoys.initialize({globals = true, debug = true})

local windowWidth = 1000
local windowHeight = 800

x = 5.0
speed = 25

mod_a = 0.0

height = 60
width = 60

function love.load()
  love.graphics.setColor(255, 0, 0)
  love.window.setMode(windowWidth, windowHeight, { resizable=true })

  cameraEntity = Entity()
  cameraEntity:initialize()
  cameraEntity:add(commonComponents.Position(30, 40))
  cameraEntity:add(commonComponents.Velocity(cpml.vec2(0, 0)))
  cameraEntity:add(commonComponents.PlayerInput())
  cameraEntity:add(commonComponents.CameraComponent())

  local eventManager = EventManager()
  eventManager:initialize();

  -- Finally, we setup an Engine.
  engine = Engine()
  engine:addEntity(cameraEntity)

  for i = 1,10,1 do
    settler = Entity()
    settler:initialize()
    settler:add(commonComponents.Position(math.random(windowWidth), math.random(windowHeight)))
    settler:add(commonComponents.Draw({1,0.5,0}))
    settler:add(commonComponents.Settler())
    settler:add(commonComponents.Velocity())
    engine:addEntity(settler)
  end

  for i = 1,10,1 do
    local wallBluePrint = Entity()
    wallBluePrint:initialize()
    wallBluePrint:add(commonComponents.Position(math.random(windowWidth), math.random(windowHeight)))
    wallBluePrint:add(commonComponents.Draw({0,0,1,1}))
    wallBluePrint:add(commonComponents.BluePrint())
    engine:addEntity(wallBluePrint)

    -- eventManager.fireEvent("blueprint_activated"
  end


  -- This will be a 'draw' System, so the
  -- Engine will call its draw method.
  engine:addSystem(PlayerInputSystem())
  engine:addSystem(CameraSystem())
  engine:addSystem(BluePrintSystem())
  engine:addSystem(SettlerSystem(eventManager))
  engine:addSystem(MoveSystem())
  engine:addSystem(DrawSystem(), "draw")
end

function love.update(dt)
  x = x + speed * dt
  mod_a = math.sin(x*0.1)*0.3+0.7
  engine:update(dt)
end

function love.draw()
  -- love.graphics.setColor(mod_a, mod_a, math.sin(x*0.07)*255)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
  --love.graphics.ellipse("fill", x, 200, width, mod_a*height, 100)
  engine:draw()
end
