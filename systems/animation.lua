local AnimationSystem = ECS.System({pool = {"animation"}})

function AnimationSystem:update(dt) --luacheck: ignore
  local currentTime = love.timer.getTime()

  for _, entity in ipairs(self.pool) do
    local animation = entity.animation
    local props = animation.props
    local activeAnimations = animation.activeAnimations

    for _, animationKey in ipairs(activeAnimations) do
      local animationProps = props[animationKey]

      local targetComponent = entity[animationProps.targetComponent]

      targetComponent[animationProps.targetProperty] = animationProps.values[animationProps.currentValueIndex]

      if not animation.finished then
        if currentTime > animationProps.lastFrameUpdate + animationProps.frameLength then
          animationProps.lastFrameUpdate = currentTime
          animationProps.currentValueIndex = animationProps.currentValueIndex + 1


          if animationProps.currentValueIndex > #animationProps.values then
            if animationProps.repeatAnimation then
              animationProps.currentValueIndex = 1
            else
              animationProps.currentValueIndex = #animationProps.values
              animationProps.finished = true
            end
          end

        end
      end
    end
  end
end

-- TODO: Figure out a better way to do this
function AnimationSystem:entityMoved(entity, position, positionDelta) --luacheck: ignore
  if entity.animation then
    local animation = entity.animation

    if positionDelta.x > 0 then
      animation.flipped = false
    else
      animation.flipped = true
    end

    if math.abs(positionDelta.x) > 0 or math.abs(positionDelta.y) > 0 then
        animation.activeAnimations = { 'walk' }
      else
        animation.activeAnimations = { }
        -- TODO: Make the idle animation
        -- animation.activeAnimations = { 'idle' }
      end
    end
end

return AnimationSystem
