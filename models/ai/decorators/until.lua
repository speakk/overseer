local class = require('libs.middleclass')
local Decorator  = require('libs.behaviourtree.node_types.decorator')
local UntilDecorator = class('UntilDecorator', Decorator)

function UntilDecorator:fail()
  self.control:running()
end

function UntilDecorator:success()
  self.control:success()
end

function UntilDecorator:running()
  self.control:running()
end

return UntilDecorator

