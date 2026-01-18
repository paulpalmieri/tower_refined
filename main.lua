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
-- TWEAKS (hot-reloadable overrides)
-- ===================
local function loadTweaks()
    -- Clear cached version so we get fresh file
    package.loaded["tweaks"] = nil
    local ok, tweaks = pcall(require, "tweaks")
    if ok and type(tweaks) == "table" then
        local count = 0
        for key, value in pairs(tweaks) do
            _G[key] = value
            count = count + 1
        end
        if count > 0 then
            print("[Tweaks] Loaded " .. count .. " overrides")
        end
        return true
    elseif not ok then
        print("[Tweaks] Error loading tweaks.lua: " .. tostring(tweaks))
        return false
    end
    return true
end

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
-- DebugConsole removed - use tweaks.lua for value tuning
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

-- New systems (architecture refactoring)
EventBus = require "src.event_bus"
EntityManager = require "src.entity_manager"
LaserSystem = require "src.systems.laser_system"
PlasmaSystem = require "src.systems.plasma_system"
GameOverSystem = require "src.systems.gameover_system"
CollisionManager = require "src.collision_manager"
AbilityManager = require "src.ability_manager"
SpawnManager = require "src.spawn_manager"
HUD = require "src.hud"

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

-- Entity arrays are managed by EntityManager and synced to globals via syncGlobals()
-- Available globals after EntityManager:init(): tower, enemies, compositeEnemies,
-- projectiles, particles, damageNumbers, chunks, flyingParts, dustParticles,
-- collectibleShards, drones, droneProjectiles, silos, missiles, enemyProjectiles,
-- aoeWarnings, damageAura

-- Spawn system state managed by SpawnManager
-- gameTime, spawnAccumulator, currentSpawnRate accessed via SpawnManager

-- Progression
local gold = 0
totalGold = 100000  -- Persistent gold across runs (set high for testing)
polygons = 0      -- Persistent polygons currency (collected from enemy shards)
totalKills = 0

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

-- Forward declaration for initGameOverAnim (defined later)
local initGameOverAnim

-- Helper to process collision results from manager calls
-- Handles common patterns: flying parts, shards, damage numbers, gold/kills
local function processCollisionResults(results)
    -- Add flying parts
    for _, partData in ipairs(results.flyingParts or {}) do
        table.insert(flyingParts, FlyingPart(partData))
    end

    -- Spawn shards at kill locations
    for _, shardData in ipairs(results.shardsToSpawn or {}) do
        spawnShardCluster(shardData.x, shardData.y, shardData.shapeName, shardData.count)
    end

    -- Spawn damage numbers
    for _, numData in ipairs(results.damageNumbers or {}) do
        spawnDamageNumber(numData.x, numData.y, numData.amount, numData.type)
    end

    -- Update gold and kills
    gold = gold + (results.goldEarned or 0)
    totalGold = totalGold + (results.goldEarned or 0)
    totalKills = totalKills + #(results.kills or {})
end

-- Helper to check if tower was destroyed and trigger game over
local function checkTowerDestroyed(results)
    if results.towerDestroyed and not godMode then
        gameState = "gameover"
        initGameOverAnim()
        Sounds.stopMusic()
        return true
    end
    return false
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
    if not LaserSystem:canActivate() then return end
    if PlasmaSystem:isActive() then return end  -- Can't use during plasma
    LaserSystem:activate()
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

-- ===================
-- ACTIVE SKILL: PLASMA MISSILE
-- ===================
local function activatePlasma()
    if not PlasmaSystem:canActivate() then return end
    if LaserSystem:isActive() then return end  -- Can't use during laser
    PlasmaSystem:activate()
end

-- Spawn system now managed by SpawnManager module

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

-- Initialize game over animation
initGameOverAnim = function()
    GameOverSystem:start()
end

-- Update game over animation state machine
local function updateGameOverAnim(dt)
    GameOverSystem:update(dt)
end

-- Trigger reveal phase (called on keypress during title_hold)
local function triggerGameOverReveal()
    GameOverSystem:triggerReveal()
end

local function drawGameOver()
    GameOverSystem:draw(SpawnManager:getGameTime(), totalKills, gold, totalGold, polygons)
end

-- ===================
-- EVENT LISTENERS
-- ===================
function registerEventListeners()
    -- Enemy hit: impact effects, blood particles, feedback
    EventBus:on("enemy_hit", function(data)
        if data.angle then
            DebrisManager:spawnImpactBurst(data.x, data.y, data.angle)
            DebrisManager:spawnBloodParticles(data.x, data.y, data.angle, data.shapeName, data.color, data.intensity)
        end
        if data.damage >= 0.5 then
            Feedback:trigger("small_hit", {
                damage_dealt = data.damage,
                current_hp = data.currentHp,
                max_hp = data.maxHp,
                impact_angle = data.angle,
                impact_x = data.x,
                impact_y = data.y,
            })
        end
    end)

    -- Enemy death: death sound and explosion burst
    EventBus:on("enemy_death", function(data)
        Sounds.playEnemyDeath()
        DebrisManager:spawnExplosionBurst(data.x, data.y, data.angle, data.shapeName, data.color, data.explosionVelocity)
    end)

    -- Projectile fire: shoot sound
    EventBus:on("projectile_fire", function(_)
        Sounds.playShoot()
    end)

    -- Tower damage: damage feedback
    EventBus:on("tower_damage", function(_)
        Feedback:trigger("tower_damage")
    end)

    -- Dash launch: anticipation feedback
    EventBus:on("dash_launch", function(_)
        Feedback:trigger("dash_launch")
    end)

    -- Dash start: launch particles
    EventBus:on("dash_start", function(data)
        if DebrisManager.spawnDashLaunchBurst then
            DebrisManager:spawnDashLaunchBurst(data.x, data.y, data.angle)
        end
    end)

    -- Dash land: landing feedback and particles
    EventBus:on("dash_land", function(data)
        Feedback:trigger("dash_land")
        if DebrisManager.spawnDashLandingBurst then
            DebrisManager:spawnDashLandingBurst(data.x, data.y, data.angle)
        end
    end)
end

-- ===================
-- GAME RESET
-- ===================
function startNewRun()
    gameState = "playing"

    -- Reset game state first (clear lights from shards, then reset all entity arrays)
    clearCollectibleShards()
    EntityManager:reset()
    gold = 0
    totalKills = 0

    -- Reset roguelite progression for new run
    Roguelite:reset()
    LevelUpUI:init()

    -- Apply skill tree upgrades
    SkillTree:applyUpgrades(stats)

    -- Create tower with upgraded HP
    tower = Turret(CENTER_X, CENTER_Y)
    EntityManager:setTower(tower)  -- Register with EntityManager for decoupled access
    tower.lightId = Lighting:addTowerGlow(tower)

    -- Initialize camera to follow tower
    Camera:init(tower.x, tower.y)
    tower.maxHp = TOWER_HP + stats.maxHp
    tower.hp = tower.maxHp
    tower.fireRate = TOWER_FIRE_RATE / stats.fireRate
    tower.projectileSpeed = PROJECTILE_SPEED * stats.projectileSpeed

    -- Reset systems
    GameOverSystem:reset()
    LaserSystem:reset()
    PlasmaSystem:reset()
    SpawnManager:reset()

    -- TEST: Spawn one of each composite template for testing
    local testTemplates = {}
    for name, _ in pairs(COMPOSITE_TEMPLATES) do
        table.insert(testTemplates, name)
    end
    table.sort(testTemplates)  -- Consistent order
    local spawnRadius = 300
    for i, templateName in ipairs(testTemplates) do
        SpawnManager:spawnCompositeEnemy(templateName)
        -- Reposition to known locations for testing
        local angle = (i - 1) * (2 * math.pi / #testTemplates)
        compositeEnemies[#compositeEnemies].worldX = CENTER_X + math.cos(angle) * spawnRadius
        compositeEnemies[#compositeEnemies].worldY = CENTER_Y + math.sin(angle) * spawnRadius
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
    clearCollectibleShards()
    EntityManager:reset()

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
    EntityManager:setTower(tower)
    tower.lightId = Lighting:addTowerGlow(tower)

    -- Start the reboot animation
    gameState = "intro"
    Intro:startReboot()
end

-- Sync roguelite abilities mid-run (called when upgrades are selected)
local function syncRogueliteAbilities()
    local syncResults = AbilityManager:syncRogueliteAbilities(
        tower, stats, drones, silos, damageAura,
        Roguelite, Lighting, Drone, Silo, Shield, DamageAura
    )
    -- Update damageAura reference if newly created
    damageAura = syncResults.damageAura
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

    -- Load hot-reloadable tweaks (press F5 to reload)
    loadTweaks()

    Sounds.init()
    DebrisManager:init()
    Lighting:init()
    SkillTree:init()
    SettingsMenu:init()
    PostFX:init()
    Intro:init()
    initGround()
    Parallax:init()

    -- Initialize new systems
    EntityManager:init()
    LaserSystem:init()
    PlasmaSystem:init()
    GameOverSystem:init()
    CollisionManager:init()
    AbilityManager:init()
    SpawnManager:init()

    -- Register event listeners for decoupled entity communication
    registerEventListeners()

    -- Start in intro state if enabled, otherwise go straight to playing
    if INTRO_ENABLED then
        gameState = "intro"
        Intro:start()
        -- Create tower for intro animation (but don't start full run yet)
        tower = Turret(CENTER_X, CENTER_Y)
        EntityManager:setTower(tower)  -- Register with EntityManager for decoupled access
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
    local laserResults = LaserSystem:update(dt, tower, stats, enemies)

    -- Process laser results
    for _, kill in ipairs(laserResults.kills) do
        totalKills = totalKills + 1
    end
    gold = gold + laserResults.goldEarned
    totalGold = totalGold + laserResults.goldEarned

    for _, shardData in ipairs(laserResults.shardsToSpawn) do
        spawnShardCluster(shardData.x, shardData.y, shardData.shapeName, shardData.count)
    end

    for _, data in ipairs(laserResults.damageDealt) do
        if data.type == "damageNumber" then
            spawnDamageNumber(data.x, data.y, data.amount)
        elseif data.type == "goldNumber" then
            spawnDamageNumber(data.x, data.y, data.amount, "gold")
        elseif data.type == "particle" then
            spawnParticle(data)
        elseif data.type == "flyingPart" then
            table.insert(flyingParts, FlyingPart(data.data))
        end
    end

    -- Update plasma missile system
    local plasmaResult = PlasmaSystem:update(dt, tower, stats)
    if plasmaResult then
        -- Create plasma projectile
        local proj = Projectile(plasmaResult.x, plasmaResult.y, plasmaResult.angle, plasmaResult.speed, plasmaResult.damage)
        proj.isPlasma = true
        proj.piercing = plasmaResult.piercing
        proj.hitEnemies = {}
        proj.size = plasmaResult.size
        proj.trailLength = plasmaResult.trailLength

        -- Register light for this projectile
        proj.lightId = Lighting:addLight({
            x = proj.x,
            y = proj.y,
            radius = plasmaResult.light.radius,
            intensity = plasmaResult.light.intensity,
            color = plasmaResult.light.color,
            type = "projectile",
            owner = proj,
            pulse = plasmaResult.light.pulse,
            pulseAmount = plasmaResult.light.pulseAmount,
        })

        table.insert(projectiles, proj)

        -- Muzzle flash
        Lighting:addLight(plasmaResult.muzzleFlash)
    end

    -- Continuous spawning (uses gameDt to freeze during hit-stop)
    SpawnManager:update(gameDt)

    -- Find target for tower (only used in auto-fire mode)
    local target = nil
    if autoFire then
        target = findNearestEnemy(tower.x, tower.y, nil)
    end

    -- Update tower - use raw dt during laser so turret can track while firing
    local laserState = LaserSystem:getState()
    local turretDt = (laserState == "firing" or laserState == "charging") and dt or gameDt
    if autoFire and target then
        -- Auto-fire mode: aim at nearest enemy and auto-fire
        tower:update(turretDt, target.x, target.y)
        if tower:canFire() and not LaserSystem:isActive() then
            fireProjectile()
        end
    else
        -- Manual mode OR no enemies: aim at mouse cursor
        local mx, my = getMousePosition()
        tower:update(turretDt, mx, my)

        -- Manual mode: auto-fire when holding mouse button
        if not autoFire and love.mouse.isDown(1) and tower:canFire() and not LaserSystem:isActive() then
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

    -- Update drone projectiles
    for _, proj in ipairs(droneProjectiles) do
        proj:update(gameDt)
    end

    -- Process drone projectile vs shard collisions
    local droneShardResults = CollisionManager:processDroneProjectileVsShards(droneProjectiles, collectibleShards, tower)
    for _, frag in ipairs(droneShardResults.fragments) do
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
    -- Clean up hit shards (remove lights and mark dead)
    for _, shard in ipairs(droneShardResults.shardsToRemove) do
        if shard.lightId then
            Lighting:removeLight(shard.lightId)
        end
        shard.dead = true
    end

    -- Clean up dead drone projectiles
    for i = #droneProjectiles, 1, -1 do
        if droneProjectiles[i].dead then
            if droneProjectiles[i].lightId then
                Lighting:removeLight(droneProjectiles[i].lightId)
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
    for _, missile in ipairs(missiles) do
        missile:update(gameDt)
    end

    -- Process missile vs enemy collisions
    local missileResults = CollisionManager:processMissileVsEnemies(missiles, enemies, stats)
    processCollisionResults(missileResults)

    -- Clean up dead missiles
    for i = #missiles, 1, -1 do
        if missiles[i].dead then
            if missiles[i].lightId then
                Lighting:removeLight(missiles[i].lightId)
            end
            table.remove(missiles, i)
        end
    end

    -- Update shield if exists
    if tower.shield then
        tower.shield:update(gameDt)
    end

    -- Process damage aura
    local auraResults = AbilityManager:processDamageAura(damageAura, enemies, stats, gameDt)
    processCollisionResults(auraResults)

    -- Update enemies (uses gameDt for gameplay freeze)
    for _, enemy in ipairs(enemies) do
        enemy:update(gameDt)
    end

    -- Process shield vs enemy collisions
    local shieldResults = CollisionManager:processShieldVsEnemies(tower.shield, enemies, tower, stats)
    processCollisionResults(shieldResults)

    -- Process enemy attacks (projectiles, AoE warnings, mini-hex swarms)
    local attackResults = AbilityManager:processEnemyAttacks(enemies, tower, EnemyProjectile)
    for _, proj in ipairs(attackResults.projectiles) do
        table.insert(enemyProjectiles, proj)
    end
    for _, warningData in ipairs(attackResults.aoeWarnings) do
        local warning = AoEWarning(warningData.x, warningData.y, warningData.radius, warningData.duration, warningData.damage)
        table.insert(aoeWarnings, warning)
    end

    -- Process enemy vs tower collisions
    local enemyTowerResults = CollisionManager:processEnemyVsTower(enemies, tower, godMode)
    checkTowerDestroyed(enemyTowerResults)

    -- Clean up dead enemies
    for i = #enemies, 1, -1 do
        if enemies[i].dead then
            table.remove(enemies, i)
        end
    end

    -- Update composite enemies
    for _, composite in ipairs(compositeEnemies) do
        composite:update(gameDt)
    end

    -- Process composite vs tower collisions
    local compTowerResults = CollisionManager:processCompositeVsTower(compositeEnemies, tower, godMode)
    checkTowerDestroyed(compTowerResults)

    -- Clean up dead composites
    for i = #compositeEnemies, 1, -1 do
        if compositeEnemies[i].dead then
            table.remove(compositeEnemies, i)
        end
    end

    -- Update projectiles
    for _, proj in ipairs(projectiles) do
        proj:update(gameDt)
    end

    -- Process projectile vs enemy collisions
    local projEnemyResults = CollisionManager:processProjectileVsEnemies(projectiles, enemies, stats)
    processCollisionResults(projEnemyResults)

    -- Process projectile vs composite collisions
    local projCompResults = CollisionManager:processProjectileVsComposites(projectiles, compositeEnemies, stats)
    processCollisionResults(projCompResults)
    -- Add detached children as independent composite enemies
    for _, child in ipairs(projCompResults.detachedChildren or {}) do
        table.insert(compositeEnemies, child)
    end

    -- Process projectile vs shard collisions (shards get caught, not destroyed)
    CollisionManager:processProjectileVsShards(projectiles, collectibleShards, tower)

    -- Clean up dead projectiles
    for i = #projectiles, 1, -1 do
        if projectiles[i].dead then
            if projectiles[i].lightId then
                Lighting:removeLight(projectiles[i].lightId)
            end
            table.remove(projectiles, i)
        end
    end

    -- Update enemy projectiles
    for _, proj in ipairs(enemyProjectiles) do
        proj:update(gameDt)
    end

    -- Process enemy projectile vs tower collisions
    local enemyProjResults = CollisionManager:processEnemyProjectileVsTower(enemyProjectiles, tower, godMode)
    checkTowerDestroyed(enemyProjResults)

    -- Clean up dead enemy projectiles
    for i = #enemyProjectiles, 1, -1 do
        if enemyProjectiles[i].dead then
            table.remove(enemyProjectiles, i)
        end
    end

    -- Process AoE warnings (pentagon telegraphs)
    local aoeResults = CollisionManager:processAoEWarnings(aoeWarnings, tower, godMode, gameDt)
    checkTowerDestroyed(aoeResults)

    -- Clean up dead AoE warnings
    for i = #aoeWarnings, 1, -1 do
        if aoeWarnings[i].dead then
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
        love.graphics.pop()
        PostFX:endCRT()
        return
    end

    -- Skill tree: CRT only (no game effects)
    if gameState == "skilltree" then
        SkillTree:draw()
        SkillTree:drawPlayTransitionOverlay()
        drawScopeCursor()
        love.graphics.pop()
        PostFX:endCRT()
        return
    end

    -- Settings menu: CRT only (no game effects)
    if gameState == "settings" then
        SettingsMenu:draw()
        drawScopeCursor()
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
    LaserSystem:drawCannons(tower)
    LaserSystem:drawBeam(tower, stats)

    -- 9. Plasma barrel charge effect
    PlasmaSystem:drawBarrelCharge(tower)

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
    HUD:draw({
        tower = tower,
        gameTime = SpawnManager:getGameTime(),
        enemyCount = #enemies + #compositeEnemies,
        gameSpeed = GAME_SPEEDS[gameSpeedIndex],
        godMode = godMode,
        autoFire = autoFire,
        laserSystem = LaserSystem,
        plasmaSystem = PlasmaSystem,
        roguelite = Roguelite,
        stats = stats,
        totalGold = totalGold,
    })

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

    love.graphics.pop()  -- End scale transform

    -- Apply CRT effect to everything (scanlines, curvature)
    PostFX:endCRT()
end

function love.keypressed(key)
    -- Hot-reload tweaks (F5)
    if key == "f5" then
        loadTweaks()
        return
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
        if GameOverSystem:getPhase() == "title_hold" then
            triggerGameOverReveal()
            return
        end

        -- Block gameplay inputs until animation is complete
        if not GameOverSystem:isComplete() then
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
    -- Reserved for future use
end

function love.mousepressed(x, y, button)
    -- Convert to game coordinates
    local gx, gy = screenToGame(x, y)


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

end

function love.wheelmoved(x, y)
    -- Skill tree zoom handling
    if gameState == "skilltree" then
        SkillTree:wheelmoved(x, y)
        return
    end
end
