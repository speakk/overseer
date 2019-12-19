local components = require('libs/concord').components

--local camera = require('camera')

local CameraSystem = ECS.System("camera", {components.position, components.Camera})

function CameraSystem:init(camera)
  self.camera = camera
end

function CameraSystem:resize(w, h)
  self.camera:setWindow(0, 0, w, h)
  self.lightWorld:refreshScreenSize(w,h)
end

return CameraSystem
