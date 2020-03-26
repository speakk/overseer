return function(e)
  e
  :assemble(ECS.a.walls.wall)
  :give('name', 'Wooden wall')
  :give('requirements', {
    ["rawMaterials.wood"] = 2
  })
  :give('sprite', 'tiles.wall_wood01')
end
