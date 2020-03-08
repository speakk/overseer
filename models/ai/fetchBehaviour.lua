local BehaviourTree = require('libs.behaviourtree')
local lume = require('libs.lume')
local Vector = require('libs.brinevector')

local universe = require('models.universe')
local entityManager = require('models.entityManager')
local UntilDecorator = require('models.ai.decorators.until')
local GotoAction = require('models.ai.sharedActions.goto')
local AtTarget = require('models.ai.sharedActions.atTarget')

function createTree(actor, world, jobType)
  -- LEAF NODES
  --
  local hasEnoughOfItem = BehaviourTree.Task:new({
    run = function(task, blackboard)
      print("fetch hasEnoughOfItem")
      local invItemId = blackboard.inventory:findItem(blackboard.selector)
      if invItemId then
        local invItem = entityManager.get(invItemId)
        if invItem and invItem:get(ECS.c.amount).amount >= blackboard.targetAmount then
          task:success()
          return
        end
      end

      task:fail()
    end
  })

  local getPotentialItemStack = BehaviourTree.Task:new({
    run = function(task, blackboard)
      print("fetch getPotentialItemStack", blackboard.selector)
      local itemsOnMap = universe.getItemsOnGround(blackboard.selector, { "item" })

      if not itemsOnMap or #itemsOnMap == 0 then
        print("NO ITEMSONMAP JESUS CHRIST")
        task:fail()
        return
      end

      blackboard.potentialItemsStack = lume.filter(itemsOnMap, function(item)
        if not item:has(ECS.c.reserved) then return true end
        local reservedComponent = item:get(ECS.c.reserved)
        --print("Status of reserved", item:get(ECS.c.amount).amount, reservedComponent.amount, blackboard.targetAmount)
        return item:get(ECS.c.amount).amount - reservedComponent.amount > blackboard.targetAmount
        --return not item:has(ECS.c.reserved)
      end)
      task:success()
    end
  })

  local insertItemIntoDestination = BehaviourTree.Task:new({
    run = function(task, blackboard)
      print("fetch insertItemIntoDestination")
      local invItem = blackboard.inventory:popItem(blackboard.selector, blackboard.targetAmount)

      if not invItem then
        --print("Something went wrong, do not have item upon arriving at destination")
        task:fail()
        return
      end

      local targetInventory = blackboard.target:get(ECS.c.inventory)
      targetInventory:insertItem(invItem:get(ECS.c.id).id)
      print("Fetch finished!", blackboard.job, blackboard.job:get(ECS.c.id).id)
      blackboard.world:emit("treeFinished", blackboard.actor, blackboard.jobType)
      blackboard.world:emit("finishWork", blackboard.actor, blackboard.job:get(ECS.c.id).id)
      blackboard.world:emit("jobFinished", blackboard.job)
      blackboard.finished = true
      task:success()
    end
  })

  local pickItemAmountUp = BehaviourTree.Task:new({
    run = function(task, blackboard)
      print("fetch pickItemAmountUp")
      local gridPosition = universe.pixelsToGridCoordinates(blackboard.actor:get(ECS.c.position).vector)
      --print("gridPosition", gridPosition)
      local itemInCurrentLocation = universe.getItemFromGround(blackboard.selector, gridPosition, { "item" })
      --print("itemInCurrentLocation", blackboard.selector, itemInCurrentLocation)
      if not itemInCurrentLocation then
        --print("Failing, not itemInCurrentLocation")
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

      --print("Added item to inventory")
      task:success()
    end
  })

  local clearCurrentTarget = BehaviourTree.Task:new({
    run = function(task, blackboard)
      print("fetch clearCurrentTarget")
      blackboard.target = nil
      task:success()
    end
  })

  local popTargetFromItemStack = BehaviourTree.Task:new({
    run = function(task, blackboard)
      print("fetch popTargetFromItemStack")
      if not blackboard.potentialItemsStack or #blackboard.potentialItemsStack <= 0 then
        --print("No potentialItemsStack in fact")
        task:fail()
        return
      end

      local potentialItem = table.remove(blackboard.potentialItemsStack)
      if potentialItem then
        if potentialItem:has(ECS.c.reserved) then
          local reservedComponent = potentialItem:get(ECS.c.reserved)
          if potentialItem:get(ECS.c.amount).amount - reservedComponent.amount < blackboard.targetAmount then
            --print("Failing 'cause not enough nonreserved?", potentialItem:get(ECS.c.amount).amount, reservedComponent.amount, blackboard.targetAmount)
            task:fail()
            return
          else
            --print("Adding to reservedAmount", blackboard.targetAmount)
            reservedComponent.amount = reservedComponent.amount + blackboard.targetAmount
          end
        else
          --print("Giving reservedComponent", blackboard.targetAmount)
          potentialItem:give(ECS.c.reserved, blackboard.actor:get(ECS.c.id).id, blackboard.targetAmount)
        end
        --print("potentialItem", potentialItem, potentialItem:get(ECS.c.item).selector)
        --print("potentialItem position", universe.pixelsToGridCoordinates(potentialItem:get(ECS.c.position).vector))
        blackboard.target = potentialItem
        --print("popTargetFromItemStack success")
        task:success()
      else
        --print("No potentialItem in fact")
        task:fail()
      end
    end
  })

  local setDestinationAsCurrentTarget = BehaviourTree.Task:new({
    run = function(task, blackboard)
      print("fetch setDestinationAsCurrentTarget")
      blackboard.target = blackboard.destination
      task:success()
    end
  })
  local gotoAction = GotoAction()
  local atTarget = AtTarget()
  local inventory = actor:get(ECS.c.inventory)
  local job = entityManager.get(actor:get(ECS.c.work).jobId)
  local fetch = job:get(ECS.c.fetchJob)
  local targetAmount = fetch.amount
  local selector = fetch.selector
  local destination = entityManager.get(job:get(ECS.c.fetchJob).targetId)
  local tree = BehaviourTree:new({
    tree = BehaviourTree.Sequence:new({
      nodes = {
        -- Priority: If has enough item, then return
        -- else start fetch sequence.
        -- If fetch sequence returns, then we have item
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
                              atTarget,
                              gotoAction
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
        -- Fetch sequence finished, so now
        -- bring item to destination
        BehaviourTree.Sequence:new({
          nodes = {
            setDestinationAsCurrentTarget,
            BehaviourTree.Priority:new({
              nodes = {
                atTarget,
                gotoAction
              }
            }),
            insertItemIntoDestination
          }
        })
      }
    })
  })

  tree:setObject({
    actor = actor,
    inventory = inventory,
    selector = selector,
    fetch = fetch,
    targetAmount = targetAmount,
    job = job,
    target = target,
    destination = destination,
    world = world,
    jobType = jobType
  })

  return tree
end

return {
  createTree = createTree
}
