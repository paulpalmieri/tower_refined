-- enemy_projectile.lua
-- Enemy-fired projectiles: square bolts and mini-hexagons

local EnemyProjectile = Object:extend()

-- Square bolt style (cyan, rotating diamond)
local SQUARE_BOLT = {
    coreColor = {0.90, 1.00, 1.00},        -- White-cyan hot core
    bodyColor = {0.00, 1.00, 1.00},        -- Bright cyan
    glowColor = {0.00, 1.00, 1.00, 0.3},   -- Cyan glow
    trailColor = {0.00, 1.00, 1.00},       -- Cyan trail
    trailLength = 6,
}

-- Mini-hex style (orange, small hexagon)
local MINI_HEX = {
    coreColor = {1.00, 0.95, 0.85},        -- White-orange hot core
    bodyColor = {1.00, 0.50, 0.10},        -- Bright orange
    glowColor = {1.00, 0.50, 0.10, 0.3},   -- Orange glow
    trailColor = {1.00, 0.50, 0.10},       -- Orange trail
    trailLength = 5,
}

function EnemyProjectile:new(x, y, angle, speed, damage, projType)
    self.x = x
    self.y = y
    self.angle = angle
    self.speed = speed
    self.damage = damage
    self.projectileType = projType or "square_bolt"  -- "square_bolt" or "mini_hex"
    self.dead = false

    -- Velocity
    self.vx = math.cos(angle) * self.speed
    self.vy = math.sin(angle) * self.speed

    -- Trail positions
    self.trail = {}
    self.trailLength = self.projectileType == "mini_hex" and MINI_HEX.trailLength or SQUARE_BOLT.trailLength

    -- Visual rotation (spins while moving)
    self.rotation = 0
    self.rotationSpeed = self.projectileType == "mini_hex" and 3 or 8

    -- Size
    self.size = self.projectileType == "mini_hex" and HEXAGON_MINI_SIZE or SQUARE_PROJECTILE_SIZE

    -- Pulse animation
    self.pulse = 0

    -- Homing target (for mini_hex)
    self.target = nil
    self.lifetime = 0
    self.maxLifetime = 8  -- Mini-hexes expire after 8 seconds
end

function EnemyProjectile:update(dt)
    self.lifetime = self.lifetime + dt

    -- Store position for trail
    table.insert(self.trail, 1, {x = self.x, y = self.y})
    if #self.trail > self.trailLength then
        table.remove(self.trail)
    end

    -- Homing behavior for mini_hex
    if self.projectileType == "mini_hex" and self.target then
        local dx = self.target.x - self.x
        local dy = self.target.y - self.y
        local targetAngle = math.atan2(dy, dx)

        -- Calculate angle difference
        local angleDiff = targetAngle - self.angle
        -- Normalize to [-pi, pi]
        while angleDiff > math.pi do angleDiff = angleDiff - math.pi * 2 end
        while angleDiff < -math.pi do angleDiff = angleDiff + math.pi * 2 end

        -- Turn toward target
        local maxTurn = HEXAGON_MINI_TURN_RATE * dt
        if math.abs(angleDiff) < maxTurn then
            self.angle = targetAngle
        elseif angleDiff > 0 then
            self.angle = self.angle + maxTurn
        else
            self.angle = self.angle - maxTurn
        end

        -- Update velocity based on new angle
        self.vx = math.cos(self.angle) * self.speed
        self.vy = math.sin(self.angle) * self.speed
    end

    -- Move
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Visual rotation
    self.rotation = self.rotation + self.rotationSpeed * dt

    -- Pulse animation
    self.pulse = self.pulse + dt * 12

    -- Check bounds or lifetime
    local left, top, right, bottom = Camera:getBounds()
    local margin = 100
    if self.x < left - margin or self.x > right + margin or
       self.y < top - margin or self.y > bottom + margin then
        self.dead = true
    end

    if self.lifetime > self.maxLifetime then
        self.dead = true
    end
end

function EnemyProjectile:draw()
    local pulseAlpha = 0.8 + math.sin(self.pulse) * 0.2

    if self.projectileType == "mini_hex" then
        self:drawMiniHex(pulseAlpha)
    else
        self:drawSquareBolt(pulseAlpha)
    end
end

function EnemyProjectile:drawSquareBolt(pulseAlpha)
    -- Draw trail
    if #self.trail >= 2 then
        local prevX, prevY = self.x, self.y
        for i, pos in ipairs(self.trail) do
            local alpha = (1 - i / #self.trail) * 0.5
            local lineWidth = (1 - i / #self.trail) * 3 + 1
            love.graphics.setColor(SQUARE_BOLT.trailColor[1], SQUARE_BOLT.trailColor[2], SQUARE_BOLT.trailColor[3], alpha)
            love.graphics.setLineWidth(lineWidth)
            love.graphics.line(prevX, prevY, pos.x, pos.y)
            prevX, prevY = pos.x, pos.y
        end
        love.graphics.setLineWidth(1)
    end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)  -- Spinning diamond

    local size = self.size

    -- Outer glow
    love.graphics.setColor(SQUARE_BOLT.glowColor[1], SQUARE_BOLT.glowColor[2], SQUARE_BOLT.glowColor[3], 0.3 * pulseAlpha)
    love.graphics.rectangle("fill", -size * 1.5, -size * 1.5, size * 3, size * 3)

    -- Body (rotated square = diamond shape)
    love.graphics.setColor(SQUARE_BOLT.bodyColor[1], SQUARE_BOLT.bodyColor[2], SQUARE_BOLT.bodyColor[3], 0.8 * pulseAlpha)
    love.graphics.rectangle("fill", -size, -size, size * 2, size * 2)

    -- Core
    love.graphics.setColor(SQUARE_BOLT.coreColor[1], SQUARE_BOLT.coreColor[2], SQUARE_BOLT.coreColor[3], pulseAlpha)
    love.graphics.rectangle("fill", -size * 0.5, -size * 0.5, size, size)

    love.graphics.pop()
end

function EnemyProjectile:drawMiniHex(pulseAlpha)
    -- Draw trail
    if #self.trail >= 2 then
        local prevX, prevY = self.x, self.y
        for i, pos in ipairs(self.trail) do
            local alpha = (1 - i / #self.trail) * 0.4
            local lineWidth = (1 - i / #self.trail) * 2 + 1
            love.graphics.setColor(MINI_HEX.trailColor[1], MINI_HEX.trailColor[2], MINI_HEX.trailColor[3], alpha)
            love.graphics.setLineWidth(lineWidth)
            love.graphics.line(prevX, prevY, pos.x, pos.y)
            prevX, prevY = pos.x, pos.y
        end
        love.graphics.setLineWidth(1)
    end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)

    local size = self.size

    -- Build hexagon vertices
    local verts = {}
    for i = 0, 5 do
        local angle = (i / 6) * math.pi * 2
        table.insert(verts, math.cos(angle) * size)
        table.insert(verts, math.sin(angle) * size)
    end

    -- Build smaller hexagon for core
    local coreVerts = {}
    local coreSize = size * 0.5
    for i = 0, 5 do
        local angle = (i / 6) * math.pi * 2
        table.insert(coreVerts, math.cos(angle) * coreSize)
        table.insert(coreVerts, math.sin(angle) * coreSize)
    end

    -- Outer glow
    local glowVerts = {}
    local glowSize = size * 1.5
    for i = 0, 5 do
        local angle = (i / 6) * math.pi * 2
        table.insert(glowVerts, math.cos(angle) * glowSize)
        table.insert(glowVerts, math.sin(angle) * glowSize)
    end
    love.graphics.setColor(MINI_HEX.glowColor[1], MINI_HEX.glowColor[2], MINI_HEX.glowColor[3], 0.3 * pulseAlpha)
    love.graphics.polygon("fill", glowVerts)

    -- Body
    love.graphics.setColor(MINI_HEX.bodyColor[1], MINI_HEX.bodyColor[2], MINI_HEX.bodyColor[3], 0.8 * pulseAlpha)
    love.graphics.polygon("fill", verts)

    -- Core
    love.graphics.setColor(MINI_HEX.coreColor[1], MINI_HEX.coreColor[2], MINI_HEX.coreColor[3], pulseAlpha)
    love.graphics.polygon("fill", coreVerts)

    love.graphics.pop()
end

function EnemyProjectile:checkTowerCollision(towerObj)
    local dx = self.x - towerObj.x
    local dy = self.y - towerObj.y
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Tower collision radius
    local collisionDist = TOWER_PAD_SIZE * BLOB_PIXEL_SIZE * TURRET_SCALE + self.size

    return dist < collisionDist
end

return EnemyProjectile
