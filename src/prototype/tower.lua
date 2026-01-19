-- src/prototype/tower.lua
-- Basic tower entity for prototype

local Object = require("lib.classic")

local Tower = Object:extend()

-- Tower types with their stats
Tower.TYPES = {
    basic = {
        name = "Turret",
        cost = 100,
        damage = 10,
        fireRate = 1.0,    -- shots per second
        range = 120,       -- pixels
        color = {0.0, 1.0, 0.0},
        projectileSpeed = 400,
        description = "Basic turret. Balanced stats.",
    },
    rapid = {
        name = "Rapid",
        cost = 200,
        damage = 5,
        fireRate = 3.0,
        range = 100,
        color = {0.0, 1.0, 1.0},
        projectileSpeed = 500,
        description = "Fast firing, low damage.",
    },
    sniper = {
        name = "Sniper",
        cost = 300,
        damage = 50,
        fireRate = 0.5,
        range = 200,
        color = {1.0, 1.0, 0.0},
        projectileSpeed = 800,
        description = "High damage, slow fire, long range.",
    },
    splash = {
        name = "Splash",
        cost = 400,
        damage = 15,
        fireRate = 0.8,
        range = 100,
        splashRadius = 50,
        color = {1.0, 0.5, 0.0},
        projectileSpeed = 300,
        description = "Area damage on impact.",
    },
}

function Tower:new(x, y, towerType, gridX, gridY)
    self.x = x
    self.y = y
    self.gridX = gridX
    self.gridY = gridY
    self.towerType = towerType or "basic"

    local stats = Tower.TYPES[self.towerType]
    self.name = stats.name
    self.damage = stats.damage
    self.fireRate = stats.fireRate
    self.range = stats.range
    self.color = stats.color
    self.projectileSpeed = stats.projectileSpeed
    self.splashRadius = stats.splashRadius

    self.fireCooldown = 0
    self.target = nil
    self.rotation = 0
    self.size = 16  -- visual size

    self.dead = false

    -- Visual feedback
    self.flashTime = 0
    self.recoil = 0
end

function Tower:update(dt, creeps, projectiles)
    -- Update cooldown
    if self.fireCooldown > 0 then
        self.fireCooldown = self.fireCooldown - dt
    end

    -- Update visual feedback
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end
    if self.recoil > 0 then
        self.recoil = self.recoil - dt * 40
        if self.recoil < 0 then self.recoil = 0 end
    end

    -- Find target
    self.target = self:findTarget(creeps)

    -- Rotate toward target
    if self.target then
        local dx = self.target.x - self.x
        local dy = self.target.y - self.y
        local targetRotation = math.atan2(dy, dx)

        -- Smooth rotation
        local rotDiff = targetRotation - self.rotation
        while rotDiff > math.pi do rotDiff = rotDiff - 2 * math.pi end
        while rotDiff < -math.pi do rotDiff = rotDiff + 2 * math.pi end
        self.rotation = self.rotation + rotDiff * dt * 10

        -- Fire if ready
        if self.fireCooldown <= 0 then
            self:fire(projectiles)
        end
    end
end

function Tower:findTarget(creeps)
    local closest = nil
    local closestDist = self.range + 1

    for _, creep in ipairs(creeps) do
        if not creep.dead then
            local dx = creep.x - self.x
            local dy = creep.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist <= self.range and dist < closestDist then
                closest = creep
                closestDist = dist
            end
        end
    end

    return closest
end

function Tower:fire(projectiles)
    if not self.target then return end

    self.fireCooldown = 1 / self.fireRate
    self.flashTime = 0.1
    self.recoil = 4

    -- Create projectile
    local Projectile = require("src.prototype.projectile")
    local proj = Projectile(
        self.x + math.cos(self.rotation) * self.size,
        self.y + math.sin(self.rotation) * self.size,
        self.rotation,
        self.projectileSpeed,
        self.damage,
        self.color,
        self.splashRadius
    )

    table.insert(projectiles, proj)
end

function Tower:draw()
    local drawX = self.x
    local drawY = self.y

    -- Apply recoil
    if self.recoil > 0 then
        drawX = drawX - math.cos(self.rotation) * self.recoil
        drawY = drawY - math.sin(self.rotation) * self.recoil
    end

    -- Draw range circle (subtle)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.1)
    love.graphics.circle("fill", self.x, self.y, self.range)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.3)
    love.graphics.circle("line", self.x, self.y, self.range)

    -- Draw base
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.circle("fill", self.x, self.y, self.size)

    -- Draw turret body
    if self.flashTime > 0 then
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(self.color)
    end
    love.graphics.circle("fill", drawX, drawY, self.size * 0.7)

    -- Draw barrel
    love.graphics.setLineWidth(4)
    local barrelLength = self.size * 1.2
    love.graphics.line(
        drawX, drawY,
        drawX + math.cos(self.rotation) * barrelLength,
        drawY + math.sin(self.rotation) * barrelLength
    )

    -- Muzzle flash
    if self.flashTime > 0 then
        love.graphics.setColor(1, 1, 0.5, self.flashTime * 10)
        love.graphics.circle("fill",
            drawX + math.cos(self.rotation) * barrelLength,
            drawY + math.sin(self.rotation) * barrelLength,
            6)
    end
end

function Tower:drawRangePreview()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.2)
    love.graphics.circle("fill", self.x, self.y, self.range)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.5)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", self.x, self.y, self.range)
end

return Tower
