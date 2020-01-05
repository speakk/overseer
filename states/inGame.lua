local inspect = require('libs.inspect')
local Gamestate = require("libs.hump.gamestate")

local inGame = {}

function inGame:init()
  self.world = ECS.World("wurld")
  self.universe = require("models.universe")
  self.universe:load(self.world)

  self.world:addSystem(ECS.Systems.serialization, "update")
  self.world:addSystem(ECS.Systems.serialization, "saveGame")
  self.world:addSystem(ECS.Systems.serialization, "loadGame")
  self.world:addSystem(ECS.Systems.serialization, "mousepressed")
  self.world:addSystem(ECS.Systems.serialization, "mousereleased")
  self.world:addSystem(ECS.Systems.serialization, "mousemoved")
  self.world:addSystem(ECS.Systems.move, "resetVelocities")
  self.world:addSystem(ECS.Systems.dayCycle, "update")
  self.world:addSystem(ECS.Systems.path, "update")
  self.world:addSystem(ECS.Systems.light, "cameraScaleChanged")
  self.world:addSystem(ECS.Systems.light, "cameraPositionChanged")
  self.world:addSystem(ECS.Systems.light, "timeOfDayChanged")
  self.world:addSystem(ECS.Systems.light, "self.worldSizeChanged")
  self.world:addSystem(ECS.Systems.gui, "keypressed")
  self.world:addSystem(ECS.Systems.gui, "mousepressed")
  self.world:addSystem(ECS.Systems.gui, "mousereleased")
  self.world:addSystem(ECS.Systems.gui, "mousemoved")
  self.world:addSystem(ECS.Systems.gui, "update")
  self.world:addSystem(ECS.Systems.playerInput, "update")
  self.world:addSystem(ECS.Systems.playerInput, "wheelmoved")
  self.world:addSystem(ECS.Systems.playerInput, "keypressed")
  self.world:addSystem(ECS.Systems.bluePrint, "bluePrintsPlaced", "placeBluePrints")
  self.world:addSystem(ECS.Systems.bluePrint, "bluePrintFinished")
  self.world:addSystem(ECS.Systems.settler, "update")
  self.world:addSystem(ECS.Systems.settler, "pathFinished")
  self.world:addSystem(ECS.Systems.settler, "jobQueueUpdated")
  self.world:addSystem(ECS.Systems.settler, "gridUpdated")
  self.world:addSystem(ECS.Systems.item)
  self.world:addSystem(ECS.Systems.camera, "resize")
  self.world:addSystem(ECS.Systems.map, "update")
  self.world:addSystem(ECS.Systems.draw, "draw")
  self.world:addSystem(ECS.Systems.draw, "registerSpriteBatchGenerator")
  self.world:addSystem(ECS.Systems.draw, "registerGUIDrawGenerator")
  self.world:addSystem(ECS.Systems.overseer, "selectedModeChanged", "setSelectedAction")
  self.world:addSystem(ECS.Systems.overseer, "dataSelectorChanged", "setDataSelector")
  self.world:addSystem(ECS.Systems.overseer, "mapClicked", "enactClick")
  self.world:addSystem(ECS.Systems.overseer, "mouseReleased")
  self.world:addSystem(ECS.Systems.overseer, "update")
  self.world:addSystem(ECS.Systems.job, "draw")
  --self.world:addSystem(ECS.Systems.job, "jobAdded", "addJob")
  self.world:addSystem(ECS.Systems.job, "jobFinished", "finishJob")
  self.world:addSystem(ECS.Systems.job, "gridUpdated", "clearInaccessibleFlag")
  self.world:addSystem(ECS.Systems.job, "cancelConstruction")
  self.world:addSystem(ECS.Systems.settler, "cancelConstruction")
  self.world:addSystem(ECS.Systems.map, "cancelConstruction")
  self.world:addSystem(ECS.Systems.move, "update")
  self.world:addSystem(ECS.Systems.sprite)
  self.world:addSystem(ECS.Systems.gui, "draw")

  self.world:getSystem(ECS.Systems.settler):initializeTestSettlers()
  self.world:getSystem(ECS.Systems.item):initializeTestItems(self.universe:getSize())
  --self.world:getSystem(ECS.Systems.light):initializeTestLights()

  self.world:emit("registerSpriteBatchGenerator", self.world:getSystem(ECS.Systems.map),
    self.world:getSystem(ECS.Systems.map).generateSpriteBatch)
  self.world:emit("registerSpriteBatchGenerator", self.world:getSystem(ECS.Systems.sprite),
    self.world:getSystem(ECS.Systems.sprite).generateSpriteBatch)
  self.world:emit("registerGUIDrawGenerator", self.world:getSystem(ECS.Systems.sprite),
    self.world:getSystem(ECS.Systems.sprite).generateGUIDraw, true)
  self.world:emit("registerGUIDrawGenerator", self.world:getSystem(ECS.Systems.overseer),
    self.world:getSystem(ECS.Systems.overseer).generateGUIDraw)
  self.world:emit("registerGUIDrawGenerator", self.world:getSystem(ECS.Systems.bluePrint),
    self.world:getSystem(ECS.Systems.bluePrint).generateGUIDraw, true)
  self.world:emit("registerGUIDrawGenerator", self.world:getSystem(ECS.Systems.serialization),
    self.world:getSystem(ECS.Systems.serialization).generateGUIDraw)

  if PROFILER then
    require('systems.profiler')
    self.world:addSystem(ECS.Systems.profiler, "update")
    self.world:addSystem(ECS.Systems.profiler, "draw")
  end

end

local asd = true
local nasd = true

function inGame:update(dt)
  self.world:emit('resetVelocities')
  self.world:emit('update', dt)
end

function inGame:draw()
  self.world:emit('draw')
end

function inGame:wheelmoved(x, y)
  self.world:emit('wheelmoved', x, y)
end

function inGame:resize(w, h)
  self.world:emit('resize', w, h)
end

function inGame:keypressed(pressedKey, scancode, isrepeat)
  self.world:emit('keypressed', pressedKey, scancode, isrepeat)
end

function inGame:mousepressed(x, y, button, istouch, presses)
  self.world:emit('mousepressed', x, y, button, istouch, presses)
end

function inGame:mousereleased(x, y, button, istouch, presses)
  self.world:emit('mousereleased', x, y, button, istouch, presses)
end

function inGame:mousemoved(x, y, dx, dy, istouch)
  self.world:emit('mousemoved', x, y, dx, dy, istouch)
end

return inGame
