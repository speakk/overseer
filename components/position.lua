return ECS.Component(function(e, vector)
  e.vector = vector or Vector(0, 0)
  e.customSerialize = function() return { x = e.vector.x, y = e.vector.y } end
end)

