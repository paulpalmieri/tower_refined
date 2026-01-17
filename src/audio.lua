-- sounds.lua
-- Sound effects for Tower Idle Roguelite
-- Note: SOUND_SHOOT_VOLUME is defined in src/config.lua

local Sounds = {}

-- Source pool for overlapping playback
local shootPool = {}
local purchasePool = {}
local plasmaPool = {}
local deathPool = {}
local POOL_SIZE = 8
local DEATH_POOL_SIZE = 12

-- Background music
local musicSource = nil
local MUSIC_VOLUME = 0.1
local PURCHASE_VOLUME = 0.3
local PURCHASE_PITCH = 2.0  -- +12 semitones = 2x frequency (one octave up)

-- Laser continuous sound
local laserSource = nil
local LASER_VOLUME = 0.4

-- Death sound settings
local DEATH_VOLUME = 0.25
local DEATH_SAMPLE_RATE = 44100
local DEATH_DURATION = 0.12

-- ===================
-- SOUND GENERATION
-- ===================

local function generateDeathSound()
    local sampleCount = math.floor(DEATH_SAMPLE_RATE * DEATH_DURATION)
    local soundData = love.sound.newSoundData(sampleCount, DEATH_SAMPLE_RATE, 16, 1)

    for i = 0, sampleCount - 1 do
        local t = i / DEATH_SAMPLE_RATE
        local progress = i / sampleCount

        -- Envelope: sharp attack, quick decay
        local envelope = math.exp(-progress * 8) * (1 - progress * 0.3)

        -- Frequency sweep: starts high, drops quickly (glitchy digital feel)
        local baseFreq = 800 - progress * 600
        local freqMod = math.sin(progress * 40) * 100

        -- Main tone with harmonics
        local sample = math.sin(2 * math.pi * (baseFreq + freqMod) * t)
        sample = sample + 0.5 * math.sin(2 * math.pi * baseFreq * 2.5 * t)
        sample = sample + 0.3 * math.sin(2 * math.pi * baseFreq * 0.5 * t)

        -- Glitch layer: bit-crush effect via quantization
        local bitDepth = 6 + math.floor(progress * 10)
        local levels = 2 ^ bitDepth
        sample = math.floor(sample * levels) / levels

        -- Random dropouts for glitchy character
        if math.random() < 0.03 then
            sample = sample * 0.2
        end

        -- Noise burst at the start for "pop"
        if progress < 0.1 then
            sample = sample + (math.random() * 2 - 1) * 0.4 * (1 - progress * 10)
        end

        -- Apply envelope and clamp
        sample = sample * envelope * 0.7
        sample = math.max(-1, math.min(1, sample))

        soundData:setSample(i, sample)
    end

    return love.audio.newSource(soundData, "static")
end

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

    -- Generate procedural death sound
    local deathSound = generateDeathSound()
    deathPool = createPoolFromSource(deathSound, DEATH_POOL_SIZE)
end

function Sounds.playShoot()
    playFromPool(shootPool, SOUND_SHOOT_VOLUME, 0.08)
end

function Sounds.playPlasmaFire()
    playFromPool(plasmaPool, PLASMA_SOUND_VOLUME, 0.05)
end

function Sounds.playEnemyDeath()
    playFromPool(deathPool, DEATH_VOLUME, 0.15)
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
