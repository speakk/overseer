local Vector = require('libs.brinevector')

local function initializeComponents()
  ECS.Component("position", function(e, vector) e.vector = vector or Vector(0, 0) end)
  ECS.Component("velocity", function(e, vector) e.vector = vector or Vector(0, 0) end)
  ECS.Component("name", function(e, name) e.name = name or "-" end)
  ECS.Component("playerInput")
  ECS.Component("camera")
  ECS.Component("draw", function(e, color, size)
    e.color = color or { 1, 0, 0 }
    e.size = size or Vector(32, 32)
  end)
  ECS.Component("sprite", function(e, selector)
    e.selector = selector or error("Sprite needs sprite selector")
    -- e.image = image or error("Sprite needs image")
    -- e.x = x or error("Sprite needs x image coordinate")
    -- e.y = y or error("Sprite needs y image coordinate")
  end)
  ECS.Component("settler", function(e, name)
    e.name = name or "Lucy"
    e.skills = {
      construction = 15
    }
  end)
  ECS.Component("work", function(e, job) e.job = job or nil end) -- Settler work
  ECS.Component("path", function(e, path, currentIndex)
    e.path = path or error("No path for Path component!")
    e.currentIndex = currentIndex or 1
  end)
  ECS.Component("fetchJob", function(e, target, selector, amount, finishedCallBack)
    e.target = target or error("Fetch has no target!")
    e.selector = selector or error("Fetch has no selector!")
    e.amount = amount
    e.finishedCallBack = finishedCallBack
  end)
  ECS.Component("healingJob")
  ECS.Component("job", function(e, target, reserved, finished, allJobsOrNothing)
    e.target = target or nil -- Not all jobs need targets
    e.reserved = reserved or false
    e.finished = finished or false
    e.allJobsOrNothing = allJobsOrNothing or false
  end)
  ECS.Component("worker", function(e, available) e.available = available or true end)
  ECS.Component("bluePrintJob", function(e)
    e.materialsConsumed = {}
    e.buildProgress = 0 -- 0/100
  end)
  ECS.Component("constructionJob")
  ECS.Component("collision")
  ECS.Component("inventory", function(e, inventory)
    e.inventory = inventory or {}
  end)
  --ECS.Component("Selector", function(e, selector) e.selector = selector or "" end)
  print("Registering item")
  ECS.Component("item", function(e, itemData, selector)
    e.itemData = itemData or {}
    e.selector = selector or error("Item needs data selector!")
  end)
  ECS.Component("parent", function(e, parent)
    e.parent = parent or error("Parent component needs parent entity")
  end)

  ECS.Component("children", function(e, children)
    e.children = children or error("Children component needs children(list of entities)")
  end)
  ECS.Component("amount", function(e, amount) e.amount = amount or 0 end)
  ECS.Component("light", function(e, color, power)
    e.color = color or { 1, 1, 1 }
    e.power = power or 64
  end)

end

return {
  initializeComponents = initializeComponents
}


