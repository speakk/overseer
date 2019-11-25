local camera = {
  x = 0,
  y = 0,
  scale = 1,
  rotation = 0
}

function camera:set()
  love.graphics.push()
  love.graphics.rotate(-self.rotation)
  love.graphics.scale(1 / self.scale, 1 / self.scale)
  love.graphics.translate(-self.x, -self.y)
end

function camera:unset()
  love.graphics.pop()
end

function camera:rotate(dr)
  self.rotation = self.rotation + dr
end

-- function camera:scale(scale)
--   scale = scale or 1
--   self.scale = scale * scale
-- end

function camera:setPosition(x, y)
  self.x = x or self.x
  self.y = y or self.y
end

function camera:setScale(scale)
  self.scale = scale or self.scale
end

return camera
