local inspect = require('libs.inspect')

local generateTileName = function(category, name) return 'media/' .. category .. '/' .. name .. '.png' end

local mediaDB = {
  {
    name = "tiles",
    items = { 'grass01', 'grass02', 'dirt01',
      'wall_wood01', 'wall_iron01', 'door_stone01', 'door_wood01',
      'wall_stone01' },
  },
  {
    name = "vegetation",
    items = { 'tree01' },
  },
  {
    name = "resources",
    items = { 'wood01', 'iron01', 'steel01', 'stone01' },
  },
  {
    name = "characters",
    items = { 'settler1_01', 'settler1_02', 'settler1_03' }
  },
  {
    name = "items",
    items = { 'torch01' }
  },
  {
    name = "seeds",
    items = { 'seeds_potato' }
  },
  {
    name = "farming",
    items = { 'potato_phase_1', 'potato_phase_2', 'potato_phase_3', 'potato_phase_4'  }
  }
}

local flatMediaDB = {}
local fileList = {}


local atlasWidth = 1280
local atlasHeight = 1280
local atlasCanvas = love.graphics.newCanvas(atlasWidth, atlasHeight)
do
  love.graphics.setCanvas(atlasCanvas)
  love.graphics.clear()

  local currentX = 0
  local currentY = 0
  local lastRowHeight = 0

  for _, category in ipairs(mediaDB) do
    for _, name in ipairs(category.items) do
      local fileName = generateTileName(category.name, name)
      local sprite = love.graphics.newImage(fileName)
      local spriteWidth, spriteHeight = sprite:getDimensions()

      love.graphics.draw(sprite, currentX, currentY)

      local quad = love.graphics.newQuad(currentX, currentY, spriteWidth, spriteHeight, atlasCanvas:getDimensions())
      print("drawing to canvas", currentX, currentY, spriteWidth, spriteHeight, atlasCanvas:getDimensions())

      flatMediaDB[category.name .. "." .. name] = {
        quad = quad
      }

      currentX = currentX + spriteWidth
      if spriteHeight > lastRowHeight then
        lastRowHeight = spriteHeight
      end

      if currentX + spriteWidth > atlasWidth then
        currentX = 0
        currentY = currentY + lastRowHeight
        lastRowHeight = 0
      end

      -- index = index + 1
      -- table.insert(fileList, fileName)
    end
  end

  love.graphics.setCanvas()
end

print("flat", inspect(flatMediaDB))


-- for _, flatItem in ipairs(flatMediaDB) do
--   table.insert(fileList, flatItem.fileName)
-- end

-- print("fileList", inspect(fileList))
-- for _, fileName in ipairs(fileList) do
--   local sprite = love.graphics.newImage(fileName)
-- end
-- local sprites = love.graphics.newArrayImage(fileList)
-- sprites:setFilter("nearest", "nearest")

local function getSpriteQuad(selector)
  --print(inspect(flatMediaDB[selector]))
  if not selector then error("getSprite is missing selector") end

  if not flatMediaDB[selector] then error("No sprite found with selector: " .. selector) end
  return flatMediaDB[selector].quad
end

return {
  atlas = atlasCanvas,
  getSpriteQuad = getSpriteQuad
}
