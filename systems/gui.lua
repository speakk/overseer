local nuklear = require("nuklear")
local settings = require("settings")
local inspect = require("libs.inspect") --luacheck: ignore
local Vector = require('libs.brinevector')

local camera = require("models.camera")

local constructionTypes = require('data.constructionTypes')

local menuWidth = 400
local menuHeight = 300

local ui

local GUISystem = ECS.System()

local function buildMenuHierarchy(self, items, key, path)
  if path and string.len(path) > 0 then path = path .. "." .. key else path = key end
  if not items.subItems then
    local requirements = ""
    if items.requirements then
      requirements = "Requires: "
      for itemKey, value in pairs(items.requirements) do
        requirements = requirements .. constructionTypes.getBySelector(itemKey).name .. ": " .. value
        requirements = requirements .. ", "
      end
    else
      requirements = requirements .. '-'
    end

    local selectionMatch = path == self.dataSelector
    local sel = { value = selectionMatch}
    if ui:selectable(items.name .. ", " .. requirements, sel) then
      if sel.value then

        self.dataSelector = path
        self:getWorld():emit("dataSelectorChanged", path, items.params)
      end
    end
  elseif type(items) == "table" then
    if items.name and items.subItems then
      if ui:treePush('tab', items.name) then
        for subKey, item in pairs(items.subItems) do
          buildMenuHierarchy(self, item, subKey, path)
        end
      ui:treePop()
      end
    end
  end
end

function GUISystem:init()
  ui = nuklear.newUI()
  self.selectedAction = nil
  self.dataSelector = nil

  self.menuHierarchy = {
    {
      name = "Build",
      id = "build",
      shortCut = "q",
      subItems = constructionTypes.data
    },
    {
      name = "Zones",
      id = "zones",
      shortCut = "e",
      subItems = {
        farming = {
          name = "Farming",
          subItems = {
            potato = {
              name = "Potato",
              params = {
                type = "construct",
                selector = "growing.tree"
              }
            }
          }
        },
        chopTrees = {
          name = "Chop trees",
          params = {
            type = "deconstruct",
            selector = "growing.tree"
          }
        }
      }
    },
    {
      name = "Settlers",
      id = "settlers",
      subItems = {}
    }
  }
end

function GUISystem:update(dt) --luacheck: ignore
  ui:frameBegin()
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()
  local actionsBarHeight = settings.actions_bar_height

  if ui:windowBegin('actions_bar', 0, windowHeight-actionsBarHeight, windowWidth, actionsBarHeight) then
    ui:layoutRow('dynamic', actionsBarHeight-10, 10)
    for _, menuItem in ipairs(self.menuHierarchy) do
      local sel = { value = menuItem.id == self.selectedAction }
      if ui:selectable(menuItem.name .. ' (' .. (menuItem.shortCut or '') .. ')', sel) then
        if sel.value then
          self.selectedAction = menuItem.id
          self:getWorld():emit("selectedModeChanged", menuItem.id)
        else
          self.selectedAction = ""
          self:getWorld():emit("selectedModeChanged", "")
        end
      end
    end
  end
  ui:windowEnd()

  for _, menuItem in pairs(self.menuHierarchy) do
    if self.selectedAction == menuItem.id then
      if ui:windowBegin('menu', 0, windowHeight-menuHeight-actionsBarHeight, menuWidth, menuHeight) then
        for key, subItem in pairs(menuItem.subItems) do
          buildMenuHierarchy(self, subItem, key)
        end
        ui:windowEnd()
      end
    end
  end
  ui:frameEnd()
end

function GUISystem:guiDraw() --luacheck: ignore
  ui:draw()
end

function GUISystem:mousepressed(x, y, button, istouch, presses)
  if ui:mousepressed(x, y, button, istouch, presses) then
    return
  end
  local globalX, globalY = camera:toWorld(x, y)
  self:getWorld():emit("mapClicked", Vector(globalX, globalY), button, self.selectedAction)
end

function GUISystem:mousereleased(x, y, button, istouch, presses) --luacheck: ignore
  if ui:mousereleased(x, y, button, istouch, presses) then
    return
  end
  local globalX, globalY = camera:toWorld(x, y)
  self:getWorld():emit("mouseReleased", Vector(globalX, globalY), button)
end


function GUISystem:keypressed(pressedKey, scancode, isrepeat) --luacheck: ignore
  for _, menuItem in pairs(self.menuHierarchy) do
    if menuItem.shortCut == pressedKey then
      menuItem.selected = not menuItem.selected
      if menuItem.selected then
        self.selectedAction = menuItem.id
        print("Setting selectedAction", menuItem.id)
        self:getWorld():emit('selectedModeChanged', menuItem.id)
      else
        self.selectedAction = ""
        self:getWorld():emit('selectedModeChanged', "")
      end
    end
    if menuItem.subItems then
      local subIndex = 1
      for _, subItem in pairs(menuItem.subItems) do
        if tonumber(pressedKey) == subIndex then
          subItem.selected = not subItem.selected
        end
        subIndex = subIndex + 1
      end
    end
  end
end

function GUISystem:setDataSelector(selector)
  self.dataSelector = selector
end

function GUISystem:mousemoved(x, y, dx, dy, istouch) --luacheck: ignore
  ui:mousemoved(x, y, dx, dy, istouch)
end

return GUISystem

