local Class = require 'libs.hump.class'
local lume = require('libs.lume') --luacheck: ignore

local WeightRunner = require 'weightRunner'
local tasks = require 'task'.loadTypes()

return Class {
  __includes = WeightRunner,
  init = function(self, entity, world)
    local weightTasks = {
      {
        behaviourTree = tasks.idle(entity, world), -- TODO: Obviously make this "eat"
        getPoints = function()
          return 100 - entity.satiety.value
        end
      }
    }

    WeightRunner.init(self, entity, world, weightTasks)
  end
}
