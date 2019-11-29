local nuklear = require("nuklear")

local constructionTypes = require('data/constructionTypes')

local ui

local GUISystem = ECS.System()

function GUISystem:init()
  ui = nuklear.newUI()
  self.currentMenu = nil

  self.menuHierarchy = {
    {
      name = "Build",
      subItems = constructionTypes
    }
  }

  -- self.menuHierarchy = {
  --   {
  --     name = "Build",
  --     subItems = function() M.map(constructionTypes, function(constructionType)
  --       ui:button(constructionType.name)
  --     end) end
  --   }
  -- }

end

function GUISystem:update()
  ui:frameBegin()
  local windowWidth = love.graphics.getWidth()
  local windowHeight = love.graphics.getHeight()
  local actionsBarHeight = 60
  if ui:windowBegin('actions_bar', 0, windowHeight-actionsBarHeight, windowWidth, actionsBarHeight) then
    ui:layoutRow('dynamic', actionsBarHeight-10, 10)
    for _, menuItem in ipairs(self.menuHierarchy) do
      if ui:button(menuItem.name) then
        print("Huh")
        menuItem.showing = not menuItem.showing
      end
    end
  end
  ui:windowEnd()

  for _, menuItem in ipairs(self.menuHierarchy) do
    if menuItem.showing then
      local menuSubItemSizeHeight = 20
      local menuSubItemSizeWidth = 20
      local menuSize = table.getn(self.menuHierarchy.subItems) * menuSubItemSizeHeight
      if ui.windowBegin('menu', 0, windowHeight-menuSize, menuSubItemSizeWidth, menuSize) then
        for _, menuSubItem in menuItem.subItems do
          ui:layoutRow('dynamic', menuSubItemSizeHeight, 1)
          if ui:button(menuSubItem.name) then
            -- overseer change selection here
            print("Yes sub")
          end
        end
      end
      ui.windowEnd()
    end
  end
  ui:frameEnd()
end

function GUISystem:draw()
  ui:draw()
end

function GUISystem:mousepressed(x, y, button, istouch, presses)
  print("Hmm")
  if ui:mousepressed(x, y, button, istouch, presses) then
    print("Well wasit")
    return
  end
end

function GUISystem:mousereleased(x, y, button, istouch, presses)
  ui:mousereleased(x, y, button, istouch, presses)
end

return GUISystem

