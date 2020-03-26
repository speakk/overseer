local plant = ECS.Component(..., function(component, frames, growInterval, currentStage)
  component.frames = frames
  component.growInterval = growInterval or 5
  component.currentStage = currentStage or 1
end)
return plant
