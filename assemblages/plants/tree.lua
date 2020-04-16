return function(e)
  e
  :assemble(ECS.a.plants.plant)
  :give('name', 'Tree')
  :give('collision')
  :give('requirements', {
    ["seeds.tree"] = 1
  })
  :give('sprite', 'vegetation.tree01')
  :give("animation", {
    idle = {
      targetComponent = 'sprite',
      targetProperty = 'selector',
      interpolate = false,
      repeatAnimation = true,
      values = {
        "vegetation.tree01", "vegetation.tree01b"
      },
      currentValueIndex = love.math.random(1,2),
      frameLength = 0.4, -- in ms
      lastFrameUpdate = love.timer.getTime(),
      finished = false
    }
  },
  {
    'idle'
  })
  -- TODO: HOW TO ADD INV FROM HERE? Probably make a "drops" thing instead that drops items when dead
  --:give("inventory", { rawWood.id.id })
end
