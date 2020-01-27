local BehaviourTree = require('libs.behaviourtree')
local lume = require('libs.lume')

local universe = require('models.universe')
local entityManager = require('models.entityManager')
local UntilDecorator = require('models.ai.decorators.until')

-- LEAF NODES

local hasEnoughOfItem = BehaviourTree.Task:new({
  run = function(task, blackboard)
    print("hasEnoughOfItem")
    local invItem = blackboard.inventory:findItem(blackboard.selector)
    print("selector", blackboard.selector)
    if invItem and invItem:get(ECS.c.amount).amount >= blackboard.targetAmount then
      task:success()
    else
      task:fail()
    end
  end
})

local getPotentialItemStack = BehaviourTree.Task:new({
  run = function(task, blackboard)
    print("getPotentialItemStack", blackboard.selector)
    local itemsOnMap = universe.getItemsOnGround(blackboard.selector)

    if not itemsOnMap or #itemsOnMap == 0 then
      task:fail()
      return
    end

    blackboard.potentialItemsStack = lume.extend({}, itemsOnMap)
    task:success()
  end
})

local insertItemIntoDestination = BehaviourTree.Task:new({
  run = function(task, blackboard)
    print("insertItemIntoDestination")
    local invItem = blackboard.inventory:popItem(blackboard.selector, blackboard.targetAmount)
    local targetInventory = blackboard.currentTarget:get(ECS.c.inventory)
    targetInventory:insertItem(invItem:get(ECS.c.id).id)
    task:success()
    blackboard.world:emit("treeFinished", blackboard.settler, blackboard.jobType)
    print("Putting into the targetInventory, as in job finished")
  end
})

local pickItemAmountUp = BehaviourTree.Task:new({
  run = function(task, blackboard)
    print("pickItemAmountUp")
    local gridPosition = universe.pixelsToGridCoordinates(blackboard.settler:get(ECS.c.position).vector)
    print("gridPosition", gridPosition)
    local itemInCurrentLocation = universe.getItemFromGround(blackboard.selector, gridPosition)
    print("itemInCurrentLocation", blackboard.selector, itemInCurrentLocation)
    if not itemInCurrentLocation then
      print("Failing, not itemInCurrentLocation")
      task:fail()
      return
    end

    local item = universe.takeItemFromGround(itemInCurrentLocation, blackboard.targetAmount)
    local itemAmount = item:get(ECS.c.amount).amount

    if itemAmount >= blackboard.targetAmount then
      blackboard.inventory:insertItem(item:get(ECS.c.id).id)
    else
      blackboard.targetAmount = blackboard.targetAmount - itemAmount
    end

    print("Added item to inventory")
    task:success()
  end
})

local areWeAtTarget = BehaviourTree.Task:new({
  run = function(task, blackboard)
    print("areWeAtTarget")
    local gridPosition = universe.pixelsToGridCoordinates(blackboard.settler:get(ECS.c.position).vector)
    local targetPosition = universe.pixelsToGridCoordinates(blackboard.currentTarget:get(ECS.c.position).vector)

    if universe.isInPosition(gridPosition, targetPosition, true) then
      print("areWeAtTarget true")
      task:success()
    else
      print("areWeAtTarget false")
      task:fail()
    end
  end
})

local clearCurrentTarget = BehaviourTree.Task:new({
  run = function(task, blackboard)
    print("clearCurrentTarget")
    blackboard.currentTarget = nil
    task:success()
  end
})

-- TODO: Check for current path for settler??
local getPathToTarget = BehaviourTree.Task:new({
  run = function(task, blackboard)
    print("getPathToTarget")
    if not blackboard.currentTarget then
      print("getPathToTarget fail#1")
      task:fail()
      return
    end

    if blackboard.settler:has(ECS.c.path) then
      if blackboard.settler:get(ECS.c.path).finished then
        print("Path finished, success")
        blackboard.settler:remove(ECS.c.path)
        task:success()
        return
      else
        print("getPathToTarget has path already")
        task:running()
        return
      end
    end

    print("What is our current target eh?")
    print(blackboard.currentTarget)

    local path = universe.getPath(
    universe.pixelsToGridCoordinates(blackboard.settler:get(ECS.c.position).vector),
    universe.pixelsToGridCoordinates(blackboard.currentTarget:get(ECS.c.position).vector)
    )

    if not path then
      print("No path, failing")
      task:fail()
      return
    end

    print("giving path to settler")
    print("from:", universe.pixelsToGridCoordinates(blackboard.settler:get(ECS.c.position).vector))
    print("to:", universe.pixelsToGridCoordinates(blackboard.currentTarget:get(ECS.c.position).vector))
    --blackboard.currentPath = path
    blackboard.settler:give(ECS.c.path, path)
    task:running()
    --task:success()
  end
})

local popTargetFromItemStack = BehaviourTree.Task:new({
  run = function(task, blackboard)
    print("popTargetFromItemStack")
    if not blackboard.potentialItemsStack or #blackboard.potentialItemsStack <= 0 then
      task:fail()
      print("popTargetFromItemStack fail#1")
      return
    end

    local potentialItem = table.remove(blackboard.potentialItemsStack)
    if potentialItem then
      print("potentialItem", potentialItem, potentialItem:get(ECS.c.item).selector)
      print("potentialItem position", universe.pixelsToGridCoordinates(potentialItem:get(ECS.c.position).vector))
      blackboard.currentTarget = potentialItem
      print("popTargetFromItemStack success")
      task:success()
    else
      print("popTargetFromItemStack fail#2")
      task:fail()
    end
  end
})

local setDestinationAsCurrentTarget = BehaviourTree.Task:new({
  run = function(task, blackboard)
    print("setDestinationAsCurrentTarget")
    blackboard.currentTarget = blackboard.destination
    task:success()
  end
})

function createTree(settler, world, jobType)
  local inventory = settler:get(ECS.c.inventory)
  local job = entityManager.get(settler:get(ECS.c.work).jobId)
  local fetch = job:get(ECS.c.fetchJob)
  local targetAmount = fetch.amount
  local selector = fetch.selector
  local destination = entityManager.get(job:get(ECS.c.fetchJob).targetId)
  local tree = BehaviourTree:new({
    tree = BehaviourTree.Sequence:new({
      nodes = {
        BehaviourTree.Priority:new({
          nodes = {
            hasEnoughOfItem,
            BehaviourTree.Sequence:new({
              nodes = {
                getPotentialItemStack,
                UntilDecorator:new({
                  node = 
                    BehaviourTree.Sequence:new({
                      nodes = {
                        popTargetFromItemStack,
                        BehaviourTree.Sequence:new({
                          nodes = {
                            BehaviourTree.InvertDecorator:new({
                              node = hasEnoughOfItem
                            }),
                            BehaviourTree.Priority:new({
                              nodes = {
                                areWeAtTarget,
                                getPathToTarget, -- TODO: Add a "now there?" leaf after this
                              }
                            }),
                            pickItemAmountUp,
                            clearCurrentTarget
                          }
                        })
                      }
                    })
                })
              }
            })
          }
        }),
        BehaviourTree.Sequence:new({
          nodes = {
            setDestinationAsCurrentTarget,
            BehaviourTree.Priority:new({
              nodes = {
                areWeAtTarget,
                getPathToTarget,
              }
            }),
            insertItemIntoDestination
          }
        })
      }
    })
  })

  tree:setObject({
    settler = settler,
    inventory = inventory,
    selector = selector,
    fetch = fetch,
    targetAmount = targetAmount,
    job = job,
    destination = destination,
    world = world,
    jobType = jobType
  })

  return tree
end

return {
  createTree = createTree
}
