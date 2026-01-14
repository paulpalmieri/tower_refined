-- chunk.lua
-- Geometric debris fragments that fly then settle

local Chunk = Object:extend()

-- Shape vertices for rendering
local SHAPES = {
    triangle = {
        {0, -1},
        {-0.866, 0.5},
        {0.866, 0.5},
    },
    square = {
        {-0.707, -0.707},
        {0.707, -0.707},
        {0.707, 0.707},
        {-0.707, 0.707},
    },
    pentagon = {
        {0, -1},
        {0.951, -0.309},
        {0.588, 0.809},
        {-0.588, 0.809},
        {-0.951, -0.309},
    },
    line = nil,  -- Special case
}

function Chunk:new(params)
    self.x = params.x or 0
    self.y = params.y or 0
    self.vx = params.vx or 0
    self.vy = params.vy or 0
    self.size = params.size or 5

    self.fragmentType = params.fragmentType or "square"

    self.rotation = lume.random(0, math.pi * 2)
    self.rotationSpeed = lume.random(-8, 8)

    local color = params.color or {0, 1, 0}
    self.color = {color[1], color[2], color[3]}
    -- Settled color: desaturated and darkened
    local gray = (color[1] + color[2] + color[3]) / 3
    self.deadColor = {
        (color[1] * 0.3 + gray * 0.7) * 0.4,
        (color[2] * 0.3 + gray * 0.7) * 0.4,
        (color[3] * 0.3 + gray * 0.7) * 0.4,
    }

    self.settled = false
    self.fullySettled = false
    self.settleTimer = 0
    self.trailTimer = 0
    self.dead = false
end

function Chunk:update(dt)
    if self.settled and not self.fullySettled then
        self.settleTimer = self.settleTimer + dt
        if self.settleTimer >= CHUNK_SETTLE_DELAY then
            self.fullySettled = true
        end
        return
    end

    if self.settled then return end

    -- Rotate while moving
    self.rotation = self.rotation + self.rotationSpeed * dt

    -- Trail sparks
    self.trailTimer = self.trailTimer + dt
    if self.trailTimer >= BLOOD_TRAIL_INTERVAL then
        self.trailTimer = 0
        if DebrisManager then
            DebrisManager:spawnTrailSparks(self.x, self.y)
        end
    end

    -- Friction
    self.vx = self.vx * (1 - CHUNK_FRICTION * dt)
    self.vy = self.vy * (1 - CHUNK_FRICTION * dt)

    -- Move
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Check if settled
    local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
    if speed < CHUNK_SETTLE_VELOCITY then
        self.settled = true
        self.settleTimer = 0
    end
end

function Chunk:draw()
    local color = self.fullySettled and self.deadColor or self.color
    local alpha = self.fullySettled and 0.5 or 1.0

    love.graphics.setColor(color[1], color[2], color[3], alpha)

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)

    local shape = SHAPES[self.fragmentType]

    if self.fragmentType == "line" then
        -- Line fragment
        love.graphics.setLineWidth(3)
        love.graphics.line(-self.size, 0, self.size, 0)
        if not self.fullySettled then
            love.graphics.setColor(color[1], color[2], color[3], alpha * 0.3)
            love.graphics.setLineWidth(6)
            love.graphics.line(-self.size, 0, self.size, 0)
        end
        love.graphics.setLineWidth(1)
    elseif shape then
        -- Polygon shapes (triangle, square, pentagon)
        local verts = {}
        for _, v in ipairs(shape) do
            table.insert(verts, v[1] * self.size)
            table.insert(verts, v[2] * self.size)
        end

        love.graphics.polygon("fill", verts)

        -- Edge glow
        if not self.fullySettled then
            love.graphics.setColor(color[1], color[2], color[3], alpha * 0.4)
            love.graphics.setLineWidth(2)
            love.graphics.polygon("line", verts)
            love.graphics.setLineWidth(1)
        end
    else
        -- Fallback: square
        love.graphics.rectangle("fill", -self.size/2, -self.size/2, self.size, self.size)
    end

    love.graphics.pop()
end

function Chunk:isFullySettled()
    return self.fullySettled
end

return Chunk
