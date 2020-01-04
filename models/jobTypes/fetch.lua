local itemUtils = require('utils.itemUtils')
local universe = require('models.universe')
local entityReferenceManager = require('models.entityReferenceManager')

local function handle(self, job, settler, dt, finishedCallBack) --luacheck: ignore
  local fetch = job:get(ECS.Components.fetchJob)
  local selector = fetch.selector
  local itemData = job:get(ECS.Components.item).itemData
  local amount = itemData.requirements[selector]
  --local amount = fetch.amount -- TODO: Use this or above?
  local inventoryComponent = settler:get(ECS.Components.inventory)
  local inventory = inventoryComponent.inventory
  --settler.searched_for_path = false
  if not settler.searched_for_path and not settler:has(ECS.Components.path) then
    print("Hadn't searched so...")
    local existingItem = itemUtils.getInventoryItemBySelector(inventory, selector)
    -- If already have the item, then place item on ground at target site
    if existingItem and existingItem:has(ECS.Components.amount) and
      existingItem:get(ECS.Components.amount).amount >= fetch.amount then
      local path = universe.getPath(
      universe.pixelsToGridCoordinates(settler:get(ECS.Components.position).vector),
      universe.pixelsToGridCoordinates(fetch.target:get(ECS.Components.position).vector)
      )

      settler.searched_for_path = true

      if path then
        -- print("Have item, found path, giving path component")

        -- path.finishedCallBack = function()
        --   settler.searched_for_path = false
        --   local invItem = itemUtils.popInventoryItemBySelector(inventory, selector, amount) -- luacheck: ignore
        --   job:get(ECS.Components.job).finishedCallBack()
        --   finishedCallBack(self, settler, job)
        -- end
        settler:give(ECS.Components.path, path)
      else
        job:get(ECS.Components.job).isInaccessible = true
      end
    else
      print("No item in inv so finding one")
      -- If we don't have item, find closest one and go fetch it
      -- If item in current location, pick it up
      local gridPosition = universe.pixelsToGridCoordinates(settler:get(ECS.Components.position).vector)
      local itemInCurrentLocation = itemUtils.getItemFromGround(selector, gridPosition)
      print("itemInCurrentLocation:", itemInCurrentLocation)
      local item
      local foundNeeded = false
      if itemInCurrentLocation then
        item = itemUtils.takeItemFromGround(itemInCurrentLocation, amount)

        if item then
          if item:get(ECS.Components.amount).amount >= amount then
            settler.searched_for_path = false
            settler:remove(ECS.Components.path) -- TODO: Maybe not needed
            table.insert(inventory, itemOnMap)
            foundNeeded = true
          else
            fetch.amount = fetch.amount - item.amount
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
end

return {
  handle = handle
}
