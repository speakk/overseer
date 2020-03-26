return function(e)
  e
  :assemble(ECS.a.doors.door)
  :give('name', 'Wooden door')
  :give('requirements', {
    ["rawMaterials.wood"] = 1
  })
  :give('sprite', 'tiles.door_wood01')
end
