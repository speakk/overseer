local PathFindGrid = require("models.pathFindGrid")
local mapGenerator = require("utils.mapGenerator")

local inGame = {}

function inGame:enter(from) --luacheck: ignore
  self.world = ECS.World()

  self.mapConfig = {
    width = 100,
    height = 100,
    cellSize = 32
  }

  local map, mapColors = mapGenerator.generateMap(self.mapConfig.width, self.mapConfig.height)
  self.pathFindGrid = PathFindGrid(map)
  self:setMap(map, mapColors)

  local inGameSystems = {
    ECS.Systems.serialization,
    ECS.Systems.settler,
    ECS.Systems.map,
    ECS.Systems.bluePrint,
    ECS.Systems.item,
    ECS.Systems.dayCycle,
    ECS.Systems.animation,
    ECS.Systems.path,
    ECS.Systems.light,
    ECS.Systems.playerInput,
    ECS.Systems.overseer,
    ECS.Systems.satiety,
    ECS.Systems.health,
    ECS.Systems.gui,
    ECS.Systems.camera,
    ECS.Systems.draw,
    ECS.Systems.sprite,
    ECS.Systems.ai,
    ECS.Systems.plant,
    ECS.Systems.zone,
    ECS.Systems.job,
    ECS.Systems.move
  }

  self.world:addSystems(unpack(inGameSystems))

  self.world:emit("registerDrawFunction", self.world:getSystem(ECS.Systems.map),
  self.world:getSystem(ECS.Systems.map).customDraw)
  self.world:emit("registerDrawFunction", self.world:getSystem(ECS.Systems.sprite),
  self.world:getSystem(ECS.Systems.sprite).customDraw)
  self.world:emit("registerGUIDrawGenerator", self.world:getSystem(ECS.Systems.sprite),
  self.world:getSystem(ECS.Systems.sprite).generateGUIDraw, true)
  self.world:emit("registerGUIDrawGenerator", self.world:getSystem(ECS.Systems.overseer),
  self.world:getSystem(ECS.Systems.overseer).generateGUIDraw)
  self.world:emit("registerGUIDrawGenerator", self.world:getSystem(ECS.Systems.bluePrint),
  self.world:getSystem(ECS.Systems.bluePrint).generateGUIDraw, true)
  self.world:emit("registerGUIDrawGenerator", self.world:getSystem(ECS.Systems.zone),
  self.world:getSystem(ECS.Systems.zone).generateGUIDraw, true)
  self.world:emit("registerGUIDrawGenerator", self.world:getSystem(ECS.Systems.dayCycle),
  self.world:getSystem(ECS.Systems.dayCycle).generateGUIDraw)
  self.world:emit("registerGUIDrawGenerator", self.world:getSystem(ECS.Systems.serialization),
  self.world:getSystem(ECS.Systems.serialization).generateGUIDraw)

  if PROFILER then
    require('systems.profiler')
    self.world:addSystem(ECS.Systems.profiler)
  end

  self:initializeTestStuff()
end

function inGame:setMap(map, mapColors)
  self.map = map
  self.mapColors = mapColors
  self.world:emit("mapUpdated", map)
end

function inGame:changeMapAt(x, y, value)
  self.map[y][x] = value
  self.world:emit("mapUpdated", self.map)
end

function inGame:update(dt)
  self.world:emit('resetVelocities')
  self.world:emit('update', dt)
end

function inGame:draw()
  self.world:emit('draw')
  self.world:emit('guiDraw')
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

function inGame:initializeTestStuff()
  self.world:getSystem(ECS.Systems.light):initializeTestLights()
  self.world:getSystem(ECS.Systems.settler):initializeTestSettlers()
  self.world:getSystem(ECS.Systems.settler):initializeTestCreatures()
  self.world:getSystem(ECS.Systems.item):initializeTestItems(self.positionUtils.getSize())
  self.world:getSystem(ECS.Systems.item):initializeTestTrees(self.positionUtils.getSize())
  self.world:getSystem(ECS.Systems.item):initializeTestShrubbery(self.positionUtils.getSize())
end

function inGame:leave()
  self.world:clear()
end

return inGame
