local job = ECS.Component(..., function(component, jobType)
  component.jobType = jobType or error("Job needs jobType")
  component.target = nil
  component.reserved = false
  component.finished = false
  component.allJobsOrNothing = false
  component.isInaccessible = false
end)
function job:serialize() return { jobType = self.jobType } end
function job:deserialize(data)
  self.jobType = data.jobType
  self.target = data.target
  self.reserved = data.reserved
  self.finished = data.finished
  self.isInaccessible = data.isInaccessible
end
return job
