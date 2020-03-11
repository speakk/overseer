local Fetch = require('models.jobTypes.fetch')
local universe = require('models.universe')
local itemUtils = require('utils.itemUtils')
local entityManager = require('models.entityManager')

local function generate(gridPosition, itemData, bluePrintItemSelector)
  local job = ECS.Entity()
  job:give(ECS.c.job, "bluePrint")
  job:give(ECS.c.name, "BluePrintJob")
  :give(ECS.c.id, entityManager.generateId())
  :give(ECS.c.onMap)
  :give(ECS.c.bluePrintJob, itemData.constructionSpeed or 1)
  :give(ECS.c.inventory) -- Item consumed so far
  :give(ECS.c.item, itemData, bluePrintItemSelector)
  :give(ECS.c.position, universe.gridPositionToPixels(gridPosition))
  :give(ECS.c.transparent)

  if itemData.components then
    for _, component in ipairs(itemData.components) do
      if not component.afterConstructed then
        if component.properties then
          job:give(ECS.c[component.name], unpack(component.properties))
        else
          job:give(ECS.c[component.name])
        end
      end
    end
  end

  local children = {}

  if itemData.requirements then
    job:give(ECS.c.children, {})
    local childrenIds = job:get(ECS.c.children).children
    for selector, amount in pairs(itemData.requirements) do
      local subJob = Fetch.generate(job:get(ECS.c.id).id, itemData, selector)
      subJob:give(ECS.c.parent, job:get(ECS.c.id).id)
      table.insert(children, subJob)
      table.insert(childrenIds, subJob:get(ECS.c.id).id)
    end
  end

  return job, children
end

local function finish(job)
    job:give(ECS.c.collision)
    job:give(ECS.c.construction, 100)
    job:remove(ECS.c.transparent)

    local itemData = job:get(ECS.c.item).itemData

    if itemData.components then
      for _, component in ipairs(itemData.components) do
        if component.afterConstructed then
          job:give(ECS.c[component.name], unpack(component.properties))
        end
      end
    end
end

return {
  generate = generate,
  finish = finish
}
