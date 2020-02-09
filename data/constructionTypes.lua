local lume = require('libs.lume')

local data = {
  walls = {
    name = "Walls",
    subItems = {
      wooden_wall = {
        name = "Wooden wall",
        components = { { name = "sprite", properties = { "tiles.wall_wood01" } }, { name = "occluder" } },
        requirements = {
          ["raw_materials.wood"] = 2
        },
        color = {0.9, 0.7, 0.1},
        hp = 100
      },
      iron_wall = {
        name = "Iron wall",
        components = { { name = "sprite", properties = { "tiles.wall_iron01" } }, { name = "occluder" }  },
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
        components = { { name = "sprite", properties = { "tiles.door_wood01" } } },
        requirements = {
          ["raw_materials.wood"] = 1
        },
        color = {0.9, 0.7, 0.1},
        hp = 100
      },
      stone_door = {
        name = "Stone door",
        components = { { name = "sprite", properties = { "tiles.wall_stone01" } } },
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
        constructionSpeed = 5,
        requirements = {
          ["raw_materials.wood"] = 1
        },
        components = {
          { name = "sprite", properties = { "items.torch01" } },
          {
            name = "light",
            afterConstructed = true,
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
  growing = {
    name = "Grow",
    subItems = {
      potato = {
        name = "Potato",
        requirements = {
          ["seeds.potato_seed"] = 1
        },
        components = {
          {
            name = "plant",
            afterConstructed = true
          },
          {
            name = "animation",
            frames = {
              "potato_phase_1",
              "potato_phase_2",
              "potato_phase_3",
              "potato_phase_4",
            }
          }
        }
      },
      tree = {
        name = "Tree",
        requirements = {
          ["seeds.tree"] = 1
        },
        components = {
          {
            name = "plant",
            afterConstructed = true
          },
          {
            name = "sprite",
            properties = { "vegetation.tree01" }
          }
        }
      }
    }
  },
  raw_materials = {
    name = "Raw materials",
    hideFromMenu = true,
    subItems = {
      wood = {
        name = "Wood",
        components = { { name = "sprite", properties = { "resources.wood01" } } }
      },
      iron = {
        name = "Iron",
        components = { { name = "sprite", properties = { "resources.iron01" } } }
      },
      stone = {
        name = "Stone",
        components = { { name = "sprite", properties = { "resources.stone01" } } }
      },
      steel = {
        name = "Steel",
        components = { { name = "sprite", properties = { "resources.steel01" } } }
      }
    }
  },
  seeds = {
    name = "Seeds",
    hideFromMenu = true,
    subItems = {
      potato_seed = {
        name = "Potato seed",
        components = { { name = "sprite", properties = { "seeds.potato01" } } }
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

  if #selectorTable > 1 and dataRemaining[lastSelector] then return getDataBySelectorTable(dataRemaining[lastSelector]["subItems"], newTable) end
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
