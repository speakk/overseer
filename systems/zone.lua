local Vector = require('libs.brinevector')
local universe = require('models.universe')
local camera = require('models.camera')

local ZoneSystem = ECS.System({ECS.c.zone, ECS.c.rect})

function ZoneSystem:init()

end

function ZoneSystem:generateGUIDraw()
  -- TODO: Optimize the _heck_ out of this. Possibly store pixel coords in rect component and then just draw here
  for _, entity in ipairs(self.pool) do
    local rect = entity:get(ECS.c.rect)

    local left = math.min(rect.x1, rect.x2)
    local top = math.min(rect.y1, rect.y2)
    local right = math.max(rect.x1, rect.x2)
    local bottom = math.max(rect.y1, rect.y2)
    local startPoint = universe.gridPositionToPixels(Vector(left, top), "left_top", 0)
    local endPoint = universe.gridPositionToPixels(Vector(right, bottom), "right_bottom", 0)

    if entity:has(ECS.c.color) then
      love.graphics.setColor(unpack(entity:get(ECS.c.color).color))
    else
      love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.rectangle("line",
      startPoint.x,
      startPoint.y,
      endPoint.x - startPoint.x,
      endPoint.y - startPoint.y
    )

    if entity:has(ECS.c.color) then
      local color = { unpack(entity:get(ECS.c.color).color) }
      color[4] = 0.1
      love.graphics.setColor(color)
    else
      love.graphics.setColor(1, 1, 1, 0.1)
    end

    love.graphics.rectangle("fill",
      startPoint.x,
      startPoint.y,
      endPoint.x - startPoint.x,
      endPoint.y - startPoint.y
    )
  end
end

return ZoneSystem
