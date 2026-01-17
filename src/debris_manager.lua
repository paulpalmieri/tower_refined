-- src/debris_manager.lua
-- Debris system for neon geometric effects

local DebrisManager = {}

function DebrisManager:init()
end

function DebrisManager:reset()
end

--- Spawn green impact burst at bullet hit location (sprays back toward shooter)
function DebrisManager:spawnImpactBurst(x, y, angle)
    local count = lume.random(6, 10)
    local baseSpeed = 350
    -- Reverse direction - particles spray back from impact
    local reverseAngle = angle + math.pi

    for _ = 1, count do
        local particleAngle = reverseAngle + lume.random(-0.6, 0.6)
        local speed = lume.random(baseSpeed * 0.6, baseSpeed * 1.4)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(particleAngle) * speed,
            vy = math.sin(particleAngle) * speed,
            color = {0.2, 1, 0.4},  -- Bright green
            size = lume.random(4, 7),
            lifetime = lume.random(0.15, 0.3),
            shape = "line",
        })
    end
end

--- Spawn spark spatter on hit
function DebrisManager:spawnMinorSpatter(x, y, angle, intensity, color)
    local count = math.floor(2 + intensity * 4)
    local baseSpeed = 120 + intensity * 180
    local sparkColor = color or NEON_PRIMARY or {0, 1, 0}

    for _ = 1, count do
        local particleAngle = angle + lume.random(-0.5, 0.5)
        local speed = lume.random(baseSpeed * 0.7, baseSpeed * 1.3)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(particleAngle) * speed,
            vy = math.sin(particleAngle) * speed,
            color = sparkColor,
            size = lume.random(2, 4),
            lifetime = lume.random(0.15, 0.3),
            shape = "line",
        })
    end
end

--- Spawn death explosion burst (particles only, no persistent debris)
function DebrisManager:spawnExplosionBurst(x, y, angle, shape, color, velocity)
    local burstColor = color or NEON_PRIMARY or {0, 1, 0}
    local baseSpeed = math.max(velocity, 400)

    -- Bright center flash (white-tinted, very short-lived)
    spawnParticle({
        x = x,
        y = y,
        vx = 0,
        vy = 0,
        color = {1, 1, 1},
        size = 18,
        lifetime = 0.08,
        shape = "square",
    })

    -- Shape-matching particle burst (increased from 15 to 20)
    for _ = 1, 20 do
        local sparkAngle = angle + lume.random(-1.1, 1.1)
        local speed = lume.random(baseSpeed * 0.4, baseSpeed * 1.6)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(sparkAngle) * speed,
            vy = math.sin(sparkAngle) * speed,
            color = burstColor,
            size = lume.random(4, 9),
            lifetime = lume.random(0.3, 0.55),
            shape = shape,
        })
    end

    -- Extra fast sparks that travel further (3 particles)
    for _ = 1, 3 do
        local sparkAngle = angle + lume.random(-0.4, 0.4)
        local speed = baseSpeed * lume.random(1.8, 2.4)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(sparkAngle) * speed,
            vy = math.sin(sparkAngle) * speed,
            color = burstColor,
            size = lume.random(3, 5),
            lifetime = lume.random(0.4, 0.6),
            shape = "line",
        })
    end
end

--- Spawn blood particles (shape-matching particles on hit)
function DebrisManager:spawnBloodParticles(x, y, angle, shape, color, intensity)
    local count = math.floor(5 + intensity * 8)
    local baseSpeed = 450 + intensity * 500
    local bloodColor = color or NEON_PRIMARY or {0, 1, 0}

    for _ = 1, count do
        local particleAngle = angle + lume.random(-0.5, 0.5)
        local speed = lume.random(baseSpeed * 0.6, baseSpeed * 1.4)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(particleAngle) * speed,
            vy = math.sin(particleAngle) * speed,
            color = bloodColor,
            size = lume.random(4, 7),
            lifetime = lume.random(0.3, 0.5),
            shape = shape,
        })
    end
end

--- Spawn trail sparks (from moving chunks)
function DebrisManager:spawnTrailSparks(x, y)
    if lume.random() > 0.4 then return end

    local angle = lume.random(0, math.pi * 2)
    local speed = lume.random(15, 40)

    spawnParticle({
        x = x + lume.random(-2, 2),
        y = y + lume.random(-2, 2),
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        color = NEON_PRIMARY_DIM or {0, 0.5, 0},
        size = lume.random(1, 3),
        lifetime = lume.random(0.2, 0.4),
        shape = "square",
    })
end

--- Spawn shield kill burst (electric arcs + enemy fragments)
function DebrisManager:spawnShieldKillBurst(x, y, angle, enemyColor)
    -- Blue-green electrified particles (sparks radiating outward)
    local sparkColor = {0.3, 0.9, 1.0}
    local burstAngle = angle + math.pi  -- Outward from turret

    -- Electric arcs (line particles)
    for _ = 1, 8 do
        local arcAngle = burstAngle + lume.random(-1.2, 1.2)
        local speed = lume.random(250, 450)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(arcAngle) * speed,
            vy = math.sin(arcAngle) * speed,
            color = sparkColor,
            size = lume.random(5, 10),
            lifetime = lume.random(0.2, 0.4),
            shape = "line",
        })
    end

    -- Enemy-colored fragments
    for _ = 1, 6 do
        local fragAngle = lume.random(0, math.pi * 2)
        local speed = lume.random(150, 300)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(fragAngle) * speed,
            vy = math.sin(fragAngle) * speed,
            color = enemyColor,
            size = lume.random(3, 6),
            lifetime = lume.random(0.3, 0.5),
            shape = "square",
        })
    end
end

--- Spawn orange missile explosion burst
function DebrisManager:spawnMissileExplosion(x, y, angle)
    local burstColor = MISSILE_COLOR or {1.0, 0.6, 0.1}
    local coreColor = MISSILE_CORE_COLOR or {1.0, 0.9, 0.7}
    local baseSpeed = MISSILE_EXPLOSION_VELOCITY or 200
    local particleCount = MISSILE_EXPLOSION_PARTICLES or 8

    -- Orange explosion particles
    for _ = 1, particleCount do
        local sparkAngle = angle + lume.random(-1.2, 1.2)
        local speed = lume.random(baseSpeed * 0.5, baseSpeed * 1.5)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(sparkAngle) * speed,
            vy = math.sin(sparkAngle) * speed,
            color = burstColor,
            size = lume.random(3, 6),
            lifetime = lume.random(0.25, 0.45),
            shape = "square",
        })
    end

    -- Core flash particles (white-orange)
    for _ = 1, 4 do
        local flashAngle = lume.random(0, math.pi * 2)
        local speed = lume.random(80, 150)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(flashAngle) * speed,
            vy = math.sin(flashAngle) * speed,
            color = coreColor,
            size = lume.random(2, 4),
            lifetime = lume.random(0.15, 0.25),
            shape = "square",
        })
    end
end

return DebrisManager
