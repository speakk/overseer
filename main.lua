require("libs/deepcopy")
local Concord = require("libs/concord")


require('components.common').initializeComponents()

DEBUG = false

ECS = {}
ECS.Component = require("libs.concord.component")
ECS.System = require("libs.concord.system")
ECS.World = require("libs.concord.world")
ECS.Entity = require("libs.concord.entity")

local world = ECS.World()

local windowWidth = 1000
local windowHeight = 800
love.window.setMode(windowWidth, windowHeight, { resizable=true })

local gamera = require('libs/gamera/gamera')
local camera = gamera.new(0, 0, 1000, 1000)

-- Add the Instance to concord to make it active
--Concord.addWorld(world)

local moveSystem = require('systems/moveSystem')()
local dayCycleSystem = require('systems/dayCycleSystem')()
local spriteSystem = require('systems/spriteSystem')()
local lightSystem = require('systems/lightSystem')(camera)
local mapSystem = require('systems/mapSystem')(camera)

local mapUtils = require("utils/mapUtils").init()

local itemSystem = require('systems/itemSystem')()
local jobSystem = require('systems/jobSystem')()
local bluePrintSystem = require('systems/bluePrintSystem')()
local overseerSystem = require('systems/overseerSystem')(camera)
local guiSystem = require('systems/guiSystem')(camera)
local playerInputSystem = require('systems/playerInputSystem')(camera)
local settlerSystem = require('systems/settlerSystem')()
local drawSystem = require('systems/drawSystem')()

local function load()
  love.graphics.setColor(255, 0, 0)

  world:addSystem(dayCycleSystem, "update")
  world:addSystem(spriteSystem)
  world:addSystem(lightSystem, "timeOfDayChanged")
  world:addSystem(guiSystem, "keypressed")
  world:addSystem(guiSystem, "mousepressed")
  world:addSystem(guiSystem, "mousereleased")
  world:addSystem(guiSystem, "mousemoved")
  world:addSystem(guiSystem, "update")
  world:addSystem(playerInputSystem, "update")
  world:addSystem(playerInputSystem, "mousepressed")
  world:addSystem(playerInputSystem, "wheelmoved")
  world:addSystem(bluePrintSystem, "update")
  world:addSystem(bluePrintSystem, "bluePrintsPlaced", "placeBluePrints")
  world:addSystem(bluePrintSystem, "bluePrintFinished")
  world:addSystem(settlerSystem, "update")
  world:addSystem(settlerSystem, "jobQueueUpdated")
  world:addSystem(settlerSystem, "gridUpdated", "invalidatePaths")
  world:addSystem(itemSystem)
  world:addSystem(mapSystem, "resize") -- Window resize event
  world:addSystem(mapSystem, "update")
  --worldce:addSystem(mapSystem, "draw")
  world:addSystem(drawSystem, "draw")
  world:addSystem(drawSystem, "registerSpriteBatchGenerator")
  world:addSystem(overseerSystem, "selectedModeChanged", "setSelectedAction")
  world:addSystem(overseerSystem, "dataSelectorChanged", "setDataSelector")
  world:addSystem(overseerSystem, "mapClicked", "enactClick")
  world:addSystem(overseerSystem, "update")
  world:addSystem(overseerSystem, "draw")
  world:addSystem(jobSystem, "draw")
  world:addSystem(jobSystem, "jobAdded", "addJob")
  world:addSystem(jobSystem, "jobFinished", "finishJob")
  world:addSystem(moveSystem, "update")
  world:addSystem(guiSystem, "draw")

  settlerSystem:initializeTestSettlers()
  itemSystem:initializeTestItems(mapSystem:getSize())
  lightSystem:initializeTestLights()

  world:emit("registerSpriteBatchGenerator", mapSystem:generateSpriteBatch)
  world:emit("registerSpriteBatchGenerator", spriteSystem:generateSpriteBatch)

  -- local profilerSystem = require('systems/profilerSystem')()
  -- instance:addSystem(profilerSystem, "update")
  -- instance:addSystem(profilerSystem, "draw")
end

function love.update(dt)
  world:emit('update', dt)
end

function love.draw()
  world:emit('draw')
end

function love.wheelmoved(x, y)
  world:emit('wheelmoved', x, y)
end

function love.resize(w, h)
  world:emit('resize', w, h)
end

function love.keypressed(pressedKey, scancode, isrepeat)
  world:emit('keypressed', pressedKey, scancode, isrepeat)
end

function love.mousepressed()
  world:emit('mousepressed', x, y, button, istouch, presses)
end

function love.mousereleased()
  world:emit('mousereleased', x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
  world:emit('mousemoved', x, y, dx, dy, istouch)
end

load()
