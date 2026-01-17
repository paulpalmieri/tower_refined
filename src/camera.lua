-- camera.lua
-- Simple follow camera for Vampire Survivors style gameplay

local Camera = {}

-- Camera position (world coordinates of camera center)
Camera.x = 0
Camera.y = 0

-- Initialize camera centered on a position
function Camera:init(x, y)
    self.x = x or CENTER_X
    self.y = y or CENTER_Y
end

-- Update camera to follow target instantly
function Camera:update(targetX, targetY)
    self.x = targetX
    self.y = targetY
end

-- Apply camera transformation (call before drawing world objects)
function Camera:apply()
    love.graphics.push()
    -- Translate so camera center is at screen center
    love.graphics.translate(CENTER_X - self.x, CENTER_Y - self.y)
end

-- Reset camera transformation (call after drawing world objects)
function Camera:reset()
    love.graphics.pop()
end

-- Convert screen coordinates to world coordinates
function Camera:screenToWorld(screenX, screenY)
    local worldX = screenX - CENTER_X + self.x
    local worldY = screenY - CENTER_Y + self.y
    return worldX, worldY
end

-- Convert world coordinates to screen coordinates
function Camera:worldToScreen(worldX, worldY)
    local screenX = worldX - self.x + CENTER_X
    local screenY = worldY - self.y + CENTER_Y
    return screenX, screenY
end

-- Get visible world bounds (left, top, right, bottom)
function Camera:getBounds()
    local left = self.x - CENTER_X
    local top = self.y - CENTER_Y
    local right = self.x + CENTER_X
    local bottom = self.y + CENTER_Y
    return left, top, right, bottom
end

-- Get visible world rect (x, y, width, height)
function Camera:getRect()
    local left, top, right, bottom = self:getBounds()
    return left, top, right - left, bottom - top
end

return Camera
