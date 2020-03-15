local work = ECS.Component(..., function(component, jobId)
  component.jobId = jobId or nil
end) -- Settler work

function work:serialize() return { jobId = self.jobId } end
function work:deserialize(data)
  self.jobId = data.jobId
end

return work
