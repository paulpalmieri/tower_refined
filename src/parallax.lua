-- parallax.lua
-- Simple grid background with gravity well effect

local Parallax = {}

function Parallax:init()
    self:reset()
end

function Parallax:reset()
    -- Nothing to reset
end

function Parallax:update(dt)
    -- Grid is static, nothing to update
    local _ = dt  -- Silence unused parameter warning
end

-- Draw background fill
function Parallax:drawBackground()
    local left, top = Camera:getBounds()

    love.graphics.setColor(NEON_BACKGROUND[1], NEON_BACKGROUND[2], NEON_BACKGROUND[3])
    love.graphics.rectangle("fill", left - 100, top - 100, WINDOW_WIDTH + 200, WINDOW_HEIGHT + 200)
end

-- Calculate gravity well displacement
function Parallax:getGravityDisplacement(pointX, pointY, playerX, playerY)
    if not GRAVITY_WELL_ENABLED or not playerX or not playerY then
        return 0, 0
    end

    local dx = pointX - playerX
    local dy = pointY - playerY
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist < 1 then dist = 1 end
    if dist > GRAVITY_WELL_RADIUS then
        return 0, 0
    end

    local falloff = 1 - (dist / GRAVITY_WELL_RADIUS)
    local pushStrength = GRAVITY_WELL_STRENGTH * falloff * falloff

    return (dx / dist) * pushStrength, (dy / dist) * pushStrength
end

-- Draw grid directly in world space
function Parallax:drawGrid()
    local left, top, right, bottom = Camera:getBounds()

    local playerX, playerY = nil, nil
    if tower then
        playerX = tower.x
        playerY = tower.y
    end

    love.graphics.setColor(NEON_GRID[1], NEON_GRID[2], NEON_GRID[3], 0.35)
    love.graphics.setLineWidth(GRID_LINE_WIDTH)

    local gridSize = GRID_SIZE
    local margin = gridSize * 2  -- Extra margin for gravity well displacement
    local gridStartX = math.floor((left - margin) / gridSize) * gridSize
    local gridStartY = math.floor((top - margin) / gridSize) * gridSize
    local gridEndX = right + margin
    local gridEndY = bottom + margin

    if GRAVITY_WELL_ENABLED and playerX then
        -- Vertical line segments with gravity displacement
        for x = gridStartX, gridEndX, gridSize do
            for y = gridStartY, gridEndY, gridSize do
                local dispX1, dispY1 = self:getGravityDisplacement(x, y, playerX, playerY)
                local dispX2, dispY2 = self:getGravityDisplacement(x, y + gridSize, playerX, playerY)
                love.graphics.line(x + dispX1, y + dispY1, x + dispX2, y + gridSize + dispY2)
            end
        end

        -- Horizontal line segments with gravity displacement
        for y = gridStartY, gridEndY, gridSize do
            for x = gridStartX, gridEndX, gridSize do
                local dispX1, dispY1 = self:getGravityDisplacement(x, y, playerX, playerY)
                local dispX2, dispY2 = self:getGravityDisplacement(x + gridSize, y, playerX, playerY)
                love.graphics.line(x + dispX1, y + dispY1, x + gridSize + dispX2, y + dispY2)
            end
        end
    else
        -- Simple straight lines (faster)
        for x = gridStartX, gridEndX, gridSize do
            love.graphics.line(x, top - margin, x, bottom + margin)
        end
        for y = gridStartY, gridEndY, gridSize do
            love.graphics.line(left - margin, y, right + margin, y)
        end
    end

    love.graphics.setLineWidth(1)
end

return Parallax
