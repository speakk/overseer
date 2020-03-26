local windowWidth = 1000
local windowHeight = 800
love.window.setMode(windowWidth, windowHeight, { resizable=true })
love.graphics.setDefaultFilter('nearest', 'nearest')

require("libs.batteries.stable_sort")
require("libs.batteries.table")

local inspect = require('libs.inspect')
local lume = require('libs.lume')
limits = love.graphics.getSystemLimits( )
print(inspect(limits))

DEBUG = false
-- PROFILER = true

local Concord = require("libs.concord")

ECS = {}

ECS.Component = function (path, ...)
  local name = string.match(path, '%.([^%.]*)$')

  return Concord.component(name, ...)
end

ECS.c = Concord.components
ECS.System = Concord.system
ECS.World = Concord.world
ECS.Entity = Concord.entity

local assemblageNames = { "creatures", "doors", "food", "jobs", "lights", "plants", "rawMaterials", "seeds", "walls" }

ECS.a = { }

for _, name in ipairs(assemblageNames) do
  ECS.a[name] = {}
  Concord.utils.loadNamespace("assemblages/" .. name, ECS.a[name])
end

local function getAssemblageBySelectorTable(data, selectorTable)
  print("selectorTable", selectorTable, data)
  if #selectorTable == 0 then
    return data
  end
  local newTable = {unpack(selectorTable)}
  local lastSelector = table.remove(newTable, 1)
  print("lastSelector", lastSelector)
  return getAssemblageBySelectorTable(data[lastSelector], newTable)

  --if #selectorTable > 1 and data[lastSelector] then return getAssemblageBySelectorTable(data[lastSelector], newTable) end
  --if #selectorTable == 1 then return getAssemblageBySelectorTable(
end

ECS.a.getBySelector = function(selector)
  local selectorTable = lume.split(selector, ".")
  return getAssemblageBySelectorTable(ECS.a, selectorTable)
end

Concord.utils.loadNamespace("components")
ECS.Systems = Concord.utils.loadNamespace("systems", {})


local Gamestate = require("libs.hump.gamestate")

local gameStates = {
  inGame = require("states.inGame"),
  mainMenu = require("states.mainMenu")
}

function love.load()
  Gamestate.registerEvents()
  Gamestate.switch(gameStates.mainMenu)
end
