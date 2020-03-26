return function(e)
  e
  :assemble(ECS.a.walls.wall)
  :give('name', 'Iron wall')
  :give('requirements', {
    ["rawMaterials.steel"] = 1,
    ["rawMaterials.wood"] = 1
  })
  :give('sprite', 'tiles.wall_iron01')
end
