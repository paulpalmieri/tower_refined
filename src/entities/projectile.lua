-- projectile.lua
-- Fast projectiles with trails

local Projectile = Object:extend()

-- Tracer bullet style
local TRACER = {
    bodyColor = {1, 0.95, 0.7},
    coreColor = {1, 1, 1},
    trailColor = {1, 0.6, 0.2},
    glowColor = {1, 0.7, 0.3, 0.25},
    trailLength = 12,
    size = 2.5,
}

function Projectile:new(x, y, angle, speed, damage)
    self.x = x
    self.y = y
    self.angle = angle
    self.speed = speed or PROJECTILE_SPEED
    self.damage = damage or PROJECTILE_DAMAGE
    self.dead = false

    -- Velocity
    self.vx = math.cos(angle) * self.speed
    self.vy = math.sin(angle) * self.speed

    -- Trail positions (for visual effect)
    self.trail = {}
    self.trailLength = TRACER.trailLength

    -- Size
    self.size = TRACER.size
end

function Projectile:update(dt)
    -- Store position for trail
    table.insert(self.trail, 1, {x = self.x, y = self.y})
    if #self.trail > self.trailLength then
        table.remove(self.trail)
    end

    -- Move
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Check bounds (off-screen = dead)
    if self.x < -50 or self.x > 850 or self.y < -50 or self.y > 650 then
        self.dead = true
    end
end

function Projectile:draw()
    -- Draw outer glow
    love.graphics.setColor(TRACER.glowColor[1], TRACER.glowColor[2], TRACER.glowColor[3], TRACER.glowColor[4])
    love.graphics.circle("fill", self.x, self.y, self.size * 2.5)

    -- Draw trail (fading)
    for i, pos in ipairs(self.trail) do
        local alpha = 1 - (i / self.trailLength)
        local size = self.size * 0.8

        love.graphics.setColor(TRACER.trailColor[1], TRACER.trailColor[2], TRACER.trailColor[3], alpha * 0.7)
        love.graphics.circle("fill", pos.x, pos.y, size)
    end

    -- Draw projectile body
    love.graphics.setColor(TRACER.bodyColor[1], TRACER.bodyColor[2], TRACER.bodyColor[3])
    love.graphics.circle("fill", self.x, self.y, self.size)

    -- Draw bright core
    love.graphics.setColor(TRACER.coreColor[1], TRACER.coreColor[2], TRACER.coreColor[3])
    love.graphics.circle("fill", self.x, self.y, self.size * 0.5)
end

function Projectile:checkCollision(enemy)
    if enemy.dead then return false end

    local dx = self.x - enemy.x
    local dy = self.y - enemy.y
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Hit radius based on enemy scale
    local hitRadius = 6 * BLOB_PIXEL_SIZE * (enemy.scale or 1)

    return dist < hitRadius
end

return Projectile
