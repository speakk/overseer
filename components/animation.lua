local bitser = require 'libs.bitser'

local animation = ECS.Component(..., function(component, props, activeAnimations)
  -- activeAnimations: {
  -- 'walk'
  -- }
  --
  -- Props: {
  -- walk = {
  --  targetComponent: 'sprite'
  --  targetProperty: 'selector',
  --  interpolate: false,
  --  repeatAnimation: true,
  --  values = { "settler1_02", "settler1_03" }
  --  currentValueIndex = 0,
  --  frameLength = 10 -- in ms
  --  lastFrameUpdate = nil -- time
  --  finished = false
  --  }
  component.props = props
  component.activeAnimations = activeAnimations
end)

function animation:serialize()
  return {
    props = bitser.dumps(self.props),
    activeAnimations = bitser.dumps(self.activeAnimations)
  }
end
function animation:deserialize(data)
  self.props = bitser.loads(data.props)
  self.activeAnimations = bitser.loads(data.activeAnimations)
end

return animation
