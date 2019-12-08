local commonComponents = require('components/common')
local inspect = require('libs/inspect')
local EntityLoader = {}

function EntityLoader.copyEntity(entity)
  if not entity then error("Trying to copy nil entity") end
  return commonComponents[name].new(...)
end

return ComponentLoader

