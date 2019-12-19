local Vector = require('libs/brinevector/brinevector')
local Concord = require('libs/concord')
local component = require('libs/concord').component

local function initializeComponents()
  Concord.component("position", function(e, vector) e.vector = vector or Vector(0, 0) end)
  Concord.component("velocity", function(e, vector) e.vector = vector or Vector(0, 0) end)
  Concord.component("name", function(e, name) e.name = name or "-" end)
  Concord.component("playerInput")
  Concord.component("camera")
  Concord.component("draw", function(e, color, size)
    e.color = color or { 1, 0, 0 }
    e.size = size or Vector(32, 32)
  end)
  Concord.component("sprite", function(e, selector)
    e.selector = selector or error("Sprite needs sprite selector")
    -- e.image = image or error("Sprite needs image")
    -- e.x = x or error("Sprite needs x image coordinate")
    -- e.y = y or error("Sprite needs y image coordinate")
  end)
  Concord.component("settler", function(e, name)
    e.name = name or "Lucy"
    e.skills = {
      construction = 15
    }
  end)
  Concord.component("work", function(e, job) e.job = job or nil end) -- Settler work
  Concord.component("path", function(e, path, currentIndex)
    e.path = path or error("No path for Path component!")
    e.currentIndex = currentIndex or 1
  end)
  Concord.component("fetchJob", function(e, target, selector, amount, finishedCallBack)
    e.target = target or error("Fetch has no target!")
    e.selector = selector or error("Fetch has no selector!")
    e.amount = amount
    e.finishedCallBack = finishedCallBack
  end)
  Concord.component("healingJob")
  Concord.component("job", function(e, target, reserved, finished, allJobsOrNothing)
    e.target = target or nil -- Not all jobs need targets
    e.reserved = reserved or false
    e.finished = finished or false
    e.allJobsOrNothing = allJobsOrNothing or false
  end)
  Concord.component("worker", function(e, available) e.available = available or true end)
  Concord.component("bluePrintJob", function(e)
    e.materialsConsumed = {} 
    e.buildProgress = 0 -- 0/100
  end)
  Concord.component("constructionJob")
  Concord.component("collision")
  Concord.component("inventory", function(e, inventory)
    e.inventory = inventory or {}
  end)
  --Concord.component("Selector", function(e, selector) e.selector = selector or "" end)
  Concord.component("item", function(e, itemData, selector)
    e.itemData = itemData or {}
    e.selector = selector or error("Item needs data selector!")
  end)
  Concord.component("parent", function(e, parent)
    e.parent = parent or error("Parent component needs parent entity")
  end)

  Concord.component("children", function(e, children)
    e.children = children or error("Children component needs children(list of entities)")
  end)
  Concord.component("amount", function(e, amount) e.amount = amount or 0 end)
  Concord.component("light", function(e, color, power)
    e.color = color or { 1, 1, 1 }
    e.power = power or 64
  end)

end

return {
  initializeComponents = initializeComponents
}


