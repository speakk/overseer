local itemUtils = require('utils.itemUtils')
local universe = require('models.universe')
local entityManager = require('models.entityManager')
local FetchBehaviour = require('models.ai.fetchBehaviour')

local function generate(targetId, itemData, selector)
  local subJob = ECS.Entity()
  :give("id", entityManager.generateId())
  subJob:give("job", "fetch")
  subJob:give("name", "FetchJob")
  subJob:give("item", itemData)
  subJob:give("selector", selector)
  subJob:give("fetchJob", targetId, selector, itemData.requirements[selector])

  return subJob
end

return {
  generate = generate
}
