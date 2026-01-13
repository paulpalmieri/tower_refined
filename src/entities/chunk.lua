-- chunk.lua
-- Permanent limb chunks (multi-pixel) that fly then settle on the ground

local Chunk = Object:extend()

-- Transform color to dead/settled chunk color
local function transformToChunkColor(color)
    local r, g, b = color[1], color[2], color[3]
    local gray = (r + g + b) / 3

    r = r * (1 - CORPSE_DESATURATION) + gray * CORPSE_DESATURATION
    g = g * (1 - CORPSE_DESATURATION) + gray * CORPSE_DESATURATION
    b = b * (1 - CORPSE_DESATURATION) + gray * CORPSE_DESATURATION

    r = r * CORPSE_DARKENING
    g = g * CORPSE_DARKENING
    b = b * CORPSE_DARKENING

    b = math.min(1, b + CORPSE_BLUE_TINT)

    return {r, g, b}
end

function Chunk:new(params)
    self.x = params.x or 0
    self.y = params.y or 0
    self.vx = params.vx or 0
    self.vy = params.vy or 0
    self.size = params.size or BLOB_PIXEL_SIZE

    -- Multi-pixel support: array of pixel offsets
    -- Each pixel has {ox, oy, color}
    if params.pixels then
        self.pixels = {}
        for _, p in ipairs(params.pixels) do
            table.insert(self.pixels, {
                ox = p.ox,
                oy = p.oy,
                color = {p.color[1], p.color[2], p.color[3]},
                deadColor = transformToChunkColor(p.color)
            })
        end
    else
        -- Single pixel fallback
        local color = params.color or {1, 1, 1}
        self.pixels = {{
            ox = 0,
            oy = 0,
            color = {color[1], color[2], color[3]},
            deadColor = transformToChunkColor(color)
        }}
    end

    self.settled = false
    self.fullySettled = false  -- Only true after delay (for color fade)
    self.settleTimer = 0       -- Time since velocity dropped
    self.trailTimer = 0        -- Timer for blood trail spawning
    self.dead = false          -- Never true - chunks are permanent
end

function Chunk:update(dt)
    -- Handle settle delay for color fade
    if self.settled and not self.fullySettled then
        self.settleTimer = self.settleTimer + dt
        if self.settleTimer >= CHUNK_SETTLE_DELAY then
            self.fullySettled = true
        end
        return  -- Don't move or spawn trails once stopped
    end

    if self.settled then
        return
    end

    -- Spawn blood trail while moving
    self.trailTimer = self.trailTimer + dt
    if self.trailTimer >= BLOOD_TRAIL_INTERVAL then
        self.trailTimer = 0
        -- Spawn trail particle via DebrisManager if available
        if DebrisManager and DebrisManager.spawnBloodTrail then
            DebrisManager:spawnBloodTrail(self.x, self.y)
        end
    end

    -- No gravity for top-down game
    -- Just friction to slow down and settle
    self.vx = self.vx * (1 - CHUNK_FRICTION * dt)
    self.vy = self.vy * (1 - CHUNK_FRICTION * dt)

    -- Move
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Check if settled (velocity low enough)
    local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
    if speed < CHUNK_SETTLE_VELOCITY then
        self.settled = true
        self.settleTimer = 0  -- Start delay timer
    end
end

function Chunk:draw()
    for _, p in ipairs(self.pixels) do
        -- Only use dead color after fully settled (delay passed)
        local color = self.fullySettled and p.deadColor or p.color
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.rectangle("fill",
            self.x + p.ox - self.size / 2,
            self.y + p.oy - self.size / 2,
            self.size,
            self.size)
    end
end

--- Check if this chunk is fully settled (for debug stats)
--- @return boolean
function Chunk:isFullySettled()
    return self.fullySettled
end

return Chunk
