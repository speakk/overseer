return function(e)
  e
  :assemble(ECS.a.plants.plant)
  :give('name', 'Tree')
  :give('collision')
  :give('requirements', {
    ["seeds.tree"] = 1
  })
  :give('sprite', 'vegetation.tree01')
end
