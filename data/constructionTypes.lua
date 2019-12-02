local lume = require('libs/lume')

local data = {
  walls = {
    name = "Walls",
    subItems = {
      wooden_wall = {
        name = "Wooden wall",
        requirements = {
          ["raw_materials.wood"] = 10,
          ["raw_materials.metal"] = 1
        },
        color = {0.9, 0.7, 0.1},
        hp = 100
      },
      iron_wall = {
        name = "Iron wall",
        requirements = {
          ["raw_materials.wood"] = 10,
          ["raw_materials.metal"] = 1
        },
        color = {0.5, 0.5, 0.55},
        hp = 500
      },
    }
  },
  doors = {
    name = "Doors",
    subItems = {
      wooden_door = {
        name = "Wooden door",
        requirements = {
          ["raw_materials.wood"] = 3
        },
        color = {0.9, 0.7, 0.1},
        hp = 100
      },
      stone_door = {
        name = "Stone door",
        requirements = {
          ["raw_materials.stone"] = 3
        },
        color = {0.8, 0.8, 0.8},
        hp = 200
      }
    }
  },
  defence = {
    name = "Defence",
    subItems = {
      turrent = {
        name = "Turret",
        requirements = {
          ["raw_materials.metal"] = 3
        },
        color = { 0.6, 0.5, 0.1 },
        hp = 300
      }
    }
  },
  raw_materials = {
    name = "Raw materials",
    subItems = {
      wood = {
        name = "Wood"
      },
      iron = {
        name = "Iron"
      },
      stone = {
        name = "Stone"
      },
      metal = {
        name = "Metal"
      }
    }
  }
}

local function getDataBySelectorTable(dataRemaining, selectorTable)
  if #selectorTable == 0 then
    return dataRemaining
  end
  local newTable = {unpack(selectorTable)}
  local lastSelector = table.remove(newTable, 1)

  if #selectorTable > 1 then return getDataBySelectorTable(dataRemaining[lastSelector]["subItems"], newTable) end
  if #selectorTable == 1 then return getDataBySelectorTable(dataRemaining[lastSelector], newTable) end
end

local function getBySelector(selector)
  local selectorTable = lume.split(selector, ".")
  return getDataBySelectorTable(data, selectorTable)
end

return {
  data = data,
  getBySelector = getBySelector
}
