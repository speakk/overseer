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
        settler:give("path", path)
      end
    end
  end
end

local function generate(gridPosition, itemData, bluePrintItemSelector)
  local job = ECS.Entity()
  job:give("job", "bluePrint")
  job:give("name", "BluePrintJob")
  :give("id", entityManager.generateId())
  :give("onMap")
  :give("bluePrintJob", itemData.constructionSpeed or 1)
  :give("inventory") -- Item consumed so far
  :give("item", itemData, bluePrintItemSelector)
  :give("position", universe.gridPositionToPixels(gridPosition))
  :give("transparent")

  if itemData.components then
    for _, component in ipairs(itemData.components) do
      if not component.afterConstructed then
        if component.properties then
          job:give(component.name, unpack(component.properties))
        else
          job:give(component.name)
        end
      end
    end
  end

  local children = {}

  if itemData.requirements then
    job:give("children", {})
    local childrenIds = job.children.children
    for selector, amount in pairs(itemData.requirements) do
      local subJob = Fetch.generate(job.id.id, itemData, selector)
      subJob:give("parent", job.id.id)
      table.insert(children, subJob)
      table.insert(childrenIds, subJob.id.id)
    end
  end

  return job, children
end

local function finish(job)
    job:give("collision")
    job:give("construction", 100)
    job:remove("transparent")

    local itemData = job.item.itemData

    if itemData.components then
      for _, component in ipairs(itemData.components) do
        if component.afterConstructed then
          job:give(component.name, unpack(component.properties))
        end
      end
    end
end

return {
  handle = handle,
  generate = generate,
  finish = finish
}
