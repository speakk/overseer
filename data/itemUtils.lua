local Vector = require('libs/brinevector/brinevector')
local constructionTypes = require("data/constructionTypes")
local commonComponents = require("components/common")
local ItemUtils = {}
function ItemUtils.createItem(instance, selector, amount)
  amount = amount or 1

  local item = ECS.Entity()
  local itemData = constructionTypes.getBySelector(selector)
  local color = itemData.color or { 0.5, 0.5, 0.5 }
  item:give(commonComponents.Item, itemData, selector)
  :give(commonComponents.Draw, color, Vector(16, 16))
  :give(commonComponents.Amount, amount)

  item:apply()
  instance:addEntity(item)

  return item
end

return ItemUtils
