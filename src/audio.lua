-- sounds.lua
-- Sound effects for Tower Idle Roguelite
-- Note: SOUND_SHOOT_VOLUME is defined in src/config.lua

local Sounds = {}

-- Source pool for overlapping playback
local shootPool = {}
local purchasePool = {}
local plasmaPool = {}
local POOL_SIZE = 8

-- Background music
local musicSource = nil
local MUSIC_VOLUME = 0.1
local PURCHASE_VOLUME = 0.3
local PURCHASE_PITCH = 2.0  -- +12 semitones = 2x frequency (one octave up)

-- Laser continuous sound
local laserSource = nil
local LASER_VOLUME = 0.4

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
    local gunSound = love.audio.newSource("assets/gun_sound.wav", "static")
    shootPool = createPoolFromSource(gunSound, POOL_SIZE)

    -- Load purchase/selection sound
    local purchaseSound = love.audio.newSource("assets/selection.wav", "static")
    purchasePool = createPoolFromSource(purchaseSound, 4)

    -- Load plasma missile fire sound
    local plasmaSound = love.audio.newSource("assets/plasma_gun_fire.mp3", "static")
    plasmaPool = createPoolFromSource(plasmaSound, 4)

    -- Load background music (stream for longer audio)
    musicSource = love.audio.newSource("assets/gameplay_loop.wav", "stream")
    musicSource:setLooping(true)
    musicSource:setVolume(MUSIC_VOLUME)

    -- Load laser continuous sound (looping)
    laserSource = love.audio.newSource("assets/laser_continuous.mp3", "stream")
    laserSource:setLooping(true)
    laserSource:setVolume(LASER_VOLUME)
end

function Sounds.playShoot()
    playFromPool(shootPool, SOUND_SHOOT_VOLUME, 0.08)
end

function Sounds.playPlasmaFire()
    playFromPool(plasmaPool, PLASMA_SOUND_VOLUME, 0.05)
end

function Sounds.playPurchase()
    -- Play with fixed +12 semitone pitch
    if not purchasePool or #purchasePool == 0 then return end
    for _, src in ipairs(purchasePool) do
        if not src:isPlaying() then
            src:setVolume(PURCHASE_VOLUME)
            src:setPitch(PURCHASE_PITCH)
            src:play()
            return
        end
    end
    purchasePool[1]:stop()
    purchasePool[1]:setVolume(PURCHASE_VOLUME)
    purchasePool[1]:setPitch(PURCHASE_PITCH)
    purchasePool[1]:play()
end

function Sounds.playMusic()
    if musicSource and not musicSource:isPlaying() then
        musicSource:play()
    end
end

function Sounds.stopMusic()
    if musicSource then
        musicSource:stop()
    end
end

function Sounds.playLaser()
    if laserSource and not laserSource:isPlaying() then
        laserSource:play()
    end
end

function Sounds.stopLaser()
    if laserSource then
        laserSource:stop()
    end
end

return Sounds
