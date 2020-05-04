require('libs.batteries.functional')
local Vector = require('libs.brinevector')
local lume = require('libs.lume')
local positionUtils = require('utils.position')
local camera = require('models.camera')
local entityFinder = require('models.entityFinder')

local ZoneSystem = ECS.System({ pool = { "zone", "rect" } })

local lastZoneUpdate = love.timer.getTime()
local zoneUpdateInterval = 2

local function getZoneCoorinates(rect)
  return positionUtils.getOuterBorderCoordinates(
  math.min(rect.x1, rect.x2),
  math.min(rect.y1, rect.y2),
  math.max(rect.x1, rect.x2),
  math.max(rect.y1, rect.y2),
  true)
end

local zoneHandlers = {
  deconstruct = {
    run = function(self, zone, params, coords, dt) --luacheck: ignore
      --local entities = entityFinder.getEntitiesInCoordinates(coords, params.selector, params.componentRequirements)
      -- local entities = entityFinder.getByQueryObject(
      --   entityFinder.queryBuilders.positionListAndSelector(coords, params.selector),
      --   params.componentRequirements)
      -- local entities = entityFinder.filterBySelector(
      --   entityFinder.getByQueryObject(
      --     entityFinder.queryBuilders.positionList(coords),
      --     params.componentRequirements
      --   ),
      --   params.selector
      -- )
      local entities = entityFinder.filterBySelector(
        entityFinder.getByList(
          functional.map(coords, function(coord) return {
            key = "position",
            value = entityFinder.getGridPositionString(coord)
          } end),
          params.componentRequirements
        ),
        params.selector
      )

      self:getWorld():emit("cancelConstruction", entities)
    end
  },
  harvest = {
    run = function(self, zone, params, coords, dt) --luacheck: ignore
      --local entities = entityFinder.getEntitiesInCoordinates(coords, nil, {'plant'})
      local entities = entityFinder.getByQueryObject(entityFinder.queryBuilders.positionList(coords), { 'plant' })
      local ripeEntities = lume.filter(entities, function(entity) return entity.plant.finished end)
      print("ripeEntities", #ripeEntities)
      self:getWorld():emit("cancelConstruction", ripeEntities)
    end
  },
  construct = {
    run = function(self, zone, params, coords, dt) --luacheck: ignore
      local assemblage = ECS.a.getBySelector(params.selector)

      for _, coordinate in ipairs(coords) do
        if not entityFinder.isPositionOccupied(coordinate) then
          self:getWorld():emit("bluePrintsPlaced", {coordinate}, assemblage)
        end
      end
    end
  }
}

function ZoneSystem:update(dt)
  local currentTime = love.timer.getTime()
  if currentTime - lastZoneUpdate > zoneUpdateInterval then
    lastZoneUpdate = love.timer.getTime()
    self:tickZones(dt)
  end
end

function ZoneSystem:tickZones(dt)
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
    local startPoint = positionUtils.gridPositionToPixels(Vector(left, top), "left_top", 0)
    local endPoint = positionUtils.gridPositionToPixels(Vector(right, bottom), "right_bottom", 0)

    if entity.color then
      love.graphics.setColor(unpack(entity.color.color))
    else
      love.graphics.setColor(1, 1, 1, 1)
    end

    if entity.zone.hilighted then
      love.graphics.setColor(1,1,1,1)
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

function ZoneSystem:mousemoved(x, y, dx, dy, istouch) --luacheck: ignore
  for _, entity in ipairs(self.pool) do
    local rect = entity.rect
    local corner1 = positionUtils.gridPositionToPixels(Vector(math.min(rect.x1, rect.x2), math.min(rect.y1, rect.y2)))
    local corner2 = positionUtils.gridPositionToPixels(Vector(math.max(rect.x1, rect.x2), math.max(rect.y1, rect.y2)), "right_bottom") --luacheck: ignore

    local globalX, globalY = camera:toWorld(x, y)

    if globalX > corner1.x and
      globalX < corner2.x and
      globalY > corner1.y and
      globalY < corner2.y then
      entity.zone.hilighted = true
    else
      entity.zone.hilighted = false
    end
  end
end

function ZoneSystem:zoneDeleteClick(mouseCoordinates) -- luacheck:ignore
  local hilighted = table.filter(self.pool, function(entity) return entity.zone.hilighted end)
  if #hilighted > 0 then
    for _, entity in ipairs(hilighted) do
      entity:destroy()
    end
  end
end

return ZoneSystem
