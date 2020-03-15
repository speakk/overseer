local Fetch = require('models.jobTypes.fetch')
local universe = require('models.universe')
local itemUtils = require('utils.itemUtils')
local entityManager = require('models.entityManager')

local function generate(gridPosition, itemData, bluePrintItemSelector)
  local job = ECS.Entity()
  job:give("job", "bluePrint")
  job:give("name", "BluePrintJob")
  :give("id", entityManager.generateId())
  :give("onMap")
  :give("bluePrintJob", itemData.constructionSpeed or 1)
  :give("inventory") -- Item consumed so far
  :give("item", itemData, bluePrintItemSelector)
  :give("position", universe.gridPositionToPixels(gridPosition))
  :give("transparent")

  if itemData.components then
    for _, component in ipairs(itemData.components) do
      if not component.afterConstructed then
        if component.properties then
          job:give(component.name, unpack(component.properties))
        else
          job:give(component.name)
        end
      end
    end
  end

  local children = {}

  if itemData.requirements then
    job:give("children", {})
    local childrenIds = job.children.children
    for selector, amount in pairs(itemData.requirements) do
      local subJob = Fetch.generate(job.id.id, itemData, selector)
      subJob:give("parent", job.id.id)
      table.insert(children, subJob)
      table.insert(childrenIds, subJob.id.id)
    end
  end

  return job, children
end

local function finish(job)
    job:give("collision")
    job:give("construction", 100)
    job:remove("transparent")

    local itemData = job.item.itemData

    if itemData.components then
      for _, component in ipairs(itemData.components) do
        if component.afterConstructed then
          job:give(component.name, unpack(component.properties))
        end
      end
    end
end

return {
  generate = generate,
  finish = finish
}
