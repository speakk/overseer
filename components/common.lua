local inspect = require('libs.inspect')
local lume = require('libs.lume')
local Path = require('libs.jumper.core.path')
local ItemUtils = require('utils.itemUtils')
local Node = require('libs.jumper.core.node')
local Vector = require('libs.brinevector')
local entityReferenceManager = require('models.entityReferenceManager')

local function initializeComponents()
  local position = ECS.Component(function(e, vector)
    e.vector = vector or Vector(0, 0)
    e.customSerialize = function() return { x = e.vector.x, y = e.vector.y } end
  end)
  -- function position:serialize() return { x = e.vector.x, y = e.vector.y } end
  -- function position:deserialize(data) self.vector = Vector(data.x, data.y) end
  position.customDeserialize = function(data)
    return position:__initialize(Vector(data.x, data.y))
  end
  ECS.Components.register("position", position)

  local velocity = ECS.Component(function(e, vector)
    e.vector = vector or Vector(0, 0)
    e.customSerialize = function() return { x = e.vector.x, y = e.vector.y } end
  end)
  velocity.customDeserialize = function(data)
    return velocity:__initialize(Vector(data.x, data.y))
  end
  ECS.Components.register("velocity", velocity)

  local debugName = ECS.Component(function(e, name)
    e.name = name or error("Debugname needs name")
    e.customSerialize = function() return { name = e.name } end
  end)
  debugName.customDeserialize = function(data)
    return debugName:__initialize(data.name)
  end
  ECS.Components.register("debugName", debugName)

  local name = ECS.Component(function(e, name)
    e.name = name or "-"
    e.customSerialize = function() return { name = e.name } end
  end)
  name.customDeserialize = function(data)
    return name:__initialize(data.name)
  end
  ECS.Components.register("name", name)

  local id = ECS.Component(function(e, id)
    e.id = id or error("Id needs id")
    e.customSerialize = function() return { id = e.id } end
  end)
  id.customDeserialize = function(data)
    return id:__initialize(data.id)
  end
  ECS.Components.register("id", id)

  local playerInput = ECS.Component()
  ECS.Components.register("playerInput", playerInput)

  local camera = ECS.Component()
  ECS.Components.register("camera", camera)

  local draw = ECS.Component(function(e, color, size)
    e.color = color or { 1, 0, 0 }
    e.size = size or Vector(32, 32)
    e.customSerialize = function() return { color = e.color, size = { x = size.x, y = size.y } } end
  end)
  draw.customDeserialize = function(data)
    return draw:__initialize(data.color, Vector(data.size.x, data.size.y))
  end
  ECS.Components.register("draw", draw)

  local sprite = ECS.Component(function(e, selector)
    e.selector = selector or error("Sprite needs sprite selector")
    -- e.image = image or error("Sprite needs image")
    -- e.x = x or error("Sprite needs x image coordinate")
    -- e.y = y or error("Sprite needs y image coordinate")
    e.customSerialize = function() return { selector = e.selector } end
  end)
  sprite.customDeserialize = function(data)
    return sprite:__initialize(data.selector)
  end
  ECS.Components.register("sprite", sprite)

  local transparent = ECS.Component(function(e, amount)
    e.amount = amount or 0.5
    e.customSerialize = function() return { amount = e.amount } end
  end)
  transparent.customDeserialize = function(data)
    return transparent:__initialize(data.amount)
  end
  ECS.Components.register("transparent", transparent)

  local settler = ECS.Component(function(e, name, skills)
    e.name = name or "Lucy"
    e.skills = skills or {
      construction = 15
    }
    e.customSerialize = function() return { name = e.name, skills = e.skills } end
  end)
  settler.customDeserialize = function(data)
    return settler:__initialize(data.name, data.skills)
  end
  ECS.Components.register("settler", settler)

  local work = ECS.Component(function(e, jobId)
    e.jobId = jobId or nil
    e.customSerialize = function()
      return { jobId = jobId }
      -- local serialized = {}
      -- if not e.jobId then error("Work has no job upon serializing") end
      -- serialized.jobId = e.job:get(ECS.Components.id).id
      -- return serialized 
    end
  end) -- Settler work

  work.customDeserialize = function(data)
    return work:__initialize(data.jobId)
    --local workC = work:__initialize()
    -- entityReferenceManager.registerReference(function(references) 
    --   workC.job = references[data.jobId]
    --   if not workC.job then error("Failed to initialize job for work on deserialize!") end
    -- end)
  end

  ECS.Components.register("work", work)

  local path = ECS.Component(function(e, path, currentIndex)
    e.path = path or error("No path for Path component!")
    e.currentIndex = currentIndex or 1
    e.customSerialize = function()
      return {
        pathNodes = lume.map(e.path._nodes, function(node) return { x = node._x, y = node._y } end),
        currentIndex = e.currentIndex
      }
    end
  end)
  path.customDeserialize = function(data)
    local gridPath = Path()
    --gridPath._nodes = data.pathNodes
    for _, node in ipairs(data.pathNodes) do
      gridPath:addNode(Node(node.x, node.y))
    end

    return path:__initialize(gridPath, data.currentIndex)
  end
  ECS.Components.register("path", path)

  local onMap = ECS.Component()
  ECS.Components.register("onMap", onMap)

  -- local fetchJob = ECS.Component(function(e, target, selector, amount)
  --   e.target = target
  --   e.selector = selector or error("Fetch has no selector!")
  --   e.amount = amount

  --   e.customSerialize = function()
  --     return {
  --       targetId = e.target:get(ECS.Components.id).id,
  --       selector = e.selector,
  --       amount = e.amount
  --     }
  --   end
  -- end)
  -- fetchJob.customDeserialize = function(data)
  --   local newFetch = fetchJob:__initialize(nil, data.selector, data.amount)
  --   entityReferenceManager.registerReference(function(references) 
  --     newFetch.target = references[data.targetId]
  --   end)
  --   return newFetch
  -- end
  -- ECS.Components.register("fetchJob", fetchJob)

  local fetchJob = ECS.Component(function(e, targetId, selector, amount)
    e.targetId = targetId
    --e.target = target
    e.selector = selector or error("Fetch has no selector!")
    e.amount = amount

    -- registerReference id, onInvalidate
    -- entityReferenceManager.registerReference(targetId, function()
    --   e.targetId = nil
    -- end)

    --entityReferenceManager.registerReference(function(references) 
    --  newFetch.target = references[data.targetId]
    --end)

    e.customSerialize = function()
      return {
        targetId = e.targetId,
        selector = e.selector,
        amount = e.amount
      }
    end
  end)
  fetchJob.customDeserialize = function(data)
    local newFetch = fetchJob:__initialize(data.targetId, data.selector, data.amount)
    --entityReferenceManager.registerReference(function(references) 
    --  newFetch.target = references[data.targetId]
    --end)
    return newFetch
  end
  ECS.Components.register("fetchJob", fetchJob)

  local healingJob = ECS.Component()
  ECS.Components.register("healingJob", healingJob)


  local job = ECS.Component(function(e, jobType)
    e.jobType = jobType or error("Job needs jobType")
    e.target = nil
    e.reserved = false
    e.finished = false
    e.allJobsOrNothing = false
    e.isInaccessible = false

    e.customSerialize = function() return { jobType = e.jobType } end
  end)
  job.customDeserialize = function(data)
    return job:__initialize(data.jobType)
  end
  ECS.Components.register("job", job)

  local worker = ECS.Component(function(e, available)
    e.available = available or true
    e.customSerialize = function() return { available = e.available } end
  end)
  worker.customDeserialize = function(data)
    return worker:__initialize(data.available)
  end
  ECS.Components.register("worker", worker)

  local bluePrintJob = ECS.Component(function(e, constructionSpeed, materialsConsumed, buildProgress)
    e.constructionSpeed = constructionSpeed or 1
    e.materialsConsumed = materialsConsumed or {}
    e.buildProgress = buildProgress or 0 -- 0/100
    e.customSerialize = function()
      return {
        constructionSpeed = e.constructionSpeed,
        materialsConsumed = e.materialsConsumed,
        buildProgress = e.buildProgress
      }
    end
  end)
  bluePrintJob.customDeserialize = function(data)
    return bluePrintJob:__initialize(data.constructionSpeed, data.materialsConsumed, data.buildProgress)
  end
  ECS.Components.register("bluePrintJob", bluePrintJob)

  local constructionJob = ECS.Component()
  ECS.Components.register("constructionJob", constructionJob)

  local collision = ECS.Component()
  ECS.Components.register("collision", collision)

  -- TODO: Add the methods into a metatable
  local inventory = ECS.Component(function(e, inventory)
    e.inventory = inventory or {}

    e.customSerialize = function()
      local inv = {}
      for _, entityId in ipairs(e.inventory) do
        table.insert(inv, entityId)
      end
      return { inventoryIds = inv }
    end

    e.findItem = function(e, selector) -- luacheck: ignore
      local itemId = lume.match(e.inventory, function(itemId)
        local item = entityReferenceManager.getEntity(itemId)
        return item:get(ECS.Components.item).selector == selector
      end)
      return itemId
    end

    e.popItem = function(e, selector, amount)
      local originalItemId = e:findItem(selector)
      print("Getting selection", selector, originalItem)
      if not originalItemId then return end
      local item, wasSplit = ItemUtils.splitItemStackIfNeeded(entityReferenceManager.getEntity(originalItemId), amount)
      if not wasSplit then
        lume.remove(e.inventory, item:get(ECS.Components.id).id)
      end

      return item
    end

    e.insertItem = function(e, itemId)
      print("Inserting id into inventory", itemId)
      local item = entityReferenceManager.getEntity(itemId)
      local amount = item:get(ECS.Components.amount).amount 
      local selector = item:get(ECS.Components.item).selector

      local existingId = lume.match(e.inventory, function(invItemId)
        local invItem = entityReferenceManager.getEntity(invItemId)
        return invItem:get(ECS.Components.item).selector == selector
      end)

      if existingId then
        local existing = entityReferenceManager.getEntity(existingId)
        local existingAmount = existing:get(ECS.Components.amount).amount 
        existingAmount = existingAmount + amount
        existing:get(ECS.Components.amount).amount = existingAmount
      else
        --entityReferenceManager.registerReference(item:get(ECS.Components.id).id, function(deletedId) e.inventory[deletedId] = nil end)
        table.insert(e.inventory, itemId)
      end
    end

  end)

  inventory.customDeserialize = function(data)
    local invC = inventory:__initialize()
    for _, entityId in ipairs(data.inventoryIds) do
      --entityReferenceManager.registerReference(entityId, function(deletedId) invC.inventory[deletedId] = nil end)
      table.insert(invC.inventory, entityId)
      --invC.insertItem(entityId)
      -- entityReferenceManager.registerReference(function(references) 
      --   local inv = invC.inventory
      --   local entity = references[entityId]
      --   table.insert(inv, entity)
      -- end)
    end

    return invC
  end
  ECS.Components.register("inventory", inventory)

  local item = ECS.Component(function(e, itemData, selector)
    e.itemData = itemData or {}
    e.selector = selector or error("Item needs data selector!")
    e.customSerialize = function()
      return { itemData = e.itemData, selector = e.selector }
    end
  end)
  item.customDeserialize = function(data)
    return item:__initialize(data.itemData, data.selector)
  end
  ECS.Components.register("item", item)

  local parent = ECS.Component(function(e, parentId)
    e.parentId = parentId
    e.customSerialize = function()
      return { parentId = e.parentId }
    end
  end)
  parent.customDeserialize = function(data)
    local parentC = parent:__initialize(data.parentId)
    --entityReferenceManager.registerReference(function(references) 
    --  parentC.parent = references[data.parentId]
    --end)

    return parentC
  end
  ECS.Components.register("parent", parent)

  local children = ECS.Component(function(e, children)
    e.children = children or {}
    e.customSerialize = function()
      local childIds = {}
      for _, entityId in ipairs(e.children) do
        table.insert(childIds, entityId)
      end
      return { childIds = childIds }
    end
  end)
  children.customDeserialize = function(data)
    local childIds = {}
    for _, entityId in ipairs(data.childIds) do
      table.insert(childIds, entityId)
    end
    return children:__initialize(childIds)
  end
  ECS.Components.register("children", children)

  local amount = ECS.Component(function(e, amount)
    e.amount = amount or 0
    e.customSerialize = function() return { amount = e.amount } end
  end)
  amount.customDeserialize = function(data) return amount:__initialize(data.amount) end
  ECS.Components.register("amount", amount)

  local speed = ECS.Component(function(e, speed)
    e.speed = speed or 0
    e.customSerialize = function() return { speed = e.speed } end
  end)
  speed.customDeserialize = function(data) return speed:__initialize(data.speed) end
  ECS.Components.register("speed", speed)

  local light = ECS.Component(function(e, color, power)
    e.color = color or { 1, 1, 1 }
    e.power = power or 64
    e.customSerialize = function()
      return { color = e.color, power = e.power }
    end
  end)
  light.customDeserialize = function(data)
    return light:__initialize(data.color, data.power)
  end
  ECS.Components.register("light", light)

  local rect = ECS.Component(function(e, x1, y1, x2, y2)
    e.x1 = x1
    e.y1 = y1
    e.x2 = x2
    e.y2 = y2
    e.customSerialize = function()
      return { x1 = e.x1, y1 = e.y1, x2 = e.x2, y2 = e.y2 }
    end
  end)

  rect.customDeserialize = function(data)
    return rect:__initialize(data.x1, data.y1, data.x2, data.y2)
  end

  ECS.Components.register("rect", rect)

  local zone = ECS.Component()
  ECS.Components.register("zone", zone)

  local color = ECS.Component(function(e, color)
    e.color = color or { 1, 1, 1, 1 }
    e.customSerialize = function()
      return { color = e.color }
    end
  end)

  color.customDeserialize = function(data)
    return color:__initialize(data.color)
  end

  ECS.Components.register("color", color)

end

return {
  initializeComponents = initializeComponents
}


