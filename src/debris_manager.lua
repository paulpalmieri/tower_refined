-- src/debris_manager.lua
-- Centralized Debris & Gore System
-- Handles all debris spawning with physics parameters

local DebrisManager = {}

-- Internal state for tracking debris stats (for debug)
local stats = {
    totalChunksSpawned = 0,
    totalParticlesSpawned = 0,
}

-- ===================
-- INTERNAL HELPERS
-- ===================

-- Add random variance to an angle
local function varyAngle(angle, variance)
    return angle + lume.random(-variance, variance)
end

-- Scale velocity based on damage intensity
local function scaleVelocity(baseVelocity, intensity)
    return baseVelocity * (0.8 + intensity * 0.4)  -- 0.8x to 1.2x range
end

-- ===================
-- PUBLIC API
-- ===================

--- Initialize the debris manager (call from love.load)
function DebrisManager:init()
    stats.totalChunksSpawned = 0
    stats.totalParticlesSpawned = 0
end

--- Reset stats (call on new run)
function DebrisManager:reset()
    stats.totalChunksSpawned = 0
    stats.totalParticlesSpawned = 0
end

--- Get debug stats
--- @return table Stats with totalChunksSpawned, totalParticlesSpawned
function DebrisManager:getStats()
    return stats
end

--- Spawn minor blood spatter (1-5 small particles)
--- @param x number Impact X position
--- @param y number Impact Y position
--- @param angle number Base direction angle (radians)
--- @param intensity number 0-1, affects count and speed
function DebrisManager:spawnMinorSpatter(x, y, angle, intensity)
    local count = math.floor(1 + intensity * 4)  -- 1-5 particles
    local baseSpeed = 100 + intensity * 200  -- 100-300 speed

    for _ = 1, count do
        local particleAngle = varyAngle(angle, 0.5)
        local speed = lume.random(baseSpeed * 0.7, baseSpeed * 1.3)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(particleAngle) * speed,
            vy = math.sin(particleAngle) * speed,
            color = {0.6, 0.08, 0.08},  -- dark red blood
            size = lume.random(BLOOD_TRAIL_SIZE_MIN, BLOOD_TRAIL_SIZE_MAX),
            lifetime = lume.random(0.1, 0.25)
        })
        stats.totalParticlesSpawned = stats.totalParticlesSpawned + 1
    end
end

--- Spawn flesh bits (small pixel chunks, 1-3 pixels each)
--- @param x number Center X position
--- @param y number Center Y position
--- @param angle number Base direction angle
--- @param pixels table Array of {color = {r,g,b}} pixel data
--- @param velocity number Base velocity
function DebrisManager:spawnFleshBits(x, y, angle, pixels, velocity)
    if not pixels or #pixels == 0 then return end

    -- Group into small chunks of 1-3 pixels
    local chunkSize = math.min(3, #pixels)
    local chunkPixels = {}

    for i, p in ipairs(pixels) do
        table.insert(chunkPixels, {
            ox = lume.random(-2, 2),
            oy = lume.random(-2, 2),
            color = p.color
        })

        if #chunkPixels >= chunkSize or i == #pixels then
            local chunkAngle = varyAngle(angle, 0.4)
            local speed = scaleVelocity(velocity, 0.8)

            spawnChunk({
                x = x + lume.random(-5, 5),
                y = y + lume.random(-5, 5),
                vx = math.cos(chunkAngle) * speed,
                vy = math.sin(chunkAngle) * speed,
                pixels = chunkPixels,
                size = BLOB_PIXEL_SIZE
            })
            stats.totalChunksSpawned = stats.totalChunksSpawned + 1

            chunkPixels = {}
            chunkSize = math.min(3, #pixels - i)
        end
    end
end

--- Spawn a multi-pixel limb chunk
--- @param x number Center X position
--- @param y number Center Y position
--- @param angle number Base direction angle
--- @param pixels table Array of {ox, oy, color} pixel data with offsets
--- @param velocity number Base velocity
function DebrisManager:spawnLimb(x, y, angle, pixels, velocity)
    if not pixels or #pixels == 0 then return end

    local chunkAngle = varyAngle(angle, 0.3)
    local speed = scaleVelocity(velocity, 1.0)

    spawnChunk({
        x = x,
        y = y,
        vx = math.cos(chunkAngle) * speed,
        vy = math.sin(chunkAngle) * speed,
        pixels = pixels,
        size = BLOB_PIXEL_SIZE
    })
    stats.totalChunksSpawned = stats.totalChunksSpawned + 1
end

--- Spawn corpse explosion (death burst with multiple limbs)
--- @param x number Center X position
--- @param y number Center Y position
--- @param angle number Base direction angle (from killing blow)
--- @param parts table Array of part groups, each is {pixels = {}, centerX, centerY}
--- @param velocity number Base burst velocity
function DebrisManager:spawnCorpseExplosion(x, y, angle, parts, velocity)
    if not parts or #parts == 0 then return end

    -- Spawn blood burst first
    for i = 1, 10 do
        local bloodAngle = varyAngle(angle, 0.6)
        local speed = lume.random(velocity * 0.7, velocity * 1.1)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(bloodAngle) * speed,
            vy = math.sin(bloodAngle) * speed,
            color = {0.6, 0.08, 0.08},
            size = lume.random(2, 4),
            lifetime = lume.random(0.2, 0.35)
        })
        stats.totalParticlesSpawned = stats.totalParticlesSpawned + 1
    end

    -- Spawn each part as a chunk with spread
    for i, part in ipairs(parts) do
        if part.pixels and #part.pixels > 0 then
            -- Spread angle based on part index
            local spreadAngle = angle + (i - (#parts + 1) / 2) * 0.4
            spreadAngle = varyAngle(spreadAngle, 0.3)
            local speed = scaleVelocity(velocity, 0.6 + i * 0.1)

            spawnChunk({
                x = part.centerX or x,
                y = part.centerY or y,
                vx = math.cos(spreadAngle) * speed,
                vy = math.sin(spreadAngle) * speed,
                pixels = part.pixels,
                size = part.size or BLOB_PIXEL_SIZE
            })
            stats.totalChunksSpawned = stats.totalChunksSpawned + 1
        end
    end
end

--- Spawn blood trail particle (called by chunks while moving)
--- @param x number Current position X
--- @param y number Current position Y
function DebrisManager:spawnBloodTrail(x, y)
    local count = math.max(1, math.floor(BLOOD_TRAIL_INTENSITY * 3))

    for _ = 1, count do
        local angle = lume.random(0, math.pi * 2)
        local speed = lume.random(10, 30)

        spawnParticle({
            x = x + lume.random(-2, 2),
            y = y + lume.random(-2, 2),
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            color = {0.5, 0.05, 0.05},  -- darker blood for trails
            size = lume.random(BLOOD_TRAIL_SIZE_MIN, BLOOD_TRAIL_SIZE_MAX),
            lifetime = lume.random(0.3, 0.5)
        })
        stats.totalParticlesSpawned = stats.totalParticlesSpawned + 1
    end
end

--- Spawn impact spatter based on damage context
--- Automatically scales effects based on damage percentage
--- @param context table {damage_dealt, current_hp, max_hp, impact_angle, impact_x, impact_y}
function DebrisManager:spawnImpactEffects(context)
    local damagePercent = context.damage_dealt / context.max_hp
    local x = context.impact_x
    local y = context.impact_y
    local angle = context.impact_angle or 0

    if damagePercent < MINOR_SPATTER_THRESHOLD then
        -- Minor spatter for small hits
        self:spawnMinorSpatter(x, y, angle, damagePercent / MINOR_SPATTER_THRESHOLD)
    else
        -- Larger hit - spawn more significant blood
        self:spawnMinorSpatter(x, y, angle, math.min(1.0, damagePercent))
    end
end

return DebrisManager
