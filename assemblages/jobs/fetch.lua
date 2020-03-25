local entityRegistry = require('models.entityRegistry')

return function(subJob, targetId, itemData, selector)
  subJob
  :give("id", entityRegistry.generateId())
  :give("job", "fetch")
  :give("name", "FetchJob")
  :give("item", itemData)
  :give("selector", selector)
  :give("fetchJob", targetId, selector, itemData.requirements[selector])
end
