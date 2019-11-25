-- Create a draw System.
local BluePrintSystem = class("BluePrintSystem", System)

-- Define this System requirements.
function BluePrintSystem:requires()
  return {"blueprint"}
end

function BluePrintSystem:update(dt)
  
end

function BluePrintSystem:onAddEntity(entity, group)

end

return BluePrintSystem


