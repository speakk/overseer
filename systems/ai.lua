local entityManager = require('models.entityManager')
local inspect = require('libs.inspect')

local AISystem = ECS.System({ECS.c.work, "work"})

local behaviours = {
  fetch = require('models.ai.fetchBehaviour').createTree
}

local attachedBehaviours = {}

function attachBehaviour(entity, type)
  local id = entity:get(ECS.c.id).id
  attachedBehaviours[id] = attachedBehaviours[id] or {}

  print("type", id, type, entity)
  attachedBehaviours[id][type] = behaviours[type](entity)
  --table.insert(attachedBehaviours[id], behaviours[type](entity))
end

function detachBehaviour(entity, type)
  attachedBehaviours[id][type] = nil
end

function AISystem:init()
  self.work.onEntityAdded = function(pool, entity)
    local jobComponent = entityManager.get(entity:get(ECS.c.work).jobId):get(ECS.c.job)
    local jobType = jobComponent.jobType
    --inspect(job:customSerialize())
    attachBehaviour(entity, jobType)
  end

  self.work.onEntityRemoved = function(pool, entity)
    local jobComponent = entityManager.get(entity:get(ECS.c.work).jobId):get(ECS.c.job)
    local jobType = jobComponent.jobType
    detachBehaviour(entity, jobType)
  end
end

function AISystem:update(dt)
  for _, entity in ipairs(self.work) do
    local id = entity:get(ECS.c.id).id
    local jobComponent = entityManager.get(entity:get(ECS.c.work).jobId):get(ECS.c.job)
    local jobType = jobComponent.jobType
    --print("attachBehaviour", inspect(attachedBehaviours[id]))
    attachedBehaviours[id][jobType]:run()
  end
end

return AISystem
