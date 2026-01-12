-- main.lua
-- Tower Idle Roguelite

-- ===================
-- LIBRARIES
-- ===================
Object = require "lib.classic"
lume = require "lib.lume"
Debug = require "debugoverlay"

-- ===================
-- TUNING CONSTANTS
-- ===================

-- Window
WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600
CENTER_X = WINDOW_WIDTH / 2
CENTER_Y = WINDOW_HEIGHT / 2

-- Tower
TOWER_HP = 100
TOWER_FIRE_RATE = 0.3          -- Seconds between shots
PROJECTILE_SPEED = 500
PROJECTILE_DAMAGE = 1

-- Enemies
BASIC_HP = 10
BASIC_SPEED = 45
FAST_HP = 5
FAST_SPEED = 100
TANK_HP = 25
TANK_SPEED = 25

-- Visual Grounding
SHADOW_OFFSET_X = 2              -- Light from upper-left
SHADOW_OFFSET_Y = 3
SHADOW_ALPHA = 0.3
BOB_AMPLITUDE = 1.5              -- Pixels of vertical bob
SPAWN_LAND_DURATION = 0.25       -- Landing animation time
SPAWN_LAND_SCALE = 1.5           -- Start bigger, shrink to normal
SPAWN_LAND_ALPHA = 0.3           -- Start transparent

-- Collision
SEPARATION_FORCE = 80            -- Push force between enemies
SEPARATION_RADIUS = 20           -- Distance for separation

-- Chaos
SPEED_VARIATION = 0.15           -- +/- speed variance per enemy

-- Dust Particles
DUST_SPAWN_CHANCE = 1.0          -- Chance to spawn dust on footstep
DUST_FADE_TIME = 0.6             -- How long dust lingers
DUST_SPEED = 40                  -- Dust drift speed
DUST_COUNT = 3                   -- Particles per footstep
DUST_SIZE_MIN = 2                -- Min particle size
DUST_SIZE_MAX = 4                -- Max particle size

-- Knockback
KNOCKBACK_FORCE = 120
KNOCKBACK_DURATION = 0.12

-- Spawning (continuous)
SPAWN_RATE = 1.5           -- Base enemies per second
MAX_ENEMIES = 40           -- Cap on screen
SPAWN_RATE_INCREASE = 0.08 -- Increase per second of game time

-- Blob appearance
BLOB_PIXEL_SIZE = 3            -- Screen pixels per blob "cell"

-- Damage
CLICK_DAMAGE = 15
DAMAGE_PER_PIXEL = 5

-- Hit feedback
BLOB_FLASH_DURATION = 0.05

-- Particle physics
PIXEL_SCATTER_VELOCITY = 350      -- Fast initial launch for limbs
DEATH_BURST_VELOCITY = 450        -- Even faster on death
PIXEL_FADE_TIME = 0.4             -- Blood fades faster
CHUNK_GRAVITY = 150               -- Unused (top-down)
CHUNK_FRICTION = 12.0             -- High friction = fast settle

-- Screen shake
SCREEN_SHAKE_INTENSITY = 5
SCREEN_SHAKE_ON_HIT = 1.5
SCREEN_SHAKE_DURATION = 0.12

-- Damage numbers
DAMAGE_NUMBER_RISE_SPEED = 40
DAMAGE_NUMBER_FADE_TIME = 0.6

-- Dead limb color settings (for settled chunks)
CORPSE_DESATURATION = 0.7      -- 0=full color, 1=grayscale
CORPSE_DARKENING = 0.4         -- 1=bright, 0=black
CORPSE_BLUE_TINT = 0.1         -- Slight ghostly blue/purple shift

-- Limb chunk settings
MIN_CHUNK_PIXELS = 9                 -- Minimum pixels per limb (~3x3 equivalent)
CHUNK_SHAPE_IRREGULARITY = 0.35      -- 0=tight clusters, 1=very irregular
CHUNK_NEIGHBOR_WEIGHT = 2.0          -- Priority for adjacent pixels (organic clumping)

-- Waves
WAVE_BASE_ENEMIES = 5
WAVE_ENEMY_INCREASE = 2
SPAWN_DELAY = 0.8              -- Time between enemy spawns

-- Progression
XP_PER_ENEMY = 10
XP_TO_LEVEL_BASE = 50
XP_LEVEL_SCALE = 1.5
GOLD_PER_WAVE = 10

-- Collision
ENEMY_CONTACT_DAMAGE = 10
ENEMY_CONTACT_RADIUS = 30

-- Active skill (Nuke)
NUKE_DAMAGE = 50
NUKE_RADIUS = 150
NUKE_COOLDOWN = 10.0

-- Fire/Burn effect
BURN_DAMAGE = 2              -- Damage per tick
BURN_TICK_RATE = 0.3         -- Seconds between ticks
BURN_DURATION = 2.0          -- Total burn time
BURN_STACK_MAX = 3           -- Maximum stacks (multiplies damage)

-- Game speed
GAME_SPEEDS = {1, 3, 5}

-- Movement Feel
MOVEMENT_JITTER_STRENGTH = 0.0    -- Position jitter (0 = disabled)
MOVEMENT_JITTER_FREQUENCY = 3.0   -- Jitter cycles per second
BOB_SQUASH_AMOUNT = 0.05          -- Vertical squash during bob

-- Chaos Behavior
BURST_CHANCE = 0.05               -- Chance per second of speed burst
BURST_SPEED_MULT = 1.5            -- Speed multiplier during burst
BURST_DURATION = 0.3              -- Burst duration in seconds

-- Turret Visual (tunable from debug overlay)
TURRET_SCALE = 1.5                -- Overall turret size
GUN_KICK_AMOUNT = 4               -- Recoil distance in pixels
GUN_KICK_DECAY = 25               -- Recoil recovery speed

-- ===================
-- GAME MODULES
-- ===================
require "particle"
require "blob"
require "turret"
require "projectile"
require "damagenumber"
require "chunk"
require "sounds"

-- ===================
-- SHOP UPGRADES
-- ===================
-- Upgrade tier definitions
-- Each upgrade type has 5 tiers with increasing costs and effects
local UPGRADE_DEFS = {
    pierce = {
        baseName = "Piercing Shots",
        tiers = {
            { cost = 50,  desc = "Pierce 1 enemy",   value = 1 },
            { cost = 75,  desc = "Pierce 2 enemies", value = 2 },
            { cost = 110, desc = "Pierce 3 enemies", value = 3 },
            { cost = 160, desc = "Pierce 4 enemies", value = 4 },
            { cost = 230, desc = "Pierce 5 enemies", value = 5 },
        }
    },
    fireRate = {
        baseName = "Rapid Fire",
        tiers = {
            { cost = 40,  desc = "+50% fire rate",  value = 0.5 },
            { cost = 60,  desc = "+100% fire rate", value = 1.0 },
            { cost = 90,  desc = "+150% fire rate", value = 1.5 },
            { cost = 135, desc = "+200% fire rate", value = 2.0 },
            { cost = 200, desc = "+250% fire rate", value = 2.5 },
        }
    },
    damage = {
        baseName = "Heavy Rounds",
        tiers = {
            { cost = 40,  desc = "+50% damage",  value = 0.5 },
            { cost = 60,  desc = "+100% damage", value = 1.0 },
            { cost = 90,  desc = "+150% damage", value = 1.5 },
            { cost = 135, desc = "+200% damage", value = 2.0 },
            { cost = 200, desc = "+250% damage", value = 2.5 },
        }
    },
    hp = {
        baseName = "Reinforced Tower",
        tiers = {
            { cost = 30,  desc = "+50 max HP",  value = 50 },
            { cost = 45,  desc = "+100 max HP", value = 100 },
            { cost = 70,  desc = "+150 max HP", value = 150 },
            { cost = 105, desc = "+200 max HP", value = 200 },
            { cost = 155, desc = "+250 max HP", value = 250 },
        }
    },
    nukeCooldown = {
        baseName = "Quick Nuke",
        tiers = {
            { cost = 35,  desc = "-30% nuke cooldown", value = 0.70 },
            { cost = 55,  desc = "-50% nuke cooldown", value = 0.50 },
            { cost = 85,  desc = "-65% nuke cooldown", value = 0.35 },
            { cost = 125, desc = "-75% nuke cooldown", value = 0.25 },
            { cost = 185, desc = "-85% nuke cooldown", value = 0.15 },
        }
    },
    multishot = {
        baseName = "Multi-Shot",
        tiers = {
            { cost = 60,  desc = "Fire 2 projectiles", value = 2 },
            { cost = 90,  desc = "Fire 3 projectiles", value = 3 },
            { cost = 135, desc = "Fire 4 projectiles", value = 4 },
            { cost = 200, desc = "Fire 5 projectiles", value = 5 },
            { cost = 295, desc = "Fire 6 projectiles", value = 6 },
        }
    },
}

-- Track purchased tier for each upgrade type (0 = none purchased)
local upgradeTiers = {
    pierce = 0,
    fireRate = 0,
    damage = 0,
    hp = 0,
    nukeCooldown = 0,
    multishot = 0,
}

-- ===================
-- GAME STATE
-- ===================
local gameState = "playing"    -- "playing", "gameover", "shop"
gameSpeedIndex = 1             -- Index into GAME_SPEEDS (global for debug overlay)

-- Entities (global for debug overlay stats)
tower = nil
enemies = {}
projectiles = {}
particles = {}
damageNumbers = {}
chunks = {}
dustParticles = {}  -- Footstep dust

-- Continuous spawning system (global for debug overlay)
gameTime = 0
local spawnAccumulator = 0
currentSpawnRate = SPAWN_RATE

-- Progression (global for debug overlay)
xp = 0
level = 1
xpToNextLevel = XP_TO_LEVEL_BASE
local gold = 0
totalGold = 0  -- Persistent gold across runs
totalKills = 0

-- Active skill
local nukeCooldown = 0
local nukeReady = true
local nukeEffect = {active = false, timer = 0, radius = 0}

-- Powers (unlocked during run via leveling) - global for debug overlay
powers = {
    ricochet = false,
    multishot = false,
    pierce = false,
    fire = false,
}

-- Power definitions for level-up selection
local POWER_DEFS = {
    ricochet = {
        name = "Ricochet",
        desc = "Projectiles bounce to nearby enemies",
        color = {0.4, 0.8, 1.0},  -- Cyan
    },
    multishot = {
        name = "Multi-Shot",
        desc = "Fire 2 projectiles at once",
        color = {0.8, 0.4, 1.0},  -- Purple
    },
    fire = {
        name = "Ignite",
        desc = "Projectiles set enemies on fire (DOT)",
        color = {1.0, 0.5, 0.2},  -- Orange
    },
}

-- Passive stats (multipliers, modified by upgrades)
local stats = {
    damage = 1.0,
    fireRate = 1.0,
    projectileSpeed = 1.0,
    maxHp = 0,
    nukeCooldown = 1.0,
}

-- ===================
-- DEBUG SYNC FUNCTION
-- ===================
-- Called by debug overlay when tuning constants change
function syncTowerFromGlobals()
    if tower then
        tower.maxHp = TOWER_HP + stats.maxHp
        -- Don't reduce current HP below 1, but allow increasing
        if tower.hp > tower.maxHp then
            tower.hp = tower.maxHp
        end
        tower.fireRate = TOWER_FIRE_RATE / stats.fireRate
        tower.projectileSpeed = PROJECTILE_SPEED * stats.projectileSpeed
        tower.damage = PROJECTILE_DAMAGE * stats.damage
    end
end

-- Screen shake state
local screenShake = {
    intensity = 0,
    duration = 0,
    timer = 0,
    offsetX = 0,
    offsetY = 0
}

-- Shop selection
local shopSelection = 1

-- Level-up power selection
local levelUpChoices = {}      -- Array of power IDs to choose from
local levelUpSelection = 1     -- Currently highlighted choice (1-3)

-- ===================
-- GROUND SYSTEM
-- ===================
local MAP_PIXEL_SIZE = 4  -- Each ground "pixel" is 4x4 screen pixels
local groundPixels = {}   -- Pre-computed pixel colors
local grassTufts = {}     -- Decorative grass details

-- Generate a tile color based on position
local function generateTileColor(x, y, dist)
    -- Deterministic noise from position
    local noise = (math.sin(x * 0.1) * math.cos(y * 0.13) +
                   math.sin(x * 0.23 + y * 0.17) +
                   math.cos(x * 0.07 - y * 0.11)) / 3 * 0.5 + 0.5

    -- Secondary noise for variation
    local noise2 = (math.sin(x * 0.31 + y * 0.19) * math.cos(y * 0.27)) * 0.5 + 0.5

    -- Center scorching (battle-worn ground)
    local centerInfluence = math.max(0, 1 - dist / 250)
    centerInfluence = centerInfluence * centerInfluence  -- Quadratic falloff

    -- Edge darkness (natural boundary)
    local edgeDarkness = math.max(0, (dist - 300) / 100)
    edgeDarkness = math.min(edgeDarkness, 1)

    -- Base color selection (grey/black palette)
    local r, g, b
    if noise < 0.12 then
        -- Dark cracks/crevices
        r, g, b = 0.04, 0.04, 0.05
    elseif noise < 0.22 then
        -- Stone/pebble (grey)
        r, g, b = 0.12 + noise2 * 0.04, 0.12 + noise2 * 0.04, 0.13 + noise2 * 0.04
    elseif noise < 0.45 then
        -- Ash/charred ground
        r, g, b = 0.08 + noise2 * 0.03, 0.08 + noise2 * 0.03, 0.09 + noise2 * 0.03
    elseif noise < 0.65 then
        -- Dark soil
        r, g, b = 0.10 + noise2 * 0.03, 0.10 + noise2 * 0.03, 0.11 + noise2 * 0.03
    elseif noise < 0.80 then
        -- Lighter grey patches
        r, g, b = 0.14 + noise2 * 0.04, 0.14 + noise2 * 0.04, 0.15 + noise2 * 0.04
    else
        -- Base dark ground
        r, g, b = 0.06 + noise2 * 0.02, 0.06 + noise2 * 0.02, 0.07 + noise2 * 0.02
    end

    -- Apply center scorching (even darker)
    r = r * (1 - centerInfluence * 0.5)
    g = g * (1 - centerInfluence * 0.5)
    b = b * (1 - centerInfluence * 0.4)

    -- Apply edge darkness
    local edgeMult = 1 - edgeDarkness * 0.9
    r = r * edgeMult
    g = g * edgeMult
    b = b * edgeMult

    return {r, g, b}
end

-- Generate tuft color based on distance from center
local function getTuftColor(dist)
    local centerInfluence = math.max(0, 1 - dist / 280)
    local edgeDarkness = math.max(0, (dist - 300) / 100)

    -- Grey tuft colors (dead vegetation, slightly lighter than ground)
    local base = 0.16 + lume.random(-0.02, 0.02)
    local r = base
    local g = base + lume.random(-0.01, 0.01)
    local b = base + 0.01 + lume.random(-0.01, 0.01)

    -- Scorched near center
    r = r * (1 - centerInfluence * 0.5)
    g = g * (1 - centerInfluence * 0.5)
    b = b * (1 - centerInfluence * 0.4)

    -- Darker at edges
    local edgeMult = 1 - edgeDarkness * 0.85
    return {r * edgeMult, g * edgeMult, b * edgeMult}
end

-- Pre-generate the ground map
local function generateGroundMap()
    local tilesX = math.ceil(WINDOW_WIDTH / MAP_PIXEL_SIZE)
    local tilesY = math.ceil(WINDOW_HEIGHT / MAP_PIXEL_SIZE)

    for y = 1, tilesY do
        groundPixels[y] = {}
        for x = 1, tilesX do
            local wx = (x - 0.5) * MAP_PIXEL_SIZE
            local wy = (y - 0.5) * MAP_PIXEL_SIZE
            local dist = math.sqrt((wx - CENTER_X)^2 + (wy - CENTER_Y)^2)
            groundPixels[y][x] = generateTileColor(wx, wy, dist)
        end
    end
end

-- Pre-generate grass tufts
local function generateGrassTufts()
    grassTufts = {}

    -- Tuft pixel patterns (top-down grass blade tips)
    local patterns = {
        {{0, 0}},
        {{0, 0}, {1, 0}},
        {{0, 0}, {0, -1}},
        {{0, 0}, {1, 0}, {0, -1}},
        {{-1, 0}, {0, 0}, {1, 0}},
        {{0, 0}, {1, 0}, {1, -1}},
    }

    for i = 1, 180 do
        local angle = lume.random(0, math.pi * 2)
        local dist = lume.random(50, 380)
        local x = CENTER_X + math.cos(angle) * dist
        local y = CENTER_Y + math.sin(angle) * dist

        -- Less grass near center (scorched) and at very edge
        local spawnChance = 1
        if dist < 100 then
            spawnChance = dist / 100
        elseif dist > 320 then
            spawnChance = math.max(0, 1 - (dist - 320) / 60)
        end

        if lume.random() < spawnChance then
            table.insert(grassTufts, {
                x = x,
                y = y,
                pixels = patterns[math.random(1, #patterns)],
                color = getTuftColor(dist)
            })
        end
    end
end

local function initGround()
    generateGroundMap()
    generateGrassTufts()
end

-- ===================
-- PARTICLE MANAGER
-- ===================
function spawnParticle(params)
    table.insert(particles, Particle(params))
end

local function updateParticles(dt)
    for i = #particles, 1, -1 do
        particles[i]:update(dt)
        if particles[i].dead then
            table.remove(particles, i)
        end
    end
end

local function drawParticles()
    for _, p in ipairs(particles) do
        p:draw()
    end
end

-- ===================
-- CHUNK MANAGER
-- ===================
function spawnChunk(params)
    table.insert(chunks, Chunk(params))
end

local function updateChunks(dt)
    for _, chunk in ipairs(chunks) do
        chunk:update(dt)
    end
    -- Chunks never die, no removal needed
end

local function drawChunks()
    for _, chunk in ipairs(chunks) do
        chunk:draw()
    end
end

-- ===================
-- DUST PARTICLES
-- ===================
function spawnDust(x, y, moveAngle)
    if lume.random() > DUST_SPAWN_CHANCE then return end

    -- Spawn dust puff going opposite to movement
    for i = 1, DUST_COUNT do
        local dustAngle = moveAngle + math.pi + lume.random(-0.8, 0.8)
        table.insert(dustParticles, {
            x = x + lume.random(-5, 5),
            y = y + lume.random(-3, 3),
            vx = math.cos(dustAngle) * DUST_SPEED * lume.random(0.5, 1.5),
            vy = math.sin(dustAngle) * DUST_SPEED * lume.random(0.5, 1.5),
            life = DUST_FADE_TIME * lume.random(0.8, 1.2),
            maxLife = DUST_FADE_TIME,
            size = lume.random(DUST_SIZE_MIN, DUST_SIZE_MAX),
        })
    end
end

local function updateDustParticles(dt)
    for i = #dustParticles, 1, -1 do
        local d = dustParticles[i]
        d.x = d.x + d.vx * dt
        d.y = d.y + d.vy * dt
        d.vx = d.vx * 0.95  -- Friction
        d.vy = d.vy * 0.95
        d.life = d.life - dt
        if d.life <= 0 then
            table.remove(dustParticles, i)
        end
    end
end

local function drawDustParticles()
    for _, d in ipairs(dustParticles) do
        local alpha = d.life / d.maxLife * 0.7
        love.graphics.setColor(0.85, 0.75, 0.6, alpha)
        love.graphics.rectangle("fill", d.x - d.size/2, d.y - d.size/2, d.size, d.size)
    end
end

-- ===================
-- DAMAGE NUMBERS
-- ===================
local function spawnDamageNumber(x, y, amount, isCrit, isBurn)
    table.insert(damageNumbers, DamageNumber(x, y, amount, isCrit, isBurn))
end

local function updateDamageNumbers(dt)
    for i = #damageNumbers, 1, -1 do
        damageNumbers[i]:update(dt)
        if damageNumbers[i].dead then
            table.remove(damageNumbers, i)
        end
    end
end

local function drawDamageNumbers()
    for _, dn in ipairs(damageNumbers) do
        dn:draw()
    end
end

-- ===================
-- SCREEN SHAKE
-- ===================
function triggerScreenShake(intensity, duration)
    if intensity > screenShake.intensity or screenShake.timer <= 0 then
        screenShake.intensity = intensity
        screenShake.duration = duration
        screenShake.timer = duration
    end
end

local function updateScreenShake(dt)
    if screenShake.timer > 0 then
        screenShake.timer = screenShake.timer - dt
        local t = screenShake.timer / screenShake.duration
        local currentIntensity = screenShake.intensity * t
        screenShake.offsetX = lume.random(-currentIntensity, currentIntensity)
        screenShake.offsetY = lume.random(-currentIntensity, currentIntensity)
    else
        screenShake.offsetX = 0
        screenShake.offsetY = 0
        screenShake.intensity = 0
    end
end

-- ===================
-- ACTIVE SKILL: NUKE
-- ===================
function activateNuke()
    if not nukeReady then return end

    nukeReady = false
    nukeCooldown = NUKE_COOLDOWN * stats.nukeCooldown

    -- Start visual effect
    nukeEffect.active = true
    nukeEffect.timer = 0.3
    nukeEffect.radius = 0

    -- Big screen shake
    triggerScreenShake(SCREEN_SHAKE_INTENSITY * 2, 0.3)

    -- Damage all enemies in radius
    for _, enemy in ipairs(enemies) do
        if not enemy.dead then
            local dist = enemy:distanceTo(tower.x, tower.y)
            if dist < NUKE_RADIUS then
                local _, killed = enemy:takeDamage(tower.x, tower.y, NUKE_DAMAGE)
                spawnDamageNumber(enemy.x, enemy.y - 20, NUKE_DAMAGE, true)

                if killed then
                    totalKills = totalKills + 1
                    addXP(XP_PER_ENEMY)
                end
            end
        end
    end

    -- Spawn explosion particles
    for i = 1, 30 do
        local angle = lume.random(0, math.pi * 2)
        local dist = lume.random(20, NUKE_RADIUS * 0.8)
        local x = tower.x + math.cos(angle) * dist
        local y = tower.y + math.sin(angle) * dist

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(angle) * lume.random(50, 150),
            vy = math.sin(angle) * lume.random(50, 150),
            color = {1, lume.random(0.3, 0.7), 0.1},
            size = lume.random(4, 8),
            lifetime = lume.random(0.5, 1.0),
            gravity = -50,  -- Float upward
        })
    end
end

local function updateNuke(dt)
    -- Cooldown
    if not nukeReady then
        nukeCooldown = nukeCooldown - dt
        if nukeCooldown <= 0 then
            nukeReady = true
            nukeCooldown = 0
        end
    end

    -- Visual effect
    if nukeEffect.active then
        nukeEffect.timer = nukeEffect.timer - dt
        nukeEffect.radius = nukeEffect.radius + NUKE_RADIUS * 4 * dt

        if nukeEffect.timer <= 0 then
            nukeEffect.active = false
        end
    end
end

local function drawNukeEffect()
    if nukeEffect.active then
        local alpha = nukeEffect.timer / 0.3

        -- Expanding ring
        love.graphics.setColor(1, 0.6, 0.2, alpha * 0.8)
        love.graphics.setLineWidth(4)
        love.graphics.circle("line", tower.x, tower.y, nukeEffect.radius)

        -- Inner glow
        love.graphics.setColor(1, 0.8, 0.3, alpha * 0.3)
        love.graphics.circle("fill", tower.x, tower.y, nukeEffect.radius * 0.5)

        love.graphics.setLineWidth(1)
    end
end

-- ===================
-- SPAWN SYSTEM (Continuous)
-- ===================
local function spawnEnemy()
    -- Spawn from edge of screen (circular arena)
    local angle = lume.random(0, math.pi * 2)
    local distance = 380
    local x = CENTER_X + math.cos(angle) * distance
    local y = CENTER_Y + math.sin(angle) * distance

    -- Determine enemy type based on game time
    local enemyType = "basic"
    local roll = lume.random()

    -- More variety as time goes on
    local tankChance = math.min(0.2, gameTime * 0.003)
    local fastChance = math.min(0.4, 0.1 + gameTime * 0.005)

    if roll < tankChance then
        enemyType = "tank"
    elseif roll < fastChance then
        enemyType = "fast"
    end

    local enemy = Blob(x, y, 1.0, enemyType)
    enemy:moveToward(CENTER_X, CENTER_Y)

    table.insert(enemies, enemy)
end

-- ===================
-- PROJECTILE SYSTEM
-- ===================
local function fireProjectile()
    local proj = tower:fire()
    if proj then
        -- Helper to apply powers to a projectile
        local function applyPowers(p)
            if powers.ricochet then
                p.canRicochet = true
                p.maxRicochets = 1
            end
            if powers.pierce then
                p.canPierce = true
                p.pierceCount = 0
                p.maxPierces = powers.pierceCount or 1
            end
            if powers.fire then
                p.canBurn = true
            end
            p.damage = p.damage * stats.damage
        end

        applyPowers(proj)
        table.insert(projectiles, proj)

        -- Multishot: fire additional projectiles
        if powers.multishot then
            local shotCount = powers.multishotCount or 2
            local totalSpread = 0.3  -- Total spread angle in radians
            local spreadStep = totalSpread / shotCount

            for i = 2, shotCount do
                -- Spread shots evenly around the center
                local offset = (i - 1) - (shotCount - 1) / 2
                local spreadAngle = offset * spreadStep

                local extraProj = Projectile(
                    proj.x, proj.y,
                    tower.angle + spreadAngle,
                    tower.projectileSpeed,
                    PROJECTILE_DAMAGE
                )
                applyPowers(extraProj)
                table.insert(projectiles, extraProj)
            end
        end
    end
end

local function findNearestEnemy(x, y, excludeEnemy)
    local nearest = nil
    local nearestDist = math.huge

    for _, enemy in ipairs(enemies) do
        if not enemy.dead and enemy ~= excludeEnemy then
            local dist = enemy:distanceTo(x, y)
            if dist < nearestDist then
                nearest = enemy
                nearestDist = dist
            end
        end
    end

    return nearest, nearestDist
end

-- ===================
-- XP AND LEVELING
-- ===================

-- Apply a random stat boost (used when all powers are unlocked)
local function applyRandomStatBoost()
    local boostType = lume.randomchoice({"damage", "fireRate", "projectileSpeed"})
    if boostType == "damage" then
        stats.damage = stats.damage + 0.1
    elseif boostType == "fireRate" then
        stats.fireRate = stats.fireRate + 0.1
        tower.fireRate = TOWER_FIRE_RATE / stats.fireRate
    else
        stats.projectileSpeed = stats.projectileSpeed + 0.1
        tower.projectileSpeed = PROJECTILE_SPEED * stats.projectileSpeed
    end
end

-- Select a power from the level-up screen
local function selectPower(powerId)
    powers[powerId] = true

    -- Special setup for multishot
    if powerId == "multishot" then
        powers.multishotCount = 2
    end

    -- Resume gameplay
    gameState = "playing"
    levelUpChoices = {}
end

function addXP(amount)
    xp = xp + amount

    if xp >= xpToNextLevel then
        xp = xp - xpToNextLevel
        level = level + 1
        xpToNextLevel = math.floor(XP_TO_LEVEL_BASE * (XP_LEVEL_SCALE ^ (level - 1)))

        -- Level up effect
        triggerScreenShake(3, 0.2)

        -- Collect available powers (not yet unlocked)
        local availablePowers = {}
        for powerId, _ in pairs(POWER_DEFS) do
            if not powers[powerId] then
                table.insert(availablePowers, powerId)
            end
        end

        -- If powers available, show selection screen
        if #availablePowers > 0 then
            -- Shuffle and pick up to 3
            levelUpChoices = {}
            local shuffled = lume.shuffle(lume.clone(availablePowers))
            for i = 1, math.min(3, #shuffled) do
                table.insert(levelUpChoices, shuffled[i])
            end
            levelUpSelection = 1
            gameState = "levelup"
        else
            -- No powers left, give random stat boost
            applyRandomStatBoost()
        end
    end
end

-- ===================
-- SHOP SYSTEM
-- ===================

-- Returns list of next available tier for each upgrade type
local function getAvailableUpgrades()
    local available = {}
    -- Order for consistent display
    local upgradeOrder = {"pierce", "multishot", "fireRate", "damage", "hp", "nukeCooldown"}

    for _, upgradeId in ipairs(upgradeOrder) do
        local def = UPGRADE_DEFS[upgradeId]
        local currentTier = upgradeTiers[upgradeId]
        local nextTier = currentTier + 1

        -- Only show if there's a next tier available
        if nextTier <= #def.tiers then
            local tierData = def.tiers[nextTier]
            table.insert(available, {
                id = upgradeId,
                tier = nextTier,
                name = def.baseName .. " " .. nextTier,
                desc = tierData.desc,
                cost = tierData.cost,
                value = tierData.value,
            })
        end
    end
    return available
end

local function buyUpgrade(upgrade)
    if totalGold >= upgrade.cost then
        totalGold = totalGold - upgrade.cost
        upgradeTiers[upgrade.id] = upgrade.tier
        return true
    end
    return false
end

local function applyPurchasedUpgrades()
    -- Reset stats to base values
    stats = {
        damage = 1.0,
        fireRate = 1.0,
        projectileSpeed = 1.0,
        maxHp = 0,
        nukeCooldown = 1.0,
    }
    powers = {
        ricochet = false,
        multishot = false,
        pierce = false,
        fire = false,
        pierceCount = 0,
        multishotCount = 1,
    }

    -- Apply upgrades based on purchased tiers
    for upgradeId, tier in pairs(upgradeTiers) do
        if tier > 0 then
            local def = UPGRADE_DEFS[upgradeId]
            local tierData = def.tiers[tier]

            if upgradeId == "pierce" then
                powers.pierce = true
                powers.pierceCount = tierData.value
            elseif upgradeId == "multishot" then
                powers.multishot = true
                powers.multishotCount = tierData.value
            elseif upgradeId == "fireRate" then
                stats.fireRate = stats.fireRate + tierData.value
            elseif upgradeId == "damage" then
                stats.damage = stats.damage + tierData.value
            elseif upgradeId == "hp" then
                stats.maxHp = tierData.value
            elseif upgradeId == "nukeCooldown" then
                stats.nukeCooldown = tierData.value
            end
        end
    end
end

-- ===================
-- ARENA DRAWING
-- ===================

-- Draw pixelated grass environment
local function drawArenaFloor()
    -- Draw pre-computed ground pixels
    for y, row in ipairs(groundPixels) do
        for x, color in ipairs(row) do
            love.graphics.setColor(color[1], color[2], color[3])
            love.graphics.rectangle("fill",
                (x - 1) * MAP_PIXEL_SIZE,
                (y - 1) * MAP_PIXEL_SIZE,
                MAP_PIXEL_SIZE,
                MAP_PIXEL_SIZE)
        end
    end

    -- Draw grass tufts on top
    for _, tuft in ipairs(grassTufts) do
        love.graphics.setColor(tuft.color[1], tuft.color[2], tuft.color[3])
        for _, p in ipairs(tuft.pixels) do
            love.graphics.rectangle("fill",
                tuft.x + p[1] * MAP_PIXEL_SIZE,
                tuft.y + p[2] * MAP_PIXEL_SIZE,
                MAP_PIXEL_SIZE,
                MAP_PIXEL_SIZE)
        end
    end
end

-- ===================
-- UI DRAWING
-- ===================
local function drawUI()
    love.graphics.setColor(1, 1, 1, 0.9)

    -- Time and enemy count
    local minutes = math.floor(gameTime / 60)
    local seconds = math.floor(gameTime % 60)
    love.graphics.print(string.format("Time: %d:%02d", minutes, seconds), 10, 10)
    love.graphics.print("Enemies: " .. #enemies, 10, 30)

    -- Game speed indicator
    local currentSpeed = GAME_SPEEDS[gameSpeedIndex]
    if currentSpeed > 1 then
        love.graphics.setColor(1, 0.8, 0.2, 0.9)
    else
        love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
    end
    love.graphics.print("Speed: " .. currentSpeed .. "x [S]", 10, 50)

    -- Level and XP
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("Level: " .. level, 10, 75)

    -- XP bar
    local xpBarWidth = 100
    local xpBarHeight = 8
    local xpPercent = xp / xpToNextLevel
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", 10, 95, xpBarWidth, xpBarHeight)
    love.graphics.setColor(0.4, 0.8, 0.4)
    love.graphics.rectangle("fill", 10, 95, xpBarWidth * xpPercent, xpBarHeight)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", 10, 95, xpBarWidth, xpBarHeight)

    -- Tower HP bar
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("Tower HP", WINDOW_WIDTH - 110, 10)

    local hpBarWidth = 100
    local hpBarHeight = 12
    local hpPercent = tower:getHpPercent()
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", WINDOW_WIDTH - 110, 30, hpBarWidth, hpBarHeight)

    local hpColor = {0.2, 0.8, 0.3}
    if hpPercent < 0.3 then
        hpColor = {0.9, 0.2, 0.2}
    elseif hpPercent < 0.6 then
        hpColor = {0.9, 0.7, 0.2}
    end
    love.graphics.setColor(hpColor[1], hpColor[2], hpColor[3])
    love.graphics.rectangle("fill", WINDOW_WIDTH - 110, 30, hpBarWidth * hpPercent, hpBarHeight)
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", WINDOW_WIDTH - 110, 30, hpBarWidth, hpBarHeight)

    -- Gold (current run)
    love.graphics.setColor(1, 0.85, 0.2)
    love.graphics.print("Gold: " .. totalGold, WINDOW_WIDTH - 110, 50)

    -- Active powers
    love.graphics.setColor(1, 1, 1, 0.7)
    local powerY = 115
    if powers.ricochet then
        love.graphics.print("[Ricochet]", 10, powerY)
        powerY = powerY + 20
    end
    if powers.multishot then
        love.graphics.print("[Multi-shot]", 10, powerY)
        powerY = powerY + 20
    end
    if powers.pierce then
        love.graphics.print("[Pierce]", 10, powerY)
    end

    -- Nuke cooldown
    local nukeY = WINDOW_HEIGHT - 60
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.rectangle("fill", 10, nukeY, 80, 30)

    if nukeReady then
        love.graphics.setColor(1, 0.6, 0.2)
        love.graphics.rectangle("fill", 10, nukeY, 80, 30)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("[1] NUKE", 18, nukeY + 8)
    else
        local cdPercent = nukeCooldown / (NUKE_COOLDOWN * stats.nukeCooldown)
        love.graphics.setColor(0.5, 0.3, 0.15)
        love.graphics.rectangle("fill", 10, nukeY, 80 * (1 - cdPercent), 30)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print(string.format("%.1fs", nukeCooldown), 30, nukeY + 8)
    end
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", 10, nukeY, 80, 30)

    -- Debug
    love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
    love.graphics.print("Particles: " .. #particles, 10, WINDOW_HEIGHT - 20)
end

local function drawGameOver()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    love.graphics.setColor(1, 0.3, 0.3)
    local title = "GAME OVER"
    local font = love.graphics.getFont()
    love.graphics.print(title, CENTER_X - font:getWidth(title) / 2, CENTER_Y - 80)

    love.graphics.setColor(1, 1, 1, 0.9)
    local minutes = math.floor(gameTime / 60)
    local seconds = math.floor(gameTime % 60)
    love.graphics.print(string.format("Time Survived: %d:%02d", minutes, seconds), CENTER_X - 70, CENTER_Y - 40)
    love.graphics.print("Enemies Killed: " .. totalKills, CENTER_X - 70, CENTER_Y - 20)

    love.graphics.setColor(1, 0.85, 0.2)
    love.graphics.print("Gold Earned: +" .. gold, CENTER_X - 70, CENTER_Y)
    love.graphics.print("Total Gold: " .. totalGold, CENTER_X - 70, CENTER_Y + 20)

    love.graphics.setColor(0.7, 0.9, 1)
    love.graphics.print("Press S for Shop", CENTER_X - 50, CENTER_Y + 60)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Press R to restart", CENTER_X - 55, CENTER_Y + 80)
end

local function drawShop()
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    -- Title
    love.graphics.setColor(1, 0.85, 0.2)
    local title = "UPGRADE SHOP"
    local font = love.graphics.getFont()
    love.graphics.print(title, CENTER_X - font:getWidth(title) / 2, 50)

    -- Gold display
    love.graphics.setColor(1, 0.85, 0.2)
    love.graphics.print("Gold: " .. totalGold, CENTER_X - 30, 80)

    -- Upgrades
    local available = getAvailableUpgrades()
    local startY = 130
    local boxHeight = 60
    local boxWidth = 300

    if #available == 0 then
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("All upgrades purchased!", CENTER_X - 70, startY)
    else
        for i, upgrade in ipairs(available) do
            local y = startY + (i - 1) * (boxHeight + 10)
            local x = CENTER_X - boxWidth / 2

            -- Selection highlight
            if i == shopSelection then
                love.graphics.setColor(0.3, 0.4, 0.5)
            else
                love.graphics.setColor(0.15, 0.15, 0.18)
            end
            love.graphics.rectangle("fill", x, y, boxWidth, boxHeight)

            -- Border
            if i == shopSelection then
                love.graphics.setColor(1, 0.85, 0.2)
            else
                love.graphics.setColor(0.4, 0.4, 0.45)
            end
            love.graphics.rectangle("line", x, y, boxWidth, boxHeight)

            -- Name
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(upgrade.name, x + 10, y + 8)

            -- Description
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(upgrade.desc, x + 10, y + 28)

            -- Cost
            local costColor = totalGold >= upgrade.cost and {1, 0.85, 0.2} or {0.6, 0.3, 0.3}
            love.graphics.setColor(costColor[1], costColor[2], costColor[3])
            love.graphics.print(upgrade.cost .. "g", x + boxWidth - 40, y + 20)
        end
    end

    -- Instructions
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("UP/DOWN to select, ENTER to buy, R to start run", CENTER_X - 150, WINDOW_HEIGHT - 50)
end

local function drawLevelUpScreen()
    -- Dark overlay
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    -- Title
    love.graphics.setColor(1, 0.85, 0.2)
    local font = love.graphics.getFont()
    local title = "LEVEL UP!"
    love.graphics.print(title, CENTER_X - font:getWidth(title) / 2, 80)

    love.graphics.setColor(1, 1, 1, 0.7)
    local levelText = "Level " .. level
    love.graphics.print(levelText, CENTER_X - font:getWidth(levelText) / 2, 110)

    -- Power cards
    local cardWidth = 180
    local cardHeight = 140
    local cardSpacing = 20
    local numChoices = #levelUpChoices
    local totalWidth = numChoices * cardWidth + (numChoices - 1) * cardSpacing
    local startX = CENTER_X - totalWidth / 2
    local cardY = CENTER_Y - cardHeight / 2

    for i, powerId in ipairs(levelUpChoices) do
        local def = POWER_DEFS[powerId]
        local x = startX + (i - 1) * (cardWidth + cardSpacing)
        local isSelected = (i == levelUpSelection)

        -- Card background
        if isSelected then
            love.graphics.setColor(0.25, 0.3, 0.35)
        else
            love.graphics.setColor(0.12, 0.12, 0.15)
        end
        love.graphics.rectangle("fill", x, cardY, cardWidth, cardHeight)

        -- Card border
        if isSelected then
            love.graphics.setColor(def.color[1], def.color[2], def.color[3])
            love.graphics.setLineWidth(3)
        else
            love.graphics.setColor(0.4, 0.4, 0.45)
            love.graphics.setLineWidth(1)
        end
        love.graphics.rectangle("line", x, cardY, cardWidth, cardHeight)

        -- Icon (large letter in power color)
        love.graphics.setColor(def.color[1], def.color[2], def.color[3])
        local icon = string.sub(def.name, 1, 1)
        love.graphics.print(icon, x + cardWidth / 2 - 5, cardY + 20)

        -- Name
        love.graphics.setColor(1, 1, 1)
        local nameWidth = font:getWidth(def.name)
        love.graphics.print(def.name, x + (cardWidth - nameWidth) / 2, cardY + 55)

        -- Description (wrapped)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf(def.desc, x + 10, cardY + 85, cardWidth - 20, "center")
    end

    love.graphics.setLineWidth(1)

    -- Instructions
    love.graphics.setColor(0.6, 0.6, 0.6)
    local instructions = "LEFT/RIGHT to select, ENTER to confirm"
    love.graphics.print(instructions, CENTER_X - font:getWidth(instructions) / 2, WINDOW_HEIGHT - 60)
end

-- ===================
-- GAME RESET
-- ===================
function startNewRun()
    gameState = "playing"

    -- Apply purchased upgrades
    applyPurchasedUpgrades()

    -- Create tower with upgraded HP
    tower = Turret(CENTER_X, CENTER_Y)
    tower.maxHp = TOWER_HP + stats.maxHp
    tower.hp = tower.maxHp
    tower.fireRate = TOWER_FIRE_RATE / stats.fireRate
    tower.projectileSpeed = PROJECTILE_SPEED * stats.projectileSpeed

    -- Reset game state
    enemies = {}
    projectiles = {}
    particles = {}
    damageNumbers = {}
    chunks = {}
    dustParticles = {}
    xp = 0
    level = 1
    xpToNextLevel = XP_TO_LEVEL_BASE
    gold = 0
    totalKills = 0
    nukeCooldown = 0
    nukeReady = true
    nukeEffect = {active = false, timer = 0, radius = 0}

    -- Reset spawning system
    gameTime = 0
    spawnAccumulator = 0
    currentSpawnRate = SPAWN_RATE
end

-- ===================
-- LOVE CALLBACKS
-- ===================
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("Tower Idle Roguelite")

    Sounds.init()
    initGround()
    startNewRun()
end

function love.update(dt)
    -- Debug overlay pauses game
    if Debug.active then
        Debug:update(dt)
        return
    end

    if gameState == "gameover" or gameState == "shop" or gameState == "levelup" then
        return
    end

    -- Apply game speed
    dt = dt * GAME_SPEEDS[gameSpeedIndex]

    -- Update screen shake
    updateScreenShake(dt)

    -- Update nuke
    updateNuke(dt)

    -- Continuous spawning
    gameTime = gameTime + dt
    currentSpawnRate = SPAWN_RATE + (gameTime * SPAWN_RATE_INCREASE)

    spawnAccumulator = spawnAccumulator + dt * currentSpawnRate
    while spawnAccumulator >= 1 and #enemies < MAX_ENEMIES do
        spawnAccumulator = spawnAccumulator - 1
        spawnEnemy()
    end

    -- Gold over time (every 10 seconds)
    if math.floor(gameTime) % 10 == 0 and math.floor(gameTime) ~= math.floor(gameTime - dt) then
        local timeGold = 5 + math.floor(gameTime / 30)
        gold = gold + timeGold
        totalGold = totalGold + timeGold
    end

    -- Find target for tower
    local target, _ = findNearestEnemy(tower.x, tower.y, nil)

    -- Update tower
    if target then
        tower:update(dt, target.x, target.y)
        if tower:canFire() then
            fireProjectile()
        end
    else
        local mx, my = love.mouse.getPosition()
        tower:update(dt, mx, my)
    end

    -- Update enemies
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        enemy:moveToward(tower.x, tower.y)
        enemy:update(dt)

        -- Process burn damage
        if enemy.isBurning and not enemy.dead then
            local burnKilled, tickOccurred, tickDamage = enemy:updateBurn(dt)
            if tickOccurred then
                -- Spawn burn damage number (orange)
                spawnDamageNumber(enemy.x, enemy.y - 10, tickDamage, false, true)
            end
            if burnKilled then
                totalKills = totalKills + 1
                addXP(XP_PER_ENEMY)
            end
        end

        local dist = enemy:distanceTo(tower.x, tower.y)
        if dist < ENEMY_CONTACT_RADIUS then
            local destroyed = tower:takeDamage(ENEMY_CONTACT_DAMAGE)
            enemy:die(tower.x, tower.y)

            if destroyed then
                gameState = "gameover"
            end
        end

        if enemy.dead then
            table.remove(enemies, i)
        end
    end

    -- Update projectiles
    for i = #projectiles, 1, -1 do
        local proj = projectiles[i]
        proj:update(dt)

        -- Track hit enemies to prevent double-hits
        proj.hitEnemies = proj.hitEnemies or {}

        for _, enemy in ipairs(enemies) do
            if proj:checkCollision(enemy) and not enemy.dead and not proj.hitEnemies[enemy] then
                -- Mark as hit
                proj.hitEnemies[enemy] = true

                -- Pass bullet angle for directional particles
                local _, killed = enemy:takeDamage(proj.x, proj.y, proj.damage, proj.angle)
                spawnDamageNumber(proj.x, proj.y - 10, math.floor(proj.damage))

                -- Apply burn if projectile has fire power
                if proj.canBurn and not enemy.dead then
                    enemy:applyBurn()
                end

                if killed then
                    totalKills = totalKills + 1
                    addXP(XP_PER_ENEMY)
                end

                -- Handle pierce
                if proj.canPierce and proj.pierceCount < proj.maxPierces then
                    proj.pierceCount = proj.pierceCount + 1
                    -- Continue through enemy (don't mark dead)
                elseif proj.canRicochet then
                    -- Handle ricochet
                    local nextTarget = findNearestEnemy(proj.x, proj.y, enemy)
                    if nextTarget and proj.ricochetCount < proj.maxRicochets then
                        proj:ricochetTo(nextTarget.x, nextTarget.y)
                    else
                        proj.dead = true
                    end
                else
                    proj.dead = true
                end

                if proj.dead then break end
            end
        end

        if proj.dead then
            table.remove(projectiles, i)
        end
    end

    updateParticles(dt)
    updateDamageNumbers(dt)
    updateChunks(dt)
    updateDustParticles(dt)
end

function love.draw()
    if gameState == "shop" then
        drawShop()
        return
    end

    if gameState == "levelup" then
        -- Draw game frozen behind
        love.graphics.push()
        love.graphics.translate(screenShake.offsetX, screenShake.offsetY)
        drawArenaFloor()
        drawChunks()
        drawDustParticles()
        for _, enemy in ipairs(enemies) do
            enemy:draw()
        end
        tower:draw()
        for _, proj in ipairs(projectiles) do
            proj:draw()
        end
        drawNukeEffect()
        drawParticles()
        drawDamageNumbers()
        love.graphics.pop()
        drawUI()
        -- Overlay
        drawLevelUpScreen()
        return
    end

    love.graphics.push()
    love.graphics.translate(screenShake.offsetX, screenShake.offsetY)

    -- 1. Ground (pixelated grass environment)
    drawArenaFloor()

    -- 2. Limb chunks (under live enemies)
    drawChunks()

    -- 2.5 Dust particles (footsteps)
    drawDustParticles()

    -- 3. Enemies
    for _, enemy in ipairs(enemies) do
        enemy:draw()
    end

    -- 4. Tower
    tower:draw()

    -- 5. Projectiles
    for _, proj in ipairs(projectiles) do
        proj:draw()
    end

    -- 6. Effects
    drawNukeEffect()
    drawParticles()
    drawDamageNumbers()

    love.graphics.pop()

    -- UI
    drawUI()

    if gameState == "gameover" then
        drawGameOver()
    end

    -- Debug overlay (drawn last, on top of everything)
    if Debug.active then
        Debug:draw()
    end
end

function love.mousepressed(x, y, button)
    if Debug.active then
        Debug:mousepressed(x, y, button)
        return
    end
end

function love.mousereleased(x, y, button)
    if Debug.active then
        Debug:mousereleased(x, y, button)
        return
    end
end

function love.wheelmoved(x, y)
    if Debug.active then
        Debug:wheelmoved(x, y)
        return
    end
end

function love.keypressed(key)
    -- D toggles debug overlay (works in ALL states)
    if key == "d" then
        Debug.active = not Debug.active
        return
    end

    -- S cycles game speed (works in ALL states, even with debug open)
    if key == "s" and gameState == "playing" then
        gameSpeedIndex = (gameSpeedIndex % #GAME_SPEEDS) + 1
        return
    end

    -- Block all other keys when debug overlay is open
    if Debug.active then
        return
    end

    -- Shop state
    if gameState == "shop" then
        local available = getAvailableUpgrades()

        if key == "up" then
            shopSelection = shopSelection - 1
            if shopSelection < 1 then shopSelection = #available end
        elseif key == "down" then
            shopSelection = shopSelection + 1
            if shopSelection > #available then shopSelection = 1 end
        elseif key == "return" or key == "space" then
            if available[shopSelection] then
                buyUpgrade(available[shopSelection])
            end
        elseif key == "r" then
            startNewRun()
        elseif key == "escape" then
            gameState = "gameover"
        end
        return
    end

    -- Level-up selection state
    if gameState == "levelup" then
        if key == "left" then
            levelUpSelection = levelUpSelection - 1
            if levelUpSelection < 1 then levelUpSelection = #levelUpChoices end
        elseif key == "right" then
            levelUpSelection = levelUpSelection + 1
            if levelUpSelection > #levelUpChoices then levelUpSelection = 1 end
        elseif key == "return" or key == "space" then
            if levelUpChoices[levelUpSelection] then
                selectPower(levelUpChoices[levelUpSelection])
            end
        end
        return
    end

    -- Gameover state
    if gameState == "gameover" then
        if key == "r" then
            startNewRun()
        elseif key == "s" then
            gameState = "shop"
            shopSelection = 1
        end
        return
    end

    -- Playing state
    if key == "escape" then
        love.event.quit()
    elseif key == "1" then
        activateNuke()
    elseif key == "r" then
        startNewRun()
    end
end
