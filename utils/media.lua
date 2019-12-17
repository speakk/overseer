local generateTileName = function(category, name) return 'media/' .. category .. '/' .. name .. '.png' end
local tiles_names = {
  generateTileName('tiles', 'grass01'),
  generateTileName('tiles', 'grass02'),
  generateTileName('tiles', 'dirt01')
}

local characters_names = {
  generateTileName('characters', 'settler')
}

local tiles = love.graphics.newArrayImage(tiles_names)
local characters = love.graphics.newArrayImage(characters_names)
tiles:setFilter("nearest", "linear") -- this "linear filter" removes some artifacts if we were to scale the tiles
characters:setFilter("nearest", "linear") -- this "linear filter" removes some artifacts if we were to scale the tiles

local tileMaps = {
  characters = characters,
  tiles = tiles
}

return {
  tileMaps = tileMaps
}
