return function(e)
  e
  :assemble(ECS.a.lights.light)
  :give('name', 'Torch')
  :give('requirements', {
    ["rawMaterials.wood"] = 1
  })
  :give('sprite', 'items.torch01')
  :give('light', { 1.0, 1.0, 0.5 })
end
