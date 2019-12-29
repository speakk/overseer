local universe = require('models.universe')

local function isBluePrintReadyToBuild(bluePrint)
  if bluePrint:get(ECS.Components.job).finished then return false end

  local bluePrintComponent = bluePrint:get(ECS.Components.bluePrintJob)
  local materialsConsumed = bluePrintComponent.materialsConsumed
  local requirements = bluePrint:get(ECS.Components.item).itemData.requirements

  for selector, item in pairs(requirements) do --luacheck: ignore
    if not materialsConsumed[selector] then
      return false
    end
  end

  return true
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
        --finishWork(self, settler, job)
        job:get(ECS.Components.job).finishedCallBack()
        finishCallback(self, settler, job)
      end
    end
  else
    settler.searched_for_path = false
    if not settler.searched_for_path then -- RIGHT ON THIS IF: Is global cache valid? If not then re-get path
      local path = universe.getPath(settlerGridPosition, bluePrintGridPosition)
      settler.searched_for_path = true
      if path then
        path.finishedCallBack = function()
          settler.searched_for_path = false
        end
        settler:give(ECS.Components.path, path)
      end
    end
  end
end

local function consumeRequirement(job, item) --luacheck: ignore
  local bluePrintComponent = job:get(ECS.Components.bluePrintJob)
  bluePrintComponent.materialsConsumed[item:get(ECS.Components.item).selector] = item
end


--function BluePrintSystem:bluePrintFinished(bluePrint) --luacheck: ignore
--  if bluePrint:has(ECS.Components.draw) then
--    local draw = bluePrint:get(ECS.Components.draw)
--    draw.color = { 1, 0, 0 }
--  end
--end
--
--
local function generate(gridPosition, itemData, bluePrintItemSelector)
  local job = ECS.Entity()
  job:give(ECS.Components.job, "bluePrint", function()
    job:give(ECS.Components.collision)
    job:remove(ECS.Components.transparent)

    if itemData.components then
      for _, component in ipairs(itemData.components) do
        job:give(ECS.Components[component.name], unpack(component.properties))
      end
    end

    job:give(ECS.Components.removeCallBack, function()
      print("Here you generate removeJob!")
    end)
  end)
  job:give(ECS.Components.name, "BluePrintJob")
  job:give(ECS.Components.onMap)
  job:give(ECS.Components.bluePrintJob, itemData.constructionSpeed or 1)
  job:give(ECS.Components.sprite, itemData.sprite)
  job:give(ECS.Components.item, itemData, bluePrintItemSelector)
  job:give(ECS.Components.position, universe.gridPositionToPixels(gridPosition))
  job:give(ECS.Components.transparent)

  if itemData.requirements then
    job:give(ECS.Components.children, {})
    local children = job:get(ECS.Components.children).children
    for selector, amount in pairs(itemData.requirements) do
      local subJob = ECS.Entity()
      subJob:give(ECS.Components.job, "fetch", function()
        consumeRequirement(job, subJob)
      end)
      subJob:give(ECS.Components.name, "FetchJob")
      subJob:give(ECS.Components.item, itemData, selector)
      subJob:give(ECS.Components.parent, job)
      subJob:give(ECS.Components.fetchJob, job, selector, amount)
      table.insert(children, subJob)
    end
  end

  return job
end

return {
  handle = handle,
  generate = generate
}
