local inspect = require('libs.inspect')
local Path = require('libs.jumper.core.path')
local Vector = require('libs.brinevector')

local function initializeComponents(entityReferenceManager)
  local position = ECS.Component(function(e, vector)
    e.vector = vector or Vector(0, 0)
    e.serialize = function() return { x = e.vector.x, y = e.vector.y } end
  end)
  position.deserialize = function(data) return Vector(data.x, data.y) end
  ECS.Components.register("position", position)

  local velocity = ECS.Component(function(e, vector)
    e.vector = vector or Vector(0, 0)
    e.serialize = function() return { x = e.vector.x, y = e.vector.y } end
  end)
  velocity.deserialize = function(data) return Vector(data.x, data.y) end
  ECS.Components.register("velocity", velocity)

  local name = ECS.Component(function(e, name)
    e.name = name or "-"
    e.serialize = function() return { name = e.name } end
  end)
  name.deserialize = function(data) return data.name end
  ECS.Components.register("name", name)

  local id = ECS.Component(function(e, id)
    e.id = id or error("Id needs id")
    e.serialize = function() return { id = e.id } end
  end)
  id.deserialize = function(data) return data.id end
  ECS.Components.register("id", id)

  local playerInput = ECS.Component()
  ECS.Components.register("playerInput", playerInput)

  local camera = ECS.Component()
  ECS.Components.register("camera", camera)

  local draw = ECS.Component(function(e, color, size)
    e.color = color or { 1, 0, 0 }
    e.size = size or Vector(32, 32)
    e.serialize = function() return { color = e.color, size = { x = size.x, y = size.y } } end
  end)
  draw.deserialize = function(data) return data.color, Vector(data.size.x, data.size.y) end
  ECS.Components.register("draw", draw)

  local sprite = ECS.Component(function(e, selector)
    e.selector = selector or error("Sprite needs sprite selector")
    -- e.image = image or error("Sprite needs image")
    -- e.x = x or error("Sprite needs x image coordinate")
    -- e.y = y or error("Sprite needs y image coordinate")
    e.serialize = function() return { selector = e.selector } end
  end)
  sprite.deserialize = function(data) return data.selector end
  ECS.Components.register("sprite", sprite)

  local transparent = ECS.Component(function(e, amount)
    e.amount = amount or 0.5
    e.serialize = function() return { amount = e.amount } end
  end)
  transparent.deserialize = function(data) return data.amount end
  ECS.Components.register("transparent", transparent)

  local settler = ECS.Component(function(e, name, skills)
    e.name = name or "Lucy"
    e.skills = skills or {
      construction = 15
    }
    e.serialize = function() return { name = e.name, skills = e.skills } end
  end)
  settler.deserialize = function(data) return data.name, data.skills end
  ECS.Components.register("settler", settler)

  local work = ECS.Component(function(e, job)
    e.job = job or nil
    e.serialize = function()
      local serialized = {}
      if job then serialized.jobId = job:get(ECS.Component.id).id end
      return serialized 
    end
  end) -- Settler work

  work.deserialize = function(data)
    local job
    entityReferenceManager.registerReference(function(references) 
      job = references[data.jobId]
    end)

    return job
  end

  ECS.Components.register("work", work)

  local path = ECS.Component(function(e, path, currentIndex)
    e.path = path or error("No path for Path component!")
    e.currentIndex = currentIndex or 1
    e.serialize = function() return { pathNodes = e.path._nodes } end
  end)
  path.deserialize = function(data)
    local path = Path()
    path._nodex = data.pathNodes

    return path, data.currentIndex
  end
  ECS.Components.register("path", path)

  -- TODO: XXX Remove, callback in component
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

    e.serialize = function()
      return {
        targetId = e.target:get(ECS.Components.id).id,
        selector = e.selector,
        amount = e.amount
      }
    end
  end)
  fetchJob.deserialize = function(data)
    local target
    entityReferenceManager.registerReference(function(references) 
      target = references[data.targetId]
    end)

    return target, selector, amount
  end
  ECS.Components.register("fetchJob", fetchJob)

  local healingJob = ECS.Component()
  ECS.Components.register("healingJob", healingJob)


  -- TODO: XXX finishedCallBack
  local job = ECS.Component(function(e, jobType, finishedCallBack)
    print("Making job", jobType)
    e.jobType = jobType or error("Job needs jobType")
    e.target = nil
    e.reserved = false
    e.finished = false
    e.allJobsOrNothing = false
    e.finishedCallBack = finishedCallBack or nil
    e.isInaccessible = false

    e.serialize = function() return { jobType = e.jobType } end
  end)
  job.deserialize = function(data)
    return data.jobType
  end
  ECS.Components.register("job", job)

  local worker = ECS.Component(function(e, available)
    e.available = available or true
    e.serialize = function() return { available = e.available } end
  end)
  worker.deserialize = function(data)
    return data.available
  end
  ECS.Components.register("worker", worker)

  local bluePrintJob = ECS.Component(function(e, constructionSpeed, materialsConsumed, buildProgress)
    e.constructionSpeed = constructionSpeed or 1
    e.materialsConsumed = {} or materialsConsumed
    e.buildProgress = 0 or buildProgress -- 0/100
    e.serialize = function()
      return {
        constructionSpeed = e.constructionSpeed,
        materialsConsumed = e.materialsConsumed,
        buildProgress = e.buildProgress
      }
    end
  end)
  bluePrintJob.deserialize = function(data)
    return data.constructionSpeed, data.materialsConsumed, data.buildProgress
  end
  ECS.Components.register("bluePrintJob", bluePrintJob)

  local constructionJob = ECS.Component()
  ECS.Components.register("constructionJob", constructionJob)

  local collision = ECS.Component()
  ECS.Components.register("collision", collision)

  local inventory = ECS.Component(function(e, inventory)
    e.inventory = inventory or {}
    e.serialize = function()
      local inv = {}
      for _, entity in ipairs(e.inventory) do
        table.insert(inv, entity:get(ECS.Components.id).id)
      end
      return { inventoryIds = inv }
    end
  end)
  inventory.deserialize = function(data)
    local inv = {}
    for _, entityId in ipairs(data.inventoryIds) do
      entityReferenceManager.registerReference(function(references) 
        local entity = references[entityId]
        table.insert(inv, entity) -- Probably not gonna work
      end)
    end

    return inv
  end
  ECS.Components.register("inventory", inventory)

  local item = ECS.Component(function(e, itemData, selector)
    e.itemData = itemData or {}
    e.selector = selector or error("Item needs data selector!")
    e.serialize = function()
      return { itemData = e.itemData, selector = e.selector }
    end
  end)
  item.deserialize = function(data)
    return data.itemData, data.selector
  end
  ECS.Components.register("item", item)

  local parent = ECS.Component(function(e, parent)
    e.parent = parent or error("Parent component needs parent entity")
    e.serialize = function()
      return {
        parentId = e.parent:get(ECS.Components.id).id,
      }
    end
  end)
  parent.deserialize = function(data)
    local parent
    entityReferenceManager.registerReference(function(references) 
      parent = references[entityId]
    end)

    return parent
  end
  ECS.Components.register("parent", parent)

  local children = ECS.Component(function(e, children)
    e.children = children or error("Children component needs children(list of entities)")
    e.serialize = function()
      local childIds = {}
      for _, entity in ipairs(e.children) do
        table.insert(childIds, entity:get(ECS.Components.id).id)
      end
      return { childIds = childIds }
    end
  end)
  children.deserialize = function(data)
    local children = {}
    for _, entityId in ipairs(data.childIds) do
      entityReferenceManager.registerReference(function(references) 
        local entity = references[entityId]
        table.insert(children, entity) -- Probably not gonna work
      end)
    end

    return children
  end
  ECS.Components.register("children", children)

  local amount = ECS.Component(function(e, amount)
    e.amount = amount or 0
    e.serialize = function()
      return { amount = e.amount }
    end
  end)
  amount.deserialize = function(data) return data.amount end
  ECS.Components.register("amount", amount)

  local light = ECS.Component(function(e, color, power)
    e.color = color or { 1, 1, 1 }
    e.power = power or 64
    e.serialize = function()
      return { color = e.color, power = e.power }
    end
  end)
  light.deserialize = function(data)
    return data.color, data.power
  end
  ECS.Components.register("light", light)

  local serialize = ECS.Component()
  ECS.Components.register("serialize", serialize)
end

return {
  initializeComponents = initializeComponents
}


