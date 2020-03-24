local itemUtils = require('utils.itemUtils')
local universe = require('models.universe')
local entityManager = require('models.entityManager')

return function(subJob, targetId, itemData, selector)
  subJob
  :give("id", entityManager.generateId())
  :give("job", "fetch")
  :give("name", "FetchJob")
  :give("item", itemData)
  :give("selector", selector)
  :give("fetchJob", targetId, selector, itemData.requirements[selector])
end
