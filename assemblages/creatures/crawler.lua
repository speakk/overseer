return function(settler, gridPosition)
  settler:assemble(ECS.a.creatures.creature, gridPosition)
  :give("sprite", 'creature.crawler1')
  :give("ai", 'animal')
  :give("name", "Crawler")
  :give("animation", {
    walk = {
      targetComponent = 'sprite',
      targetProperty = 'selector',
      interpolate = false,
      repeatAnimation = true,
      values = {
        "creatures.crawler1", "creatures.crawler2"
      },
      currentValueIndex = 1,
      frameLength = 0.2, -- in ms
      lastFrameUpdate = love.timer.getTime(),
      finished = false
    }
  },
  {
    'walk'
  })

end
