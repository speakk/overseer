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
    local jobId = settler:get(ECS.Components.work).jobId
    local job = entityReferenceManager.getEntity(jobId)
    local targetId = job:get(ECS.Components.fetchJob).targetId
    local target = entityReferenceManager.getEntity(targetId)

    settler.searched_for_path = false
    local inventory = settler:get(ECS.Components.inventory)
    local invItem = inventory:popItem(selector, amount)
    local targetInventory = target:get(ECS.Components.inventory)
    targetInventory:insertItem(invItem:get(ECS.Components.id).id)
    print("Putting into the targetInventory, as in job finished")
    -- JOB FINISHED!
  end
})

--local moveItemFromTo = function(fromInventory, toInventory, item)
--  targetInventory:insertItem(invItem:get(ECS.Components.id).id)
--end

