-- src/prototype/projectile.lua
-- Projectile entity for prototype

local Object = require("lib.classic")

local Projectile = Object:extend()

function Projectile:new(x, y, angle, speed, damage, color, splashRadius)
    self.x = x
    self.y = y
    self.angle = angle
    self.speed = speed
    self.damage = damage
    self.color = color or {0, 1, 0}
    self.splashRadius = splashRadius  -- nil for no splash

    self.vx = math.cos(angle) * speed
    self.vy = math.sin(angle) * speed

    self.radius = 4
    self.dead = false
    self.lifetime = 3  -- Max lifetime in seconds
end

function Projectile:update(dt, creeps, grid)
    -- Move
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Lifetime
    self.lifetime = self.lifetime - dt
    if self.lifetime <= 0 then
        self.dead = true
        return
    end

    -- Check bounds (using grid info)
    if self.x < 0 or self.x > grid.playAreaWidth or
       self.y < 0 or self.y > grid.gridHeight then
        self.dead = true
        return
    end

    -- Check collision with creeps
    for _, creep in ipairs(creeps) do
        if not creep.dead then
            local dx = creep.x - self.x
            local dy = creep.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist < self.radius + creep.radius then
                self:hit(creep, creeps)
                self.dead = true
                return
            end
        end
    end
end

function Projectile:hit(creep, allCreeps)
    if self.splashRadius then
        -- Splash damage
        for _, c in ipairs(allCreeps) do
            if not c.dead then
                local dx = c.x - self.x
                local dy = c.y - self.y
                local dist = math.sqrt(dx * dx + dy * dy)

                if dist <= self.splashRadius then
                    -- Damage falloff from center
                    local falloff = 1 - (dist / self.splashRadius) * 0.5
                    c:takeDamage(self.damage * falloff)
                end
            end
        end
    else
        -- Single target damage
        creep:takeDamage(self.damage)
    end
end

function Projectile:draw()
    -- Glow
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.3)
    love.graphics.circle("fill", self.x, self.y, self.radius * 2)

    -- Core
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, self.radius)

    -- Bright center
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", self.x, self.y, self.radius * 0.5)
end

return Projectile
