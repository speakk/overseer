local nuklear = require("nuklear")
local inspect = require("libs/inspect")
local lume = require("libs/lume")
local Vector = require('libs/brinevector/brinevector')

local constructionTypes = require('data/constructionTypes')

local ui

local GUISystem = ECS.System()

local materialNames = {
  wood = "Wood",
  metal = "Metal",
  stone = "Stone"
}

function buildMenuHierarchy(self, items, key, path)
  if path then path = lume.concat(path, {key}) else path = {} end
  --path = path or {}
  --table.insert(path, 1, key)
  if not items.subItems then
    local requirements = "Requires: "
    --print("Items", inspect(items))
    for key, value in pairs(items.requirements) do
      requirements = requirements .. materialNames[key] .. ": " .. value
      requirements = requirements .. ", "
    end

    local currentSelection = self.overseerSystem:getDataSelector()
    local selectionMatch = lume.all(currentSelection, function(selection) return lume.find(path, selection) end)
    local sel = { value = selectionMatch}
    if ui:selectable(items.name .. ", " .. requirements, sel) then
      if sel.value then
        self.overseerSystem:setDataSelector(path)
      end
    end
  elseif type(items) == "table" then
    if items.name and items.subItems then
      if ui:treePush('tab', items.name) then
        -- If tab is open AND also need to check if other tabs are open
        --table.insert(path, key)
        table.insert(path, "subItems")
        for key, item in pairs(items.subItems) do
          buildMenuHierarchy(self, item, key, path)
        end
      end
      ui:treePop()
    end
  end
end

function GUISystem:init(overseerSystem, mapSystem, camera)
  ui = nuklear.newUI()
  self.overseerSystem = overseerSystem
  self.mapSystem = mapSystem
  self.camera = camera
  self.currentMenu = nil

  self.menuHierarchy = {
    build = {
      name = "Build",
      subItems = constructionTypes
    },
    settlers = {
      name = "Settlers",
      subItems = {}
    }
  }
end

function GUISystem:update(dt)
  ui:frameBegin()
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()
  local actionsBarHeight = 60

  if ui:windowBegin('actions_bar', 0, windowHeight-actionsBarHeight, windowWidth, actionsBarHeight) then
    ui:layoutRow('dynamic', actionsBarHeight-10, 10)
    for menuName, menuItem in pairs(self.menuHierarchy) do
      local currentSelection = self.overseerSystem:getSelectedAction()
      local sel = { value = menuName == currentSelection }
      if ui:selectable(menuItem.name .. ' (' .. (menuItem.shortCut or '') .. ')', sel) then
        if sel.value then
          self.overseerSystem:setSelectedAction(menuName)
        else
          self.overseerSystem:setSelectedAction("")
        end
      end
    end
  end
  ui:windowEnd()

  local menuSize = 200
  local menuWidth = 400
  for menuName, menuItem in pairs(self.menuHierarchy) do
    print("Huh", menuName)
    if self.overseerSystem:getSelectedAction() == menuName then
      if ui:windowBegin('menu', 0, windowHeight-menuSize-actionsBarHeight, menuWidth, menuSize) then
        local shortMenu = lume.clone(menuItem)
        table.remove(shortMenu, 1)
        print("shortMenu", inspect(shortMenu))
        buildMenuHierarchy(self, shortMenu, nil)
        ui:windowEnd()
      end
    end
  end
  ui:frameEnd()
end

function GUISystem:draw()
  ui:draw()
end

function GUISystem:mousepressed(x, y, button, istouch, presses)
  if ui:mousepressed(x, y, button, istouch, presses) then
    return
  end
  globalX, globalY = self.camera:toWorld(x, y)
  local position = self.mapSystem:pixelsToGridCoordinates(Vector(globalX, globalY))
  self.overseerSystem:enactClick(self.mapSystem:pixelsToGridCoordinates(Vector(globalX, globalY)))
end

function GUISystem:keypressed(pressedKey, scancode, isrepeat)
  for menuName, menuItem in pairs(self.menuHierarchy) do
    if menuItem.shortCut == pressedKey then
      menuItem.selected = not menuItem.selected
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

function GUISystem:mousereleased(x, y, button, istouch, presses)
  ui:mousereleased(x, y, button, istouch, presses)
end

function GUISystem:mousemoved(x, y, dx, dy, istouch)
  ui:mousemoved(x, y, dx, dy, istouch)
end

return GUISystem

