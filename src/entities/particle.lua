-- particle.lua
-- Geometric spark particles that fly and fade

local Particle = Object:extend()

function Particle:new(params)
    self.x = params.x or 0
    self.y = params.y or 0
    self.vx = params.vx or 0
    self.vy = params.vy or 0
    self.color = params.color or NEON_PRIMARY or {0, 1, 0}
    self.size = params.size or BLOB_PIXEL_SIZE
    self.lifetime = params.lifetime or PIXEL_FADE_TIME
    self.age = 0
    self.dead = false

    -- Geometric shape type
    self.shape = params.shape or "square"  -- "square", "line", "triangle", "pentagon"

    -- Rotation for geometric particles
    self.rotation = lume.random(0, math.pi * 2)
    self.rotationSpeed = lume.random(-10, 10)
end

function Particle:update(dt)
    self.age = self.age + dt
    if self.age >= self.lifetime then
        self.dead = true
        return
    end

    -- Rotate
    self.rotation = self.rotation + self.rotationSpeed * dt

    -- Light friction (particles should fly out, not stop immediately)
    local friction = 3.0
    self.vx = self.vx * (1 - friction * dt)
    self.vy = self.vy * (1 - friction * dt)

    -- Move
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

function Particle:draw()
    -- Full alpha, fade only at the end
    local lifeRatio = self.age / self.lifetime
    local alpha = lifeRatio < 0.7 and 1.0 or (1 - (lifeRatio - 0.7) / 0.3)

    love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)

    if self.shape == "triangle" then
        love.graphics.polygon("fill",
            0, -self.size,
            -self.size * 0.6, self.size * 0.5,
            self.size * 0.6, self.size * 0.5
        )

    elseif self.shape == "pentagon" then
        local vertices = {}
        for i = 0, 4 do
            local a = (i / 5) * math.pi * 2 - math.pi / 2
            table.insert(vertices, math.cos(a) * self.size)
            table.insert(vertices, math.sin(a) * self.size)
        end
        love.graphics.polygon("fill", vertices)

    elseif self.shape == "line" then
        -- Trailing line (oriented to velocity)
        love.graphics.rotate(-self.rotation)  -- Undo rotation for velocity alignment
        local angle = math.atan2(self.vy, self.vx)
        love.graphics.rotate(angle)
        love.graphics.setLineWidth(2)
        love.graphics.line(-self.size * 1.5, 0, 0, 0)
        love.graphics.setLineWidth(1)

    else
        -- Square (default)
        love.graphics.rectangle("fill",
            -self.size / 2,
            -self.size / 2,
            self.size,
            self.size)
    end

    love.graphics.pop()
end

return Particle
