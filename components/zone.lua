local bitser = require 'libs.bitser'
local zone = ECS.Component(..., function(component, types, params)
  component.types = types
  component.params = params
end)
function zone:serialize()
  return {
    types = self.types,
    params = bitser.dumps(self.params)
  }
end
function zone:deserialize(data)
  self.types = data.types
  self.params = bitser.loads(data.params)
end
return zone
