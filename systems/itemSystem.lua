local Vector = require('libs/brinevector/brinevector')
local lume = require('libs/lume')
--local inspect = require('libs/inspect')
local components = require('libs/concord').components
local constructionTypes = require('data/constructionTypes')

local gridUtils = require('utils/gridUtils')
local itemUtils = require('utils/itemUtils')

local ItemSystem = ECS.System("item", {components.item})

function ItemSystem:initializeTestItems(mapSize)
  local randomTable = {
    --walls = { "wooden_wall", "iron_wall" },
    raw_materials = { "wood", "iron", "stone", "steel" }
  }

  for i=1,200,1 do  --luacheck: ignore
    local position = Vector(math.random(mapSize.x), math.random(mapSize.y))
    local keys1 = lume.keys(randomTable)
    local key = keys1[math.random(#keys1)]
    local category = randomTable[key]
    local itemName = category[math.random(#category)]
    local selector = key .. "." .. itemName
    local amount = love.math.random(30)
    local item = itemUtils.createItem(selector, amount)
    self:getWorld():addEntity(item)
    print("Creating item", selector)
    itemUtils.placeItemOnGround(item, position)
  end
end

ItemSystem.Inventory = {}

return ItemSystem
