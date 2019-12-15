local Vector = require('libs/brinevector/brinevector')
local commonComponents = require('components/common')
local utils = require('utils/utils')

-- Create a draw System.
local DrawSystem = ECS.System({commonComponents.Position, commonComponents.Draw})

local shader_code = [[

extern float dayTime;

vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {
  vec4 pixel = Texel(image, uvs);
  return pixel * color * vec4(0.4 * dayTime + 0.7, 0.4 * dayTime + 0.7, 1.0, 1);
}

]]

function DrawSystem:init(mapSystem, jobSystem, camera, dayCycleSystem)
  self.mapSystem = mapSystem
  --self.lightWorld = mapSystem:getLightWorld()
  self.jobSystem = jobSystem
  self.camera = camera
  self.dayCycleSystem = dayCycleSystem
  self.shader = love.graphics.newShader(shader_code)
end

function DrawSystem:drawMap(l, t, w, h, map)
  local cellSize = self.mapSystem:getCellSize()
  local padding = self.mapSystem:getPadding()
  local mapColors = self.mapSystem:getMapColorArray()
  for rowNum, row in ipairs(map) do
    for cellNum, cellValue in ipairs(row) do --luacheck: ignore
      local drawMargin = cellSize
      local x1 = (cellNum * cellSize)
      local x2 = x1 + cellSize
      local y1 = rowNum * cellSize
      local y2 = y1 + cellSize
      if utils.withinBounds(x1, y1, x2, y2, l, t, l+w, t+h, drawMargin) then
        local color = mapColors[rowNum][cellNum]
        if color.grass == 1 then
          love.graphics.setColor(0.35, 0.4+(color.c*0.1), 0.1)
        else
          love.graphics.setColor(color.a*0.1+0.5, color.a*0.1+0.3, color.c*0.05+0.15)
        end
        love.graphics.rectangle("fill",
        cellNum*cellSize,
        rowNum*cellSize,
        cellSize - padding,
        cellSize - padding
        )
      end
    end
  end
end

function DrawSystem:drawEntity(l, t, w, h, entity)
  local positionVector = entity:get(commonComponents.Position).vector
  local draw = entity:get(commonComponents.Draw)
  local sizeVector = draw.size
  if utils.withinBounds(positionVector.x,
    positionVector.y,
    positionVector.x + sizeVector.x,
    positionVector.y + sizeVector.y,
    l, t, l+w, t+h, sizeVector.x) then
    local color = draw.color
    local size = draw.size


    if entity:has(commonComponents.Job) then
      if entity:has(commonComponents.BluePrintJob) then
        local jobComponent = entity:get(commonComponents.Job)
        if jobComponent.finished then
          color[4] = 1.0
        else
          color[4] = 0.5
          love.graphics.setColor(1, 1, 1, 1)
          local progress = entity:get(commonComponents.BluePrintJob).buildProgress
          love.graphics.print(" " .. string.format("%d", progress) .. "%", positionVector.x, positionVector.y)
        end
      end
    end

    love.graphics.setColor(color[1], color[2], color[3], color[4])
    love.graphics.rectangle("fill",
    positionVector.x,
    positionVector.y,
    size.x, size.y)

    if entity:has(commonComponents.Amount) then
      love.graphics.setColor(1, 1, 1)
      love.graphics.print(" " .. tostring(entity:get(commonComponents.Amount).amount),
      positionVector.x+10, positionVector.y+10)
    end

    if DEBUG then
      if (entity:has(commonComponents.Path)) then
        local pathComponent = entity:get(commonComponents.Path)
        if pathComponent.path then
          local vertices = {}
          for node, count in pathComponent.path:nodes() do --luacheck: ignore
            local pixelPosition = self.mapSystem:gridPositionToPixels(
            Vector(node:getX(), node:getY()), 'center', 2
            )
            table.insert(vertices, pixelPosition.x)
            table.insert(vertices, pixelPosition.y)
          end
          love.graphics.setColor(1, 1, 1)
          love.graphics.line(vertices)
        end
      end
    end
  end
end

function DrawSystem:draw()
  love.graphics.setShader(self.shader)
  self.shader:send("dayTime", self.dayCycleSystem:getTimeOfDay())
  self.camera:draw(function(l,t,w,h)
    --self.lightWorld:draw(function()
      self:drawMap(l, t, w, h, self.mapSystem:getMap())
      for _, entity in ipairs(self.pool.objects) do
        self:drawEntity(l, t, w, h, entity)
      end
    --end)
  end)

  love.graphics.setColor(1, 1, 0)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10, 0, 1.3, 1.3)
  love.graphics.print("Amount of jobs: "..tostring(#self.jobSystem.pool.objects), 10, 40, 0, 1.3, 1.3)
  love.graphics.setShader()
end


return DrawSystem
