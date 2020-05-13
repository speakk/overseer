local Vector = require('libs.brinevector')
local Gamestate = require("libs.hump.gamestate")
local inspect = require('libs.inspect') --luacheck: ignore
local lume = require('libs.lume')
local entityRegistry = require('models.entityRegistry')

local positionUtils = require('utils.position')
local itemUtils = require('utils.itemUtils')

local ItemSystem = ECS.System({ pool = {"item"}})

function ItemSystem:initializeTestItems() --luacheck: ignore
  local mapConfig = Gamestate.current().mapConfig
  local randomTable = {
    --walls = { "wooden_wall", "iron_wall" },
    rawMaterials = { "wood", "iron", "stone", "steel" },
    seeds = { "potato" }
  }

  for i=1,40,1 do  --luacheck: ignore
    local position = Vector(math.random(mapConfig.width), math.random(mapConfig.height))
    if positionUtils.isPositionWalkable(position) then
      local keys1 = lume.keys(randomTable)
      local key = keys1[math.random(#keys1)]
      local category = randomTable[key]
      local itemName = category[math.random(#category)]
      local selector = key .. "." .. itemName
      local amount = 100
      local item = itemUtils.createItem(selector, amount)
      item:give("onMap")
      item:give("position", positionUtils.gridPositionToPixels(position))
      --self:getWorld():addEntity(item)
      --itemUtils.placeItemOnGround(item, position)
    end
  end
end

function ItemSystem:initializeTestTrees(mapSize)
  local mapConfig = Gamestate.current().mapConfig
  for i=1,300,1 do  --luacheck: ignore
    local position = Vector(math.random(mapConfig.width), math.random(mapConfig.height))
    if positionUtils.isPositionWalkable(position) then
      local selector = "growing.tree"
      local entity = ECS.Entity():assemble(ECS.a.getBySelector('plants.tree'))
      entity
      :give("position", positionUtils.gridPositionToPixels(position))
      :give("onMap")
      -- local rawWood = itemUtils.createItem('rawMaterials.wood', 2)
      -- local entity = ECS.Entity()
      -- entity:give("sprite", "vegetation.tree01")
      -- :give("onMap")
      -- :give("collision")
      -- :give("id", entityRegistry.generateId())
      -- :give("construction", 100)
      -- --:give("occluder")
      -- :give("selector", selector)
      -- :give("position", positionUtils.gridPositionToPixels(position))
      -- :give("animation", {
      --   idle = {
      --     targetComponent = 'sprite',
      --     targetProperty = 'selector',
      --     interpolate = false,
      --     repeatAnimation = true,
      --     values = {
      --       "vegetation.tree01", "vegetation.tree01b"
      --     },
      --     currentValueIndex = love.math.random(1,2),
      --     frameLength = 0.4, -- in ms
      --     lastFrameUpdate = love.timer.getTime(),
      --     finished = false
      --   }
      -- },
      -- {
      --   'idle'
      -- })
      self:getWorld():addEntity(entity)
    end
    --itemUtils.placeItemOnGround(item, position)
  end
end

function ItemSystem:initializeTestShrubbery(mapSize)
  local mapConfig = Gamestate.current().mapConfig
  for i=1,200,1 do  --luacheck: ignore
    local position = Vector(math.random(mapConfig.width), math.random(mapConfig.height))
    local entity = ECS.Entity():assemble(ECS.a.getBySelector("plants.plant"))
    entity:give("sprite", "vegetation." .. lume.randomchoice({"bush01", "grass01", "grass02", "grass03"}))
    :give("onMap")
    :give("selector", "shrubberytest")
    :give("id", entityRegistry.generateId())
    :give("position", positionUtils.gridPositionToPixels(position))
    self:getWorld():addEntity(entity)
    --itemUtils.placeItemOnGround(item, position)
  end
end

return ItemSystem
