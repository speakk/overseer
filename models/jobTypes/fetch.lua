local itemUtils = require('utils.itemUtils')
local universe = require('models.universe')
local entityManager = require('models.entityManager')
local FetchBehaviour = require('models.ai.fetchBehaviour')

local function generate(targetId, itemData, selector)
  local subJob = ECS.Entity()
  :give(ECS.c.id, entityManager.generateId())
  subJob:give(ECS.c.job, "fetch")
  subJob:give(ECS.c.name, "FetchJob")
  subJob:give(ECS.c.item, itemData)
  subJob:give(ECS.c.selector, selector)
  subJob:give(ECS.c.fetchJob, targetId, selector, itemData.requirements[selector])

  return subJob
end

return {
  generate = generate
}
