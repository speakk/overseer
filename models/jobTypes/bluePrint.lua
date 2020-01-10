local Fetch = require('models.jobTypes.fetch')
local universe = require('models.universe')
local itemUtils = require('utils.itemUtils')
local entityReferenceManager = require('models.entityReferenceManager')

local function isBluePrintReadyToBuild(bluePrint)
  if bluePrint:get(ECS.Components.job).finished then return false end

  local bluePrintComponent = bluePrint:get(ECS.Components.bluePrintJob)
  local requirements = bluePrint:get(ECS.Components.item).itemData.requirements

  for selector, amount in pairs(requirements) do --luacheck: ignore
    local itemId = bluePrint:get(ECS.Components.inventory):findItem(selector)
    local item = entityReferenceManager.getEntity(itemId)
    --local itemInv = itemUtils.getInventoryItemBySelector(bluePrint:get(ECS.Components.inventory).inventory, selector)
    -- print("Blueprint pos", universe.pixelsToGridCoordinates(bluePrint:get(ECS.Components.position).vector))
    -- local itemInPosition = itemUtils.getItemFromGround(selector, universe.pixelsToGridCoordinates(bluePrint:get(ECS.Components.position).vector))
    if not item or item:get(ECS.Components.amount).amount < amount then
      --print("Didn't have no!", selector)
      return false
    end
  end

  return true
end

local function consumeRequirements(bluePrint)
  -- For now below is commented, items will just stay in bluePrint inventory
  -- local requirements = bluePrint:get(ECS.Components.item).itemData.requirements
  -- for selector, amount in pairs(requirements) do --luacheck: ignore
  --   local itemInPosition = itemUtils.getItemFromGround(selector, universe.pixelsToGridCoordinates(bluePrint:get(ECS.Components.position).vector))
  --   itemUtils.takeItemFromGround(itemInPosition, amount)
  -- end
end

local function handle(self, job, settler, dt, finishCallback)
  local bluePrintComponent = job:get(ECS.Components.bluePrintJob)
  local settlerGridPosition = universe.pixelsToGridCoordinates(settler:get(ECS.Components.position).vector)
  local bluePrintGridPosition = universe.pixelsToGridCoordinates(job:get(ECS.Components.position).vector)
  if universe.isInPosition(settlerGridPosition, bluePrintGridPosition, true) then
    if isBluePrintReadyToBuild(job) then
      local constructionSkill = settler:get(ECS.Components.settler).skills.construction
      bluePrintComponent.buildProgress = bluePrintComponent.buildProgress + (constructionSkill * bluePrintComponent.constructionSpeed) * dt
      if bluePrintComponent.buildProgress >= 100 then
        consumeRequirements(job)
        return true
        --finishWork(self, settler, job)
        --
        --job:get(ECS.Components.job).finishedCallBack()
        --finishCallback(self, settler, job)
      end
    end
  else
    settler.searched_for_path = false
    if not settler.searched_for_path then -- RIGHT ON THIS IF: Is global cache valid? If not then re-get path
      local path = universe.getPath(settlerGridPosition, bluePrintGridPosition)
      settler.searched_for_path = true
      if path then
        -- path.finishedCallBack = function()
        --   settler.searched_for_path = false
        -- end
        settler:give(ECS.Components.path, path)
      end
    end
  end
end

local function generate(gridPosition, itemData, bluePrintItemSelector)
  local job = ECS.Entity()
  job:give(ECS.Components.job, "bluePrint")
  job:give(ECS.Components.name, "BluePrintJob")
  :give(ECS.Components.id, entityReferenceManager.generateId())
  :give(ECS.Components.onMap)
  :give(ECS.Components.bluePrintJob, itemData.constructionSpeed or 1)
  :give(ECS.Components.inventory) -- Item consumed so far
  :give(ECS.Components.item, itemData, bluePrintItemSelector)
  :give(ECS.Components.position, universe.gridPositionToPixels(gridPosition))
  :give(ECS.Components.transparent)

  if itemData.components then
    for _, component in ipairs(itemData.components) do
      if not component.afterConstructed then
        job:give(ECS.Components[component.name], unpack(component.properties))
      end
    end
  end

  local children = {}

  if itemData.requirements then
    job:give(ECS.Components.children, {})
    local childrenIds = job:get(ECS.Components.children).children
    for selector, amount in pairs(itemData.requirements) do
      local subJob = Fetch.generate(job:get(ECS.Components.id).id, itemData, selector)
      subJob:give(ECS.Components.parent, job:get(ECS.Components.id).id)
      table.insert(children, subJob)
      table.insert(childrenIds, subJob:get(ECS.Components.id).id)
    end
  end

  return job, children
end

local function finish(job)
    job:give(ECS.Components.collision)
    job:remove(ECS.Components.transparent)

    local itemData = job:get(ECS.Components.item).itemData

    if itemData.components then
      for _, component in ipairs(itemData.components) do
        if component.afterConstructed then
          job:give(ECS.Components[component.name], unpack(component.properties))
        end
      end
    end
end

return {
  handle = handle,
  generate = generate,
  finish = finish
}
