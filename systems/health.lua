local HealthSystem = ECS.System({ pool = { "health" } })

local stomachEmptyDamageSpeed = 10

function HealthSystem:satietyAtZero(entity, dt) --luacheck: ignore
  if entity.health then
    entity.health.value = entity.health.value - stomachEmptyDamageSpeed * dt
  end
end

function HealthSystem:update(dt) --luacheck: ignore
  for _, entity in ipairs(self.pool) do
    if entity.health.value <= 0 then
      self:getWorld():emit("death", entity)
    end
  end
end

-- TODO: Probably move this into something more sinister sounding like DeathSystem
function HealthSystem:death(entity)
  local position = entity.position.vector.copy
  local blood = ECS.Entity():give("sprite", "gore.blood1"):give("position", position)
  self:getWorld():addEntity(blood)

  entity:destroy()
end

return HealthSystem
