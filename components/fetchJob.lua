-- targetId == where to return stuff to
local fetchJob = ECS.Component(..., function(component, targetId, selector, amount)
  component.targetId = targetId
  component.selector = selector or error("Fetch has no selector!")
  component.amount = amount
end)
function fetchJob:customSerialize()
  return {
    targetId = self.targetId,
    selector = self.selector,
    amount = self.amount
  }
end
function fetchJob:customDeserialize(data)
  self.targetId = data.targetId
  self.selector = data.selector
  self.amount = data.amount
end
return fetchJob
