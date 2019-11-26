local commonComponents = require('components/common')
-- Create a draw System.
local BluePrintSystem = ECS.System({commonComponents.BluePrint})

function BluePrintSystem:update(dt)
  
end

function BluePrintSystem:bluePrintFinished(bluePrint)
  if bluePrint:has(commonComponents.Draw) then
    local draw = bluePrint:get(commonComponents.Draw)
    draw.color = { 1, 0, 0 }
  end

end

return BluePrintSystem


