DEBUG = false
local PROFILER = false

local Gamestate = require("libs.hump.gamestate")

local gameStates = {
  inGame = require("states.inGame"),
  mainMenu = require("states.mainMenu")
}


ECS = {}
ECS.Component = require("libs.concord").component
ECS.Components = require("libs.concord").components
ECS.System = require("libs.concord").system
ECS.Systems = require("libs.concord").systems
ECS.World = require("libs.concord").world
ECS.Entity = require("libs.concord").entity

require('components.common').initializeComponents()

local Concord = require("libs.concord")
Concord.loadSystems("systems")

local windowWidth = 1000
local windowHeight = 800
love.window.setMode(windowWidth, windowHeight, { resizable=true })

function love.load()
  Gamestate.registerEvents()
  Gamestate.switch(gameStates.mainMenu)
end

