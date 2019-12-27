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
    name = "resources",
    items = { 'wood01', 'iron01', 'steel01', 'stone01' },
  },
  {
    name = "characters",
    items = { 'settler' }
  },
  {
    name = "items",
    items = { 'torch01' }
  }
}

local flatMediaDB = {}
local fileList = {}

do
  local index = 1
  for _, category in ipairs(mediaDB) do
    for _, name in ipairs(category.items) do
      print("Index now", index)
      local fileName = generateTileName(category.name, name)
      flatMediaDB[category.name .. "." .. name] = {
        index = index,
        fileName = fileName
      }

      index = index + 1
      table.insert(fileList, fileName)
    end
  end
end

print("flat", inspect(flatMediaDB))


-- for _, flatItem in ipairs(flatMediaDB) do
--   table.insert(fileList, flatItem.fileName)
-- end

print("fileList", inspect(fileList))
local sprites = love.graphics.newArrayImage(fileList)
sprites:setFilter("nearest", "nearest")

local function getSpriteIndex(selector)
  --print(inspect(flatMediaDB[selector]))
  if not selector then error("getSprite is missing selector") end

  if not flatMediaDB[selector] then error("No sprite found with selector: " .. selector) end
  return flatMediaDB[selector].index
end

return {
  sprites = sprites,
  getSpriteIndex = getSpriteIndex
}
