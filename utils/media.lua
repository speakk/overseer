local inspect = require('libs.inspect')

local generateTileName = function(category, name) return 'media/' .. category .. '/' .. name .. '.png' end

local mediaDB = {
  {
    name = "tiles",
    items = { 'grass01', 'grass02', 'dirt01',
    'wall_wood01', 'wall_iron01', 'door_stone01', 'door_wood01',
    'wall_stone01', 'water01', 'water02' },
  },
  {
    name = "vegetation",
    items = {
      {
        fileName = 'tree01',
        originX = 0.5,
        originY = 1
      },
      {
        fileName = 'tree01b',
        originX = 0.5,
        originY = 1
      },
      'bush01', 'grass01', 'grass02', 'grass03'
    }
  },
  {
    name = "resources",
    items = { 'wood01', 'iron01', 'steel01', 'stone01' },
  },
  {
    name = "characters",
    items = {
      {
        fileName = 'settler1_01',
        originX = 0.5,
        originY = 1
      },
      {
        fileName = 'settler1_02',
        originX = 0.5,
        originY = 1
      },
      {
        fileName = 'settler1_03',
        originX = 0.5,
        originY = 1
      }
    },
  },
  {
    name = "creatures",
    items = {
      {
        fileName = 'crawler1',
        originX = 0.5,
        originY = 0.6
      },
      {
        fileName = 'crawler2',
        originX = 0.5,
        originY = 0.6
      }
    }
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
  },
  {
    name = "misc",
    items = { "daycycle" }
  },
  {
    name = "gore",
    items = {
      {
        fileName = 'blood1',
        originX = 0.5,
        originY = 0.8
      },
    }
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
    for _, item in ipairs(category.items) do
      if type(item) == "string" then
        local fileName = item
        item = {}
        item.fileName = fileName
        item.originX = 0.5
        item.originY = 0.5
      end
      local fileName = generateTileName(category.name, item.fileName)
      local sprite = love.graphics.newImage(fileName)
      local spriteWidth, spriteHeight = sprite:getDimensions()

      love.graphics.draw(sprite, currentX, currentY)

      local quad = love.graphics.newQuad(currentX, currentY, spriteWidth, spriteHeight, atlasCanvas:getDimensions())

      flatMediaDB[category.name .. "." .. item.fileName] = {
        quad = quad,
        hotPoints = item.hotPoints,
        originX = item.originX,
        originY = item.originY,
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

local function getSpriteQuad(selector)
  if not selector then error("getSprite is missing selector") end
  if not flatMediaDB[selector] then error("No sprite found with selector: " .. selector) end
  return flatMediaDB[selector].quad
end

local function getSprite(selector)
  if not selector then error("getSprite is missing selector") end
  if not flatMediaDB[selector] then error("No sprite found with selector: " .. selector) end
  return flatMediaDB[selector]
end

return {
  atlas = atlasCanvas,
  getSpriteQuad = getSpriteQuad,
  getSprite = getSprite
}
