local nuklear = require("nuklear")
local settings = require("settings")
local inspect = require("libs.inspect") --luacheck: ignore
local lume = require("libs.lume")
local Vector = require('libs.brinevector')
local media = require('utils.media')

local camera = require("models.camera")

local atlas = media.atlas

local ui
--local constructionTypes = require('data.constructionTypes')

local menuWidth = 400
local menuHeight = 300

local config = {
  settlerListWindow = { w = 400, h = 400 },
  settlerWindow = { w = 400, h = 400 },
}

local drawSettlerListWindow = function(self, uiState) --luacheck: ignore
  ui:windowBegin("Settlers", 30, love.graphics.getHeight() - settings.actions_bar_height - config.settlerListWindow.h,
  config.settlerListWindow.w, config.settlerListWindow.h, { 'title', 'scrollbar' })
  for _, entity in ipairs(self.settlers) do
    local name = entity.name.name
    ui:layoutRowBegin('dynamic', 30, 3)
    ui:layoutRowPush(0.33)
    if ui:button(name) then
      uiState.selectedSettler = entity
    end
    ui:label("Health", 'right')
    ui:stylePush({progress={['cursor normal']=nuklear.colorRGBA(100,255,100)}})
    ui:progress(entity.health.value, 100)
    ui:stylePop()
    ui:layoutRowEnd()

  end
  ui:windowEnd()
end

local uiState = {
  selectedSettler = nil,
  menuHierarchy = {
    {
      name = "Build",
      id = "build",
      event = "build",
      shortCut = "q",
      subItems = {
        construct = {
          name = "Construct",
          spriteSelector = "tiles.door_wood01",
          subItems = lume.map(lume.concat(ECS.a.doors, ECS.a.walls, ECS.a.lights), function(assemblage)
            local e = ECS.Entity():assemble(assemblage)
            if not e.name then return nil end
            return {
              name = e.name.name,
              spriteSelector = e.sprite.selector,
              assemblage = assemblage
            }
          end)
        }
      }
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
                types = {"construct", "harvest"},
                selector = "plants.potato"
              }
            }
          }
        },
        chopTrees = {
          name = "Chop trees",
          params = {
            types = { "deconstruct" },
            selector = "plants.tree"
          }
        }
      }
    },
    {
      name = "Settlers",
      id = "settlers",
      shortCut = "r",
      draw = drawSettlerListWindow
    }
  }
}




local GUISystem = ECS.System( {settlers = { "settler" } })

local function buildMenuHierarchy(self, items, key, path)
  if path and string.len(path) > 0 then path = path .. "." .. key else path = key end
  if not items.subItems then
    local requirements
    if items.requirements then
      requirements = "Requires: "
      for itemKey, value in pairs(items.requirements) do
        --requirements = requirements .. constructionTypes.getBySelector(itemKey).name .. ": " .. value
        requirements = "todo"
        requirements = requirements .. ", "
      end
    end

    --local selectionMatch = items.assemblage == self.selectedAssemblage
    local selectionMatch = path == self.selectedPath
    local sel = { value = selectionMatch}
    local name = items.name
    if requirements then name = name .. ", " .. requirements end
    local image = nil
    if items.spriteSelector then
      image = { atlas, media.getSpriteQuad(items.spriteSelector) }
    end
    ui:stylePush({selectable={
      ['normal']=nuklear.colorRGBA(255,255,255, 0),
      ['hover']=nuklear.colorRGBA(255,255,255, 0),
      ['normal active']=nuklear.colorRGBA(255,255,255, 0),
      ['hover active']=nuklear.colorRGBA(255,255,255, 0),
      ['pressed active']=nuklear.colorRGBA(255,255,255, 0),
      ['text hover']=nuklear.colorRGBA(255,255,100, 255),
      ['text hover active']=nuklear.colorRGBA(255,170,100, 255),
      ['text normal active']=nuklear.colorRGBA(255,170,100, 255)
      }})
    if ui:selectable(name, image, sel) then
      self.selectedAssemblage = items.assemblage
      self.selectedPath = path
      self:getWorld():emit("selectedAssemblageChanged", items.assemblage, items.params)
    end
    ui:stylePop()

  elseif type(items) == "table" then
    if items.name and items.subItems and not items.hideFromMenu then
      local image = nil
      if items.spriteSelector then
        image = { atlas, media.getSpriteQuad(items.spriteSelector) }
      end
      if ui:treePush('tab', items.name, image) then
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
  self.selectedAssemblage = nil
end

function GUISystem:update(dt) --luacheck: ignore
  ui:frameBegin()
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()
  local actionsBarHeight = settings.actions_bar_height

  if ui:windowBegin('actions_bar', 0, windowHeight-actionsBarHeight, windowWidth, actionsBarHeight) then
    ui:layoutRow('dynamic', actionsBarHeight-10, 8)
    for _, menuItem in ipairs(uiState.menuHierarchy) do
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

  for _, menuItem in pairs(uiState.menuHierarchy) do
    if self.selectedAction == menuItem.id then
      if menuItem.subItems then
        if ui:windowBegin('menu', 0, windowHeight-menuHeight-actionsBarHeight, menuWidth, menuHeight) then
          for key, subItem in pairs(menuItem.subItems) do
            buildMenuHierarchy(self, subItem, key)
          end
          ui:windowEnd()
        end
      end

      if menuItem.draw then
        menuItem.draw(self, uiState)
      end
    end
  end

  self:renderWindows()
  ui:frameEnd()
end

function GUISystem:renderWindows() --luacheck: ignore
  if uiState.selectedSettler then
    local settler = uiState.selectedSettler
    if ui:windowBegin("Settler: " .. settler.name.name, 30, 30,
      config.settlerWindow.w, config.settlerWindow.h, { 'title', 'movable', 'closable' }) then
      ui:layoutRowBegin('dynamic', 30, 2)
      ui:layoutRowPush(0.5)
      ui:label("Health")
      ui:stylePush({progress={['cursor normal']=nuklear.colorRGBA(100,255,100)}})
      ui:progress(settler.health.value, 100)
      ui:stylePop()
      ui:layoutRowEnd()
      ui:layoutRowBegin('dynamic', 30, 2)
      ui:layoutRowPush(0.5)
      ui:label("Satiation level")
      ui:stylePush({progress={['cursor normal']=nuklear.colorRGBA(200,200,100)}})
      ui:progress(settler.satiety.value, 100)
      ui:stylePop()
      ui:layoutRowEnd()
      ui:windowEnd()
    else
      print("Setting selectedSettler to nil")
      uiState.selectedSettler = nil
    end
  end
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

  -- if self.selectedMenu then
  --   local event = self.selectedMenu.event
  --   local params = self.selectedParams
  --   self:getWorld():emit(event, globalX, globalY, button, table.unpack(params))
  -- end
end

function GUISystem:mousereleased(x, y, button, istouch, presses) --luacheck: ignore
  if ui:mousereleased(x, y, button, istouch, presses) then
    return
  end
  local globalX, globalY = camera:toWorld(x, y)
  self:getWorld():emit("mouseReleased", Vector(globalX, globalY), button)
end


function GUISystem:keypressed(pressedKey, scancode, isrepeat) --luacheck: ignore
  for _, menuItem in pairs(uiState.menuHierarchy) do
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

function GUISystem:setSelectedAssemblage(assemblage)
  self.selectedAssemblage = assemblage
end

function GUISystem:mousemoved(x, y, dx, dy, istouch) --luacheck: ignore
  ui:mousemoved(x, y, dx, dy, istouch)
end

function GUISystem:wheelmoved(x, y)
  if not ui:wheelmoved(x, y) then
    self:getWorld():emit("wheelmoved_pass", x, y)
  end
end

return GUISystem

