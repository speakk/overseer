local commonComponents = require('components/common')

--local camera = require('camera')

local CameraSystem = ECS.System({commonComponents.Position, commonComponents.Camera})

function CameraSystem:init(camera)
  self.camera = camera
end

function CameraSystem:resize(w, h)
  self.camera:setWindow(0, 0, w, h)
  self.lightWorld:refreshScreenSize(w,h)
end

return CameraSystem
