local commonComponents = require('components/common')
local inspect = require('libs/inspect')
local ComponentLoader = {}

function ComponentLoader.loadComponent(name, ...)
  if not name then error("Trying to load component with no name!") end
  print(inspect(commonComponents[name]))
  return commonComponents[name].new(...)
end

return ComponentLoader
