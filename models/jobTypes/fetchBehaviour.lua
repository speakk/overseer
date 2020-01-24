local fetchTask = BehaviourTree.Task:new({
  run = function(task, dog)
    dog:bark()
    task:success()
  end
})

-- LEAF NODES

local hasEnoughOfItem = BehaviourTree.Task:new({
  run = function(task, blackboard)
    local invItem = blackboard.inventory:get(selector)
    if invItem:get(ECS.c.amount).amount >= blackboard.targetAmount then
      task:success()
    else
      task:fail()
    end
  end
})

local insertItemIntoDestination = BehaviourTree.Task:new({
  run = function(task, blackboard)
    local invItem = inventory:popItem(selector, amount)
    local targetInventory = target:get(ECS.c.inventory)
    targetInventory:insertItem(invItem:get(ECS.c.id).id)
    task:success()
    print("Putting into the targetInventory, as in job finished")
  end
})

local pickItemAmountUp = BehaviourTree.Task:new({
  run = function(task, blackboard)
    local gridPosition = universe.pixelsToGridCoordinates(blackboard.settler:get(ECS.c.position).vector)
    local itemInCurrentLocation = universe.getItemFromGround(blackboard.selector, gridPosition)
    local item = universe.takeItemFromGround(itemInCurrentLocation, blackboard.targetAmount)
    local itemAmount = item:get(ECS.c.amount).amount

    if itemAmount >= blackboard.targetAmount then
      blackboard.inventory:insertItem(item:get(ECS.c.id).id)
    else
      blackboard.targetAmount = blackboard.targetAmount - itemAmount
    end

    task:success()
  end
})

local getPathToTarget = BehaviourTree.Task:new({
  run = function(task, vars) -- vars: settler, target
    if not blackboard.currentTarget then
      task:fail()
      return
    end

    local path = universe.getPath(
    universe.pixelsToGridCoordinates(blackboard.settler:get(ECS.c.position).vector),
    universe.pixelsToGridCoordinates(blackboard.currentTarget:get(ECS.c.position).vector)
    )

    if not path then
      task:fail()
      return
    end

    --blackboard.currentPath = path
    settler:give(ECS.c.path, path)
    task:success()
  end
})

local popTargetFromItemStack = BehaviourTree.Task:new({
  run = function(task, blackboard)
    local potentialItem = table.remove(blackboard.potentialItems)
    if potentialItem then
      blackboard.currentTarget = potentialItem
      task:success()
    else
      task:fail()
    end
  end
})

local setDestinationAsCurrentTarget = BehaviourTree.Task:new({
  run = function(task, blackboard)
    blackboard.currentTarget = blackboard.destination
    task:success()
  end
})

-- local moveItemFromTo = BehaviourTree.Task:new({
--   start = function(task, vars) 
-- 
--   end,
--   run = function(task, vars) -- vars: settler, target
--     local fetch = job:get(ECS.c.fetchJob)
--     local selector = fetch.selector
--     local job = entityManager.get(settler:get(ECS.c.work).jobId)
--     local target = entityManager.get(job:get(ECS.c.fetchJob).targetId)
--     settler.searched_for_path = false
--     local inventory = settler:get(ECS.c.inventory)
--     local invItem = inventory:popItem(selector, amount)
--     local targetInventory = target:get(ECS.c.inventory)
--     targetInventory:insertItem(invItem:get(ECS.c.id).id)
--     print("Putting into the targetInventory, as in job finished")
--     -- JOB FINISHED!
--   end
-- })

function createTree(settler)
  local inventory = settler:get(ECS.c.inventory)
  local fetch = job:get(ECS.c.fetchJob)
  local selector = fetch.selector
  local job = entityManager.get(settler:get(ECS.c.work).jobId)
  local destination = entityManager.get(job:get(ECS.c.fetchJob).targetId)
  local tree = BehaviourTree:new({
    tree = BehaviourTree.Sequence:new({
      nodes = {
        hasItem,
        getItem,
        moveItemFromTo,
      }
    })
  })

  fetchTree:setObject({
    settler = settler,
    inventory = inventory,
    fetch = fetch,
    job = job,
    destination = destination
  })

  return fetchTree
end


--local moveItemFromTo = function(fromInventory, toInventory, item)
--  targetInventory:insertItem(invItem:get(ECS.c.id).id)
--end
