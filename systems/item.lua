local Vector = require('libs.brinevector')
local inspect = require('libs.inspect') --luacheck: ignore
local lume = require('libs.lume')
local entityManager = require('models.entityManager')

local positionUtils = require('models.positionUtils')
local itemUtils = require('utils.itemUtils')

local ItemSystem = ECS.System({ pool = {"item"}})

function ItemSystem:initializeTestItems(mapSize) --luacheck: ignore
  local randomTable = {
    --walls = { "wooden_wall", "iron_wall" },
    raw_materials = { "wood", "iron", "stone", "steel" },
    seeds = { "potato_seed" }
  }

  for i=1,40,1 do  --luacheck: ignore
    local position = Vector(math.random(mapSize.x), math.random(mapSize.y))
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
  for i=1,400,1 do  --luacheck: ignore
    local position = Vector(love.math.random(mapSize.x), love.math.random(mapSize.y))
    if positionUtils.isPositionWalkable(position) then
      local selector = "growing.tree"
      local rawWood = itemUtils.createItem('raw_materials.wood', 2)
      local entity = ECS.Entity()
      entity:give("sprite", "vegetation.tree01")
      :give("onMap")
      :give("collision")
      :give("id", entityManager.generateId())
      :give("construction", 100)
      --:give("occluder")
      :give("selector", selector)
      :give("inventory", { rawWood.id.id })
      :give("position", positionUtils.gridPositionToPixels(position))
      :give("animation", {
        idle = {
          targetComponent = 'sprite',
          targetProperty = 'selector',
          interpolate = false,
          repeatAnimation = true,
          values = {
            "vegetation.tree01", "vegetation.tree01b"
          },
          currentValueIndex = love.math.random(1,2),
          frameLength = 0.4, -- in ms
          lastFrameUpdate = love.timer.getTime(),
          finished = false
        }
      },
      {
        'idle'
      })
      self:getWorld():addEntity(entity)
    end
    --itemUtils.placeItemOnGround(item, position)
  end
end

function ItemSystem:initializeTestShrubbery(mapSize)
  for i=1,200,1 do  --luacheck: ignore
    local position = Vector(love.math.random(mapSize.x), love.math.random(mapSize.y))
    local entity = ECS.Entity()
    entity:give("sprite", "vegetation." .. lume.randomchoice({"bush01", "grass01", "grass02", "grass03"}))
    :give("onMap")
    :give("id", entityManager.generateId())
    :give("position", positionUtils.gridPositionToPixels(position))
    self:getWorld():addEntity(entity)
    --itemUtils.placeItemOnGround(item, position)
  end
end
ItemSystem.Inventory = {}

return ItemSystem
