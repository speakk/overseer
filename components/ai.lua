local ai = ECS.Component(..., function(component, behaviourType)
  component.behaviourType = behaviourType
end)
function ai:serialize() return { behaviourType = self.behaviourType} end
function ai:deserialize(data) self.behaviourType = data.behaviourType end
return ai

