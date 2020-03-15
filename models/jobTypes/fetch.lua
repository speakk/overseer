local itemUtils = require('utils.itemUtils')
local universe = require('models.universe')
local entityManager = require('models.entityManager')
local FetchBehaviour = require('models.ai.fetchBehaviour')

local function generate(targetId, itemData, selector)
  local subJob = ECS.Entity()
  :give("id", entityManager.generateId())
  subJob:give("job", "fetch")
  subJob:give("name", "FetchJob")
  subJob:give("item", itemData)
  subJob:give("selector", selector)
  --subJob:give("fetchJob", target, selector, itemData.requirements[selector])
  subJob:give("fetchJob", targetId, selector, itemData.requirements[selector])

  return subJob
end

-- If already have path then we aren't even here.
--
--  If have item and enough of item:
--    If in correct location, drop it. Done!
--    Otherwise add path to final location
--  
--  Not have item:
--    If in location with item, pick item up
--    If not item, or not enough of item,
--    Otherwise add path to item

local function handle(self, job, settler, dt) --luacheck: ignore

end


-- local function handle(self, job, settler, dt) --luacheck: ignore
--   local fetch = job.fetchJob
--   local targetId = job.fetchJob.targetId
--   --print("TARGETID", targetId)
--   local target = entityManager.get(targetId)
--   if not target then
--     fetch:destroy()
--     return
--   end
-- 
--   local selector = fetch.selector
--   local gridPosition = universe.pixelsToGridCoordinates(settler.position.vector)
--   local itemData = job.item.itemData
--   local amount = fetch.amount
--   local inventory = settler.inventory
--   --local existingItem = itemUtils.getInventoryItemBySelector(inventory, selector)
--   local existingItemId = inventory:findItem(selector)
--   local existingItem = entityManager.get(existingItemId)
--   -- If already have the item, then place item on ground at target site
--   if existingItem and existingItem.amount and
--     existingItem.amount.amount >= fetch.amount then
--     print("Had item and enough of it")
-- 
--     local targetGridPosition = universe.pixelsToGridCoordinates(target.position.vector)
--     -- In correct location? Drop item, done! 
--     if universe.isInPosition(gridPosition, targetGridPosition, true) then
--       settler.searched_for_path = false
--       --local invItem = itemUtils.popInventoryItemBySelector(inventory, selector, amount) -- luacheck: ignore
--       local invItem = inventory:popItem(selector, amount)
--       local targetInventory = target.inventory
--       targetInventory:insertItem(invItem.id.id)
--       print("Putting into the targetInventory, as in job finished")
--       --itemUtils.putItemIntoInventory(targetInventory, invItem, amount)
--       -- JOB FINISHED!
--       return true
--     else
--       -- Have item but not in location. Get new path to location!
--       print("Have item but not in location. Get new path to location!")
--       local path = universe.getPath(
--       universe.pixelsToGridCoordinates(settler.position.vector),
--       universe.pixelsToGridCoordinates(target.position.vector)
--       )
-- 
--       settler.searched_for_path = true
-- 
--       if path then
--         settler:give("path", path)
--       else
--         job.job.isInaccessible = true
--       end
--     end
--   else
--     if settler.searched_for_path then return nil end
--     -- If we don't have item, find closest one and go fetch it
--     print("we don't have item, find closest one and go fetch it")
--     local itemInCurrentLocation = universe.getItemFromGround(selector, gridPosition)
--     local item
--     local foundNeeded = false
--     --settler.searched_for_path = true
--     if itemInCurrentLocation then
--       print("itemInCurrentLocation")
--       item = universe.takeItemFromGround(itemInCurrentLocation, amount)
--       print("took item from current location", item, "in amount", amount)
-- 
--       if item then
--         local itemAmount = item.amount.amount
--         print("itemAmount", itemAmount)
--         if itemAmount >= amount then
--           print("DUUDIT")
--           settler.searched_for_path = false
--           settler:remove("path") -- TODO: Maybe not needed
--           local inventory = settler.inventory
--           inventory:insertItem(item.id.id)
--           --table.insert(inventory, item)
--           foundNeeded = true
--         else
--           fetch.amount = fetch.amount - itemAmount
--         end
--       else
--         settler.searched_for_path = true
--       end
--     end
-- 
--     if not foundNeeded then
--       local itemsOnMap = universe.getItemsOnGround(selector)
--       --print("Trying to find from map:", #itemsOnMap)
--       if itemsOnMap and #itemsOnMap > 0 then
--         print("Item is on map")
--         -- TODO: Get closest item to settler, for now just pick first from list
--         local itemOnMap = itemsOnMap[love.math.random(#itemsOnMap)]
--         if itemOnMap.position then
--           print("GETTING PATH 2")
--           local path = universe.getPath(
--           universe.pixelsToGridCoordinates(settler.position.vector),
--           universe.pixelsToGridCoordinates(itemOnMap.position.vector))
--           if path then
--             print("Had path for item, giving path to settler")
--             settler:give("path", path)
--           else
--             job.job.isInaccessible = true
--           end
--         end
--       end
--     end
--   end
-- end

return {
  handle = handle,
  generate = generate
}
