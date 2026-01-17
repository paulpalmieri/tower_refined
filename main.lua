-- main.lua
-- Tower Idle Roguelite

-- ===================
-- LIBRARIES
-- ===================
Object = require "lib.classic"
lume = require "lib.lume"

-- ===================
-- CONFIG (all tuning constants)
-- ===================
require "src.config"

-- ===================
-- GAME MODULES
-- ===================
Particle = require "src.entities.particle"
Enemy = require "src.entities.enemy"
Turret = require "src.entities.turret"
Projectile = require "src.entities.projectile"
DamageNumber = require "src.entities.damagenumber"
Chunk = require "src.entities.chunk"
FlyingPart = require "src.entities.flying_part"
CollectibleShard = require "src.entities.collectible_shard"
Drone = require "src.entities.drone"
Shield = require "src.entities.shield"
Silo = require "src.entities.silo"
Missile = require "src.entities.missile"
EnemyProjectile = require "src.entities.enemy_projectile"
AoEWarning = require "src.entities.aoe_warning"
Sounds = require "src.audio"
Feedback = require "src.feedback"
DebrisManager = require "src.debris_manager"
Lighting = require "src.lighting"
DebugConsole = require "src.debug_console"
SkillTree = require "src.skilltree"
PostFX = require "src.postfx"
Intro = require "src.intro"
SettingsMenu = require "src.settings_menu"
CompositeEnemy = require "src.entities.composite_enemy"
require "src.composite_templates"
Camera = require "src.camera"
Parallax = require "src.parallax"
Roguelite = require "src.roguelite"
LevelUpUI = require "src.roguelite.levelup_ui"
DamageAura = require "src.entities.damage_aura"

-- ===================
-- GAME STATE
-- ===================
local gameState = "playing"    -- "intro", "playing", "gameover", "skilltree", "settings"
local previousState = nil      -- Track state before settings opened
gameSpeedIndex = 4             -- Index into GAME_SPEEDS (starts at 1x)
local perfOverlay = false      -- Toggle with U (performance overlay)
local godMode = false          -- Toggle with G (tower invincibility)
local autoFire = false         -- Toggle with A (auto-fire mode)
isFullscreen = false           -- Toggle with B (borderless fullscreen) - global for settings menu

-- ===================
-- SCALING SYSTEM
-- ===================
-- Update scale values based on current window size
local function updateScale()
    local windowWidth, windowHeight = love.graphics.getDimensions()

    -- Calculate scale to fit virtual resolution while maintaining aspect ratio
    SCALE_X = windowWidth / WINDOW_WIDTH
    SCALE_Y = windowHeight / WINDOW_HEIGHT
    SCALE = math.min(SCALE_X, SCALE_Y)

    -- Calculate letterbox/pillarbox offsets to center the game
    OFFSET_X = (windowWidth - WINDOW_WIDTH * SCALE) / 2
    OFFSET_Y = (windowHeight - WINDOW_HEIGHT * SCALE) / 2
end

-- Convert screen coordinates to game coordinates
local function screenToGame(screenX, screenY)
    local gameX = (screenX - OFFSET_X) / SCALE
    local gameY = (screenY - OFFSET_Y) / SCALE
    return gameX, gameY
end

-- Get mouse position in game coordinates (scaled)
local function getMousePositionScaled()
    local mx, my = love.mouse.getPosition()
    return screenToGame(mx, my)
end

-- Get mouse position in world coordinates (accounting for camera)
local function getMousePosition()
    local mx, my = love.mouse.getPosition()
    local gx, gy = screenToGame(mx, my)
    return Camera:screenToWorld(gx, gy)
end

-- Toggle fullscreen mode (global for settings menu)
function toggleFullscreen()
    isFullscreen = not isFullscreen
    love.window.setFullscreen(isFullscreen, "desktop")
    updateScale()
end

-- Entities
tower = nil
enemies = {}
compositeEnemies = {}  -- Composite enemies with hierarchical structure
projectiles = {}
particles = {}
damageNumbers = {}
chunks = {}
flyingParts = {}  -- Destroyed enemy sides
dustParticles = {}  -- Footstep dust

-- Continuous spawning system
gameTime = 0
local spawnAccumulator = 0
currentSpawnRate = SPAWN_RATE

-- Progression
local gold = 0
totalGold = 100000  -- Persistent gold across runs (set high for testing)
polygons = 0      -- Persistent polygons currency (collected from enemy shards)
totalKills = 0
collectibleShards = {}  -- Clickable shards dropped by enemies
drones = {}               -- Orbiting XP collector drones
droneProjectiles = {}     -- Drone-fired projectiles (only hit shards)
silos = {}                -- Missile silos around turret
missiles = {}             -- Homing missiles in flight
enemyProjectiles = {}     -- Enemy-fired projectiles (square bolts, mini-hexes)
aoeWarnings = {}          -- Pentagon telegraphed danger zones
damageAura = nil          -- Damage aura entity (from roguelite upgrade)

-- Laser beam system
local laser = {
    state = "ready",      -- "ready", "deploying", "charging", "firing", "retracting"
    timer = 0,            -- Time in current state
    cannonExtend = 0,     -- 0-1, how far side cannons extended
    chargeGlow = 0,       -- 0-1, charge intensity
    damageAccum = 0,      -- Accumulated damage time for DPS tick
    hitEnemies = {},      -- Track which enemies were hit this frame for damage numbers
}

-- Plasma missile system
local plasma = {
    state = "ready",      -- "ready", "charging", "cooldown"
    timer = 0,            -- Time in current state
    chargeProgress = 0,   -- 0-1, how far charge has progressed (back to front)
}

-- Game over animation state
local gameOverAnim = {
    phase = "none",       -- "none", "fade_in", "title_hold", "reveal", "complete"
    timer = 0,
    titleAlpha = 0,
    titleY = CENTER_Y,
    statRevealProgress = 0,
    overlayAlpha = 0,
}

-- Passive stats (multipliers, modified by skill tree)
local stats = {
    damage = 1.0,
    fireRate = 1.0,
    projectileSpeed = 1.0,
    maxHp = 0,
    goldMultiplier = 1.0,
    -- Laser stats
    laserDamage = 1.0,
    laserDuration = 1.0,
    laserChargeSpeed = 1.0,
    laserWidth = 1.0,
    -- Plasma stats
    plasmaDamage = 1.0,
    plasmaSpeed = 1.0,
    plasmaCooldown = 1.0,
    plasmaSize = 1.0,
    -- Collection stats
    magnetEnabled = false,
    pickupRadius = 1.0,
    -- Drone stats
    droneCount = 0,
    droneFireRate = 1.0,
    -- Shield stats
    shieldUnlocked = false,
    shieldCharges = 0,
    shieldRadius = 1.0,
    -- Silo stats
    siloCount = 0,
    siloFireRate = 1.0,
    siloDoubleShot = false,
}

-- ===================
-- GROUND SYSTEM (Geometric Grid)
-- ===================

-- Initialize ground (now just a no-op, grid is drawn procedurally)
local function initGround()
    -- No pre-generation needed for geometric grid
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

local function updateFlyingParts(dt)
    for i = #flyingParts, 1, -1 do
        flyingParts[i]:update(dt)
        if flyingParts[i].dead then
            table.remove(flyingParts, i)
        end
    end
end

local function drawFlyingParts()
    for _, part in ipairs(flyingParts) do
        part:draw()
    end
end

-- ===================
-- DAMAGE NUMBERS
-- ===================
function spawnDamageNumber(x, y, amount, isCrit)
    table.insert(damageNumbers, DamageNumber(x, y, amount, isCrit))
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
-- COLLECTIBLE SHARDS
-- ===================
function spawnShardCluster(x, y, shapeName, count)
    -- Spawn multiple shards in a cluster pattern
    for i = 1, count do
        -- Distribute shards in a circle with some randomness
        local baseAngle = (i / count) * math.pi * 2
        local angle = baseAngle + lume.random(-0.3, 0.3)

        -- Offset position slightly for cluster effect
        local offsetDist = lume.random(0, POLYGON_CLUSTER_SPREAD)
        local offsetAngle = lume.random(0, math.pi * 2)
        local spawnX = x + math.cos(offsetAngle) * offsetDist
        local spawnY = y + math.sin(offsetAngle) * offsetDist

        -- Vary eject speed slightly for organic feel
        local speed = POLYGON_EJECT_SPEED * lume.random(0.7, 1.3)

        local shard = CollectibleShard({
            x = spawnX,
            y = spawnY,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            shapeName = shapeName,
            size = POLYGON_CLUSTER_SHARD_SIZE,
            value = 1,
        })

        -- Add purple glow light
        shard.lightId = Lighting:addLight({
            x = spawnX,
            y = spawnY,
            radius = POLYGON_LIGHT_RADIUS * 0.6,
            intensity = POLYGON_LIGHT_INTENSITY * 0.7,
            color = POLYGON_COLOR,
            pulse = POLYGON_PULSE_SPEED,
            pulseAmount = POLYGON_PULSE_AMOUNT,
            owner = shard,
        })

        table.insert(collectibleShards, shard)
    end
end

local function updateCollectibleShards(dt, towerX, towerY)
    -- Calculate pickup radius based on skill tree and roguelite upgrades
    local pickupRadius = POLYGON_PICKUP_RADIUS_BASE * stats.pickupRadius * Roguelite.runtimeStats.pickupRadiusMult

    for i = #collectibleShards, 1, -1 do
        local shard = collectibleShards[i]

        -- Auto-attract shards if magnet enabled or within pickup radius
        if shard.state == "idle" then
            local dx = shard.x - towerX
            local dy = shard.y - towerY
            local dist = math.sqrt(dx * dx + dy * dy)

            -- Magnet attracts all idle shards, pickup radius only nearby ones
            if stats.magnetEnabled or dist < pickupRadius then
                shard:catch(towerX, towerY)
            end
        end

        -- Update shard and check for collection
        local collectedValue = shard:update(dt)
        if collectedValue then
            -- Add XP to roguelite system (polygons are now XP during runs)
            local leveledUp = Roguelite:addXP(collectedValue)
            if leveledUp then
                -- Show level-up notification
                LevelUpUI:show()
            end
            -- Spawn floating number at turret (show as XP)
            spawnDamageNumber(towerX, towerY - 30, collectedValue, "xp")
        end

        -- Clean up dead shards (light is auto-removed via owner.dead check)
        if shard.dead then
            table.remove(collectibleShards, i)
        end
    end
end

local function drawCollectibleShards()
    for _, shard in ipairs(collectibleShards) do
        shard:draw()
    end
end

local function clearCollectibleShards()
    for _, shard in ipairs(collectibleShards) do
        if shard.lightId then
            Lighting:removeLight(shard.lightId)
        end
    end
    collectibleShards = {}
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
-- ACTIVE SKILL: LASER BEAM
-- ===================
local function activateLaser()
    if laser.state ~= "ready" then return end
    laser.state = "deploying"
    laser.timer = 0
    laser.cannonExtend = 0
    laser.chargeGlow = 0
    laser.damageAccum = 0
    laser.hitEnemies = {}
end

-- ===================
-- DASH ABILITY
-- ===================
local function tryDash()
    if not tower then return end

    -- Get WASD direction
    local dirX, dirY = 0, 0
    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
        dirY = -1
    end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
        dirY = 1
    end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        dirX = -1
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        dirX = 1
    end

    -- If no movement keys, dash toward mouse
    if dirX == 0 and dirY == 0 then
        local mx, my = getMousePosition()
        dirX = mx - tower.x
        dirY = my - tower.y
    end

    -- Try to dash
    tower:tryDash(dirX, dirY)
end

-- Draw dash charge UI (arc segments below turret)
local function drawDashChargeUI()
    if not tower then return end

    local info = tower:getDashInfo()
    local radius = DASH_UI_RADIUS
    local arcSpan = DASH_UI_ARC_SPAN
    local gap = DASH_UI_GAP

    -- Arc centered at bottom, segments ordered left to right
    -- In LOVE2D, angles increase clockwise, so left = smaller angle
    local centerAngle = math.pi / 2  -- Bottom (pointing down)
    local totalArcStart = centerAngle - arcSpan / 2  -- Left edge
    local segmentSpan = (arcSpan - gap * (info.maxCharges - 1)) / info.maxCharges

    for i = 1, info.maxCharges do
        -- Segments go left to right (i=1 is leftmost)
        local segStart = totalArcStart + (i - 1) * (segmentSpan + gap)
        local segEnd = segStart + segmentSpan

        -- Determine fill state
        local isFull = i <= info.charges
        local isRecharging = (i == info.charges + 1)

        -- Colors
        local alpha, r, g, b
        if isFull then
            -- Full charge: bright green
            r, g, b, alpha = 0, 1, 0, 0.8
        elseif isRecharging then
            -- Recharging: animated fill
            r, g, b = 0, 0.6, 0.2
            alpha = 0.5
        else
            -- Empty: dim
            r, g, b, alpha = 0, 0.3, 0, 0.3
        end

        -- Draw arc segment background
        love.graphics.setColor(0, 0.1, 0, 0.4)
        love.graphics.setLineWidth(4)
        love.graphics.arc("line", "open", tower.x, tower.y, radius, segStart, segEnd)

        -- Draw filled portion
        if isFull then
            -- Full segment
            love.graphics.setColor(r, g, b, alpha)
            love.graphics.setLineWidth(3)
            love.graphics.arc("line", "open", tower.x, tower.y, radius, segStart, segEnd)
        elseif isRecharging then
            -- Partial fill from left to right within the segment
            local fillEnd = segStart + segmentSpan * info.rechargeProgress
            love.graphics.setColor(r, g, b, alpha)
            love.graphics.setLineWidth(3)
            love.graphics.arc("line", "open", tower.x, tower.y, radius, segStart, fillEnd)
        end
    end

    love.graphics.setLineWidth(1)
end

-- Check if a point is inside the laser beam
local function pointInLaserBeam(px, py, beamStartX, beamStartY, beamAngle, beamLength, beamWidth)
    -- Transform point to beam-local coordinates
    local dx = px - beamStartX
    local dy = py - beamStartY

    -- Rotate to align with beam (beam points along positive X in local space)
    local cosA = math.cos(-beamAngle)
    local sinA = math.sin(-beamAngle)
    local localX = dx * cosA - dy * sinA
    local localY = dx * sinA + dy * cosA

    -- Check if within beam bounds
    return localX >= 0 and localX <= beamLength and math.abs(localY) <= beamWidth / 2
end

local function updateLaser(dt, gameDt)
    -- Calculate scaled times based on charge speed upgrade
    local deployTime = LASER_DEPLOY_TIME / stats.laserChargeSpeed
    local chargeTime = LASER_CHARGE_TIME / stats.laserChargeSpeed
    local fireTime = LASER_FIRE_TIME * stats.laserDuration
    local beamWidth = LASER_BEAM_WIDTH * stats.laserWidth

    if laser.state == "ready" then
        return
    elseif laser.state == "deploying" then
        laser.timer = laser.timer + dt
        laser.cannonExtend = math.min(1, laser.timer / deployTime)
        if laser.timer >= deployTime then
            laser.state = "charging"
            laser.timer = 0
        end
    elseif laser.state == "charging" then
        laser.timer = laser.timer + dt
        laser.chargeGlow = math.min(1, laser.timer / chargeTime)
        -- Subtle shake during charge
        if laser.timer > chargeTime * 0.5 then
            Feedback:trigger("laser_charge")
        end
        if laser.timer >= chargeTime then
            laser.state = "firing"
            laser.timer = 0
            laser.damageAccum = 0
            Sounds.playLaser()
        end
    elseif laser.state == "firing" then
        laser.timer = laser.timer + dt

        -- Continuous screen shake while firing
        Feedback:trigger("laser_continuous")

        -- Get beam geometry
        local muzzleX, muzzleY = tower:getMuzzleTip()
        local beamAngle = tower.angle

        -- Damage enemies in beam (uses raw dt so damage always applies)
        laser.damageAccum = laser.damageAccum + dt
        local damageThisFrame = LASER_DAMAGE_PER_SEC * stats.laserDamage * dt

        for _, enemy in ipairs(enemies) do
            if not enemy.dead then
                if pointInLaserBeam(enemy.x, enemy.y, muzzleX, muzzleY, beamAngle, LASER_BEAM_LENGTH, beamWidth) then
                    -- Pass nil angle to disable knockback
                    local killed, flyingPartsData = enemy:takeDamage(damageThisFrame, nil)

                    -- Spawn flying parts for any destroyed sides
                    for _, partData in ipairs(flyingPartsData) do
                        table.insert(flyingParts, FlyingPart(partData))
                    end

                    -- Show damage number periodically (every 0.5s per enemy)
                    if not laser.hitEnemies[enemy] then
                        laser.hitEnemies[enemy] = 0
                    end
                    laser.hitEnemies[enemy] = laser.hitEnemies[enemy] + dt
                    if laser.hitEnemies[enemy] >= 0.5 then
                        spawnDamageNumber(enemy.x, enemy.y - 10, math.floor(LASER_DAMAGE_PER_SEC * stats.laserDamage * 0.5))
                        laser.hitEnemies[enemy] = 0
                    end

                    if killed then
                        totalKills = totalKills + 1
                        local goldAmount = math.floor(GOLD_PER_KILL * stats.goldMultiplier)
                        gold = gold + goldAmount
                        totalGold = totalGold + goldAmount
                        spawnDamageNumber(enemy.x, enemy.y - 20, goldAmount, "gold")
                        -- Spawn shard cluster (one shard per HP)
                        spawnShardCluster(enemy.x, enemy.y, enemy.shapeName, enemy.maxHp)
                    end
                end
            end
        end

        -- Spawn beam particles
        if lume.random() < 0.3 then
            local dist = lume.random(50, LASER_BEAM_LENGTH * 0.8)
            local px = muzzleX + math.cos(beamAngle) * dist
            local py = muzzleY + math.sin(beamAngle) * dist
            local perpAngle = beamAngle + (lume.random() > 0.5 and math.pi/2 or -math.pi/2)
            spawnParticle({
                x = px + lume.random(-5, 5),
                y = py + lume.random(-5, 5),
                vx = math.cos(perpAngle) * lume.random(30, 80),
                vy = math.sin(perpAngle) * lume.random(30, 80),
                color = {lume.random(0.8, 1), 1, lume.random(0.8, 1)},
                size = lume.random(2, 4),
                lifetime = lume.random(0.2, 0.4),
                gravity = 0,
            })
        end

        if laser.timer >= fireTime then
            laser.state = "retracting"
            laser.timer = 0
            Sounds.stopLaser()
        end
    elseif laser.state == "retracting" then
        laser.timer = laser.timer + dt
        laser.cannonExtend = math.max(0, 1 - laser.timer / LASER_RETRACT_TIME)
        laser.chargeGlow = math.max(0, 1 - laser.timer / LASER_RETRACT_TIME)
        if laser.timer >= LASER_RETRACT_TIME then
            laser.state = "ready"
            laser.timer = 0
            laser.cannonExtend = 0
            laser.chargeGlow = 0
            laser.hitEnemies = {}
        end
    end
end

local function drawLaserBeam()
    if laser.state ~= "firing" then return end

    local beamWidth = LASER_BEAM_WIDTH * stats.laserWidth
    local muzzleX, muzzleY = tower:getMuzzleTip()
    local beamAngle = tower.angle
    local endX = muzzleX + math.cos(beamAngle) * LASER_BEAM_LENGTH
    local endY = muzzleY + math.sin(beamAngle) * LASER_BEAM_LENGTH

    -- Animated wave offset for beam edges
    local time = love.timer.getTime() * 10
    local waveAmp = 3

    -- Outer glow (widest, most transparent)
    love.graphics.setColor(0, 0.8, 0.2, 0.15)
    love.graphics.setLineWidth(beamWidth * 2)
    love.graphics.line(muzzleX, muzzleY, endX, endY)

    -- Middle glow
    love.graphics.setColor(0, 1, 0.3, 0.3)
    love.graphics.setLineWidth(beamWidth * 1.2)
    love.graphics.line(muzzleX, muzzleY, endX, endY)

    -- Inner beam (intense green)
    love.graphics.setColor(0.3, 1, 0.5, 0.7)
    love.graphics.setLineWidth(beamWidth * 0.6)
    love.graphics.line(muzzleX, muzzleY, endX, endY)

    -- Core (white hot center)
    love.graphics.setColor(0.9, 1, 0.95, 0.9)
    love.graphics.setLineWidth(beamWidth * 0.2)
    love.graphics.line(muzzleX, muzzleY, endX, endY)

    -- Draw wavy edge particles along beam
    local segments = 20
    for i = 0, segments do
        local t = i / segments
        local dist = LASER_BEAM_LENGTH * t
        local px = muzzleX + math.cos(beamAngle) * dist
        local py = muzzleY + math.sin(beamAngle) * dist

        -- Wavy offset perpendicular to beam
        local perpAngle = beamAngle + math.pi / 2
        local wave = math.sin(time + i * 0.5) * waveAmp
        local edgeX = px + math.cos(perpAngle) * (beamWidth * 0.4 + wave)
        local edgeY = py + math.sin(perpAngle) * (beamWidth * 0.4 + wave)

        love.graphics.setColor(0.7, 1, 0.8, 0.6)
        love.graphics.circle("fill", edgeX, edgeY, 2)

        -- Other side
        edgeX = px - math.cos(perpAngle) * (beamWidth * 0.4 + wave)
        edgeY = py - math.sin(perpAngle) * (beamWidth * 0.4 + wave)
        love.graphics.circle("fill", edgeX, edgeY, 2)
    end

    love.graphics.setLineWidth(1)
end

-- Draw side cannons on turret (called from turret or here)
local function drawLaserCannons()
    if laser.cannonExtend <= 0 and laser.chargeGlow <= 0 then return end

    local flinchX = tower.damageFlinch * math.cos(tower.angle + math.pi) * 2
    local flinchY = tower.damageFlinch * math.sin(tower.angle + math.pi) * 2
    local drawX = tower.x + flinchX
    local drawY = tower.y + flinchY

    love.graphics.push()
    love.graphics.translate(drawX, drawY)
    love.graphics.rotate(tower.angle)

    -- Match main barrel dimensions
    local cannonLength = 50  -- Same as BARREL_LENGTH
    local cannonWidth = 14   -- Same as BARREL_WIDTH
    local barrelBack = 15    -- Same as BARREL_BACK
    local gap = 2            -- Small gap between barrels

    -- Final position: right next to main barrel with gap
    local finalYOffset = cannonWidth / 2 + gap + cannonWidth / 2  -- = 16

    -- Animation: slide in from outside during deploying
    local startYOffset = 60  -- Start far away
    local currentYOffset = startYOffset - (startYOffset - finalYOffset) * laser.cannonExtend

    -- Side cannon positions (perpendicular to barrel)
    for side = -1, 1, 2 do
        local yOffset = side * currentYOffset

        -- Cannon fill (green)
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.rectangle("fill", -barrelBack, yOffset - cannonWidth/2, cannonLength + barrelBack, cannonWidth)

        -- Cannon border
        love.graphics.setColor(0, 1, 0, 0.6)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", -barrelBack, yOffset - cannonWidth/2, cannonLength + barrelBack, cannonWidth)
    end

    -- White glow on all 3 barrels during charging/firing
    if laser.chargeGlow > 0 then
        local glowIntensity = laser.chargeGlow

        -- Glow on side cannons
        for side = -1, 1, 2 do
            local yOffset = side * currentYOffset
            love.graphics.setColor(1, 1, 1, glowIntensity * 0.7)
            love.graphics.rectangle("fill", -barrelBack, yOffset - cannonWidth/2, cannonLength + barrelBack, cannonWidth)
        end

        -- Glow on main barrel (center)
        love.graphics.setColor(1, 1, 1, glowIntensity * 0.7)
        love.graphics.rectangle("fill", -barrelBack, -cannonWidth/2, cannonLength + barrelBack, cannonWidth)
    end

    love.graphics.setLineWidth(1)
    love.graphics.pop()
end

-- ===================
-- ACTIVE SKILL: PLASMA MISSILE
-- ===================
local function activatePlasma()
    if plasma.state ~= "ready" then return end
    if laser.state ~= "ready" then return end  -- Can't use during laser
    plasma.state = "charging"
    plasma.timer = 0
    plasma.chargeProgress = 0

    -- Play charge sound immediately when starting
    Sounds.playPlasmaFire()
end

local function firePlasmaMissile()
    local muzzleX, muzzleY = tower:getMuzzleTip()

    -- Create plasma projectile with upgraded stats
    local plasmaSpeed = PLASMA_MISSILE_SPEED * stats.plasmaSpeed
    local plasmaDamage = PLASMA_DAMAGE * stats.plasmaDamage
    local plasmaSize = PLASMA_MISSILE_SIZE * stats.plasmaSize

    local proj = Projectile(muzzleX, muzzleY, tower.angle, plasmaSpeed, plasmaDamage)
    proj.isPlasma = true
    proj.piercing = true
    proj.hitEnemies = {}
    proj.size = plasmaSize
    proj.trailLength = 12  -- Longer trail for plasma

    -- Register intense purple light for this projectile
    proj.lightId = Lighting:addLight({
        x = proj.x,
        y = proj.y,
        radius = PLASMA_LIGHT_RADIUS,
        intensity = PLASMA_LIGHT_INTENSITY,
        color = PLASMA_COLOR,
        type = "projectile",
        owner = proj,
        pulse = 8,
        pulseAmount = 0.3,
    })

    table.insert(projectiles, proj)

    -- Big muzzle flash
    local flashX, flashY = tower:getMuzzleTip()
    Lighting:addLight({
        x = flashX,
        y = flashY,
        radius = 80,
        intensity = 1.0,
        color = PLASMA_COLOR,
        duration = 0.15,
    })

    -- Feedback
    Feedback:trigger("plasma_fire")
end

local function updatePlasma(dt)
    -- Calculate scaled times based on upgrades
    local chargeTime = PLASMA_CHARGE_TIME
    local cooldownTime = PLASMA_COOLDOWN_TIME * stats.plasmaCooldown

    if plasma.state == "ready" then
        return
    elseif plasma.state == "charging" then
        plasma.timer = plasma.timer + dt
        plasma.chargeProgress = math.min(1, plasma.timer / chargeTime)

        -- Subtle shake during charge
        if plasma.timer > chargeTime * 0.5 then
            Feedback:trigger("plasma_charge")
        end

        if plasma.timer >= chargeTime then
            -- Fire the plasma missile
            firePlasmaMissile()
            plasma.state = "cooldown"
            plasma.timer = 0
            plasma.chargeProgress = 0
        end
    elseif plasma.state == "cooldown" then
        plasma.timer = plasma.timer + dt
        if plasma.timer >= cooldownTime then
            plasma.state = "ready"
            plasma.timer = 0
        end
    end
end

local function drawPlasmaBarrelCharge()
    if plasma.chargeProgress <= 0 then return end

    local flinchX = tower.damageFlinch * math.cos(tower.angle + math.pi) * 2
    local flinchY = tower.damageFlinch * math.sin(tower.angle + math.pi) * 2
    local drawX = tower.x + flinchX
    local drawY = tower.y + flinchY

    love.graphics.push()
    love.graphics.translate(drawX, drawY)
    love.graphics.rotate(tower.angle)

    -- Match turret barrel dimensions exactly
    local BARREL_LENGTH = 50
    local BARREL_WIDTH = 14
    local BARREL_BACK = 15

    -- Account for gun kick like the turret does
    local kickBack = tower.gunKick * 10
    local barrelStart = -kickBack - BARREL_BACK
    local barrelTotal = BARREL_LENGTH + BARREL_BACK
    local halfWidth = BARREL_WIDTH / 2

    -- Charge fills from back to front progressively
    local chargeLength = barrelTotal * plasma.chargeProgress

    -- Purple glow intensity increases as charge progresses
    local glowIntensity = 0.4 + plasma.chargeProgress * 0.6
    local pulseTime = love.timer.getTime() * 10
    local pulse = 1 + math.sin(pulseTime) * 0.15 * plasma.chargeProgress

    -- Outer glow (extends slightly beyond barrel)
    love.graphics.setColor(PLASMA_COLOR[1], PLASMA_COLOR[2], PLASMA_COLOR[3], glowIntensity * 0.3 * pulse)
    love.graphics.rectangle("fill", barrelStart, -halfWidth - 4, chargeLength, BARREL_WIDTH + 8)

    -- Main fill (matches barrel exactly)
    love.graphics.setColor(PLASMA_COLOR[1], PLASMA_COLOR[2], PLASMA_COLOR[3], glowIntensity * 0.85 * pulse)
    love.graphics.rectangle("fill", barrelStart, -halfWidth, chargeLength, BARREL_WIDTH)

    -- Inner core (white-purple hot center)
    love.graphics.setColor(PLASMA_CORE_COLOR[1], PLASMA_CORE_COLOR[2], PLASMA_CORE_COLOR[3], glowIntensity * 0.7 * pulse)
    love.graphics.rectangle("fill", barrelStart, -halfWidth + 3, chargeLength, BARREL_WIDTH - 6)

    -- Leading edge spark at the charge front
    if plasma.chargeProgress > 0.05 then
        local sparkX = barrelStart + chargeLength
        local sparkSize = 3 + math.sin(pulseTime * 2) * 2 + plasma.chargeProgress * 3
        love.graphics.setColor(1, 1, 1, glowIntensity)
        love.graphics.circle("fill", sparkX, 0, sparkSize)
    end

    love.graphics.pop()
end

-- ===================
-- SPAWN SYSTEM (Continuous)
-- ===================
local function spawnEnemy()
    -- Spawn from just outside visible area (edge spawning)
    local left, top, right, bottom = Camera:getBounds()
    local margin = 100  -- Spawn margin outside visible area

    -- Pick random edge (0=top, 1=right, 2=bottom, 3=left)
    local edge = math.random(0, 3)
    local x, y

    if edge == 0 then  -- Top
        x = lume.random(left - margin, right + margin)
        y = top - margin
    elseif edge == 1 then  -- Right
        x = right + margin
        y = lume.random(top - margin, bottom + margin)
    elseif edge == 2 then  -- Bottom
        x = lume.random(left - margin, right + margin)
        y = bottom + margin
    else  -- Left
        x = left - margin
        y = lume.random(top - margin, bottom + margin)
    end

    -- Determine enemy type - all types available from start
    local enemyType = "basic"
    local roll = lume.random()

    -- Fixed spawn weights: 40% basic, 25% fast, 18% tank, 12% brute, 5% elite
    if roll < 0.05 then
        enemyType = "elite"
    elseif roll < 0.17 then
        enemyType = "brute"
    elseif roll < 0.35 then
        enemyType = "tank"
    elseif roll < 0.60 then
        enemyType = "fast"
    end

    local enemy = Enemy(x, y, 1.0, enemyType)
    table.insert(enemies, enemy)
end

local function spawnCompositeEnemy(templateName)
    local template = COMPOSITE_TEMPLATES[templateName]
    if not template then return end

    -- Spawn from just outside visible area (edge spawning)
    local left, top, right, bottom = Camera:getBounds()
    local margin = 100

    local edge = math.random(0, 3)
    local x, y

    if edge == 0 then  -- Top
        x = lume.random(left - margin, right + margin)
        y = top - margin
    elseif edge == 1 then  -- Right
        x = right + margin
        y = lume.random(top - margin, bottom + margin)
    elseif edge == 2 then  -- Bottom
        x = lume.random(left - margin, right + margin)
        y = bottom + margin
    else  -- Left
        x = left - margin
        y = lume.random(top - margin, bottom + margin)
    end

    local composite = CompositeEnemy(x, y, template, 0)
    table.insert(compositeEnemies, composite)
end

-- Spawn a random composite enemy based on game time
local function spawnRandomComposite()
    -- Available templates weighted by difficulty
    local templates = {"half_shielded_square", "shielded_square"}

    -- Add harder templates as game progresses
    if gameTime > 45 then
        table.insert(templates, "shielded_pentagon")
    end
    if gameTime > 90 then
        table.insert(templates, "half_shielded_hexagon")
    end
    if gameTime > 150 then
        table.insert(templates, "shielded_hexagon")
    end

    local templateName = templates[math.random(#templates)]
    spawnCompositeEnemy(templateName)
end

-- ===================
-- PROJECTILE SYSTEM
-- ===================
local function fireProjectile()
    local proj = tower:fire()
    if proj then
        -- Apply skill tree and roguelite damage multipliers
        proj.damage = proj.damage * stats.damage * Roguelite.runtimeStats.damageMult
        -- Add projectile light for grid illumination
        proj.lightId = Lighting:addProjectileLight(proj)
        table.insert(projectiles, proj)

        -- Add muzzle flash at visual barrel tip
        local flashX, flashY = tower:getMuzzleTip()
        Lighting:addMuzzleFlash(flashX, flashY, tower.angle)
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

    -- Also check composite enemies
    for _, composite in ipairs(compositeEnemies) do
        if not composite.dead and composite ~= excludeEnemy then
            local dist = composite:distanceTo(x, y)
            if dist < nearestDist then
                nearest = composite
                nearestDist = dist
            end
        end
    end

    return nearest, nearestDist
end

-- ===================
-- ARENA DRAWING
-- ===================

-- Draw geometric grid floor
local function drawArenaFloor()
    -- Background fill
    Parallax:drawBackground()

    -- Main grid (with gravity well effect)
    Parallax:drawGrid()
end

-- ===================
-- CROSSHAIR (Manual Aiming Mode)
-- ===================
local function drawScopeCursor()
    -- Draw crosshair cursor in all game states
    -- Use screen coordinates (not world) since this is drawn outside camera transform
    local mx, my = getMousePositionScaled()
    -- Snap to pixels for crisp pixely look
    mx, my = math.floor(mx), math.floor(my)

    local gap = CROSSHAIR_GAP
    local len = CROSSHAIR_LENGTH

    -- Draw bloom/glow layers (outer to inner)
    for i = CROSSHAIR_GLOW_LAYERS, 1, -1 do
        local spread = i * CROSSHAIR_GLOW_SPREAD
        local alpha = CROSSHAIR_COLOR[4] * (0.15 / i)  -- Fading alpha for outer layers
        local thickness = CROSSHAIR_THICKNESS + spread * 2

        love.graphics.setColor(CROSSHAIR_COLOR[1], CROSSHAIR_COLOR[2], CROSSHAIR_COLOR[3], alpha)
        love.graphics.setLineWidth(thickness)

        -- Extended cross for glow
        love.graphics.line(mx - gap - len, my, mx - gap, my)  -- Left
        love.graphics.line(mx + gap, my, mx + gap + len, my)  -- Right
        love.graphics.line(mx, my - gap - len, mx, my - gap)  -- Up
        love.graphics.line(mx, my + gap, mx, my + gap + len)  -- Down
    end

    -- Draw core crosshair (bright)
    love.graphics.setColor(CROSSHAIR_COLOR[1], CROSSHAIR_COLOR[2], CROSSHAIR_COLOR[3], CROSSHAIR_COLOR[4])
    love.graphics.setLineWidth(CROSSHAIR_THICKNESS)

    love.graphics.line(mx - gap - len, my, mx - gap, my)  -- Left
    love.graphics.line(mx + gap, my, mx + gap + len, my)  -- Right
    love.graphics.line(mx, my - gap - len, mx, my - gap)  -- Up
    love.graphics.line(mx, my + gap, mx, my + gap + len)  -- Down

    love.graphics.setLineWidth(1)
end

-- ===================
-- UI DRAWING
-- ===================
local function drawUI()
    -- ===================
    -- NEON UI STYLING
    -- ===================

    -- Time and enemy count (neon green)
    love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.9)
    local minutes = math.floor(gameTime / 60)
    local seconds = math.floor(gameTime % 60)
    love.graphics.print(string.format("Time: %d:%02d", minutes, seconds), 10, 10)
    love.graphics.print("Enemies: " .. (#enemies + #compositeEnemies), 10, 30)

    -- Game speed indicator
    local currentSpeed = GAME_SPEEDS[gameSpeedIndex]
    local speedText
    if currentSpeed == 0 then
        love.graphics.setColor(NEON_RED[1], NEON_RED[2], NEON_RED[3], 0.9)
        speedText = "PAUSED [Z]"
    elseif currentSpeed < 1 then
        love.graphics.setColor(NEON_CYAN[1], NEON_CYAN[2], NEON_CYAN[3], 0.9)
        speedText = "Speed: " .. currentSpeed .. "x [Z]"
    elseif currentSpeed > 1 then
        love.graphics.setColor(NEON_YELLOW[1], NEON_YELLOW[2], NEON_YELLOW[3], 0.9)
        speedText = "Speed: " .. currentSpeed .. "x [Z]"
    else
        love.graphics.setColor(NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.7)
        speedText = "Speed: " .. currentSpeed .. "x [Z]"
    end
    love.graphics.print(speedText, 10, 50)

    -- God mode indicator
    if godMode then
        love.graphics.setColor(NEON_CYAN[1], NEON_CYAN[2], NEON_CYAN[3], 0.9)
        love.graphics.print("GOD MODE [G]", 10, 70)
    end

    -- Auto-fire mode indicator
    local autoFireY = godMode and 90 or 70
    if autoFire then
        love.graphics.setColor(NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.7)
        love.graphics.print("Auto-Fire: ON [X]", 10, autoFireY)
    else
        love.graphics.setColor(NEON_RED[1], NEON_RED[2], NEON_RED[3], 0.9)
        love.graphics.print("Manual Aim [X]", 10, autoFireY)
    end

    -- Tower HP bar with neon styling
    love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.9)
    love.graphics.print("CORE HP", WINDOW_WIDTH - 110, 10)

    local hpBarWidth = 100
    local hpBarHeight = 14
    local hpPercent = tower:getHpPercent()

    -- Dark fill background
    love.graphics.setColor(0.02, 0.05, 0.02, 0.9)
    love.graphics.rectangle("fill", WINDOW_WIDTH - 110, 30, hpBarWidth, hpBarHeight)

    -- HP bar color based on health
    local hpColor = {NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3]}
    if hpPercent < 0.3 then
        hpColor = {NEON_RED[1], NEON_RED[2], NEON_RED[3]}
    elseif hpPercent < 0.6 then
        hpColor = {NEON_YELLOW[1], NEON_YELLOW[2], NEON_YELLOW[3]}
    end

    -- HP fill with glow
    love.graphics.setColor(hpColor[1], hpColor[2], hpColor[3], 0.3)
    love.graphics.rectangle("fill", WINDOW_WIDTH - 110, 30, hpBarWidth * hpPercent, hpBarHeight)
    love.graphics.setColor(hpColor[1], hpColor[2], hpColor[3], 0.8)
    love.graphics.rectangle("fill", WINDOW_WIDTH - 110, 32, hpBarWidth * hpPercent, hpBarHeight - 4)

    -- Neon border
    love.graphics.setColor(hpColor[1], hpColor[2], hpColor[3], 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", WINDOW_WIDTH - 110, 30, hpBarWidth, hpBarHeight)
    love.graphics.setLineWidth(1)

    -- HP text inside bar
    local hpText = math.floor(tower.hp) .. "/" .. math.floor(tower.maxHp)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(hpText)
    local textHeight = font:getHeight()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(hpText, WINDOW_WIDTH - 110 + (hpBarWidth - textWidth) / 2, 30 + (hpBarHeight - textHeight) / 2)

    -- Gold (current run) - yellow neon
    love.graphics.setColor(NEON_YELLOW[1], NEON_YELLOW[2], NEON_YELLOW[3], 0.9)
    love.graphics.print("Gold: " .. totalGold, WINDOW_WIDTH - 110, 50)

    -- XP Bar and Level - purple neon
    local xpBarX = WINDOW_WIDTH - 160
    local xpBarY = 70
    local xpBarWidth = 150
    local xpBarHeight = 14

    -- Level text
    love.graphics.setColor(POLYGON_COLOR[1], POLYGON_COLOR[2], POLYGON_COLOR[3], 0.9)
    love.graphics.print("LVL " .. Roguelite.level, xpBarX, xpBarY - 16)

    -- XP bar background
    love.graphics.setColor(0.02, 0.02, 0.05, 0.9)
    love.graphics.rectangle("fill", xpBarX, xpBarY, xpBarWidth, xpBarHeight)

    -- XP bar fill
    local xpProgress = Roguelite:getXPProgress()
    love.graphics.setColor(POLYGON_COLOR[1], POLYGON_COLOR[2], POLYGON_COLOR[3], 0.4)
    love.graphics.rectangle("fill", xpBarX, xpBarY, xpBarWidth * xpProgress, xpBarHeight)
    love.graphics.setColor(POLYGON_COLOR[1], POLYGON_COLOR[2], POLYGON_COLOR[3], 0.8)
    love.graphics.rectangle("fill", xpBarX, xpBarY + 2, xpBarWidth * xpProgress, xpBarHeight - 4)

    -- XP bar border
    love.graphics.setColor(POLYGON_COLOR[1], POLYGON_COLOR[2], POLYGON_COLOR[3], 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", xpBarX, xpBarY, xpBarWidth, xpBarHeight)
    love.graphics.setLineWidth(1)

    -- XP text inside bar
    local xpText = math.floor(Roguelite.currentXP) .. "/" .. math.floor(Roguelite.xpToNextLevel)
    local xpTextW = font:getWidth(xpText)
    local xpTextH = font:getHeight()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(xpText, xpBarX + (xpBarWidth - xpTextW) / 2, xpBarY + (xpBarHeight - xpTextH) / 2)

    -- Laser button with neon styling
    local laserY = WINDOW_HEIGHT - 60
    local laserWidth = 90
    local laserHeight = 30

    -- Dark background
    love.graphics.setColor(0.02, 0.05, 0.02, 0.9)
    love.graphics.rectangle("fill", 10, laserY, laserWidth, laserHeight)

    if laser.state == "ready" then
        -- Ready glow
        love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.4)
        love.graphics.rectangle("fill", 10, laserY, laserWidth, laserHeight)
        love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.8)
        love.graphics.rectangle("fill", 12, laserY + 2, laserWidth - 4, laserHeight - 4)

        -- Border glow
        love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 10, laserY, laserWidth, laserHeight)
        love.graphics.setLineWidth(1)

        -- Text
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("[1] LASER", 18, laserY + 8)
    elseif laser.state == "deploying" or laser.state == "charging" then
        -- Charging progress fill (green to white based on charge)
        local chargePercent
        if laser.state == "deploying" then
            chargePercent = (laser.timer / LASER_DEPLOY_TIME) * 0.1
        else
            chargePercent = 0.1 + (laser.timer / LASER_CHARGE_TIME) * 0.9
        end

        -- Interpolate from green to white based on charge
        local whiteBlend = laser.chargeGlow
        local r = NEON_PRIMARY[1] + (1 - NEON_PRIMARY[1]) * whiteBlend
        local g = NEON_PRIMARY[2]
        local b = NEON_PRIMARY[3] + (1 - NEON_PRIMARY[3]) * whiteBlend

        love.graphics.setColor(r, g, b, 0.5)
        love.graphics.rectangle("fill", 10, laserY, laserWidth * chargePercent, laserHeight)

        -- Border
        love.graphics.setColor(r, g, b, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 10, laserY, laserWidth, laserHeight)
        love.graphics.setLineWidth(1)

        -- Text
        love.graphics.setColor(r, g, b, 1)
        love.graphics.print("CHARGING", 22, laserY + 8)
    elseif laser.state == "firing" then
        -- Firing glow (pulsing)
        local pulse = 0.6 + math.sin(love.timer.getTime() * 15) * 0.4
        love.graphics.setColor(1, 1, 1, pulse * 0.6)
        love.graphics.rectangle("fill", 10, laserY, laserWidth, laserHeight)

        -- Border
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 10, laserY, laserWidth, laserHeight)
        love.graphics.setLineWidth(1)

        -- Text
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print("FIRING!", 26, laserY + 8)
    else
        -- Retracting (dim)
        love.graphics.setColor(NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.3)
        love.graphics.rectangle("fill", 10, laserY, laserWidth * laser.cannonExtend, laserHeight)

        -- Border
        love.graphics.setColor(NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", 10, laserY, laserWidth, laserHeight)

        -- Text
        love.graphics.setColor(NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.7)
        love.graphics.print("[1] LASER", 18, laserY + 8)
    end

    -- Plasma button with purple neon styling
    local plasmaX = 110
    local plasmaY = WINDOW_HEIGHT - 60
    local plasmaWidth = 90
    local plasmaHeight = 30

    -- Dark background
    love.graphics.setColor(0.03, 0.01, 0.05, 0.9)
    love.graphics.rectangle("fill", plasmaX, plasmaY, plasmaWidth, plasmaHeight)

    if plasma.state == "ready" then
        -- Ready glow (purple)
        love.graphics.setColor(PLASMA_COLOR[1], PLASMA_COLOR[2], PLASMA_COLOR[3], 0.4)
        love.graphics.rectangle("fill", plasmaX, plasmaY, plasmaWidth, plasmaHeight)
        love.graphics.setColor(PLASMA_COLOR[1], PLASMA_COLOR[2], PLASMA_COLOR[3], 0.8)
        love.graphics.rectangle("fill", plasmaX + 2, plasmaY + 2, plasmaWidth - 4, plasmaHeight - 4)

        -- Border glow
        love.graphics.setColor(PLASMA_COLOR[1], PLASMA_COLOR[2], PLASMA_COLOR[3], 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", plasmaX, plasmaY, plasmaWidth, plasmaHeight)
        love.graphics.setLineWidth(1)

        -- Text
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("[2] PLASMA", plasmaX + 6, plasmaY + 8)
    elseif plasma.state == "charging" then
        -- Charging progress fill (purple to white based on charge)
        local chargePercent = plasma.chargeProgress

        -- Interpolate from purple to white based on charge
        local whiteBlend = plasma.chargeProgress
        local r = PLASMA_COLOR[1] + (1 - PLASMA_COLOR[1]) * whiteBlend
        local g = PLASMA_COLOR[2] + (1 - PLASMA_COLOR[2]) * whiteBlend
        local b = PLASMA_COLOR[3]

        love.graphics.setColor(r, g, b, 0.5)
        love.graphics.rectangle("fill", plasmaX, plasmaY, plasmaWidth * chargePercent, plasmaHeight)

        -- Border
        love.graphics.setColor(r, g, b, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", plasmaX, plasmaY, plasmaWidth, plasmaHeight)
        love.graphics.setLineWidth(1)

        -- Text
        love.graphics.setColor(r, g, b, 1)
        love.graphics.print("CHARGING", plasmaX + 10, plasmaY + 8)
    else
        -- Cooldown (dim purple with progress)
        local cooldownTime = PLASMA_COOLDOWN_TIME * stats.plasmaCooldown
        local cooldownPercent = plasma.timer / cooldownTime
        love.graphics.setColor(PLASMA_COLOR[1] * 0.4, PLASMA_COLOR[2] * 0.4, PLASMA_COLOR[3] * 0.4, 0.3)
        love.graphics.rectangle("fill", plasmaX, plasmaY, plasmaWidth * cooldownPercent, plasmaHeight)

        -- Border
        love.graphics.setColor(PLASMA_COLOR[1] * 0.5, PLASMA_COLOR[2] * 0.5, PLASMA_COLOR[3] * 0.5, 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", plasmaX, plasmaY, plasmaWidth, plasmaHeight)

        -- Text
        love.graphics.setColor(PLASMA_COLOR[1] * 0.5, PLASMA_COLOR[2] * 0.5, PLASMA_COLOR[3] * 0.5, 0.7)
        love.graphics.print("[2] PLASMA", plasmaX + 6, plasmaY + 8)
    end

    -- Shield charges indicator (below ability buttons)
    if tower.shield and tower.shield.maxCharges > 0 then
        local shieldX = 10
        local shieldY = WINDOW_HEIGHT - 25
        local shieldWidth = 90
        local shieldHeight = 16

        -- Background
        love.graphics.setColor(0.02, 0.03, 0.05, 0.9)
        love.graphics.rectangle("fill", shieldX, shieldY, shieldWidth, shieldHeight)

        -- Charge fill
        local chargeRatio = tower.shield:getChargeRatio()
        if chargeRatio > 0 then
            love.graphics.setColor(NEON_CYAN[1], NEON_CYAN[2], NEON_CYAN[3], 0.6)
            love.graphics.rectangle("fill", shieldX, shieldY, shieldWidth * chargeRatio, shieldHeight)
        end

        -- Border
        local borderAlpha = chargeRatio > 0 and 0.8 or 0.3
        love.graphics.setColor(NEON_CYAN[1], NEON_CYAN[2], NEON_CYAN[3], borderAlpha)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", shieldX, shieldY, shieldWidth, shieldHeight)

        -- Text
        local textAlpha = chargeRatio > 0 and 1 or 0.5
        love.graphics.setColor(1, 1, 1, textAlpha)
        love.graphics.print("Shield: " .. tower.shield.charges, shieldX + 5, shieldY + 2)
    end
end

-- Ease-out cubic function for smooth deceleration
local function easeOutCubic(t)
    return 1 - math.pow(1 - t, 3)
end

-- Initialize game over animation
local function initGameOverAnim()
    gameOverAnim.phase = "fade_in"
    gameOverAnim.timer = 0
    gameOverAnim.titleAlpha = 0
    gameOverAnim.titleY = CENTER_Y * 0.3  -- 30% from top
    gameOverAnim.statRevealProgress = 0
    gameOverAnim.overlayAlpha = 0
end

-- Update game over animation state machine
local function updateGameOverAnim(dt)
    if gameOverAnim.phase == "none" then return end

    gameOverAnim.timer = gameOverAnim.timer + dt

    if gameOverAnim.phase == "fade_in" then
        local t = math.min(gameOverAnim.timer / GAMEOVER_FADE_DURATION, 1)
        gameOverAnim.overlayAlpha = easeOutCubic(t) * 0.85
        if t >= 1 then
            gameOverAnim.phase = "title_hold"
            gameOverAnim.timer = 0
        end

    elseif gameOverAnim.phase == "title_hold" then
        -- Fade in title
        local fadeT = math.min(gameOverAnim.timer / GAMEOVER_TITLE_FADE_DURATION, 1)
        gameOverAnim.titleAlpha = easeOutCubic(fadeT)

        -- Auto-advance to reveal after timeout
        if gameOverAnim.timer >= GAMEOVER_TITLE_HOLD_TIMEOUT then
            gameOverAnim.phase = "reveal"
            gameOverAnim.timer = 0
        end

    elseif gameOverAnim.phase == "reveal" then
        local t = math.min(gameOverAnim.timer / GAMEOVER_REVEAL_DURATION, 1)
        gameOverAnim.statRevealProgress = easeOutCubic(t)

        if t >= 1 then
            gameOverAnim.phase = "complete"
            gameOverAnim.timer = 0
        end

    -- "complete" phase: nothing to update, just wait for input
    end
end

-- Trigger reveal phase (called on keypress during title_hold)
local function triggerGameOverReveal()
    if gameOverAnim.phase == "title_hold" then
        gameOverAnim.phase = "reveal"
        gameOverAnim.timer = 0
    end
end

local function drawGameOver()
    -- Don't draw if animation hasn't started
    if gameOverAnim.phase == "none" then return end

    local font = love.graphics.getFont()
    local title = "SYSTEM FAILURE"
    local titleWidth = font:getWidth(title)

    -- Layout constants
    local titleYBase = CENTER_Y * 0.3      -- ~30% from top when revealed
    local titleYStart = CENTER_Y - 80      -- Initial centered position
    local statsStartY = CENTER_Y * 0.45    -- Stats start at ~45% from top
    local statLineHeight = 20
    local buttonsY = CENTER_Y * 0.7        -- Buttons at ~70% from top

    -- Dark overlay
    love.graphics.setColor(0.01, 0.03, 0.01, gameOverAnim.overlayAlpha)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    -- During fade_in, just draw overlay
    if gameOverAnim.phase == "fade_in" then return end

    -- Calculate title position (slides up during reveal)
    local titleY
    if gameOverAnim.phase == "title_hold" then
        titleY = titleYStart
    else
        -- Interpolate from center to top position during reveal
        titleY = lume.lerp(titleYStart, titleYBase, gameOverAnim.statRevealProgress)
    end
    local titleX = CENTER_X - titleWidth / 2

    -- Title with red neon glow
    local titleAlpha = gameOverAnim.titleAlpha
    love.graphics.setColor(NEON_RED[1], NEON_RED[2], NEON_RED[3], 0.3 * titleAlpha)
    love.graphics.print(title, titleX - 1, titleY - 1)
    love.graphics.print(title, titleX + 1, titleY + 1)
    love.graphics.setColor(NEON_RED[1], NEON_RED[2], NEON_RED[3], titleAlpha)
    love.graphics.print(title, titleX, titleY)

    -- Don't draw stats during title_hold phase
    if gameOverAnim.phase == "title_hold" then return end

    -- Stats with staggered reveal
    local statsX = CENTER_X - 70
    local revealProgress = gameOverAnim.statRevealProgress

    -- Helper to get alpha for a specific stat index (0-based)
    local function getStatAlpha(index)
        local statStart = index * GAMEOVER_STAT_STAGGER
        local statProgress = (revealProgress - statStart) / (1 - statStart)
        return math.max(0, math.min(1, statProgress)) * 0.9
    end

    -- Time Survived (green)
    local minutes = math.floor(gameTime / 60)
    local seconds = math.floor(gameTime % 60)
    love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], getStatAlpha(0))
    love.graphics.print(string.format("Time Survived: %d:%02d", minutes, seconds), statsX, statsStartY)

    -- Enemies Destroyed (green)
    love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], getStatAlpha(1))
    love.graphics.print("Enemies Destroyed: " .. totalKills, statsX, statsStartY + statLineHeight)

    -- Credits Earned (yellow)
    love.graphics.setColor(NEON_YELLOW[1], NEON_YELLOW[2], NEON_YELLOW[3], getStatAlpha(2))
    love.graphics.print("Credits Earned: +" .. gold, statsX, statsStartY + statLineHeight * 2)

    -- Total Credits (yellow)
    love.graphics.setColor(NEON_YELLOW[1], NEON_YELLOW[2], NEON_YELLOW[3], getStatAlpha(3))
    love.graphics.print("Total Credits: " .. totalGold, statsX, statsStartY + statLineHeight * 3)

    -- Polygons (purple)
    love.graphics.setColor(POLYGON_COLOR[1], POLYGON_COLOR[2], POLYGON_COLOR[3], getStatAlpha(4))
    love.graphics.print("Polygons: P" .. polygons, statsX, statsStartY + statLineHeight * 4)

    -- Only show buttons when animation is complete
    if gameOverAnim.phase == "complete" then
        -- [R] REBOOT
        love.graphics.setColor(NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.7)
        love.graphics.print("[R] REBOOT", CENTER_X - 100, buttonsY)

        -- [S] SKILL TREE
        love.graphics.setColor(NEON_CYAN[1], NEON_CYAN[2], NEON_CYAN[3], 0.8)
        love.graphics.print("[S] SKILL TREE", CENTER_X + 20, buttonsY)
    end
end

-- ===================
-- GAME RESET
-- ===================
function startNewRun()
    gameState = "playing"

    -- Reset roguelite progression for new run
    Roguelite:reset()
    LevelUpUI:init()

    -- Apply skill tree upgrades
    SkillTree:applyUpgrades(stats)

    -- Create tower with upgraded HP
    tower = Turret(CENTER_X, CENTER_Y)
    tower.lightId = Lighting:addTowerGlow(tower)

    -- Initialize camera to follow tower
    Camera:init(tower.x, tower.y)
    tower.maxHp = TOWER_HP + stats.maxHp
    tower.hp = tower.maxHp
    tower.fireRate = TOWER_FIRE_RATE / stats.fireRate
    tower.projectileSpeed = PROJECTILE_SPEED * stats.projectileSpeed

    -- Reset game state
    enemies = {}
    compositeEnemies = {}
    projectiles = {}
    particles = {}
    damageNumbers = {}
    chunks = {}
    flyingParts = {}
    dustParticles = {}
    clearCollectibleShards()
    drones = {}
    droneProjectiles = {}
    enemyProjectiles = {}
    aoeWarnings = {}
    damageAura = nil
    gold = 0
    totalKills = 0

    -- Reset game over animation
    gameOverAnim.phase = "none"

    -- Reset laser state
    laser.state = "ready"
    laser.timer = 0
    laser.cannonExtend = 0
    laser.chargeGlow = 0
    laser.damageAccum = 0
    laser.hitEnemies = {}
    Sounds.stopLaser()

    -- Reset plasma state
    plasma.state = "ready"
    plasma.timer = 0
    plasma.chargeProgress = 0

    -- Reset spawning system
    gameTime = 0
    spawnAccumulator = 0
    currentSpawnRate = SPAWN_RATE

    -- TEST: Spawn one of each composite template for testing
    local testTemplates = {}
    for name, _ in pairs(COMPOSITE_TEMPLATES) do
        table.insert(testTemplates, name)
    end
    table.sort(testTemplates)  -- Consistent order
    local spawnRadius = 300
    for i, templateName in ipairs(testTemplates) do
        local angle = (i - 1) * (2 * math.pi / #testTemplates)
        local x = CENTER_X + math.cos(angle) * spawnRadius
        local y = CENTER_Y + math.sin(angle) * spawnRadius
        local composite = CompositeEnemy(x, y, COMPOSITE_TEMPLATES[templateName], 0)
        table.insert(compositeEnemies, composite)
    end

    -- Reset feedback, debris, and lighting state
    Feedback:reset()
    DebrisManager:reset()
    Lighting:reset()
    Parallax:reset()

    -- Create drones based on skill tree
    for i = 1, stats.droneCount do
        local drone = Drone(tower, i - 1, stats.droneCount)
        drone.fireRate = DRONE_BASE_FIRE_RATE / stats.droneFireRate

        -- Add drone glow light
        drone.lightId = Lighting:addLight({
            x = drone.x,
            y = drone.y,
            radius = DRONE_LIGHT_RADIUS,
            intensity = DRONE_LIGHT_INTENSITY,
            color = DRONE_COLOR,
            owner = drone,
            pulse = 2,
            pulseAmount = 0.15,
        })

        table.insert(drones, drone)
    end

    -- Create shield if unlocked
    if stats.shieldUnlocked then
        tower.shield = Shield(tower)
        tower.shield:setCharges(stats.shieldCharges, stats.shieldCharges)
        tower.shield:setRadius(stats.shieldRadius)
    else
        tower.shield = nil
    end

    -- Create silos based on skill tree
    silos = {}
    missiles = {}
    if stats.siloCount > 0 then
        for i = 1, stats.siloCount do
            local silo = Silo(tower, i - 1, stats.siloCount)
            silo.fireRate = SILO_BASE_FIRE_RATE / stats.siloFireRate
            silo.doubleShot = stats.siloDoubleShot
            table.insert(silos, silo)
        end
    end

    -- Start background music
    Sounds.playMusic()
end

-- Trigger reboot animation before starting a new run
-- This plays the "SYSTEM ONLINE" + turret animation without the text phases
function triggerRebootAnimation()
    -- Stop any playing music
    Sounds.stopMusic()
    Sounds.stopLaser()

    -- Clear all game entities for a clean arena during animation
    enemies = {}
    compositeEnemies = {}
    projectiles = {}
    particles = {}
    damageNumbers = {}
    chunks = {}
    flyingParts = {}
    dustParticles = {}
    clearCollectibleShards()
    drones = {}
    droneProjectiles = {}
    enemyProjectiles = {}
    aoeWarnings = {}
    damageAura = nil
    silos = {}
    missiles = {}

    -- Reset lighting
    Lighting:reset()

    -- Keep or create tower for the animation
    if not tower then
        tower = Turret(CENTER_X, CENTER_Y)
    else
        -- Reset tower position for animation
        tower.x = CENTER_X
        tower.y = CENTER_Y
    end
    tower.lightId = Lighting:addTowerGlow(tower)

    -- Start the reboot animation
    gameState = "intro"
    Intro:startReboot()
end

-- Sync roguelite abilities mid-run (called when upgrades are selected)
local function syncRogueliteAbilities()
    local rs = Roguelite.runtimeStats

    -- Update tower fire rate with roguelite multiplier
    tower.fireRate = TOWER_FIRE_RATE / (stats.fireRate * rs.fireRateMult)
    tower.projectileSpeed = PROJECTILE_SPEED * stats.projectileSpeed * rs.projectileSpeedMult

    -- Sync shield
    if rs.shieldCharges > 0 then
        if not tower.shield then
            tower.shield = Shield(tower)
        end
        tower.shield:setCharges(rs.shieldCharges, rs.shieldCharges)
        tower.shield:setRadius(stats.shieldRadius)
    end

    -- Sync drones
    local currentDroneCount = #drones
    local targetDroneCount = stats.droneCount + rs.droneCount
    if targetDroneCount > currentDroneCount then
        -- Add new drones
        for i = currentDroneCount + 1, targetDroneCount do
            local drone = Drone(tower, i - 1, targetDroneCount)
            drone.fireRate = DRONE_BASE_FIRE_RATE / stats.droneFireRate

            -- Add drone glow light
            drone.lightId = Lighting:addLight({
                x = drone.x,
                y = drone.y,
                radius = DRONE_LIGHT_RADIUS,
                intensity = DRONE_LIGHT_INTENSITY,
                color = DRONE_COLOR,
                owner = drone,
                pulse = 2,
                pulseAmount = 0.15,
            })

            table.insert(drones, drone)
        end
        -- Reposition existing drones for even spacing
        for i, drone in ipairs(drones) do
            drone.orbitIndex = i - 1
            local spacing = (2 * math.pi) / targetDroneCount
            drone.orbitAngle = (i - 1) * spacing
            drone:updateOrbitPosition()
        end
    end

    -- Sync silos
    local currentSiloCount = #silos
    local targetSiloCount = stats.siloCount + rs.siloCount
    if targetSiloCount > currentSiloCount then
        -- Add new silos
        for i = currentSiloCount + 1, targetSiloCount do
            local silo = Silo(tower, i - 1, targetSiloCount)
            silo.fireRate = SILO_BASE_FIRE_RATE / stats.siloFireRate
            silo.doubleShot = stats.siloDoubleShot
            table.insert(silos, silo)
        end
        -- Reposition existing silos for even spacing
        for i, silo in ipairs(silos) do
            silo.orbitIndex = i - 1
            local spacing = (2 * math.pi) / targetSiloCount
            silo.orbitAngle = (i - 1) * spacing
            silo:updateOrbitPosition()
        end
    end

    -- Sync damage aura
    if rs.auraEnabled and not damageAura then
        damageAura = DamageAura(tower)
    end
    if damageAura then
        damageAura:setStats(rs.auraDamageMult, rs.auraRadiusMult)
    end
end

-- ===================
-- LOVE CALLBACKS
-- ===================
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setTitle("Tower Idle Roguelite")
    love.mouse.setVisible(false)  -- Always use custom crosshair cursor

    -- Enable window resizing for fullscreen support
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
        resizable = true,
        minwidth = WINDOW_WIDTH / 2,
        minheight = WINDOW_HEIGHT / 2,
    })
    updateScale()

    -- Load and set custom pixel font
    local gameFont = love.graphics.newFont(FONT_PATH, FONT_SIZE)
    gameFont:setFilter("nearest", "nearest")  -- Crisp pixel rendering
    love.graphics.setFont(gameFont)

    Sounds.init()
    DebrisManager:init()
    Lighting:init()
    DebugConsole:init()
    SkillTree:init()
    SettingsMenu:init()
    PostFX:init()
    Intro:init()
    initGround()
    Parallax:init()

    -- Start in intro state if enabled, otherwise go straight to playing
    if INTRO_ENABLED then
        gameState = "intro"
        Intro:start()
        -- Create tower for intro animation (but don't start full run yet)
        tower = Turret(CENTER_X, CENTER_Y)
        tower.lightId = Lighting:addTowerGlow(tower)
    else
        startNewRun()
    end
end

function love.resize(w, h)
    updateScale()
    PostFX:resize(w, h)
end

function love.update(dt)
    -- Update debug console (always, even when paused)
    DebugConsole:update(dt)

    -- Update post-processing effects (always, for animated shaders)
    PostFX:update(dt)

    -- Update intro if active
    if gameState == "intro" then
        Intro:update(dt)
        if Intro:isComplete() then
            gameState = "playing"
            startNewRun()
        end
        return
    end

    -- Update skill tree if active
    if gameState == "skilltree" then
        SkillTree:update(dt)

        -- Update play transition if active
        if SkillTree:isPlayTransitionActive() then
            if SkillTree:updatePlayTransition(dt) then
                -- Transition complete, play reboot animation then start
                triggerRebootAnimation()
            end
        end
        return
    end

    -- Update settings menu if active
    if gameState == "settings" then
        SettingsMenu:update(dt)
        return
    end

    if gameState == "gameover" then
        updateGameOverAnim(dt)
        return
    end

    -- Level-up selection pauses gameplay
    if Roguelite.levelUpPending then
        LevelUpUI:update(dt, Roguelite)
        return
    end

    -- Sync abilities after level-up completed (check if abilities need updating)
    syncRogueliteAbilities()

    -- Apply game speed
    dt = dt * GAME_SPEEDS[gameSpeedIndex]

    -- Update Feedback system (returns 0 during hit-stop to freeze gameplay)
    local gameDt = Feedback:update(dt)

    -- Update laser beam system (uses both raw dt and gameDt)
    updateLaser(dt, gameDt)

    -- Update plasma missile system
    updatePlasma(dt)

    -- Continuous spawning (uses gameDt to freeze during hit-stop)
    gameTime = gameTime + gameDt
    currentSpawnRate = SPAWN_RATE + (gameTime * SPAWN_RATE_INCREASE)

    local totalEnemyCount = #enemies + #compositeEnemies
    spawnAccumulator = spawnAccumulator + gameDt * currentSpawnRate
    while spawnAccumulator >= 1 and totalEnemyCount < MAX_ENEMIES do
        spawnAccumulator = spawnAccumulator - 1

        -- 15% chance to spawn composite (after 10 seconds), otherwise regular enemy
        if gameTime > 10 and lume.random() < 0.15 then
            spawnRandomComposite()
        else
            spawnEnemy()
        end
        totalEnemyCount = totalEnemyCount + 1
    end

    -- Find target for tower (only used in auto-fire mode)
    local target = nil
    if autoFire then
        target = findNearestEnemy(tower.x, tower.y, nil)
    end

    -- Update tower - use raw dt during laser so turret can track while firing
    local turretDt = (laser.state == "firing" or laser.state == "charging") and dt or gameDt
    if autoFire and target then
        -- Auto-fire mode: aim at nearest enemy and auto-fire
        tower:update(turretDt, target.x, target.y)
        if tower:canFire() and laser.state == "ready" then
            fireProjectile()
        end
    else
        -- Manual mode OR no enemies: aim at mouse cursor
        local mx, my = getMousePosition()
        tower:update(turretDt, mx, my)

        -- Manual mode: auto-fire when holding mouse button
        if not autoFire and love.mouse.isDown(1) and tower:canFire() and laser.state == "ready" then
            fireProjectile()
        end
    end

    -- Update camera to follow tower
    Camera:update(tower.x, tower.y, gameDt)

    -- Update parallax dust particles
    Parallax:update(gameDt)

    -- Update drones
    for _, drone in ipairs(drones) do
        drone:update(gameDt, collectibleShards)

        -- Auto-fire at nearest idle shard
        local shardTarget = drone:findNearestShard(collectibleShards)
        if shardTarget and drone:canFire() then
            local proj = drone:fire()
            if proj then
                -- Track hit shards to prevent double-hits
                proj.hitShards = proj.hitShards or {}

                -- Add purple drone projectile light
                proj.lightId = Lighting:addLight({
                    x = proj.x,
                    y = proj.y,
                    radius = DRONE_LIGHT_RADIUS * 0.8,
                    intensity = DRONE_LIGHT_INTENSITY,
                    color = DRONE_COLOR,
                    owner = proj,
                })

                -- Add muzzle flash
                local flashX, flashY = drone:getMuzzleTip()
                Lighting:addLight({
                    x = flashX,
                    y = flashY,
                    radius = 25,
                    intensity = 0.8,
                    color = DRONE_COLOR,
                    duration = 0.05,
                })

                table.insert(droneProjectiles, proj)
            end
        end
    end

    -- Update drone projectiles (only hit shards, not enemies)
    for i = #droneProjectiles, 1, -1 do
        local proj = droneProjectiles[i]
        proj:update(gameDt)

        -- Track hit shards
        proj.hitShards = proj.hitShards or {}

        -- Only check collision with collectible shards
        for _, shard in ipairs(collectibleShards) do
            if shard.state == "idle" and not shard.dead and not proj.hitShards[shard] then
                if shard:checkProjectileHit(proj.x, proj.y) then
                    proj.hitShards[shard] = true

                    -- Shatter the shard
                    local fragments = shard:shatter(tower.x, tower.y)
                    for _, frag in ipairs(fragments) do
                        -- Add light to fragment
                        frag.lightId = Lighting:addLight({
                            x = frag.x,
                            y = frag.y,
                            radius = POLYGON_LIGHT_RADIUS * 0.5,
                            intensity = POLYGON_LIGHT_INTENSITY,
                            color = POLYGON_COLOR,
                            owner = frag,
                        })
                        table.insert(collectibleShards, frag)
                    end

                    -- Remove original shard's light
                    if shard.lightId then
                        Lighting:removeLight(shard.lightId)
                    end
                    shard.dead = true
                    proj.dead = true
                    break
                end
            end
        end

        if proj.dead then
            if proj.lightId then
                Lighting:removeLight(proj.lightId)
            end
            table.remove(droneProjectiles, i)
        end
    end

    -- Update silos and spawn missiles
    for _, silo in ipairs(silos) do
        local fireData = silo:update(gameDt)
        if fireData then
            -- Spawn missile(s)
            for _ = 1, fireData.count do
                local missile = Missile(fireData.x, fireData.y)
                missile.lightId = Lighting:addLight({
                    x = missile.x,
                    y = missile.y,
                    radius = MISSILE_LIGHT_RADIUS,
                    intensity = MISSILE_LIGHT_INTENSITY,
                    color = MISSILE_COLOR,
                    owner = missile,
                })

                -- Find random target from alive enemies
                local validEnemies = {}
                for _, enemy in ipairs(enemies) do
                    if not enemy.dead then
                        table.insert(validEnemies, enemy)
                    end
                end
                if #validEnemies > 0 then
                    missile.target = validEnemies[math.random(#validEnemies)]
                end

                table.insert(missiles, missile)
            end

            -- Feedback for launch
            Feedback:trigger("missile_launch")
        end
    end

    -- Update missiles
    for i = #missiles, 1, -1 do
        local missile = missiles[i]
        missile:update(gameDt)

        -- Check collision with enemies
        for _, enemy in ipairs(enemies) do
            if missile:checkCollision(enemy) then
                -- Deal damage
                local killed, flyingPartsData = enemy:takeDamage(missile.damage, missile.angle)

                -- Spawn flying parts
                for _, partData in ipairs(flyingPartsData) do
                    table.insert(flyingParts, FlyingPart(partData))
                end

                -- Spawn explosion
                DebrisManager:spawnMissileExplosion(missile.x, missile.y, missile.angle)

                -- Spawn damage number
                spawnDamageNumber(missile.x, missile.y - 10, missile.damage)

                if killed then
                    totalKills = totalKills + 1
                    local goldAmount = math.floor(GOLD_PER_KILL * stats.goldMultiplier)
                    gold = gold + goldAmount
                    totalGold = totalGold + goldAmount
                    spawnDamageNumber(enemy.x, enemy.y - 20, goldAmount, "gold")
                    spawnShardCluster(enemy.x, enemy.y, enemy.shapeName, enemy.maxHp)
                end

                -- Feedback
                Feedback:trigger("missile_impact")

                missile.dead = true
                break
            end
        end

        if missile.dead then
            table.remove(missiles, i)
        end
    end

    -- Update shield if exists
    if tower.shield then
        tower.shield:update(gameDt)
    end

    -- Update damage aura if exists
    if damageAura then
        damageAura:update(gameDt)

        -- Apply damage to enemies in range
        local hits = damageAura:damageEnemiesInRange(enemies)
        for _, hit in ipairs(hits) do
            local enemy = hit.enemy
            local damage = hit.damage

            -- Apply damage
            local killed, flyingPartsData = enemy:takeDamage(damage, nil)

            -- Spawn flying parts
            for _, partData in ipairs(flyingPartsData) do
                table.insert(flyingParts, FlyingPart(partData))
            end

            -- Show damage number
            spawnDamageNumber(enemy.x, enemy.y - 10, math.floor(damage))

            if killed then
                totalKills = totalKills + 1
                local goldAmount = math.floor(GOLD_PER_KILL * stats.goldMultiplier)
                gold = gold + goldAmount
                totalGold = totalGold + goldAmount
                spawnDamageNumber(enemy.x, enemy.y - 20, goldAmount, "gold")
                spawnShardCluster(enemy.x, enemy.y, enemy.shapeName, enemy.maxHp)
            end
        end
    end

    -- Update enemies (uses gameDt for gameplay freeze)
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        enemy:update(gameDt)

        -- Check shield collision first (before tower collision)
        if tower.shield and tower.shield:checkEnemyCollision(enemy) then
            -- Shield kills enemy instantly
            tower.shield:consumeCharge()

            -- Calculate angle from turret to enemy for effects
            local deathAngle = math.atan2(enemy.y - tower.y, enemy.x - tower.x)

            -- Spawn shield kill burst particles
            DebrisManager:spawnShieldKillBurst(enemy.x, enemy.y, deathAngle, enemy.color)

            -- Trigger feedback
            Feedback:trigger("shield_kill")

            -- Kill enemy with enhanced explosion
            enemy:die(deathAngle, {velocity = PROJECTILE_SPEED * 1.5})

            -- Award gold and shards
            totalKills = totalKills + 1
            local goldAmount = math.floor(GOLD_PER_KILL * stats.goldMultiplier)
            gold = gold + goldAmount
            totalGold = totalGold + goldAmount
            spawnDamageNumber(enemy.x, enemy.y - 20, goldAmount, "gold")
            spawnShardCluster(enemy.x, enemy.y, enemy.shapeName, enemy.maxHp)
        end

        -- Process enemy attack flags
        if enemy.shouldFireProjectile then
            -- Square: Fire projectile at tower
            local angle = math.atan2(tower.y - enemy.y, tower.x - enemy.x)
            local proj = EnemyProjectile(enemy.x, enemy.y, angle, SQUARE_PROJECTILE_SPEED, SQUARE_PROJECTILE_DAMAGE, "square_bolt")
            table.insert(enemyProjectiles, proj)
            -- Muzzle flash effect
            DebrisManager:spawnSquareMuzzleFlash(enemy.x, enemy.y, angle)
        end

        if enemy.shouldCreateTelegraph then
            -- Pentagon: Create AoE warning at tower position
            local warning = AoEWarning(tower.x, tower.y, PENTAGON_AOE_RADIUS, PENTAGON_TELEGRAPH_TIME, PENTAGON_AOE_DAMAGE)
            table.insert(aoeWarnings, warning)
        end

        if enemy.shouldSpawnMiniHex then
            -- Hexagon: Spawn mini-hex swarm
            for j = 1, HEXAGON_MINI_COUNT do
                local spreadAngle = (j - 1) / HEXAGON_MINI_COUNT * math.pi * 2 + lume.random(-0.3, 0.3)
                local proj = EnemyProjectile(enemy.x, enemy.y, spreadAngle, HEXAGON_MINI_SPEED, HEXAGON_MINI_DAMAGE, "mini_hex")
                proj.target = tower  -- Home toward tower
                table.insert(enemyProjectiles, proj)
            end
            -- Spawn burst effect
            DebrisManager:spawnMiniHexBurst(enemy.x, enemy.y, enemy.color)
        end

        -- Square collision with tower pad - trigger when touching boundary
        local padHalfSize = TOWER_PAD_SIZE * BLOB_PIXEL_SIZE * TURRET_SCALE
        local dx = math.abs(enemy.x - tower.x)
        local dy = math.abs(enemy.y - tower.y)
        -- Since enemies are clamped to the boundary, check if they're at/near the edge
        -- They must be within padHalfSize + small tolerance on both axes
        if dx <= padHalfSize + 5 and dy <= padHalfSize + 5 then
            -- Calculate damage (triangle kamikaze deals explosion damage)
            local contactDamage = ENEMY_CONTACT_DAMAGE
            if enemy.shapeName == "triangle" and enemy.isCharging then
                contactDamage = TRIANGLE_EXPLOSION_DAMAGE
                -- Spawn kamikaze explosion effect
                DebrisManager:spawnKamikazeExplosion(enemy.x, enemy.y, TRIANGLE_EXPLOSION_RADIUS)
                Feedback:trigger("kamikaze_explosion")
            end

            if not godMode then
                local destroyed = tower:takeDamage(contactDamage)
                if destroyed then
                    gameState = "gameover"
                    initGameOverAnim()
                    Sounds.stopMusic()
                end
            end
            -- Calculate angle from tower to enemy for death explosion direction
            local deathAngle = math.atan2(enemy.y - tower.y, enemy.x - tower.x)
            enemy:die(deathAngle)
        end

        if enemy.dead then
            table.remove(enemies, i)
        end
    end

    -- Update composite enemies
    for i = #compositeEnemies, 1, -1 do
        local composite = compositeEnemies[i]
        composite:update(gameDt)

        -- Check tower collision (any node touching tower)
        if composite:checkTowerCollision() then
            if not godMode then
                local destroyed = tower:takeDamage(ENEMY_CONTACT_DAMAGE)
                if destroyed then
                    gameState = "gameover"
                    initGameOverAnim()
                    Sounds.stopMusic()
                end
            end
            -- Kill the composite and all children
            local deathAngle = math.atan2(composite.worldY - tower.y, composite.worldX - tower.x)
            composite:die(deathAngle)
        end

        if composite.dead then
            table.remove(compositeEnemies, i)
        end
    end

    -- Update projectiles (uses gameDt for gameplay freeze)
    for i = #projectiles, 1, -1 do
        local proj = projectiles[i]
        proj:update(gameDt)

        -- Track hit enemies to prevent double-hits
        proj.hitEnemies = proj.hitEnemies or {}

        for _, enemy in ipairs(enemies) do
            if proj:checkCollision(enemy) and not enemy.dead and not proj.hitEnemies[enemy] then
                -- Mark as hit
                proj.hitEnemies[enemy] = true

                -- Calculate actual bullet speed for dynamic effects
                local bulletSpeed = math.sqrt(proj.vx * proj.vx + proj.vy * proj.vy)

                -- Pass position data for ray-based side detection
                local killed, flyingPartsData, isGapHit = enemy:takeDamage(proj.damage, proj.angle, {
                    velocity = bulletSpeed,
                    vx = proj.vx,
                    vy = proj.vy,
                    bulletX = proj.x,
                    bulletY = proj.y,
                    prevX = proj.prevX,
                    prevY = proj.prevY,
                })

                -- Spawn flying parts for all destroyed sides
                for _, partData in ipairs(flyingPartsData) do
                    table.insert(flyingParts, FlyingPart(partData))
                end

                -- Show damage number (bonus damage for gap hits)
                local displayDamage = math.floor(proj.damage * (isGapHit and GAP_DAMAGE_BONUS or 1))
                spawnDamageNumber(proj.x, proj.y - 10, displayDamage, isGapHit and "crit" or nil)

                if killed then
                    totalKills = totalKills + 1
                    -- Award gold on kill (with multiplier from skill tree)
                    local goldAmount = math.floor(GOLD_PER_KILL * stats.goldMultiplier)
                    gold = gold + goldAmount
                    totalGold = totalGold + goldAmount
                    spawnDamageNumber(enemy.x, enemy.y - 20, goldAmount, "gold")
                    -- Spawn shard cluster (one shard per HP)
                    spawnShardCluster(enemy.x, enemy.y, enemy.shapeName, enemy.maxHp)
                end

                -- Only destroy projectile if not piercing
                if not proj.piercing then
                    proj.dead = true
                    break
                end
            end
        end

        -- Check collision with composite enemies (hierarchical hit detection)
        if not proj.dead then
            proj.hitComposites = proj.hitComposites or {}
            for _, composite in ipairs(compositeEnemies) do
                if not composite.dead and not proj.hitComposites[composite] then
                    -- Find which node gets hit (outermost children first)
                    local hitNode, _, hitX, hitY, isGapHit = composite:findHitNode(
                        proj.x, proj.y, proj.prevX, proj.prevY
                    )

                    if hitNode then
                        proj.hitComposites[composite] = true

                        -- Calculate bullet speed
                        local bulletSpeed = math.sqrt(proj.vx * proj.vx + proj.vy * proj.vy)

                        -- Deal damage to the specific node hit
                        local killed, flyingPartsData, _, detachedChildren = hitNode:takeDamageOnNode(
                            proj.damage, proj.angle, {
                                velocity = bulletSpeed,
                                bulletX = proj.x,
                                bulletY = proj.y,
                                prevX = proj.prevX,
                                prevY = proj.prevY,
                                isGapHit = isGapHit,
                            }
                        )

                        -- Spawn flying parts
                        for _, partData in ipairs(flyingPartsData) do
                            table.insert(flyingParts, FlyingPart(partData))
                        end

                        -- Handle detached children (add them as independent composite enemies)
                        for _, child in ipairs(detachedChildren) do
                            table.insert(compositeEnemies, child)
                        end

                        -- Show damage number
                        local displayDamage = math.floor(proj.damage * (isGapHit and GAP_DAMAGE_BONUS or 1))
                        spawnDamageNumber(hitX, hitY - 10, displayDamage, isGapHit and "crit" or nil)

                        if killed then
                            totalKills = totalKills + 1
                            local goldAmount = math.floor(GOLD_PER_KILL * stats.goldMultiplier)
                            gold = gold + goldAmount
                            totalGold = totalGold + goldAmount
                            spawnDamageNumber(hitNode.worldX, hitNode.worldY - 20, goldAmount, "gold")
                            spawnShardCluster(hitNode.worldX, hitNode.worldY, hitNode.shapeName, hitNode.maxHp)

                            -- Trigger feedback
                            Feedback:trigger("enemy_death")
                        end

                        -- Destroy projectile if not piercing
                        if not proj.piercing then
                            proj.dead = true
                            break
                        end
                    end
                end
            end
        end

        -- Check collision with collectible shards (projectile passes through)
        proj.hitShards = proj.hitShards or {}
        for _, shard in ipairs(collectibleShards) do
            if shard.state == "idle" and not proj.hitShards[shard] and shard:checkProjectileHit(proj.x, proj.y) then
                proj.hitShards[shard] = true
                -- Send shard directly to turret
                shard:catch(tower.x, tower.y)
            end
        end

        if proj.dead then
            -- Remove associated light
            if proj.lightId then
                Lighting:removeLight(proj.lightId)
            end
            table.remove(projectiles, i)
        end
    end

    -- Update enemy projectiles (square bolts, mini-hexes)
    for i = #enemyProjectiles, 1, -1 do
        local proj = enemyProjectiles[i]
        proj:update(gameDt)

        -- Check collision with tower
        if proj:checkTowerCollision(tower) then
            if not godMode then
                local destroyed = tower:takeDamage(proj.damage)
                if destroyed then
                    gameState = "gameover"
                    initGameOverAnim()
                    Sounds.stopMusic()
                end
            end
            -- Spawn impact particles
            DebrisManager:spawnSquareImpact(proj.x, proj.y, proj.angle, proj.projectileType == "mini_hex" and SHAPE_COLORS.hexagon or SHAPE_COLORS.square)
            Feedback:trigger("enemy_projectile_hit")
            proj.dead = true
        end

        if proj.dead then
            table.remove(enemyProjectiles, i)
        end
    end

    -- Update AoE warnings (pentagon telegraphs)
    for i = #aoeWarnings, 1, -1 do
        local warning = aoeWarnings[i]
        local triggeredDamage = warning:update(gameDt)

        if triggeredDamage then
            -- Check if tower is inside the damage zone
            if warning:containsPoint(tower.x, tower.y) then
                if not godMode then
                    local destroyed = tower:takeDamage(triggeredDamage)
                    if destroyed then
                        gameState = "gameover"
                        initGameOverAnim()
                        Sounds.stopMusic()
                    end
                end
            end
            -- Spawn trigger effect
            DebrisManager:spawnPentagonTrigger(warning.x, warning.y, warning.radius, warning.color)
            Feedback:trigger("aoe_trigger")
        end

        if warning.dead then
            table.remove(aoeWarnings, i)
        end
    end

    -- Visual effects use raw dt (keep animating during hit-stop)
    updateParticles(dt)
    updateDamageNumbers(dt)
    updateChunks(dt)
    updateFlyingParts(dt)
    updateCollectibleShards(dt, tower.x, tower.y)
    updateDustParticles(dt)
    Lighting:update(dt)
end

function love.draw()
    -- Clear to black for letterbox bars
    love.graphics.clear(0, 0, 0)

    -- Start CRT capture (applies to everything including UI)
    PostFX:beginCRT()

    -- Apply scaling transformation
    love.graphics.push()
    love.graphics.translate(OFFSET_X, OFFSET_Y)
    love.graphics.scale(SCALE, SCALE)

    -- Intro: CRT only, custom drawing
    if gameState == "intro" then
        -- For text phases, draw intro's own content
        if not Intro:isInFadeOrLater() then
            Intro:draw()
        else
            -- For fade/alert/barrel phases, draw arena and turret
            drawArenaFloor()

            -- Draw turret with barrel extension
            if Intro:isInBarrelPhase() then
                tower:draw(Intro:getBarrelExtend())
            else
                tower:drawBaseOnly()
            end

            -- Draw intro overlays (fade, alert text)
            Intro:drawGameElements()
        end

        drawScopeCursor()
        DebugConsole:draw()
        love.graphics.pop()
        PostFX:endCRT()
        return
    end

    -- Skill tree: CRT only (no game effects)
    if gameState == "skilltree" then
        SkillTree:draw()
        SkillTree:drawPlayTransitionOverlay()
        drawScopeCursor()
        DebugConsole:draw()
        love.graphics.pop()
        PostFX:endCRT()
        return
    end

    -- Settings menu: CRT only (no game effects)
    if gameState == "settings" then
        SettingsMenu:draw()
        drawScopeCursor()
        DebugConsole:draw()
        love.graphics.pop()
        PostFX:endCRT()
        return
    end

    -- === GAMEPLAY: Apply post-processing to game world only ===
    PostFX:beginCapture()

    -- Apply screen shake from Feedback system
    local shakeX, shakeY = Feedback:getShakeOffset()
    love.graphics.push()
    love.graphics.translate(shakeX, shakeY)

    -- Apply camera transform
    Camera:apply()

    -- 1. Ground (pixelated grass environment)
    drawArenaFloor()

    -- 2. Limb chunks (under live enemies)
    drawChunks()

    -- 2.3 Flying parts (destroyed enemy sides)
    drawFlyingParts()

    -- 2.5 Collectible shards (above chunks, below enemies)
    drawCollectibleShards()

    -- 2.6 AoE warnings (below enemies so they can see them)
    for _, warning in ipairs(aoeWarnings) do
        warning:draw()
    end

    -- 3. Dust particles (footsteps)
    drawDustParticles()

    -- 4. Enemies
    for _, enemy in ipairs(enemies) do
        enemy:draw()
    end

    -- 4.5 Composite enemies
    for _, composite in ipairs(compositeEnemies) do
        composite:draw()
    end

    -- 5. Tower (with dash effects)
    -- Draw dash afterimages first (behind turret)
    tower:drawAfterimages()

    -- Draw turret
    tower:draw()

    -- Draw dash charge UI (arc segments below turret)
    drawDashChargeUI()

    -- 5.25 Shield
    if tower.shield then
        tower.shield:draw()
    end

    -- 5.3 Damage Aura
    if damageAura then
        damageAura:draw()
    end

    -- 5.5 Drones
    for _, drone in ipairs(drones) do
        drone:draw()
    end

    -- 5.6 Silos (around turret)
    for _, silo in ipairs(silos) do
        silo:draw()
    end

    -- 6. Projectiles
    for _, proj in ipairs(projectiles) do
        proj:draw()
    end

    -- 6.5 Drone projectiles
    for _, proj in ipairs(droneProjectiles) do
        proj:draw()
    end

    -- 6.6 Missiles
    for _, missile in ipairs(missiles) do
        missile:draw()
    end

    -- 6.7 Enemy projectiles
    for _, proj in ipairs(enemyProjectiles) do
        proj:draw()
    end

    -- 7. Lighting (additive glow)
    Lighting:drawLights()

    -- 8. Laser beam and cannons
    drawLaserCannons()
    drawLaserBeam()

    -- 9. Plasma barrel charge effect
    drawPlasmaBarrelCharge()

    -- 10. Visual effects (non-text)
    drawParticles()

    -- End camera transform
    Camera:reset()

    love.graphics.pop()  -- End shake transform

    -- End capture and draw game world with game effects (glitch, heat, chromatic)
    PostFX:endCapture()
    love.graphics.pop()  -- End scale transform (before drawing PostFX result)
    PostFX:drawScene()

    -- === UI/TEXT LAYER (no post-processing) ===
    love.graphics.push()
    love.graphics.translate(OFFSET_X, OFFSET_Y)
    love.graphics.scale(SCALE, SCALE)

    -- Apply shake to damage numbers so they match game world
    local shakeX2, shakeY2 = Feedback:getShakeOffset()
    love.graphics.push()
    love.graphics.translate(shakeX2, shakeY2)
    drawDamageNumbers()
    love.graphics.pop()

    -- Scope cursor (drawn in game space, unaffected by shake)
    drawScopeCursor()

    -- UI elements
    drawUI()

    -- Level-up UI overlay
    if Roguelite.levelUpPending then
        LevelUpUI:draw(Roguelite)
    end

    if gameState == "gameover" then
        drawGameOver()
    end

    -- Performance overlay (toggle with R)
    if perfOverlay then
        local fps = love.timer.getFPS()
        local memKB = collectgarbage("count")
        local y = 10
        local lineHeight = 14

        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 5, 5, 160, 180)

        love.graphics.setColor(0, 1, 0, 0.9)
        love.graphics.print(string.format("FPS: %d", fps), 10, y)
        y = y + lineHeight
        love.graphics.print(string.format("Memory: %.1f MB", memKB / 1024), 10, y)
        y = y + lineHeight + 5

        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.print("--- Entities ---", 10, y)
        y = y + lineHeight
        love.graphics.print(string.format("Enemies: %d", #enemies), 10, y)
        y = y + lineHeight
        love.graphics.print(string.format("Composites: %d", #compositeEnemies), 10, y)
        y = y + lineHeight
        love.graphics.print(string.format("Projectiles: %d", #projectiles), 10, y)
        y = y + lineHeight
        love.graphics.print(string.format("Particles: %d", #particles), 10, y)
        y = y + lineHeight
        love.graphics.print(string.format("Chunks: %d", #chunks), 10, y)
        y = y + lineHeight
        love.graphics.print(string.format("Shards: %d", #collectibleShards), 10, y)
        y = y + lineHeight
        love.graphics.print(string.format("Lights: %d", Lighting:getLightCount()), 10, y)
        y = y + lineHeight
        love.graphics.print(string.format("Speed: %.1fx", GAME_SPEEDS[gameSpeedIndex]), 10, y)
    end

    -- Debug console
    DebugConsole:draw()

    love.graphics.pop()  -- End scale transform

    -- Apply CRT effect to everything (scanlines, curvature)
    PostFX:endCRT()
end

function love.keypressed(key)
    -- Debug console toggle (backtick)
    if key == "`" then
        DebugConsole:toggle()
        return
    end

    -- Handle console input when visible (consume all keys)
    if DebugConsole:isVisible() then
        -- First check if focused text input handles the key
        if DebugConsole:handleKeypress(key) then
            return
        end
        -- Otherwise handle command line input
        if key == "escape" then
            DebugConsole:close()
        elseif key == "return" then
            DebugConsole:executeInput()
        elseif key == "backspace" then
            DebugConsole:backspace()
        elseif key == "tab" then
            DebugConsole:autocomplete()
        end
        return -- Consume all keys when console visible
    end

    -- Performance overlay toggle (U)
    if key == "u" then
        perfOverlay = not perfOverlay
        return
    end

    -- Z cycles game speed
    if key == "z" and gameState == "playing" then
        gameSpeedIndex = (gameSpeedIndex % #GAME_SPEEDS) + 1
        return
    end

    -- Intro state: any key skips
    if gameState == "intro" then
        if key == "escape" then
            love.event.quit()
        elseif key == "b" then
            toggleFullscreen()
        else
            Intro:skip()
        end
        return
    end

    -- Settings state
    if gameState == "settings" then
        local action = SettingsMenu:keypressed(key)
        if action == "close" then
            gameState = previousState or "playing"
        end
        return
    end

    -- Skill tree state
    if gameState == "skilltree" then
        if key == "escape" then
            love.event.quit()
        elseif key == "b" then
            toggleFullscreen()
        elseif key == "o" then
            previousState = gameState
            gameState = "settings"
        else
            local action = SkillTree:keypressed(key)
            if action == "play" then
                SkillTree:startPlayTransition()
            elseif action == "back" then
                gameState = "gameover"
            end
        end
        return
    end

    -- Gameover state
    if gameState == "gameover" then
        -- During title_hold phase, any key triggers reveal
        if gameOverAnim.phase == "title_hold" then
            triggerGameOverReveal()
            return
        end

        -- Block gameplay inputs until animation is complete
        if gameOverAnim.phase ~= "complete" then
            return
        end

        -- Animation complete, accept inputs
        if key == "escape" then
            love.event.quit()
        elseif key == "r" then
            triggerRebootAnimation()
        elseif key == "s" then
            gameState = "skilltree"
            SkillTree:startTransition()
        elseif key == "b" then
            toggleFullscreen()
        elseif key == "o" then
            previousState = gameState
            gameState = "settings"
        end
        return
    end

    -- Level-up UI takes priority when pending
    if Roguelite.levelUpPending then
        if LevelUpUI:keypressed(key, Roguelite) then
            return
        end
    end

    -- Playing state
    if key == "escape" then
        gameState = "gameover"
        initGameOverAnim()
        Sounds.stopMusic()
    elseif key == "space" and not Roguelite.levelUpPending then
        tryDash()
    elseif key == "1" and not Roguelite.levelUpPending then
        activateLaser()
    elseif key == "2" and not Roguelite.levelUpPending then
        activatePlasma()
    elseif key == "r" then
        triggerRebootAnimation()
    elseif key == "g" then
        godMode = not godMode
    elseif key == "x" then
        autoFire = not autoFire
    elseif key == "b" then
        toggleFullscreen()
    elseif key == "o" then
        previousState = gameState
        gameState = "settings"
    end
end

function love.textinput(text)
    -- Filter out backtick (used to toggle console)
    if text == "`" then return end

    if DebugConsole:isVisible() then
        -- First check if focused text input handles the input
        if DebugConsole:handleTextInput(text) then
            return
        end
        -- Otherwise pass to command line input
        DebugConsole:appendText(text)
    end
end

function love.mousepressed(x, y, button)
    -- Convert to game coordinates
    local gx, gy = screenToGame(x, y)

    -- Debug console mouse handling (consume clicks when visible)
    if DebugConsole:mousepressed(gx, gy, button) then
        return
    end

    -- Level-up UI mouse handling
    if Roguelite.levelUpPending then
        if LevelUpUI:mousepressed(gx, gy, button, Roguelite) then
            return
        end
    end

    -- Skill tree mouse handling
    if gameState == "skilltree" then
        local action = SkillTree:mousepressed(gx, gy, button)
        if action == "play" then
            SkillTree:startPlayTransition()
        end
        return
    end

    -- Manual fire mode: left click to fire (but not during level-up)
    if button == 1 and not autoFire and gameState == "playing" and not Roguelite.levelUpPending then
        fireProjectile()
    end
end

function love.mousereleased(x, y, button)
    local gx, gy = screenToGame(x, y)

    -- Skill tree mouse handling
    if gameState == "skilltree" then
        SkillTree:mousereleased(gx, gy, button)
        return
    end

    DebugConsole:mousereleased(gx, gy, button)
end

function love.mousemoved(x, y)
    local gx, gy = screenToGame(x, y)

    -- Level-up UI mouse handling
    if Roguelite.levelUpPending then
        LevelUpUI:mousemoved(gx, gy, Roguelite)
        return
    end

    -- Skill tree mouse handling
    if gameState == "skilltree" then
        SkillTree:mousemoved(gx, gy)
        return
    end

    DebugConsole:mousemoved(gx, gy)
end

function love.wheelmoved(x, y)
    if DebugConsole:wheelmoved(x, y) then
        return
    end

    -- Skill tree zoom handling
    if gameState == "skilltree" then
        SkillTree:wheelmoved(x, y)
        return
    end
end
