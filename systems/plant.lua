local PlantSystem = ECS.System({ plants = { "plant" } })

local lastTick = love.timer.getTime()
local tickInterval = 3

function PlantSystem:init()
  self.plants.onEntityAdded = function(pool, entity)
    entity:give("sprite", entity.plant.frames[entity.plant.currentStage or 1])
  end
end

function PlantSystem:timeChanged(time, timeOfDay)
  for _, entity in ipairs(self.plants) do
    local plantC = entity.plant
    if not plantC.finished then
      if not plantC.lastGrowth then
        plantC.lastGrowth = time
      end

      local growTimeDelta = time - plantC.lastGrowth
      if growTimeDelta > plantC.growInterval then
        self:plantProgress(entity)
        plantC.lastGrowth = time
      end
    end
  end
end

function PlantSystem:plantProgress(entity)
  local plantC = entity.plant
  if not plantC.currentStage then plantC.currentStage = 1 end

  plantC.currentStage = plantC.currentStage + 1
  if plantC.currentStage >= #plantC.frames then
    plantC.currentStage = #plantC.frames
    plantC.finished = true
    self:getWorld():emit("plantGrowingFinished")
  end

  entity:give("sprite", plantC.frames[plantC.currentStage])
end

return PlantSystem
