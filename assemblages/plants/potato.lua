return function(e)
  e
  :assemble(ECS.a.plants.plant)
  :give('name', 'Potato')
  :give('requirements', {
    ["seeds.potato"] = 1
  })
  :give('plant',
  {
    "farming.potato_phase_1",
    "farming.potato_phase_2",
    "farming.potato_phase_3",
    "farming.potato_phase_4",
  })
end
