local settler = ECS.Component(..., function(component, name, skills)
  component.name = name or "Lucy"
  component.skills = skills or { construction = 15 }
end)
function settler:serialize() return { name = self.name, skills = self.skills } end
function settler:deserialize(data)
  self.name = data.name
  self.skills = data.skills
end

return settler
