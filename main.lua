local windowWidth = 1000
local windowHeight = 800
love.window.setMode(windowWidth, windowHeight, { resizable=true })
love.graphics.setDefaultFilter('nearest', 'nearest')

local inspect = require('libs.inspect')
limits = love.graphics.getSystemLimits( )
print(inspect(limits))

DEBUG = false
local PROFILER = false

local Concord = require("libs.concord")

ECS = {}
-- ECS.Component = Concord.component
ECS.Component = function (path, ...)
  local name = string.match(path, '%.([^%.]*)$')

  return Concord.component(name, ...)
end
ECS.c = Concord.components
ECS.System = Concord.system
ECS.World = Concord.world
ECS.Entity = Concord.entity

Concord.utils.loadNamespace("components")
ECS.Systems = Concord.utils.loadNamespace("systems", {})

--Concord.loadComponents("components")
--Concord.loadSystems("systems")

local Gamestate = require("libs.hump.gamestate")

local gameStates = {
  inGame = require("states.inGame"),
  mainMenu = require("states.mainMenu")
}

function love.load()
  Gamestate.registerEvents()
  Gamestate.switch(gameStates.mainMenu)
end

