local Class = require 'libs.hump.class'
local inspect = require('libs.inspect')
local lume = require('libs.lume')

local positionUtils = require('utils.position')
local ItemUtils = require('utils.itemUtils')
local entityFinder = require('models.entityFinder')
local entityRegistry = require('models.entityRegistry')
local Task = require('models.ai.task')

return Class {
  __includes = Task,
  init = function(self, actor, world)
    Task.init(self, actor, world)
  end,
  initializeTree = function(commonNodes, nodes)
    return {
      type = "sequence",
      children = {
        function() print("Sequence started for FETCH") return false, true end,
        {
          type = "selector*",
          children = {
            nodes.hasEnoughOfItem,
            {
              type = "sequence*",
              children = {
                nodes.getPotentialItemStack,
                {
                  type = "doUntil",
                  children = {
                    {
                      type = "sequence*",
                      children = {
                        nodes.popTargetFromItemStack,
                        {
                          type = "sequence*",
                          children = {
                            -- {
                            --   type = "negate",
                            --   children = {
                            --     nodes.hasEnoughOfItem
                            --   }
                            -- },
                            commonNodes.goto,
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
                commonNodes.goto
              }
            },
            nodes.insertItemIntoDestination
          }
        }
      }
    }
  end,
  initializeBlackboard = function(actor)
    print("Creating fetch tree")

    local job = entityRegistry.get(actor.work.jobId)
    local fetch = job.fetchJob
    local targetAmount = fetch.amount
    local selector = fetch.selector
    local destination = entityRegistry.get(job.fetchJob.targetId)

    return {
      selector = selector,
      fetch = fetch,
      targetAmount = targetAmount,
      job = job,
      destination = destination
    }
  end,
  initializeNodes = function(_, actor, _, blackboard)
    return {
      hasEnoughOfItem = function()
        print("fetch hasEnoughOfItem")
        if not actor.inventory then
          print("No inventory?", actor, inspect(actor, {depth=2}))
        end
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
          print("No potentialItemsStack in fact")
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
          print("No potentialItem in fact")
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
}
