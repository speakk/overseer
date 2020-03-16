local Vector = require('libs.brinevector')
local lume = require('libs.lume')
local universe = require('models.universe')
local camera = require('models.camera')

local constructionTypes = require('data.constructionTypes')

local ZoneSystem = ECS.System({ pool = { "zone", "rect" } })

local lastZoneUpdate = love.timer.getTime()
local zoneUpdateInterval = 2

local function getZoneCoorinates(rect)
  return universe.getOuterBorderCoordinates(
  math.min(rect.x1, rect.x2),
  math.min(rect.y1, rect.y2),
  math.max(rect.x1, rect.x2),
  math.max(rect.y1, rect.y2),
  true)
end

local zoneHandlers = {
  deconstruct = {
    run = function(self, zone, params, coords, dt)
      print("Running zoneHandlers deconstruct", params.selector)
      local entities = universe.getEntitiesInCoordinates(coords, params.selector, params.componentRequirements)
      self:getWorld():emit("cancelConstruction", entities)
    end
  },
  harvest = {
    run = function(self, zone, params, coords, dt)
      local entities = universe.getEntitiesInCoordinates(coords, nil, {'plant'})
      local ripeEntities = lume.filter(entities, function(entity) return entity.plant.finished end)
      print("ripeEntities", #ripeEntities)
      self:getWorld():emit("cancelConstruction", ripeEntities)
    end
  },
  construct = {
    run = function(self, zone, params, coords, dt)
      local constructSelector = params.selector

      for _, coordinate in ipairs(coords) do
        if not universe.isPositionOccupied(coordinate) then
          local data = constructionTypes.getBySelector(constructSelector)
          self:getWorld():emit("bluePrintsPlaced", {coordinate}, data, constructSelector)
        end
      end
    end
  }
}

function ZoneSystem:init()

end

function ZoneSystem:update(dt)
  local currentTime = love.timer.getTime()
  if currentTime - lastZoneUpdate > zoneUpdateInterval then
    lastZoneUpdate = love.timer.getTime()
    self:tickZones(dt)
  end
end

function ZoneSystem:tickZones()
  for _, zone in ipairs(self.pool) do
    local zoneC = zone.zone
    local rect = zone.rect
    local types = zoneC.types
    local params = zoneC.params
    local coords = getZoneCoorinates(rect)
    for _, type in ipairs(types) do
      assert(zoneHandlers[type], "No such zone handler exists: " .. (type or "nil"))
      zoneHandlers[type].run(self, zone, params, coords, dt)
    end
  end
end

function ZoneSystem:generateGUIDraw()
  -- TODO: Optimize the _heck_ out of this. Possibly store pixel coords in rect component and then just draw here
  for _, entity in ipairs(self.pool) do
    local rect = entity.rect

    local left = math.min(rect.x1, rect.x2)
    local top = math.min(rect.y1, rect.y2)
    local right = math.max(rect.x1, rect.x2)
    local bottom = math.max(rect.y1, rect.y2)
    local startPoint = universe.gridPositionToPixels(Vector(left, top), "left_top", 0)
    local endPoint = universe.gridPositionToPixels(Vector(right, bottom), "right_bottom", 0)

    if entity.color then
      love.graphics.setColor(unpack(entity.color.color))
    else
      love.graphics.setColor(1, 1, 1, 1)
    end

    love.graphics.rectangle("line",
      startPoint.x,
      startPoint.y,
      endPoint.x - startPoint.x,
      endPoint.y - startPoint.y
    )

    if entity.color then
      local color = { unpack(entity.color.color) }
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
