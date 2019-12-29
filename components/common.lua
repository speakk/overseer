local Vector = require('libs.brinevector')

local function initializeComponents()
  local position = ECS.Component(function(e, vector) e.vector = vector or Vector(0, 0) end)
  ECS.Components.register("position", position)

  local velocity = ECS.Component(function(e, vector) e.vector = vector or Vector(0, 0) end)
  ECS.Components.register("velocity", velocity)

  local name = ECS.Component(function(e, name) e.name = name or "-" end)
  ECS.Components.register("name", name)

  local playerInput = ECS.Component()
  ECS.Components.register("playerInput", playerInput)

  local camera = ECS.Component()
  ECS.Components.register("camera", camera)

  local draw = ECS.Component(function(e, color, size)
    e.color = color or { 1, 0, 0 }
    e.size = size or Vector(32, 32)
  end)
  ECS.Components.register("draw", draw)

  local sprite = ECS.Component(function(e, selector)
    e.selector = selector or error("Sprite needs sprite selector")
    -- e.image = image or error("Sprite needs image")
    -- e.x = x or error("Sprite needs x image coordinate")
    -- e.y = y or error("Sprite needs y image coordinate")
  end)
  ECS.Components.register("sprite", sprite)

  local transparent = ECS.Component(function(e, amount)
    e.amount = amount or 0.5
  end)
  ECS.Components.register("transparent", transparent)

  local settler = ECS.Component(function(e, name)
    e.name = name or "Lucy"
    e.skills = {
      construction = 15
    }
  end)
  ECS.Components.register("settler", settler)

  local work = ECS.Component(function(e, job) e.job = job or nil end) -- Settler work
  ECS.Components.register("work", work)

  local path = ECS.Component(function(e, path, currentIndex)
    e.path = path or error("No path for Path component!")
    e.currentIndex = currentIndex or 1
  end)
  ECS.Components.register("path", path)

  local removeCallBack = ECS.Component(function(e, callBack)
    e.callBack = callBack or error "removeCallBack needs callBack"
  end)

  ECS.Components.register("removeCallBack", removeCallBack)

  local onMap = ECS.Component()
  ECS.Components.register("onMap", onMap)

  local fetchJob = ECS.Component(function(e, target, selector, amount)
    e.target = target or error("Fetch has no target!")
    e.selector = selector or error("Fetch has no selector!")
    e.amount = amount
  end)
  ECS.Components.register("fetchJob", fetchJob)

  local healingJob = ECS.Component()
  ECS.Components.register("healingJob", healingJob)


  local job = ECS.Component(function(e, jobType, finishedCallBack)
    print("Making job", jobType)
    e.jobType = jobType or error("Job needs jobType")
    e.target = nil
    e.reserved = false
    e.finished = false
    e.allJobsOrNothing = false
    e.finishedCallBack = finishedCallBack or nil
    e.isInaccessible = false
  end)
  ECS.Components.register("job", job)

  local worker = ECS.Component(function(e, available) e.available = available or true end)
  ECS.Components.register("worker", worker)

  local bluePrintJob = ECS.Component(function(e, constructionSpeed)
    e.constructionSpeed = constructionSpeed or 1
    e.materialsConsumed = {}
    e.buildProgress = 0 -- 0/100
  end)
  ECS.Components.register("bluePrintJob", bluePrintJob)

  local constructionJob = ECS.Component()
  ECS.Components.register("constructionJob", constructionJob)

  local collision = ECS.Component()
  ECS.Components.register("collision", collision)

  local inventory = ECS.Component(function(e, inventory)
    e.inventory = inventory or {}
  end)
  ECS.Components.register("inventory", inventory)

  local item = ECS.Component(function(e, itemData, selector)
    e.itemData = itemData or {}
    e.selector = selector or error("Item needs data selector!")
  end)
  ECS.Components.register("item", item)

  local parent = ECS.Component(function(e, parent)
    e.parent = parent or error("Parent component needs parent entity")
  end)
  ECS.Components.register("parent", parent)

  local children = ECS.Component(function(e, children)
    e.children = children or error("Children component needs children(list of entities)")
  end)
  ECS.Components.register("children", children)

  local amount = ECS.Component(function(e, amount) e.amount = amount or 0 end)
  ECS.Components.register("amount", amount)

  local light = ECS.Component(function(e, color, power)
    e.color = color or { 1, 1, 1 }
    e.power = power or 64
  end)
  ECS.Components.register("light", light)
end

return {
  initializeComponents = initializeComponents
}


