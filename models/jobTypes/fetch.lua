local itemUtils = require('utils.itemUtils')
local universe = require('models.universe')
local entityManager = require('models.entityManager')
local FetchBehaviour = require('models.ai.fetchBehaviour')

local function generate(targetId, itemData, selector)
  local subJob = ECS.Entity()
  :give(ECS.c.id, entityManager.generateId())
  subJob:give(ECS.c.job, "fetch")
  subJob:give(ECS.c.name, "FetchJob")
  subJob:give(ECS.c.item, itemData)
  subJob:give(ECS.c.selector, selector)
  --subJob:give(ECS.c.fetchJob, target, selector, itemData.requirements[selector])
  subJob:give(ECS.c.fetchJob, targetId, selector, itemData.requirements[selector])

  print("Generating fetch", subJob, targetId, itemData, selector)
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
--   local fetch = job:get(ECS.c.fetchJob)
--   local targetId = job:get(ECS.c.fetchJob).targetId
--   --print("TARGETID", targetId)
--   local target = entityManager.get(targetId)
--   if not target then
--     fetch:destroy()
--     return
--   end
-- 
--   local selector = fetch.selector
--   local gridPosition = universe.pixelsToGridCoordinates(settler:get(ECS.c.position).vector)
--   local itemData = job:get(ECS.c.item).itemData
--   local amount = fetch.amount
--   local inventory = settler:get(ECS.c.inventory)
--   --local existingItem = itemUtils.getInventoryItemBySelector(inventory, selector)
--   local existingItemId = inventory:findItem(selector)
--   local existingItem = entityManager.get(existingItemId)
--   -- If already have the item, then place item on ground at target site
--   if existingItem and existingItem:has(ECS.c.amount) and
--     existingItem:get(ECS.c.amount).amount >= fetch.amount then
--     print("Had item and enough of it")
-- 
--     local targetGridPosition = universe.pixelsToGridCoordinates(target:get(ECS.c.position).vector)
--     -- In correct location? Drop item, done! 
--     if universe.isInPosition(gridPosition, targetGridPosition, true) then
--       settler.searched_for_path = false
--       --local invItem = itemUtils.popInventoryItemBySelector(inventory, selector, amount) -- luacheck: ignore
--       local invItem = inventory:popItem(selector, amount)
--       local targetInventory = target:get(ECS.c.inventory)
--       targetInventory:insertItem(invItem:get(ECS.c.id).id)
--       print("Putting into the targetInventory, as in job finished")
--       --itemUtils.putItemIntoInventory(targetInventory, invItem, amount)
--       -- JOB FINISHED!
--       return true
--     else
--       -- Have item but not in location. Get new path to location!
--       print("Have item but not in location. Get new path to location!")
--       local path = universe.getPath(
--       universe.pixelsToGridCoordinates(settler:get(ECS.c.position).vector),
--       universe.pixelsToGridCoordinates(target:get(ECS.c.position).vector)
--       )
-- 
--       settler.searched_for_path = true
-- 
--       if path then
--         settler:give(ECS.c.path, path)
--       else
--         job:get(ECS.c.job).isInaccessible = true
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
--         local itemAmount = item:get(ECS.c.amount).amount
--         print("itemAmount", itemAmount)
--         if itemAmount >= amount then
--           print("DUUDIT")
--           settler.searched_for_path = false
--           settler:remove(ECS.c.path) -- TODO: Maybe not needed
--           local inventory = settler:get(ECS.c.inventory)
--           inventory:insertItem(item:get(ECS.c.id).id)
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
--         if itemOnMap:has(ECS.c.position) then
--           print("GETTING PATH 2")
--           local path = universe.getPath(
--           universe.pixelsToGridCoordinates(settler:get(ECS.c.position).vector),
--           universe.pixelsToGridCoordinates(itemOnMap:get(ECS.c.position).vector))
--           if path then
--             print("Had path for item, giving path to settler")
--             settler:give(ECS.c.path, path)
--           else
--             job:get(ECS.c.job).isInaccessible = true
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
