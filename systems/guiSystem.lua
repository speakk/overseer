local nuklear = require("nuklear")

local ui

local GUISystem = ECS.System()

function GUISystem:init()
  ui = nuklear.newUI()
end

function GUISystem:update()
  ui:frameBegin()
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()
  local actionsBarHeight = 60
  if ui:windowBegin('actions_bar', 0, windowHeight-actionsBarHeight, windowWidth, actionsBarHeight) then
    ui:layoutRow('dynamic', actionsBarHeight-10, 10)
    if ui:button('Build') then
      print('Button!')
    end
  end
  ui:windowEnd()
  ui:frameEnd()
end

function GUISystem:draw()
  ui:draw()
end

function love.mousepressed(x, y, button, istouch, presses)
  print("Uii")
	ui:mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
	ui:mousereleased(x, y, button, istouch, presses)
end

return GUISystem

