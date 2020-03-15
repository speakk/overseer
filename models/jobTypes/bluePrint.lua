local Fetch = require('models.jobTypes.fetch')
local universe = require('models.universe')
local itemUtils = require('utils.itemUtils')
local entityManager = require('models.entityManager')

local function isBluePrintReadyToBuild(bluePrint)
  if bluePrint.job.finished then return false end

  local bluePrintComponent = bluePrint.bluePrintJob
  local requirements = bluePrint.item.itemData.requirements

  for selector, amount in pairs(requirements) do --luacheck: ignore
    local itemId = bluePrint.inventory:findItem(selector)
    local item = entityManager.get(itemId)
    --local itemInv = itemUtils.getInventoryItemBySelector(bluePrint.inventory.inventory, selector)
    -- print("Blueprint pos", universe.pixelsToGridCoordinates(bluePrint.position.vector))
    -- local itemInPosition = itemUtils.getItemFromGround(selector, universe.pixelsToGridCoordinates(bluePrint.position.vector))
    if not item or item.amount.amount < amount then
      --print("Didn't have no!", selector)
      return false
    end
  end

  return true
end

local function consumeRequirements(bluePrint)
  -- For now below is commented, items will just stay in bluePrint inventory
  -- local requirements = bluePrint.item.itemData.requirements
  -- for selector, amount in pairs(requirements) do --luacheck: ignore
  --   local itemInPosition = itemUtils.getItemFromGround(selector, universe.pixelsToGridCoordinates(bluePrint.position.vector))
  --   itemUtils.takeItemFromGround(itemInPosition, amount)
  -- end
end

local function handle(self, job, settler, dt, finishCallback)
  print("LOLOL STILL HANDLING WLOFLWEFOEW")
  local bluePrintComponent = job.bluePrintJob
  local settlerGridPosition = universe.pixelsToGridCoordinates(settler.position.vector)
  local bluePrintGridPosition = universe.pixelsToGridCoordinates(job.position.vector)
  if universe.isInPosition(settlerGridPosition, bluePrintGridPosition, true) then
    if isBluePrintReadyToBuild(job) then
      local constructionSkill = settler.settler.skills.construction
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
        if component.properties then
          job:give(ECS.c[component.name], unpack(component.properties))
        else
          job:give(ECS.c[component.name])
        end
      end
    end
  end

  local children = {}

  if itemData.requirements then
    job:give(ECS.c.children, {})
    local childrenIds = job.children.children
    for selector, amount in pairs(itemData.requirements) do
      local subJob = Fetch.generate(job.id.id, itemData, selector)
      subJob:give(ECS.c.parent, job.id.id)
      table.insert(children, subJob)
      table.insert(childrenIds, subJob.id.id)
    end
  end

  return job, children
end

local function finish(job)
    job:give(ECS.c.collision)
    job:give(ECS.c.construction, 100)
    job:remove(ECS.c.transparent)

    local itemData = job.item.itemData

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
