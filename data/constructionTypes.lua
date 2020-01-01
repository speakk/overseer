local lume = require('libs.lume')

local data = {
  walls = {
    name = "Walls",
    subItems = {
      wooden_wall = {
        name = "Wooden wall",
        sprite = "tiles.wall_wood01",
        requirements = {
          ["raw_materials.wood"] = 2
        },
        color = {0.9, 0.7, 0.1},
        hp = 100
      },
      iron_wall = {
        name = "Iron wall",
        sprite = "tiles.wall_iron01",
        requirements = {
          ["raw_materials.steel"] = 1,
          ["raw_materials.wood"] = 1
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
        sprite = "tiles.door_wood01",
        requirements = {
          ["raw_materials.wood"] = 1
        },
        color = {0.9, 0.7, 0.1},
        hp = 100
      },
      stone_door = {
        name = "Stone door",
        sprite = "tiles.wall_stone01",
        requirements = {
          ["raw_materials.stone"] = 1
        },
        color = {0.8, 0.8, 0.8},
        hp = 200
      }
    }
  },
  lights = {
    name  = "Lights",
    subItems = {
      torch = {
        name = "Torch",
        sprite = "items.torch01",
        constructionSpeed = 5,
        requirements = {
          ["raw_materials.wood"] = 1
        },
        components = {
          {
            name = "light",
            properties = { { 1.0, 1.0, 0.5 } }
          }
        }
      }
    }
  },
  defence = {
    name = "Defence",
    subItems = {
      turrent = {
        name = "Turret",
        requirements = {
          ["raw_materials.steel"] = 3
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
        name = "Wood",
        sprite = "resources.wood01"
      },
      iron = {
        name = "Iron",
        sprite = "resources.iron01"
      },
      stone = {
        name = "Stone",
        sprite = "resources.stone01"
      },
      steel = {
        name = "Steel",
        sprite = "resources.steel01"
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
