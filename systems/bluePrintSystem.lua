local commonComponents = require('components/common')
-- Create a draw System.
local BluePrintSystem = ECS.System({commonComponents.BluePrint})

function BluePrintSystem:update(dt)
  
end

return BluePrintSystem


