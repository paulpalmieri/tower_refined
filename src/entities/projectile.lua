-- projectile.lua
-- Neon Energy Bolts with trailing lines

local Projectile = Object:extend()

-- Neon energy bolt style (scaled ~0.67x)
local ENERGY_BOLT = {
    -- Core colors
    coreColor = {0.90, 1.00, 0.90},        -- White-green hot core
    bodyColor = {0.00, 1.00, 0.00},        -- Bright neon green
    glowColor = {0.00, 1.00, 0.00, 0.3},   -- Green glow

    -- Trail
    trailColor = {0.00, 1.00, 0.00},       -- Neon green trail
    trailLength = 8,                        -- Trail segments

    -- Size
    coreSize = 2,
    bodySize = 3,
    glowSize = 7,
}

-- Plasma missile style (uses PLASMA_COLOR and PLASMA_CORE_COLOR from config, scaled ~0.67x)
local PLASMA_BOLT = {
    trailLength = 12,                       -- Longer trail
    coreSize = 6,                           -- ~3x normal (scaled)
    bodySize = 10,                          -- ~3x normal (scaled)
    glowSize = 20,                          -- ~3x normal (scaled)
}

-- Drone bolt style (purple, smaller than main turret, scaled ~0.67x)
local DRONE_BOLT = {
    coreColor = {0.95, 0.85, 1.00},         -- White-purple hot core
    bodyColor = {0.70, 0.20, 1.00},         -- Bright purple
    glowColor = {0.70, 0.20, 1.00, 0.3},    -- Purple glow
    trailColor = {0.70, 0.20, 1.00},        -- Purple trail
    trailLength = 6,                         -- Shorter trail
    coreSize = 1,
    bodySize = 3,
    glowSize = 5,
}

function Projectile:new(x, y, angle, speed, damage)
    self.x = x
    self.y = y
    self.angle = angle
    self.speed = speed or PROJECTILE_SPEED
    self.damage = damage or PROJECTILE_DAMAGE
    self.dead = false

    -- Previous position for ray-based collision detection
    self.prevX = x
    self.prevY = y

    -- Velocity
    self.vx = math.cos(angle) * self.speed
    self.vy = math.sin(angle) * self.speed

    -- Trail positions (for visual effect)
    self.trail = {}
    self.trailLength = ENERGY_BOLT.trailLength

    -- Size
    self.size = ENERGY_BOLT.bodySize

    -- Pulse animation
    self.pulse = 0
end

function Projectile:update(dt)
    -- Store previous position for ray-based collision detection
    self.prevX = self.x
    self.prevY = self.y

    -- Store position for trail
    table.insert(self.trail, 1, {x = self.x, y = self.y})
    if #self.trail > self.trailLength then
        table.remove(self.trail)
    end

    -- Move
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Pulse animation
    self.pulse = self.pulse + dt * 15

    -- Check bounds (off-screen = dead) using camera bounds with margin
    local left, top, right, bottom = Camera:getBounds()
    local margin = 100  -- Extra margin before dying
    if self.x < left - margin or self.x > right + margin or self.y < top - margin or self.y > bottom + margin then
        self.dead = true
    end
end

function Projectile:draw()
    local pulseAlpha = 0.8 + math.sin(self.pulse) * 0.2

    -- Choose style based on projectile type
    if self.isPlasma then
        self:drawPlasma(pulseAlpha)
    elseif self.isDrone then
        self:drawDroneBolt(pulseAlpha)
    else
        self:drawEnergyBolt(pulseAlpha)
    end
end

function Projectile:drawEnergyBolt(pulseAlpha)
    local width = 19
    local height = 4

    -- Draw segmented fading trail
    if #self.trail >= 2 then
        local prevX, prevY = self.x, self.y
        for i, pos in ipairs(self.trail) do
            local alpha = (1 - i / #self.trail) * 0.5
            local lineWidth = (1 - i / #self.trail) * 4 + 1
            love.graphics.setColor(ENERGY_BOLT.bodyColor[1], ENERGY_BOLT.bodyColor[2], ENERGY_BOLT.bodyColor[3], alpha)
            love.graphics.setLineWidth(lineWidth)
            love.graphics.line(prevX, prevY, pos.x, pos.y)
            prevX, prevY = pos.x, pos.y
        end
        love.graphics.setLineWidth(1)
    end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)

    -- Rectangular glow layers (bloom will soften these)
    love.graphics.setColor(ENERGY_BOLT.bodyColor[1], ENERGY_BOLT.bodyColor[2], ENERGY_BOLT.bodyColor[3], 0.15)
    love.graphics.rectangle("fill", -width/2 - 6, -height/2 - 4, width + 12, height + 8)
    love.graphics.setColor(ENERGY_BOLT.bodyColor[1], ENERGY_BOLT.bodyColor[2], ENERGY_BOLT.bodyColor[3], 0.3)
    love.graphics.rectangle("fill", -width/2 - 3, -height/2 - 2, width + 6, height + 4)

    -- Solid core
    love.graphics.setColor(ENERGY_BOLT.coreColor[1], ENERGY_BOLT.coreColor[2], ENERGY_BOLT.coreColor[3], 1)
    love.graphics.rectangle("fill", -width/2, -height/2, width, height)

    love.graphics.pop()
end

function Projectile:drawDroneBolt(pulseAlpha)
    -- Purple energy bolt for drone projectiles (smaller than main turret)

    -- ===================
    -- 1. DRAW TRAIL
    -- ===================
    if #self.trail >= 2 then
        local trailPoints = {self.x, self.y}
        for _, pos in ipairs(self.trail) do
            table.insert(trailPoints, pos.x)
            table.insert(trailPoints, pos.y)
        end

        -- Outer glow trail
        love.graphics.setColor(DRONE_BOLT.trailColor[1], DRONE_BOLT.trailColor[2], DRONE_BOLT.trailColor[3], 0.15)
        love.graphics.setLineWidth(4)
        love.graphics.line(trailPoints)

        -- Mid glow trail
        love.graphics.setColor(DRONE_BOLT.trailColor[1], DRONE_BOLT.trailColor[2], DRONE_BOLT.trailColor[3], 0.3)
        love.graphics.setLineWidth(2)
        love.graphics.line(trailPoints)

        -- Core trail
        love.graphics.setColor(DRONE_BOLT.trailColor[1], DRONE_BOLT.trailColor[2], DRONE_BOLT.trailColor[3], 0.6)
        love.graphics.setLineWidth(1)
        love.graphics.line(trailPoints)

        love.graphics.setLineWidth(1)
    end

    -- ===================
    -- 2. DRAW BOLT HEAD
    -- ===================

    -- Outer glow
    love.graphics.setColor(DRONE_BOLT.glowColor[1], DRONE_BOLT.glowColor[2], DRONE_BOLT.glowColor[3], 0.3 * pulseAlpha)
    love.graphics.circle("fill", self.x, self.y, DRONE_BOLT.glowSize)

    -- Body glow
    love.graphics.setColor(DRONE_BOLT.bodyColor[1], DRONE_BOLT.bodyColor[2], DRONE_BOLT.bodyColor[3], 0.7 * pulseAlpha)
    love.graphics.circle("fill", self.x, self.y, DRONE_BOLT.bodySize)

    -- Core (white-hot center)
    love.graphics.setColor(DRONE_BOLT.coreColor[1], DRONE_BOLT.coreColor[2], DRONE_BOLT.coreColor[3], pulseAlpha)
    love.graphics.circle("fill", self.x, self.y, DRONE_BOLT.coreSize)

    -- ===================
    -- 3. DRAW DIRECTIONAL TIP
    -- ===================
    local tipLength = 3
    local tipWidth = 1

    local tipX = self.x + math.cos(self.angle) * tipLength
    local tipY = self.y + math.sin(self.angle) * tipLength

    local perpAngle = self.angle + math.pi / 2
    local baseX1 = self.x + math.cos(perpAngle) * tipWidth
    local baseY1 = self.y + math.sin(perpAngle) * tipWidth
    local baseX2 = self.x - math.cos(perpAngle) * tipWidth
    local baseY2 = self.y - math.sin(perpAngle) * tipWidth

    love.graphics.setColor(DRONE_BOLT.coreColor[1], DRONE_BOLT.coreColor[2], DRONE_BOLT.coreColor[3], 0.8 * pulseAlpha)
    love.graphics.polygon("fill", tipX, tipY, baseX1, baseY1, baseX2, baseY2)
end

function Projectile:drawPlasma(pulseAlpha)
    -- Intense purple plasma missile with larger sizes

    -- ===================
    -- 1. DRAW TRAIL (plasma energy)
    -- ===================
    if #self.trail >= 2 then
        -- Build trail line points
        local trailPoints = {self.x, self.y}
        for _, pos in ipairs(self.trail) do
            table.insert(trailPoints, pos.x)
            table.insert(trailPoints, pos.y)
        end

        -- Outer glow trail (very wide purple)
        love.graphics.setColor(PLASMA_COLOR[1], PLASMA_COLOR[2], PLASMA_COLOR[3], 0.2)
        love.graphics.setLineWidth(16)
        love.graphics.line(trailPoints)

        -- Mid glow trail
        love.graphics.setColor(PLASMA_COLOR[1], PLASMA_COLOR[2], PLASMA_COLOR[3], 0.4)
        love.graphics.setLineWidth(8)
        love.graphics.line(trailPoints)

        -- Core trail (white-purple)
        love.graphics.setColor(PLASMA_CORE_COLOR[1], PLASMA_CORE_COLOR[2], PLASMA_CORE_COLOR[3], 0.7)
        love.graphics.setLineWidth(4)
        love.graphics.line(trailPoints)

        love.graphics.setLineWidth(1)
    end

    -- ===================
    -- 2. DRAW PLASMA HEAD (intense glow)
    -- ===================

    -- Extra outer glow (for "intense" effect)
    love.graphics.setColor(PLASMA_COLOR[1], PLASMA_COLOR[2], PLASMA_COLOR[3], 0.15 * pulseAlpha)
    love.graphics.circle("fill", self.x, self.y, PLASMA_BOLT.glowSize * 1.5)

    -- Outer glow
    love.graphics.setColor(PLASMA_COLOR[1], PLASMA_COLOR[2], PLASMA_COLOR[3], 0.3 * pulseAlpha)
    love.graphics.circle("fill", self.x, self.y, PLASMA_BOLT.glowSize)

    -- Body glow
    love.graphics.setColor(PLASMA_COLOR[1], PLASMA_COLOR[2], PLASMA_COLOR[3], 0.8 * pulseAlpha)
    love.graphics.circle("fill", self.x, self.y, PLASMA_BOLT.bodySize)

    -- Core (white-purple hot center)
    love.graphics.setColor(PLASMA_CORE_COLOR[1], PLASMA_CORE_COLOR[2], PLASMA_CORE_COLOR[3], pulseAlpha)
    love.graphics.circle("fill", self.x, self.y, PLASMA_BOLT.coreSize)

    -- ===================
    -- 3. DRAW DIRECTIONAL TIP (larger, scaled ~0.67x)
    -- ===================
    local tipLength = 12
    local tipWidth = 6

    local tipX = self.x + math.cos(self.angle) * tipLength
    local tipY = self.y + math.sin(self.angle) * tipLength

    local perpAngle = self.angle + math.pi / 2
    local baseX1 = self.x + math.cos(perpAngle) * tipWidth
    local baseY1 = self.y + math.sin(perpAngle) * tipWidth
    local baseX2 = self.x - math.cos(perpAngle) * tipWidth
    local baseY2 = self.y - math.sin(perpAngle) * tipWidth

    -- Outer tip glow
    love.graphics.setColor(PLASMA_COLOR[1], PLASMA_COLOR[2], PLASMA_COLOR[3], 0.5 * pulseAlpha)
    love.graphics.polygon("fill", tipX, tipY, baseX1, baseY1, baseX2, baseY2)

    -- Inner tip (white-hot)
    local innerTipLength = 8
    local innerTipWidth = 3
    local innerTipX = self.x + math.cos(self.angle) * innerTipLength
    local innerTipY = self.y + math.sin(self.angle) * innerTipLength
    local innerBaseX1 = self.x + math.cos(perpAngle) * innerTipWidth
    local innerBaseY1 = self.y + math.sin(perpAngle) * innerTipWidth
    local innerBaseX2 = self.x - math.cos(perpAngle) * innerTipWidth
    local innerBaseY2 = self.y - math.sin(perpAngle) * innerTipWidth

    love.graphics.setColor(PLASMA_CORE_COLOR[1], PLASMA_CORE_COLOR[2], PLASMA_CORE_COLOR[3], 0.9 * pulseAlpha)
    love.graphics.polygon("fill", innerTipX, innerTipY, innerBaseX1, innerBaseY1, innerBaseX2, innerBaseY2)
end

function Projectile:checkCollision(enemy)
    if enemy.dead then return false end

    local dx = self.x - enemy.x
    local dy = self.y - enemy.y
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Hit radius based on enemy scale and size
    local hitRadius = enemy.size * enemy.scale

    -- Plasma missiles have larger collision radius
    if self.isPlasma then
        hitRadius = hitRadius + PLASMA_BOLT.bodySize
    end

    return dist < hitRadius
end

return Projectile
