local itemUtils = require('utils.itemUtils')
local universe = require('models.universe')
local entityReferenceManager = require('models.entityReferenceManager')

local function generate(target, itemData, selector)
  local subJob = ECS.Entity()
  :give(ECS.Components.id, entityReferenceManager.generateId())
  subJob:give(ECS.Components.job, "fetch")
  -- , function()
  --   consumeRequirement(job, subJob)
  -- end)
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

local function handle(self, job, settler, dt, finishedCallBack) --luacheck: ignore
  local fetch = job:get(ECS.Components.fetchJob)
  local selector = fetch.selector
  local gridPosition = universe.pixelsToGridCoordinates(settler:get(ECS.Components.position).vector)
  local itemData = job:get(ECS.Components.item).itemData
  --local amount = itemData.requirements[selector]
  local amount = fetch.amount -- TODO: Use this or above?
  print("fetch amount?", amount)
  local inventoryComponent = settler:get(ECS.Components.inventory)
  local inventory = inventoryComponent.inventory
  local existingItem = itemUtils.getInventoryItemBySelector(inventory, selector)
  -- If already have the item, then place item on ground at target site
  if existingItem and existingItem:has(ECS.Components.amount) and
    existingItem:get(ECS.Components.amount).amount >= fetch.amount then
    print("Had item yeah")

    local targetGridPosition = universe.pixelsToGridCoordinates(fetch.target:get(ECS.Components.position).vector)
    print("Cor loc?", targetGridPosition.x, targetGridPosition.y, "vs current", gridPosition.x, gridPosition.y)
    -- In correct location? Drop item, done! 
    if universe.isInPosition(gridPosition, targetGridPosition, true) then
      settler.searched_for_path = false
      local invItem = itemUtils.popInventoryItemBySelector(inventory, selector, amount) -- luacheck: ignore
      itemUtils.placeItemOnGround(invItem, targetGridPosition)
      -- TODO: Should we ever emit from fetch?
      --job:get(ECS.Components.job).finished = true -- This gets done in the settler system
      print("FetchJob finished!")
      return true
      --   job:get(ECS.Components.job).finishedCallBack()
      --   finishedCallBack(self, settler, job)
    else
      print("Not in position so getting new path")
      -- Have item but not in location. Get new path to location!
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
    print("No item in inv so finding one")
    -- If we don't have item, find closest one and go fetch it
    local itemInCurrentLocation = itemUtils.getItemFromGround(selector, gridPosition)
    print("itemInCurrentLocation:", itemInCurrentLocation)
    local item
    local foundNeeded = false
    if itemInCurrentLocation then
      item = itemUtils.takeItemFromGround(itemInCurrentLocation, amount)

      if item then
        print("amounts", item:get(ECS.Components.amount).amount, "vs required: ", amount)
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
      local itemsOnMap = itemUtils.getItemsFromGroundBySelector(selector)
      if itemsOnMap and #itemsOnMap > 0 then
        print("Item is on map")
        -- TODO: Get closest item to settler, for now just pick first from list
        local itemOnMap = itemsOnMap[love.math.random(#itemsOnMap)]
        if itemOnMap:has(ECS.Components.position) then
          local path = universe.getPath(
          universe.pixelsToGridCoordinates(settler:get(ECS.Components.position).vector),
          universe.pixelsToGridCoordinates(itemOnMap:get(ECS.Components.position).vector))
          if path then
            print("Had path for item, giving path to settler")
            -- path.finishedCallBack = function()
            --   settler.searched_for_path = false
            --   settler:remove(ECS.Components.path)
            --   table.insert(inventory, itemOnMap)
            --   itemUtils.takeItemFromGround(itemOnMap, amount)
            -- end
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
