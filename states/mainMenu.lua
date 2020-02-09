local nuklear = require("nuklear")
local settings = require("settings")
local Gamestate = require("libs.hump.gamestate")

local headerFont = love.graphics.newFont("fonts/MavenPro-Medium.ttf", 32)

local inGame = require("states.inGame")
local loading = require("states.loading")

local media = require("utils/media")

local mainMenu = {}

local menuWidth = 600
local menuHeight = 600

local buttonHeight = 30

love.graphics.reset()
local sprite = love.graphics.newImage("media/tiles/grass01.png")
local canvasTest = love.graphics.newCanvas(480, 480)
love.graphics.push('all')
love.graphics.setStencilTest( )
love.graphics.setBlendMode('alpha')
love.graphics.setCanvas({ canvasTest, stencil=false})
love.graphics.setColor(1,1,1,1)
love.graphics.rectangle("fill", 0, 0, 48, 48)
love.graphics.setShader()
love.graphics.origin()
love.graphics.draw(sprite)
love.graphics.setCanvas()
love.graphics.pop()
print("DID CNAVAS")

function mainMenu:init()
  self.ui = nuklear.newUI()
  print("init init")
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
      Gamestate.switch(loading)
    end
    if love.filesystem.getInfo(settings.quick_save_name) then
      if self.ui:button('Continue game') then
        Gamestate.switch(loading, settings.quick_save_name)
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
  print("draw rawr")
  --self.ui:draw()
  love.graphics.setShader()
  love.graphics.setColor(1,1,1,1)
  --love.graphics.rectangle("fill", 0, 0, 512, 512)
  love.graphics.draw(canvasTest, 200, 100)
  love.graphics.draw(sprite, 200, 100)
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
