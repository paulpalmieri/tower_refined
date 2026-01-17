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
            size = lume.random(3, 5),  -- Scaled ~0.67x
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
            size = lume.random(1, 3),  -- Scaled ~0.67x
            lifetime = lume.random(0.15, 0.3),
            shape = "line",
        })
    end
end

--- Spawn death explosion burst (particles only, no persistent debris)
function DebrisManager:spawnExplosionBurst(x, y, angle, shape, color, velocity)
    local burstColor = color or NEON_PRIMARY or {0, 1, 0}
    local baseSpeed = math.max(velocity, 400)

    -- Bright center flash (white-tinted, very short-lived, scaled ~0.67x)
    spawnParticle({
        x = x,
        y = y,
        vx = 0,
        vy = 0,
        color = {1, 1, 1},
        size = 12,
        lifetime = 0.08,
        shape = "square",
    })

    -- Shape-matching particle burst (increased from 15 to 20, scaled ~0.67x)
    for _ = 1, 20 do
        local sparkAngle = angle + lume.random(-1.1, 1.1)
        local speed = lume.random(baseSpeed * 0.4, baseSpeed * 1.6)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(sparkAngle) * speed,
            vy = math.sin(sparkAngle) * speed,
            color = burstColor,
            size = lume.random(3, 6),
            lifetime = lume.random(0.3, 0.55),
            shape = shape,
        })
    end

    -- Extra fast sparks that travel further (3 particles, scaled ~0.67x)
    for _ = 1, 3 do
        local sparkAngle = angle + lume.random(-0.4, 0.4)
        local speed = baseSpeed * lume.random(1.8, 2.4)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(sparkAngle) * speed,
            vy = math.sin(sparkAngle) * speed,
            color = burstColor,
            size = lume.random(2, 3),
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
            size = lume.random(3, 5),  -- Scaled ~0.67x
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
        size = lume.random(1, 2),  -- Scaled ~0.67x
        lifetime = lume.random(0.2, 0.4),
        shape = "square",
    })
end

--- Spawn shield kill burst (electric arcs + enemy fragments)
function DebrisManager:spawnShieldKillBurst(x, y, angle, enemyColor)
    -- Blue-green electrified particles (sparks radiating outward)
    local sparkColor = {0.3, 0.9, 1.0}
    local burstAngle = angle + math.pi  -- Outward from turret

    -- Electric arcs (line particles, scaled ~0.67x)
    for _ = 1, 8 do
        local arcAngle = burstAngle + lume.random(-1.2, 1.2)
        local speed = lume.random(250, 450)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(arcAngle) * speed,
            vy = math.sin(arcAngle) * speed,
            color = sparkColor,
            size = lume.random(3, 7),
            lifetime = lume.random(0.2, 0.4),
            shape = "line",
        })
    end

    -- Enemy-colored fragments (scaled ~0.67x)
    for _ = 1, 6 do
        local fragAngle = lume.random(0, math.pi * 2)
        local speed = lume.random(150, 300)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(fragAngle) * speed,
            vy = math.sin(fragAngle) * speed,
            color = enemyColor,
            size = lume.random(2, 4),
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

    -- Orange explosion particles (scaled ~0.67x)
    for _ = 1, particleCount do
        local sparkAngle = angle + lume.random(-1.2, 1.2)
        local speed = lume.random(baseSpeed * 0.5, baseSpeed * 1.5)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(sparkAngle) * speed,
            vy = math.sin(sparkAngle) * speed,
            color = burstColor,
            size = lume.random(2, 4),
            lifetime = lume.random(0.25, 0.45),
            shape = "square",
        })
    end

    -- Core flash particles (white-orange, scaled ~0.67x)
    for _ = 1, 4 do
        local flashAngle = lume.random(0, math.pi * 2)
        local speed = lume.random(80, 150)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(flashAngle) * speed,
            vy = math.sin(flashAngle) * speed,
            color = coreColor,
            size = lume.random(1, 3),
            lifetime = lume.random(0.15, 0.25),
            shape = "square",
        })
    end
end

--- Spawn triangle kamikaze explosion (red-white expanding ring)
function DebrisManager:spawnKamikazeExplosion(x, y, radius)
    local glowColor = TRIANGLE_GLOW_COLOR or {1.0, 0.3, 0.3}

    -- Bright center flash
    spawnParticle({
        x = x,
        y = y,
        vx = 0,
        vy = 0,
        color = {1, 1, 1},
        size = 20,
        lifetime = 0.12,
        shape = "triangle",
    })

    -- Red-white expanding ring particles
    local count = 16
    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local speed = lume.random(250, 400)

        -- Red outer particles
        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            color = glowColor,
            size = lume.random(4, 7),
            lifetime = lume.random(0.3, 0.5),
            shape = "triangle",
        })

        -- White inner particles (smaller, faster)
        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(angle) * speed * 1.3,
            vy = math.sin(angle) * speed * 1.3,
            color = {1, 0.9, 0.8},
            size = lume.random(2, 4),
            lifetime = lume.random(0.2, 0.35),
            shape = "line",
        })
    end
end

--- Spawn square muzzle flash when square enemy fires
function DebrisManager:spawnSquareMuzzleFlash(x, y, angle)
    local color = SHAPE_COLORS and SHAPE_COLORS.square or {0, 1, 1}

    -- Muzzle flash particles
    for _ = 1, 4 do
        local sparkAngle = angle + lume.random(-0.3, 0.3)
        local speed = lume.random(80, 150)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(sparkAngle) * speed,
            vy = math.sin(sparkAngle) * speed,
            color = color,
            size = lume.random(2, 4),
            lifetime = lume.random(0.1, 0.2),
            shape = "square",
        })
    end
end

--- Spawn square impact particles when enemy projectile hits
function DebrisManager:spawnSquareImpact(x, y, angle, color)
    local impactColor = color or SHAPE_COLORS and SHAPE_COLORS.square or {0, 1, 1}
    local reverseAngle = angle + math.pi

    -- Impact burst
    for _ = 1, 6 do
        local sparkAngle = reverseAngle + lume.random(-0.8, 0.8)
        local speed = lume.random(100, 200)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(sparkAngle) * speed,
            vy = math.sin(sparkAngle) * speed,
            color = impactColor,
            size = lume.random(2, 4),
            lifetime = lume.random(0.15, 0.3),
            shape = "square",
        })
    end
end

--- Spawn pentagon AoE trigger burst
function DebrisManager:spawnPentagonTrigger(x, y, radius, color)
    local triggerColor = color or SHAPE_COLORS and SHAPE_COLORS.pentagon or {1, 1, 0}

    -- White flash at center
    spawnParticle({
        x = x,
        y = y,
        vx = 0,
        vy = 0,
        color = {1, 1, 1},
        size = 15,
        lifetime = 0.1,
        shape = "pentagon",
    })

    -- Pentagon-shaped burst expanding outward
    local count = 10
    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local speed = lume.random(200, 350)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            color = triggerColor,
            size = lume.random(4, 7),
            lifetime = lume.random(0.25, 0.45),
            shape = "pentagon",
        })
    end

    -- Inner orange/red danger particles
    for _ = 1, 6 do
        local angle = lume.random(0, math.pi * 2)
        local speed = lume.random(150, 250)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            color = {1, 0.5, 0.2},
            size = lume.random(3, 5),
            lifetime = lume.random(0.2, 0.35),
            shape = "square",
        })
    end
end

--- Spawn mini-hex burst when hexagon spawns swarm
function DebrisManager:spawnMiniHexBurst(x, y, color)
    local burstColor = color or SHAPE_COLORS and SHAPE_COLORS.hexagon or {1, 0.4, 0.1}

    -- Orange burst effect
    for _ = 1, 8 do
        local angle = lume.random(0, math.pi * 2)
        local speed = lume.random(100, 180)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            color = burstColor,
            size = lume.random(3, 5),
            lifetime = lume.random(0.2, 0.35),
            shape = "hexagon",
        })
    end

    -- White-orange center flash
    spawnParticle({
        x = x,
        y = y,
        vx = 0,
        vy = 0,
        color = {1, 0.9, 0.7},
        size = 10,
        lifetime = 0.08,
        shape = "hexagon",
    })
end

--- Spawn dash launch burst (particles behind player at start)
function DebrisManager:spawnDashLaunchBurst(x, y, angle)
    local backAngle = angle + math.pi  -- Particles go backward

    -- Main backward burst particles (12 particles)
    for _ = 1, 12 do
        local particleAngle = backAngle + lume.random(-0.6, 0.6)
        local speed = lume.random(200, 350)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(particleAngle) * speed,
            vy = math.sin(particleAngle) * speed,
            color = {0.2, 1, 0.4},  -- Bright green
            size = lume.random(3, 5),
            lifetime = lume.random(0.15, 0.25),
            shape = "line",
        })
    end

    -- Dust ring around the launch point (8 particles)
    for i = 1, 8 do
        local ringAngle = (i / 8) * math.pi * 2
        local speed = lume.random(80, 150)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(ringAngle) * speed,
            vy = math.sin(ringAngle) * speed,
            color = {0.1, 0.5, 0.2},  -- Dim green
            size = lume.random(2, 4),
            lifetime = lume.random(0.2, 0.35),
            shape = "square",
        })
    end
end

--- Spawn dash landing burst (impact ring at end)
function DebrisManager:spawnDashLandingBurst(x, y, angle)
    -- Impact ring particles (10 particles)
    for i = 1, 10 do
        local ringAngle = (i / 10) * math.pi * 2
        local speed = lume.random(100, 180)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(ringAngle) * speed,
            vy = math.sin(ringAngle) * speed,
            color = {0.2, 1, 0.4},  -- Bright green
            size = lume.random(2, 4),
            lifetime = lume.random(0.15, 0.3),
            shape = "square",
        })
    end

    -- Forward momentum sparks (6 particles in movement direction)
    for _ = 1, 6 do
        local particleAngle = angle + lume.random(-0.4, 0.4)
        local speed = lume.random(120, 220)

        spawnParticle({
            x = x,
            y = y,
            vx = math.cos(particleAngle) * speed,
            vy = math.sin(particleAngle) * speed,
            color = {0.3, 1, 0.5},  -- Bright green
            size = lume.random(2, 3),
            lifetime = lume.random(0.2, 0.35),
            shape = "line",
        })
    end
end

return DebrisManager
