local fetchTask = BehaviourTree.Task:new({
  run = function(task, dog)
    dog:bark()
    task:success()
  end
})

local pickItemUpTask = BehaviourTree.Task:new({
  run = function(task, settler)

  end
})



local moveItemFromTo = BehaviourTree.Task:new({
  start = function(task, vars) 

  end,
  run = function(task, vars) -- vars: settler, target
    local jobId = settler:get(ECS.c.work).jobId
    local job = entityManager.get(jobId)
    --local job = entities.getById(settler:get(ECS.c.work).jobId)
    local targetId = job:get(ECS.c.fetchJob).targetId
    local target = entityManager.get(targetId)

    settler.searched_for_path = false
    local inventory = settler:get(ECS.c.inventory)
    local invItem = inventory:popItem(selector, amount)
    local targetInventory = target:get(ECS.c.inventory)
    targetInventory:insertItem(invItem:get(ECS.c.id).id)
    print("Putting into the targetInventory, as in job finished")
    -- JOB FINISHED!
  end
})

--local moveItemFromTo = function(fromInventory, toInventory, item)
--  targetInventory:insertItem(invItem:get(ECS.c.id).id)
--end
