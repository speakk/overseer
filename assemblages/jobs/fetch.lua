local entityRegistry = require('models.entityRegistry')

-- targetId == where to return stuff to
return function(subJob, targetId, selector, amount)
  subJob
  :give("id", entityRegistry.generateId())
  :give("job", "fetch")
  :give("name", "FetchJob")
  :give("item", itemData)
  :give("fetchJob", targetId, selector, amount)
end
