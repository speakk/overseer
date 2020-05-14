local nuklear = require("nuklear")
local settings = require("settings")
local Gamestate = require("libs.hump.gamestate")

local headerFont = love.graphics.newFont("fonts/MavenPro-Medium.ttf", 32)

local menuImage = love.graphics.newImage("media/menus/main_menu.png")
local menuButtons = {
  play = love.graphics.newImage("media/menus/main_menu_buttons/play.png"),
  play_hover = love.graphics.newImage("media/menus/main_menu_buttons/play_hover.png"),
  continue = love.graphics.newImage("media/menus/main_menu_buttons/continue.png"),
  continue_hover = love.graphics.newImage("media/menus/main_menu_buttons/continue_hover.png"),
  quit = love.graphics.newImage("media/menus/main_menu_buttons/quit.png"),
  quit_hover = love.graphics.newImage("media/menus/main_menu_buttons/quit_hover.png"),
}

local buttonsStartH = 95

local buttonW = 95
local buttonH = 29

local inGame = require("states.inGame")

local mainMenu = {}

local music

local menuWidth = 600
local menuHeight = 600

local scale = 1

local buttonHeight = 30

function mainMenu:init()
  self.ui = nuklear.newUI()

  music = love.audio.newSource('media/music/menu.mp3', 'stream')
  music:setVolume(0.4)
  music:setLooping(true)
  music:play()
end

function mainMenu:leave()
  music:stop()
end

local hoveredStates = {}

function mainMenu:primeHoveredSound(id)
    local previousHovered = hoveredStates[id]
    hoveredStates[id] = self.ui:widgetIsHovered()
    if not previousHovered and hoveredStates[id] then
      local sound = love.audio.newSource("media/sounds/menu_hover.mp3", "static")
      sound:setVolume(0.05)
      sound:play()
    end
end


function mainMenu:update(dt) --luacheck: ignore
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()

  local left = windowWidth / 2 - buttonW / 2 * scale
  local top = buttonsStartH * scale

  self.ui:frameBegin()
  self.ui:stylePush({
    ['window'] = {
      ['fixed background'] = "#00000000",
      ['background'] = "#00000000"
    }
  })
  if self.ui:windowBegin('main_menu', left, top, buttonW*scale+10, menuHeight) then
    self.ui:layoutRow('static', buttonH*scale, buttonW*scale, 1)
    self.ui:stylePush({
      ['button'] = {
        ['normal'] = menuButtons.play,
        ['hover'] = menuButtons.play_hover
      }
    })
    self:primeHoveredSound('play')
    if self.ui:button('') then
      Gamestate.switch(inGame)
    end
    self.ui:stylePop()

    if love.filesystem.getInfo(settings.quick_save_name) then
      self.ui:stylePush({
        ['button'] = {
          ['normal'] = menuButtons.continue,
          ['hover'] = menuButtons.continue_hover
        }
      })
      self.ui:layoutRow('static', buttonH*scale, buttonW*scale, 1)
      self:primeHoveredSound('continue')
      if self.ui:button('') then
        Gamestate.switch(inGame, settings.quick_save_name)
      end
      self.ui:stylePop()
    end

    self.ui:stylePush({
      ['button'] = {
        ['normal'] = menuButtons.quit,
        ['hover'] = menuButtons.quit_hover
      }
    })
    self.ui:layoutRow('static', buttonH*scale, buttonW*scale, 1)
    self.ui:layoutRow('static', buttonH*scale, buttonW*scale, 1)

    self:primeHoveredSound('quit')
    if self.ui:button('') then
      love.event.quit()
    end
    self.ui:stylePop()

    self.ui:windowEnd()
  end
  self.ui:stylePop()

  self.ui:frameEnd()
end

function mainMenu:draw()
  local w, h = menuImage:getDimensions()
  local sw, sh = love.graphics.getDimensions()
  scale = sh/h
  local x = sw/2 - w*scale/2
  love.graphics.draw(menuImage, x, 0, 0, scale, scale)
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
