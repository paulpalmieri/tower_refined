-- particle.lua
-- Blood spray particles that fly in bullet direction and fade

Particle = Object:extend()

function Particle:new(params)
    self.x = params.x or 0
    self.y = params.y or 0
    self.vx = params.vx or 0
    self.vy = params.vy or 0
    self.color = params.color or {1, 1, 1}
    self.size = params.size or BLOB_PIXEL_SIZE
    self.lifetime = params.lifetime or PIXEL_FADE_TIME
    self.age = 0
    self.dead = false
end

function Particle:update(dt)
    self.age = self.age + dt
    if self.age >= self.lifetime then
        self.dead = true
        return
    end

    -- No gravity for top-down game
    -- Just friction to slow down
    self.vx = self.vx * (1 - CHUNK_FRICTION * dt)
    self.vy = self.vy * (1 - CHUNK_FRICTION * dt)

    -- Move
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

function Particle:draw()
    -- Calculate alpha with quadratic ease-out (stays visible longer, fades fast at end)
    local alpha = 1 - (self.age / self.lifetime)
    alpha = alpha * alpha

    love.graphics.setColor(self.color[1], self.color[2], self.color[3], alpha)
    love.graphics.rectangle("fill",
        self.x - self.size / 2,
        self.y - self.size / 2,
        self.size,
        self.size)
end
