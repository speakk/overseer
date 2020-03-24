local cpml = require('libs.cpml')

local function generateMap(width, height)
  local map = {}
  local mapColors = {}
  local grassNoiseScale = 0.05
  local foliageNoiseScale = 0.05
  local waterNoiseScale = 0.04

  for y = 1,height,1 do
    local row = {}
    local colorRow = {}
    for x = 1,width,1 do
      row[x] = 0
      colorRow[x] = {
        a = love.math.noise(x + love.math.random(), y + love.math.random()),
        b = love.math.noise(x + love.math.random(), y + love.math.random()),
        c = love.math.noise(x + love.math.random(), y + love.math.random()),
        grass = cpml.utils.round(love.math.noise(x * grassNoiseScale, y * grassNoiseScale)-0.3),
        foliage = cpml.utils.round(love.math.noise(x+1 * foliageNoiseScale, y+1 * foliageNoiseScale)-0.44),
        water = cpml.utils.round(love.math.noise(x * waterNoiseScale, y * waterNoiseScale)-0.45)
      }

      if colorRow[x].water == 1 then
        row[x] = 1
      end
    end
    map[y] = row
    mapColors[y] = colorRow
  end

  return map, mapColors
end

return {
  generateMap = generateMap
}
