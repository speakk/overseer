local bitser = require 'libs.bitser'
local zone = ECS.Component(..., function(component, type, params)
  component.type = type
  component.params = params
end)
function zone:serialize()
  return {
    type = self.type,
    params = bitser.dumps(self.params)
  }
end
function zone:deserialize(data)
  self.type = data.type
  self.params = bitser.loads(data.params)
end
return zone
