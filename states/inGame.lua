local inspect = require('libs.inspect')
local Gamestate = require("libs.hump.gamestate")

local inGame = {}

function inGame:init()

  -- Initialize BT shared actions

  local asd = true
  local nasd = true

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

  function inGame:enter(from, world)
    self.world = world
    -- if existing then
    --   self.world:emit('loadGame', existingSave)
    -- else
    -- end
    local inGameSystems = {
      ECS.Systems.dayCycle,
      ECS.Systems.animation,
      ECS.Systems.path,
      ECS.Systems.light,
      ECS.Systems.playerInput,
      ECS.Systems.overseer,
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

    if not self.world:hasSystem(ECS.Systems.settler) then
      self.world:addSystem(ECS.Systems.settler)
    end

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

    -- if PROFILER then
    --   require('systems.profiler')
    --   self.world:addSystem(ECS.Systems.profiler, "update")
    --   self.world:addSystem(ECS.Systems.profiler, "draw")
    -- end
    self.world:getSystem(ECS.Systems.light):initializeTestLights()

  end
end

function inGame:leave()
  self.world:clear()
end

return inGame
