local nuklear = require("nuklear")
local Gamestate = require("libs.hump.gamestate")

local headerFont = love.graphics.newFont("fonts/MavenPro-Medium.ttf", 32)

local inGame = require("states.inGame")

local mainMenu = {}

local menuWidth = 600
local menuHeight = 600

local buttonHeight = 30

function mainMenu:init()
  self.ui = nuklear.newUI()
end

function mainMenu:update(dt) --luacheck: ignore
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()

  local left = windowWidth / 2 - menuWidth / 2
  local top = windowHeight / 2 - menuHeight / 2

  self.ui:frameBegin()
  if self.ui:windowBegin('main_menu', left, top, menuWidth, menuHeight) then
    self.ui:layoutRow('dynamic', buttonHeight * 2, 1)
    self.ui:stylePush({
      ['font'] = headerFont
    })
    self.ui:label('overseer', 'centered')
    self.ui:stylePop()
    -- Rough vertical centering
    self.ui:layoutRow('dynamic', menuHeight/2 - buttonHeight * 4, 1)
    self.ui:layoutRow('dynamic', buttonHeight, 1)
    if self.ui:button('Start game') then
      Gamestate.switch(inGame)
    end
    if love.filesystem.getInfo('overseer_quicksave') then
      if self.ui:button('Continue game') then
        Gamestate.switch(inGame, 'overseer_quicksave')
      end
    end
    self.ui:layoutRow('dynamic', buttonHeight, 1)
    if self.ui:button('Quit') then
      love.event.quit()
    end
    self.ui:windowEnd()
  end

  self.ui:frameEnd()
end

function mainMenu:draw()
  self.ui:draw()
end

function mainMenu:keypressed(key, scancode, isrepeat)
  self.ui:keypressed(key, scancode, isrepeat)
end

function mainMenu:keyreleased(key, scancode)
  self.ui:keyreleased(key, scancode)
end

function mainMenu:mousepressed(x, y, button, istouch, presses)
  self.ui:mousepressed(x, y, button, istouch, presses)
end

function mainMenu:mousereleased(x, y, button, istouch, presses)
  self.ui:mousereleased(x, y, button, istouch, presses)
end

function mainMenu:mousemoved(x, y, dx, dy, istouch)
  self.ui:mousemoved(x, y, dx, dy, istouch)
end

return mainMenu
