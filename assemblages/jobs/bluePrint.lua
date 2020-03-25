local positionUtils = require('utils.position')
local itemUtils = require('utils.itemUtils')
local entityRegistry = require('models.entityRegistry')

return function(e, gridPosition, itemData, bluePrintItemSelector)
  e
  :give("job", "bluePrint", "bluePrintFinished")
  :give("name", "BluePrintJob")
  :give("id", entityRegistry.generateId())
  :give("onMap")
  :give("bluePrintJob", itemData.constructionSpeed or 1)
  :give("inventory") -- Item consumed so far
  :give("item", itemData, bluePrintItemSelector)
  :give("position", positionUtils.gridPositionToPixels(gridPosition))
  :give("transparent")

  if itemData.components then
    for _, component in ipairs(itemData.components) do
      if not component.afterConstructed then
        if component.properties then
          e:give(component.name, unpack(component.properties))
        else
          e:give(component.name)
        end
      end
    end
  end

  --local children = {}

  -- -- TODO: MOVE OUTSIDE
  -- if itemData.requirements then
  --   job:give("children", {})
  --   local childrenIds = job.children.children
  --   for selector, amount in pairs(itemData.requirements) do
  --     local subJob = Fetch.generate(job.id.id, itemData, selector)
  --     subJob:give("parent", job.id.id)
  --     table.insert(children, subJob)
  --     table.insert(childrenIds, subJob.id.id)
  --   end
  -- end
end
