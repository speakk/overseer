local bluePrintJob = ECS.Component(..., function(component, constructionSpeed, materialsConsumed, buildProgress)
  component.constructionSpeed = constructionSpeed or 8
  component.materialsConsumed = materialsConsumed or {}
  component.buildProgress = buildProgress or 0 -- 0/100
end)
function bluePrintJob:serialize()
  return {
    constructionSpeed = self.constructionSpeed,
    materialsConsumed = self.materialsConsumed,
    buildProgress = self.buildProgress
  }
end
function bluePrintJob:deserialize(data)
  self.constructionSpeed = data.constructionSpeed
  self.materialsConsumed = data.materialsConsumed
  self.buildProgress = data.buildProgress
end
return bluePrintJob
