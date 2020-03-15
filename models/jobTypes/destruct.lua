return {
  finish = function(job, world)
    world:emit("immediateDestroy", job)
  end
}
