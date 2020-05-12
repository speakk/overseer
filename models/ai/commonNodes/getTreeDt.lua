return function(blackboard)
  return function()
    if not blackboard.lastTick then
      blackboard.lastTick = 0
    end

    local time = love.timer.getTime()
    blackboard.treeDt = time - blackboard.lastTick
    blackboard.lastTick = time
    return false, true
  end
end

