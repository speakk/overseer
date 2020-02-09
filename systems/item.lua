local Vector = require('libs.brinevector')
local inspect = require('libs.inspect') --luacheck: ignore
local lume = require('libs.lume')

local universe = require('models.universe')
local itemUtils = require('utils.itemUtils')

local ItemSystem = ECS.System({ECS.c.item})

function ItemSystem:initializeTestItems(mapSize)
  local randomTable = {
    --walls = { "wooden_wall", "iron_wall" },
    raw_materials = { "wood", "iron", "stone", "steel" }
  }

  for i=1,40,1 do  --luacheck: ignore
    local position = Vector(math.random(mapSize.x), math.random(mapSize.y))
    local keys1 = lume.keys(randomTable)
    local key = keys1[math.random(#keys1)]
    local category = randomTable[key]
    local itemName = category[math.random(#category)]
    local selector = key .. "." .. itemName
    local amount = 100
    local item = itemUtils.createItem(selector, amount)
    item:give(ECS.c.onMap)
    item:give(ECS.c.position, universe.gridPositionToPixels(position))
    --self:getWorld():addEntity(item)
    --itemUtils.placeItemOnGround(item, position)
  end
end

function ItemSystem:initializeTestTrees(mapSize)
  for i=1,200,1 do  --luacheck: ignore
    local position = Vector(math.random(mapSize.x), math.random(mapSize.y))
    local selector = "growing.tree"
    local entity = ECS.Entity()
    entity:give(ECS.c.sprite, "vegetation.tree01")
    :give(ECS.c.onMap)
    :give(ECS.c.collision)
    :give(ECS.c.occluder)
    :give(ECS.c.position, universe.gridPositionToPixels(position))
    self:getWorld():addEntity(entity)
    --itemUtils.placeItemOnGround(item, position)
  end
end

ItemSystem.Inventory = {}

return ItemSystem
