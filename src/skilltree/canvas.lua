-- src/skilltree/canvas.lua
-- Pan/zoom camera system for skill tree

local Object = require "lib.classic"
local lume = require "lib.lume"

local Canvas = Object:extend()

-- Zoom constraints
local MIN_ZOOM = 0.5
local MAX_ZOOM = 2.0
local ZOOM_SPEED = 0.15

-- Pan constraints (extra margin beyond grid bounds)
local PAN_MARGIN = 200

function Canvas:new(gridSize, cellSize)
    self.gridSize = gridSize
    self.cellSize = cellSize

    -- Camera position (world coordinates of screen center)
    self.x = (gridSize / 2) * cellSize
    self.y = (gridSize / 2) * cellSize

    -- Zoom level
    self.zoom = 1.0
    self.targetZoom = 1.0

    -- Drag state
    self.dragging = false
    self.dragStartX = 0
    self.dragStartY = 0
    self.camStartX = 0
    self.camStartY = 0
end

function Canvas:update(dt)
    -- Smooth zoom interpolation
    if self.zoom ~= self.targetZoom then
        self.zoom = self.zoom + (self.targetZoom - self.zoom) * 10 * dt
        if math.abs(self.zoom - self.targetZoom) < 0.01 then
            self.zoom = self.targetZoom
        end
    end

    -- Clamp camera position
    self:clampPosition()
end

function Canvas:clampPosition()
    local worldSize = self.gridSize * self.cellSize
    local minX = -PAN_MARGIN
    local maxX = worldSize + PAN_MARGIN
    local minY = -PAN_MARGIN
    local maxY = worldSize + PAN_MARGIN

    self.x = lume.clamp(self.x, minX, maxX)
    self.y = lume.clamp(self.y, minY, maxY)
end

function Canvas:screenToWorld(screenX, screenY)
    local centerX = WINDOW_WIDTH / 2
    local centerY = WINDOW_HEIGHT / 2

    local worldX = (screenX - centerX) / self.zoom + self.x
    local worldY = (screenY - centerY) / self.zoom + self.y

    return worldX, worldY
end

function Canvas:worldToScreen(worldX, worldY)
    local centerX = WINDOW_WIDTH / 2
    local centerY = WINDOW_HEIGHT / 2

    local screenX = (worldX - self.x) * self.zoom + centerX
    local screenY = (worldY - self.y) * self.zoom + centerY

    return screenX, screenY
end

function Canvas:applyTransform()
    love.graphics.push()
    love.graphics.translate(WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2)
    love.graphics.scale(self.zoom, self.zoom)
    love.graphics.translate(-self.x, -self.y)
end

function Canvas:resetTransform()
    love.graphics.pop()
end

function Canvas:startDrag(screenX, screenY)
    self.dragging = true
    self.dragStartX = screenX
    self.dragStartY = screenY
    self.camStartX = self.x
    self.camStartY = self.y
end

function Canvas:drag(screenX, screenY)
    if not self.dragging then
        return
    end

    local dx = (screenX - self.dragStartX) / self.zoom
    local dy = (screenY - self.dragStartY) / self.zoom

    self.x = self.camStartX - dx
    self.y = self.camStartY - dy
end

function Canvas:endDrag()
    self.dragging = false
end

function Canvas:adjustZoom(delta)
    self.targetZoom = lume.clamp(
        self.targetZoom + delta * ZOOM_SPEED,
        MIN_ZOOM,
        MAX_ZOOM
    )
end

function Canvas:setZoom(zoom)
    self.targetZoom = lume.clamp(zoom, MIN_ZOOM, MAX_ZOOM)
    self.zoom = self.targetZoom
end

function Canvas:centerOn(worldX, worldY)
    self.x = worldX
    self.y = worldY
end

function Canvas:reset(gridSize, cellSize)
    self.x = (gridSize / 2) * cellSize
    self.y = (gridSize / 2) * cellSize
    self.zoom = 1.0
    self.targetZoom = 1.0
    self.dragging = false
end

return Canvas
