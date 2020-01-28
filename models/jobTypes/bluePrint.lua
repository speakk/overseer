local Fetch = require('models.jobTypes.fetch')
local universe = require('models.universe')
local itemUtils = require('utils.itemUtils')
local entityManager = require('models.entityManager')

local function isBluePrintReadyToBuild(bluePrint)
  if bluePrint:get(ECS.c.job).finished then return false end

  local bluePrintComponent = bluePrint:get(ECS.c.bluePrintJob)
  local requirements = bluePrint:get(ECS.c.item).itemData.requirements

  for selector, amount in pairs(requirements) do --luacheck: ignore
    local itemId = bluePrint:get(ECS.c.inventory):findItem(selector)
    local item = entityManager.get(itemId)
    --local itemInv = itemUtils.getInventoryItemBySelector(bluePrint:get(ECS.c.inventory).inventory, selector)
    -- print("Blueprint pos", universe.pixelsToGridCoordinates(bluePrint:get(ECS.c.position).vector))
    -- local itemInPosition = itemUtils.getItemFromGround(selector, universe.pixelsToGridCoordinates(bluePrint:get(ECS.c.position).vector))
    if not item or item:get(ECS.c.amount).amount < amount then
      --print("Didn't have no!", selector)
      return false
    end
  end

  return true
end

local function consumeRequirements(bluePrint)
  -- For now below is commented, items will just stay in bluePrint inventory
  -- local requirements = bluePrint:get(ECS.c.item).itemData.requirements
  -- for selector, amount in pairs(requirements) do --luacheck: ignore
  --   local itemInPosition = itemUtils.getItemFromGround(selector, universe.pixelsToGridCoordinates(bluePrint:get(ECS.c.position).vector))
  --   itemUtils.takeItemFromGround(itemInPosition, amount)
  -- end
end

local function handle(self, job, settler, dt, finishCallback)
  local bluePrintComponent = job:get(ECS.c.bluePrintJob)
  local settlerGridPosition = universe.pixelsToGridCoordinates(settler:get(ECS.c.position).vector)
  local bluePrintGridPosition = universe.pixelsToGridCoordinates(job:get(ECS.c.position).vector)
  if universe.isInPosition(settlerGridPosition, bluePrintGridPosition, true) then
    if isBluePrintReadyToBuild(job) then
      local constructionSkill = settler:get(ECS.c.settler).skills.construction
      bluePrintComponent.buildProgress = bluePrintComponent.buildProgress + (constructionSkill * bluePrintComponent.constructionSpeed) * dt
      if bluePrintComponent.buildProgress >= 100 then
        consumeRequirements(job)
        return true
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
        settler:give(ECS.c.path, path)
      end
    end
  end
end

local function generate(gridPosition, itemData, bluePrintItemSelector)
  local job = ECS.Entity()
  job:give(ECS.c.job, "bluePrint")
  job:give(ECS.c.name, "BluePrintJob")
  :give(ECS.c.id, entityManager.generateId())
  :give(ECS.c.onMap)
  :give(ECS.c.bluePrintJob, itemData.constructionSpeed or 1)
  :give(ECS.c.inventory) -- Item consumed so far
  :give(ECS.c.item, itemData, bluePrintItemSelector)
  :give(ECS.c.position, universe.gridPositionToPixels(gridPosition))
  :give(ECS.c.transparent)

  if itemData.components then
    for _, component in ipairs(itemData.components) do
      if not component.afterConstructed then
        job:give(ECS.c[component.name], unpack(component.properties))
      end
    end
  end

  local children = {}

  if itemData.requirements then
    job:give(ECS.c.children, {})
    local childrenIds = job:get(ECS.c.children).children
    for selector, amount in pairs(itemData.requirements) do
      local subJob = Fetch.generate(job:get(ECS.c.id).id, itemData, selector)
      subJob:give(ECS.c.parent, job:get(ECS.c.id).id)
      table.insert(children, subJob)
      table.insert(childrenIds, subJob:get(ECS.c.id).id)
    end
  end

  return job, children
end

local function finish(job)
    job:give(ECS.c.collision)
    job:remove(ECS.c.transparent)

    local itemData = job:get(ECS.c.item).itemData

    if itemData.components then
      for _, component in ipairs(itemData.components) do
        if component.afterConstructed then
          job:give(ECS.c[component.name], unpack(component.properties))
        end
      end
    end
end

return {
  handle = handle,
  generate = generate,
  finish = finish
}
