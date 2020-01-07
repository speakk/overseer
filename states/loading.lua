local Gamestate = require("libs.hump.gamestate")

local inGame = require('states.inGame')

local loading = {}

function loading:init()

end

function loading:update(dt) --luacheck: ignore

end

function loading:draw()
  love.graphics.print("Loading game")
end

function loading:enter(from, existingSave)
  local systems = {
    ECS.Systems.serialization,
    ECS.Systems.map,
    ECS.Systems.bluePrint,
    ECS.Systems.job,
    ECS.Systems.item
  }
  self.world = ECS.World()
  self.world:addSystems(unpack(systems))
  self.universe = require("models.universe")
  self.universe:load(self.world)
  print("Entering", existingSave)
  print("Entering2", existingSave)

  if existingSave then
    print("Emitting")
    self.world:emit('loadGame', existingSave)
  else
    self.world:addSystems(ECS.Systems.settler)
    self.world:getSystem(ECS.Systems.settler):initializeTestSettlers()
    self.world:getSystem(ECS.Systems.item):initializeTestItems(self.universe:getSize())
  end

  Gamestate.switch(inGame, self.world)
end

return loading
