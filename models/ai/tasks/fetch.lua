local BehaviourTree = require('libs.behaviourtree')
local lume = require('libs.lume')

local positionUtils = require('utils.position')
local ItemUtils = require('utils.itemUtils')
local entityFinder = require('models.entityFinder')
local entityRegistry = require('models.entityRegistry')
local UntilDecorator = require('models.ai.decorators.until')
local GotoAction = require('models.ai.sharedActions.goto')
local AtTarget = require('models.ai.sharedActions.atTarget')

local function createTree(actor, world, jobType)
  -- LEAF NODES
  --
  local hasEnoughOfItem = BehaviourTree.Task:new({
    run = function(task, blackboard)
      print("fetch hasEnoughOfItem")
      local invItemId = blackboard.inventory:findItem(blackboard.selector)
      if invItemId then
        local invItem = entityRegistry.get(invItemId)
        if invItem and invItem.amount.amount >= blackboard.targetAmount then
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
      --local itemsOnMap = entityFinder.getItemsOnGround(blackboard.selector, { "item" })
      local itemsOnMap = entityFinder.getEntities('selector', blackboard.selector, { "item" })
      print("Found many items:", #itemsOnMap)

      if not itemsOnMap or #itemsOnMap == 0 then
        print("NO ITEMSONMAP JESUS CHRIST")
        task:fail()
        return
      end

      blackboard.potentialItemsStack = lume.filter(itemsOnMap, function(item)
        if not item.reserved then return true end
        local reservedComponent = item.reserved
        --print("Status of reserved", item.amount.amount, reservedComponent.amount, blackboard.targetAmount)
        return item.amount.amount - reservedComponent.amount > blackboard.targetAmount
        --return not item.reserved
      end)
      print("potentialItemsStack ends up being size:", #blackboard.potentialItemsStack)
      task:success()
    end
  })

  local insertItemIntoDestination = BehaviourTree.Task:new({
    run = function(task, blackboard)
      print("fetch insertItemIntoDestination")
      local invItem = blackboard.inventory:popItem(blackboard.selector, blackboard.targetAmount)

      if not invItem then
        --print("Something went wrong, do not have item upon arriving at destination")
        return task:fail()
      end

      local targetInventory = blackboard.target.inventory
      targetInventory:insertItem(invItem.id.id)
      print("Fetch finished!", blackboard.job, blackboard.job.id.id)
      -- blackboard.world:emit("treeFinished", blackboard.actor, blackboard.jobType)
      -- blackboard.world:emit("finishWork", blackboard.actor, blackboard.job.id.id)
      -- blackboard.world:emit("jobFinished", blackboard.job)
      blackboard.finished = true
      return task:success()
    end
  })

  local pickItemAmountUp = BehaviourTree.Task:new({
    run = function(task, blackboard)
      print("fetch pickItemAmountUp")
      local gridPosition = positionUtils.pixelsToGridCoordinates(blackboard.actor.position.vector)
      --print("gridPosition", gridPosition)
      --local itemInCurrentLocation = entityFinder.getItemFromGround(blackboard.selector, gridPosition, { "item" })
      local itemInCurrentLocation = entityFinder.getByQueryObject(
        entityFinder.queryBuilders.positionListAndSelector(positionUtils.getCoordinatesAround(gridPosition.x, gridPosition.y, 1), blackboard.selector),
        { 'item' })
      print("itemInCurrentLocation", blackboard.selector, itemInCurrentLocation)
      if not itemInCurrentLocation or #itemInCurrentLocation == 0 then
        print("Failing, not itemInCurrentLocation")
        task:fail()
        return
      end

      local itemInCurrentLocation = itemInCurrentLocation[1]

      local item = ItemUtils.takeItemFromGround(itemInCurrentLocation, blackboard.targetAmount)
      local itemAmount = item.amount.amount

      if itemAmount >= blackboard.targetAmount then
        blackboard.inventory:insertItem(item.id.id)
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
        if potentialItem.reserved then
          local reservedComponent = potentialItem.reserved
          if potentialItem.amount.amount - reservedComponent.amount < blackboard.targetAmount then
            task:fail()
            return
          else
            print("Adding to reservedAmount", blackboard.targetAmount)
            reservedComponent.amount = reservedComponent.amount + blackboard.targetAmount
          end
        else
          print("Giving reservedComponent", blackboard.targetAmount)
          potentialItem:give("reserved", blackboard.actor.id.id, blackboard.targetAmount)
        end
        --print("potentialItem", potentialItem, potentialItem.item.selector)
        --print("potentialItem position", positionUtils.pixelsToGridCoordinates(potentialItem.position.vector))
        print("Setting target for fetch as", potentialItem, potentialItem.position)
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
  local inventory = actor.inventory
  local job = entityRegistry.get(actor.work.jobId)
  local fetch = job.fetchJob
  local targetAmount = fetch.amount
  local selector = fetch.selector
  local destination = entityRegistry.get(job.fetchJob.targetId)
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
    destination = destination,
    world = world,
    jobType = jobType
  })

  return tree
end

return {
  createTree = createTree
}
