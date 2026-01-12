-- chunk.lua
-- Permanent limb chunks (multi-pixel) that fly then settle on the ground

Chunk = Object:extend()

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
    self.dead = false  -- Never true - chunks are permanent
end

function Chunk:update(dt)
    if self.settled then
        return
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
    if speed < 40 then
        self.settled = true
    end
end

function Chunk:draw()
    for _, p in ipairs(self.pixels) do
        local color = self.settled and p.deadColor or p.color
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.rectangle("fill",
            self.x + p.ox - self.size / 2,
            self.y + p.oy - self.size / 2,
            self.size,
            self.size)
    end
end
