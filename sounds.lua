-- sounds.lua
-- Sound effects for Tower Idle Roguelite

Sounds = {}

-- Tuning constants
SOUND_SHOOT_VOLUME = 0.5

-- Source pool for overlapping playback
local shootPool = {}
local POOL_SIZE = 8

-- ===================
-- POOLING
-- ===================

local function createPoolFromSource(source, size)
    local pool = {}
    for i = 1, size do
        pool[i] = source:clone()
    end
    return pool
end

local function playFromPool(pool, volume, pitchVar)
    if not pool or #pool == 0 then return end
    pitchVar = pitchVar or 0
    for _, src in ipairs(pool) do
        if not src:isPlaying() then
            src:setVolume(volume)
            src:setPitch(1 + (math.random() * 2 - 1) * pitchVar)
            src:play()
            return
        end
    end
    pool[1]:stop()
    pool[1]:setVolume(volume)
    pool[1]:setPitch(1 + (math.random() * 2 - 1) * pitchVar)
    pool[1]:play()
end

-- ===================
-- PUBLIC API
-- ===================

function Sounds.init()
    -- Load gun sound from mp3 file
    local gunSound = love.audio.newSource("gun_sound.mp3", "static")
    shootPool = createPoolFromSource(gunSound, POOL_SIZE)
end

function Sounds.playShoot()
    playFromPool(shootPool, SOUND_SHOOT_VOLUME, 0.08)
end

function Sounds.playHit()
    -- Removed
end

function Sounds.playDeath()
    -- Removed - no death sound
end
