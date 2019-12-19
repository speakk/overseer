local BluePrintUtils = {}

function BluePrintUtils.isBluePrintReadyToBuild(bluePrint)
  if bluePrint:get(components.job).finished then return false end

  local bluePrintComponent = bluePrint:get(components.bluePrintJob)
  local materialsConsumed = bluePrintComponent.materialsConsumed
  local requirements = bluePrint:get(components.item).itemData.requirements

  for selector, item in pairs(requirements) do
    if not materialsConsumed[selector] then
      return false
    end
  end

  return true
end

return BluePrintUtils
