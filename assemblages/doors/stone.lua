return function(e)
  e
  :assemble(ECS.a.doors.door)
  :give('name', 'Stone door')
  :give('requirements', {
    ["rawMaterials.stone"] = 1
  })
  :give('sprite', 'tiles.wall_stone01')
end
