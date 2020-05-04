local lume = require('libs.lume')
local luabt = require('libs.luabt')

local positionUtils = require('utils.position')
local ItemUtils = require('utils.itemUtils')
local entityFinder = require('models.entityFinder')
local entityRegistry = require('models.entityRegistry')
local GotoAction = require('models.ai.sharedActions.goto')
local AtTarget = require('models.ai.sharedActions.atTarget')

local getNodes = function(actor, blackboard)
  return {
    hasEnoughOfItem = function()
      print("fetch hasEnoughOfItem")
      local invItemId = actor.inventory:findItem(blackboard.selector)
      if invItemId then
        local invItem = entityRegistry.get(invItemId)
        if invItem and invItem.amount.amount >= blackboard.targetAmount then
          return false, true
        end
      end

      return false, false
    end,
    getPotentialItemStack = function()
      print("fetch getPotentialItemStack", blackboard.selector)
      --local itemsOnMap = entityFinder.getItemsOnGround(blackboard.selector, { "item" })
      local itemsOnMap = entityFinder.getEntities('selector', blackboard.selector, { "item" })
      print("Found many items:", #itemsOnMap)

      if not itemsOnMap or #itemsOnMap == 0 then
        print("NO ITEMSONMAP JESUS CHRIST")
        return false, false
      end

      blackboard.potentialItemsStack = lume.filter(itemsOnMap, function(item)
        if not item.reserved then return true end
        local reservedComponent = item.reserved
        --print("Status of reserved", item.amount.amount, reservedComponent.amount, blackboard.targetAmount)
        return item.amount.amount - reservedComponent.amount > blackboard.targetAmount
        --return not item.reserved
      end)
      print("potentialItemsStack ends up being size:", #blackboard.potentialItemsStack)
      return false, true
    end,
    insertItemIntoDestination = function()
      print("fetch insertItemIntoDestination")
      local invItem = actor.inventory:popItem(blackboard.selector, blackboard.targetAmount)

      if not invItem then
        --print("Something went wrong, do not have item upon arriving at destination")
        return false, false
      end

      local targetInventory = blackboard.target.inventory
      targetInventory:insertItem(invItem.id.id)
      print("Fetch finished!", blackboard.job, blackboard.job.id.id)
      -- blackboard.world:emit("treeFinished", actor, blackboard.jobType)
      -- blackboard.world:emit("finishWork", actor, blackboard.job.id.id)
      -- blackboard.world:emit("jobFinished", blackboard.job)
      blackboard.finished = true
      return false, true
    end,
    pickItemAmountUp = function()
      print("fetch pickItemAmountUp")
      local gridPosition = positionUtils.pixelsToGridCoordinates(actor.position.vector)

      local itemsInCurrentLocation = entityFinder.filterBySelector(
      entityFinder.getByList(
      functional.map(positionUtils.getCoordinatesAround(gridPosition.x, gridPosition.y, 1), function(coord) return {
        key = "position",
        value = entityFinder.getGridPositionString(coord)
      } end),
      { 'item' }
      ),
      blackboard.selector
      )
      print("itemInCurrentLocation", blackboard.selector, itemsInCurrentLocation)
      if not itemsInCurrentLocation or #itemsInCurrentLocation == 0 then
        print("Failing, not itemsInCurrentLocation")
        return false, false
      end

      local itemInCurrentLocation = itemsInCurrentLocation[1]

      local item = ItemUtils.takeItemFromGround(itemInCurrentLocation, blackboard.targetAmount)
      local itemAmount = item.amount.amount

      if itemAmount >= blackboard.targetAmount then
        actor.inventory:insertItem(item.id.id)
      else
        blackboard.targetAmount = blackboard.targetAmount - itemAmount
      end

      --print("Added item to inventory")
      return false, true
    end,
    clearCurrentTarget = function()
      print("fetch clearCurrentTarget")
      blackboard.target = nil
      return false, true
    end,
    popTargetFromItemStack = function()
      print("fetch popTargetFromItemStack")
      if not blackboard.potentialItemsStack or #blackboard.potentialItemsStack <= 0 then
        --print("No potentialItemsStack in fact")
        return false, false
      end

      local potentialItem = table.remove(blackboard.potentialItemsStack)
      if potentialItem then
        if potentialItem.reserved then
          local reservedComponent = potentialItem.reserved
          if potentialItem.amount.amount - reservedComponent.amount < blackboard.targetAmount then
            return false, false
          else
            print("Adding to reservedAmount", blackboard.targetAmount)
            reservedComponent.amount = reservedComponent.amount + blackboard.targetAmount
          end
        else
          print("Giving reservedComponent", blackboard.targetAmount)
          potentialItem:give("reserved", actor.id.id, blackboard.targetAmount)
        end
        --print("potentialItem", potentialItem, potentialItem.item.selector)
        --print("potentialItem position", positionUtils.pixelsToGridCoordinates(potentialItem.position.vector))
        print("Setting target for fetch as", potentialItem, potentialItem.position)
        blackboard.target = potentialItem
        --print("popTargetFromItemStack success")
        return false, true
      else
        --print("No potentialItem in fact")
        return false, false
      end
    end,
    setDestinationAsCurrentTarget = function()
      print("fetch setDestinationAsCurrentTarget")
      blackboard.target = blackboard.destination
      return false, true
    end
  }
end

local function createTree(actor, world, jobType)
  -- LEAF NODES
  print("Creating fetch tree")

  local job = entityRegistry.get(actor.work.jobId)
  local fetch = job.fetchJob
  local targetAmount = fetch.amount
  local selector = fetch.selector
  local destination = entityRegistry.get(job.fetchJob.targetId)

  local blackboard = {
    actor = actor,
    selector = selector,
    fetch = fetch,
    targetAmount = targetAmount,
    job = job,
    destination = destination,
    world = world,
    jobType = jobType
  }

  local commonNodes = {
    gotoAction = GotoAction(blackboard),
    atTarget = AtTarget(blackboard)
  }

  local nodes = getNodes(actor, blackboard)

  local tree = {
    type = "sequence",
    children = {
      function() print("Sequence started for FETCH") end,
      {
        type = "selector*",
        children = {
          nodes.hasEnoughOfItem,
          {
            type = "sequence*",
            children = {
              nodes.getPotentialItemStack,
              {
                type = "until",
                children = {
                  {
                    type = "sequence*",
                    children = {
                      nodes.popTargetFromItemStack,
                      {
                        type = "sequence*",
                        children = {
                          {
                            type = "negate",
                            children = {
                              nodes.hasEnoughOfItem
                            }
                          },
                          {
                            type = "selector*",
                            children = {
                              commonNodes.atTarget,
                              commonNodes.gotoAction
                            }
                          },
                          nodes.pickItemAmountUp,
                          nodes.clearCurrentTarget
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      },
      -- Fetch sequence finished, so now
      -- bring item to destination
      {
        type = "sequence*",
        children = {
          nodes.setDestinationAsCurrentTarget,
          {
            type = "selector*",
            children = {
              commonNodes.atTarget,
              commonNodes.gotoAction
            }
          },
          nodes.insertItemIntoDestination
        }
      }
    }
  }

  local bt = luabt.create(tree)

  return function(treeDt)
    blackboard.treeDt = treeDt
    return bt()
  end

  -- local tree = BehaviourTree:new({
  --   tree = BehaviourTree.Sequence:new({
  --     nodes = {
  --       -- Priority: If has enough item, then return
  --       -- else start fetch sequence.
  --       -- If fetch sequence returns, then we have item
  --       BehaviourTree.Priority:new({
  --         nodes = {
  --           hasEnoughOfItem,
  --           BehaviourTree.Sequence:new({
  --             nodes = {
  --               getPotentialItemStack,
  --               UntilDecorator:new({
  --                 node =
  --                 BehaviourTree.Sequence:new({
  --                   nodes = {
  --                     popTargetFromItemStack,
  --                     BehaviourTree.Sequence:new({
  --                       nodes = {
  --                         BehaviourTree.InvertDecorator:new({
  --                           node = hasEnoughOfItem
  --                         }),
  --                         BehaviourTree.Priority:new({
  --                           nodes = {
  --                             atTarget,
  --                             gotoAction
  --                           }
  --                         }),
  --                         pickItemAmountUp,
  --                         clearCurrentTarget
  --                       }
  --                     })
  --                   }
  --                 })
  --               })
  --             }
  --           })
  --         }
  --       }),
  --       -- Fetch sequence finished, so now
  --       -- bring item to destination
  --       BehaviourTree.Sequence:new({
  --         nodes = {
  --           setDestinationAsCurrentTarget,
  --           BehaviourTree.Priority:new({
  --             nodes = {
  --               atTarget,
  --               gotoAction
  --             }
  --           }),
  --           insertItemIntoDestination
  --         }
  --       })
  --     }
  --   })
  -- })

end

return {
  createTree = createTree
}
