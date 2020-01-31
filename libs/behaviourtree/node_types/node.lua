local _PACKAGE  = (...):match("^(.+)[%./][^%./]+"):gsub("[%./]?node_types", "")
local class     = require(_PACKAGE..'/middleclass')
local Registry  = require(_PACKAGE..'/registry')
local Node      = class('Node')

function Node:initialize(config)
  config = config or {}
  for k, v in pairs(config) do
    self[k] = v
  end

  if self.name ~= nil then
    Registry.register(self.name, self)
  end
end

function Node:start() end
function Node:finish() end
function Node:run() end

function Node:call_run(object)
  print("call_run", object)
  success = function() self:success() end
  fail = function()    self:fail() end
  running = function() self:running() end
  self:run(object)
  success, fail, running = nil,nil,nil
end

function Node:setObject(object)
  self.object = object
end

function Node:setControl(control)
  print("Setting control?", control)
  self.control = control
end

function Node:running()
  print("running")
  print("But no control?", self.control)
  if self.control then
    self.control:running(self)
  end
end

function Node:success()
  if self.control then
    self.control:success()
  end
end

function Node:fail()
  if self.control then
    self.control:fail()
  end
end

return Node
