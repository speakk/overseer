local nuklear = require("nuklear")
local Vector = require('libs/brinevector/brinevector')

local universe = require("models/universe")

local constructionTypes = require('data/constructionTypes')

local ui

local GUISystem = ECS.System("gui")

local function buildMenuHierarchy(self, items, key, path)
  if path and string.len(path) > 0 then path = path .. "." .. key else path = key end
  if not items.subItems then
    local requirements = "Requires: "
    if items.requirements then
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

        self:getWorld():emit("dataSelectorChanged", path)
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

function GUISystem:init(camera)
  ui = nuklear.newUI()
  self.camera = camera
  self.selectedAction = nil
  self.dataSelector = nil

  self.menuHierarchy = {
    build = {
      name = "Build",
      shortCut = "q",
      subItems = constructionTypes.data
    },
    settlers = {
      name = "Settlers",
      subItems = {}
    }
  }
end

function GUISystem:update(dt) --luacheck: ignore
  ui:frameBegin()
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()
  local actionsBarHeight = 60

  if ui:windowBegin('actions_bar', 0, windowHeight-actionsBarHeight, windowWidth, actionsBarHeight) then
    ui:layoutRow('dynamic', actionsBarHeight-10, 10)
    for menuName, menuItem in pairs(self.menuHierarchy) do
      local sel = { value = menuName == self.selectedAction }
      if ui:selectable(menuItem.name .. ' (' .. (menuItem.shortCut or '') .. ')', sel) then
        if sel.value then
          self.selectedAction = menuName
          self:getWorld():emit("selectedModeChanged", menuName)
        else
          self.selectedAction = ""
          self:getWorld():emit("selectedModeChanged", "")
        end
      end
    end
  end
  ui:windowEnd()

  local menuSize = 200
  local menuWidth = 400
  for menuName, menuItem in pairs(self.menuHierarchy) do
    if self.selectedAction == menuName then
      if ui:windowBegin('menu', 0, windowHeight-menuSize-actionsBarHeight, menuWidth, menuSize) then
        for key, subItem in pairs(menuItem.subItems) do
          buildMenuHierarchy(self, subItem, key)
        end
        ui:windowEnd()
      end
    end
  end
  ui:frameEnd()
end

function GUISystem:draw() --luacheck: ignore
  ui:draw()
end

function GUISystem:mousepressed(x, y, button, istouch, presses)
  if ui:mousepressed(x, y, button, istouch, presses) then
    return
  end
  local globalX, globalY = self.camera:toWorld(x, y)
  self:getWorld():emit("mapClicked", universe.pixelsToGridCoordinates(Vector(globalX, globalY)))
end

function GUISystem:keypressed(pressedKey, scancode, isrepeat) --luacheck: ignore
  if pressedKey == 'z' then
    DEBUG = not DEBUG
  end

  for menuName, menuItem in pairs(self.menuHierarchy) do
    if menuItem.shortCut == pressedKey then
      menuItem.selected = not menuItem.selected
      if menuItem.selected then
        self.selectedAction = menuItem
        self:getWorld():emit('selectedModeChanged', menuName)
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

function GUISystem:mousereleased(x, y, button, istouch, presses) --luacheck: ignore
  ui:mousereleased(x, y, button, istouch, presses)
end

function GUISystem:mousemoved(x, y, dx, dy, istouch) --luacheck: ignore
  ui:mousemoved(x, y, dx, dy, istouch)
end

return GUISystem

