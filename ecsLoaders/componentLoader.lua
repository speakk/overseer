local commonComponents = require('components/commonComponents')
local ComponentLoader = {}

function ComponentLoader.loadComponent(name, params)
  if not name then error("Trying to load component with no name!")
  return commonComponents[name](params)
end

return ComponentLoader
