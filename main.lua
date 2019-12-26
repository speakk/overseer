DEBUG = false
local PROFILER = false

ECS = {}
ECS.Component = require("libs.concord").component
ECS.Components = require("libs.concord").components
ECS.System = require("libs.concord").system
ECS.Systems = require("libs.concord").systems
ECS.World = require("libs.concord").world
ECS.Entity = require("libs.concord").entity

require('components.common').initializeComponents()


local world = ECS.World("wurld")
local universe = require("models.universe")
universe:load(world)

local windowWidth = 1000
local windowHeight = 800
love.window.setMode(windowWidth, windowHeight, { resizable=true })

-- Add the Instance to concord to make it active
--Concord.addWorld(world)

require('systems.cameraSystem')
require('systems.moveSystem')
require('systems.dayCycleSystem')
require('systems.spriteSystem')
require('systems.lightSystem')
require('systems.mapSystem')

require('systems.itemSystem')
require('systems.jobSystem')
require('systems.bluePrintSystem')
require('systems.overseerSystem')
require('systems.guiSystem')
require('systems.playerInputSystem')
require('systems.settlerSystem')
require('systems.drawSystem')

function love.load()
  love.graphics.setColor(255, 0, 0)

  world:addSystem(ECS.Systems.dayCycle, "update")
  world:addSystem(ECS.Systems.sprite)
  world:addSystem(ECS.Systems.light, "cameraScaleChanged")
  world:addSystem(ECS.Systems.light, "cameraPositionChanged")
  world:addSystem(ECS.Systems.light, "timeOfDayChanged")
  world:addSystem(ECS.Systems.light, "worldSizeChanged")
  world:addSystem(ECS.Systems.gui, "keypressed")
  world:addSystem(ECS.Systems.gui, "mousepressed")
  world:addSystem(ECS.Systems.gui, "mousereleased")
  world:addSystem(ECS.Systems.gui, "mousemoved")
  world:addSystem(ECS.Systems.gui, "update")
  world:addSystem(ECS.Systems.playerInput, "update")
  world:addSystem(ECS.Systems.playerInput, "wheelmoved")
  world:addSystem(ECS.Systems.bluePrint, "bluePrintsPlaced", "placeBluePrints")
  world:addSystem(ECS.Systems.bluePrint, "bluePrintFinished")
  world:addSystem(ECS.Systems.settler, "update")
  world:addSystem(ECS.Systems.settler, "jobQueueUpdated")
  world:addSystem(ECS.Systems.settler, "gridUpdated", "invalidatePaths")
  world:addSystem(ECS.Systems.item)
  world:addSystem(ECS.Systems.camera, "resize")
  world:addSystem(ECS.Systems.map, "update")
  world:addSystem(ECS.Systems.draw, "draw")
  world:addSystem(ECS.Systems.draw, "registerSpriteBatchGenerator")
  world:addSystem(ECS.Systems.draw, "registerGUIDrawGenerator")
  world:addSystem(ECS.Systems.overseer, "selectedModeChanged", "setSelectedAction")
  world:addSystem(ECS.Systems.overseer, "dataSelectorChanged", "setDataSelector")
  world:addSystem(ECS.Systems.overseer, "mapClicked", "enactClick")
  world:addSystem(ECS.Systems.overseer, "update")
  world:addSystem(ECS.Systems.job, "draw")
  world:addSystem(ECS.Systems.job, "jobAdded", "addJob")
  world:addSystem(ECS.Systems.job, "jobFinished", "finishJob")
  world:addSystem(ECS.Systems.move, "update")
  world:addSystem(ECS.Systems.gui, "draw")

  world:getSystem(ECS.Systems.settler):initializeTestSettlers()
  world:getSystem(ECS.Systems.item):initializeTestItems(universe:getSize())
  world:getSystem(ECS.Systems.light):initializeTestLights()

  world:emit("registerSpriteBatchGenerator", world:getSystem(ECS.Systems.map), world:getSystem(ECS.Systems.map).generateSpriteBatch)
  world:emit("registerSpriteBatchGenerator", world:getSystem(ECS.Systems.sprite), world:getSystem(ECS.Systems.sprite).generateSpriteBatch)
  world:emit("registerGUIDrawGenerator", world:getSystem(ECS.Systems.overseer), world:getSystem(ECS.Systems.overseer).generateGUIDraw)
  world:emit("registerGUIDrawGenerator", world:getSystem(ECS.Systems.bluePrint), world:getSystem(ECS.Systems.bluePrint).generateGUIDraw, true)

  if PROFILER then
    local profilerSystem = require('systems/profilerSystem')
    world:addSystem(ECS.Systems.profiler, "update")
    world:addSystem(ECS.Systems.profiler, "draw")
  end
end

function love.update(dt)
  world:flush()
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

function love.mousepressed(x, y, button, istouch, presses)
  world:emit('mousepressed', x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
  world:emit('mousereleased', x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
  world:emit('mousemoved', x, y, dx, dy, istouch)
end
