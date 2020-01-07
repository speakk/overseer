local itemUtils = require('utils.itemUtils')
local universe = require('models.universe')
local entityReferenceManager = require('models.entityReferenceManager')

local function generate(target, itemData, selector)
  local subJob = ECS.Entity()
  :give(ECS.Components.id, entityReferenceManager.generateId())
  subJob:give(ECS.Components.job, "fetch")
  subJob:give(ECS.Components.name, "FetchJob")
  subJob:give(ECS.Components.item, itemData, selector)
  subJob:give(ECS.Components.fetchJob, target, selector, itemData.requirements[selector])

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
  local fetch = job:get(ECS.Components.fetchJob)
  local selector = fetch.selector
  local gridPosition = universe.pixelsToGridCoordinates(settler:get(ECS.Components.position).vector)
  local itemData = job:get(ECS.Components.item).itemData
  local amount = fetch.amount
  local inventoryComponent = settler:get(ECS.Components.inventory)
  local inventory = inventoryComponent.inventory
  local existingItem = itemUtils.getInventoryItemBySelector(inventory, selector)
  -- If already have the item, then place item on ground at target site
  if existingItem and existingItem:has(ECS.Components.amount) and
    existingItem:get(ECS.Components.amount).amount >= fetch.amount then

    local targetGridPosition = universe.pixelsToGridCoordinates(fetch.target:get(ECS.Components.position).vector)
    -- In correct location? Drop item, done! 
    if universe.isInPosition(gridPosition, targetGridPosition, true) then
      settler.searched_for_path = false
      local invItem = itemUtils.popInventoryItemBySelector(inventory, selector, amount) -- luacheck: ignore
      --itemUtils.placeItemOnGround(invItem, targetGridPosition)
      local targetInventory = fetch.target:get(ECS.Components.inventory).inventory
      itemUtils.putItemIntoInventory(targetInventory, invItem, amount)
      -- JOB FINISHED!
      return true
    else
      -- Have item but not in location. Get new path to location!
      print("GETTING PATH")
      local path = universe.getPath(
      universe.pixelsToGridCoordinates(settler:get(ECS.Components.position).vector),
      universe.pixelsToGridCoordinates(fetch.target:get(ECS.Components.position).vector)
      )

      settler.searched_for_path = true

      if path then
        settler:give(ECS.Components.path, path)
      else
        job:get(ECS.Components.job).isInaccessible = true
      end
    end
  else
    -- If we don't have item, find closest one and go fetch it
    local itemInCurrentLocation = universe.getItemFromGround(selector, gridPosition)
    local item
    local foundNeeded = false
    if itemInCurrentLocation then
      item = universe.takeItemFromGround(itemInCurrentLocation, amount)

      if item then
        local itemAmount = item:get(ECS.Components.amount).amount
        if itemAmount >= amount then
          print("DUUDIT")
          settler.searched_for_path = false
          settler:remove(ECS.Components.path) -- TODO: Maybe not needed
          table.insert(inventory, item)
          foundNeeded = true
        else
          fetch.amount = fetch.amount - itemAmount
        end
      end
    end

    if not foundNeeded then
      local itemsOnMap = universe.getItemsOnGround(selector)
      --print("Trying to find from map:", #itemsOnMap)
      if itemsOnMap and #itemsOnMap > 0 then
        print("Item is on map")
        -- TODO: Get closest item to settler, for now just pick first from list
        local itemOnMap = itemsOnMap[love.math.random(#itemsOnMap)]
        if itemOnMap:has(ECS.Components.position) then
          print("GETTING PATH 2")
          local path = universe.getPath(
          universe.pixelsToGridCoordinates(settler:get(ECS.Components.position).vector),
          universe.pixelsToGridCoordinates(itemOnMap:get(ECS.Components.position).vector))
          if path then
            print("Had path for item, giving path to settler")
            settler:give(ECS.Components.path, path)
          else
            job:get(ECS.Components.job).isInaccessible = true
          end
        end
      end
    end
  end
end

return {
  handle = handle,
  generate = generate
}
