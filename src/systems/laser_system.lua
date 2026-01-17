-- laser_system.lua
-- Manages the laser beam active ability state machine

local LaserSystem = {
    state = "ready",      -- "ready", "deploying", "charging", "firing", "retracting"
    timer = 0,            -- Time in current state
    cannonExtend = 0,     -- 0-1, how far side cannons extended
    chargeGlow = 0,       -- 0-1, charge intensity
    damageAccum = 0,      -- Accumulated damage time for DPS tick
    hitEnemies = {},      -- Track which enemies were hit this frame for damage numbers
}

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

-- Initialize the system
function LaserSystem:init()
    self:reset()
end

-- Reset state (call between runs)
function LaserSystem:reset()
    self.state = "ready"
    self.timer = 0
    self.cannonExtend = 0
    self.chargeGlow = 0
    self.damageAccum = 0
    self.hitEnemies = {}
    Sounds.stopLaser()
end

-- Check if the laser can be activated
function LaserSystem:canActivate()
    return self.state == "ready"
end

-- Activate the laser ability
function LaserSystem:activate()
    if not self:canActivate() then return false end

    self.state = "deploying"
    self.timer = 0
    return true
end

-- Update the laser state machine
-- Returns a table of results: {kills = {}, goldEarned = 0, shardsToSpawn = {}}
function LaserSystem:update(dt, tower, stats, enemies)
    local results = {
        kills = {},
        goldEarned = 0,
        shardsToSpawn = {},
        damageDealt = {},
    }

    -- Calculate scaled times based on charge speed upgrade
    local deployTime = LASER_DEPLOY_TIME / stats.laserChargeSpeed
    local chargeTime = LASER_CHARGE_TIME / stats.laserChargeSpeed
    local fireTime = LASER_FIRE_TIME * stats.laserDuration
    local beamWidth = LASER_BEAM_WIDTH * stats.laserWidth

    if self.state == "ready" then
        return results
    elseif self.state == "deploying" then
        self.timer = self.timer + dt
        self.cannonExtend = math.min(1, self.timer / deployTime)
        if self.timer >= deployTime then
            self.state = "charging"
            self.timer = 0
        end
    elseif self.state == "charging" then
        self.timer = self.timer + dt
        self.chargeGlow = math.min(1, self.timer / chargeTime)
        -- Subtle shake during charge
        if self.timer > chargeTime * 0.5 then
            Feedback:trigger("laser_charge")
        end
        if self.timer >= chargeTime then
            self.state = "firing"
            self.timer = 0
            self.damageAccum = 0
            Sounds.playLaser()
        end
    elseif self.state == "firing" then
        self.timer = self.timer + dt

        -- Continuous screen shake while firing
        Feedback:trigger("laser_continuous")

        -- Get beam geometry
        local muzzleX, muzzleY = tower:getMuzzleTip()
        local beamAngle = tower.angle

        -- Damage enemies in beam (uses raw dt so damage always applies)
        self.damageAccum = self.damageAccum + dt
        local damageThisFrame = LASER_DAMAGE_PER_SEC * stats.laserDamage * dt

        for _, enemy in ipairs(enemies) do
            if not enemy.dead then
                if pointInLaserBeam(enemy.x, enemy.y, muzzleX, muzzleY, beamAngle, LASER_BEAM_LENGTH, beamWidth) then
                    -- Pass nil angle to disable knockback
                    local killed, flyingPartsData = enemy:takeDamage(damageThisFrame, nil)

                    -- Store flying parts data in results
                    for _, partData in ipairs(flyingPartsData) do
                        table.insert(results.damageDealt, {type = "flyingPart", data = partData})
                    end

                    -- Show damage number periodically (every 0.5s per enemy)
                    if not self.hitEnemies[enemy] then
                        self.hitEnemies[enemy] = 0
                    end
                    self.hitEnemies[enemy] = self.hitEnemies[enemy] + dt
                    if self.hitEnemies[enemy] >= 0.5 then
                        table.insert(results.damageDealt, {
                            type = "damageNumber",
                            x = enemy.x,
                            y = enemy.y - 10,
                            amount = math.floor(LASER_DAMAGE_PER_SEC * stats.laserDamage * 0.5),
                        })
                        self.hitEnemies[enemy] = 0
                    end

                    if killed then
                        table.insert(results.kills, enemy)
                        local goldAmount = math.floor(GOLD_PER_KILL * stats.goldMultiplier)
                        results.goldEarned = results.goldEarned + goldAmount
                        table.insert(results.shardsToSpawn, {
                            x = enemy.x,
                            y = enemy.y,
                            shapeName = enemy.shapeName,
                            count = enemy.maxHp,
                        })
                        table.insert(results.damageDealt, {
                            type = "goldNumber",
                            x = enemy.x,
                            y = enemy.y - 20,
                            amount = goldAmount,
                        })
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
            table.insert(results.damageDealt, {
                type = "particle",
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

        if self.timer >= fireTime then
            self.state = "retracting"
            self.timer = 0
            Sounds.stopLaser()
        end
    elseif self.state == "retracting" then
        self.timer = self.timer + dt
        self.cannonExtend = math.max(0, 1 - self.timer / LASER_RETRACT_TIME)
        self.chargeGlow = math.max(0, 1 - self.timer / LASER_RETRACT_TIME)
        if self.timer >= LASER_RETRACT_TIME then
            self.state = "ready"
            self.timer = 0
            self.cannonExtend = 0
            self.chargeGlow = 0
            self.hitEnemies = {}
        end
    end

    return results
end

-- Draw the laser beam
function LaserSystem:drawBeam(tower, stats)
    if self.state ~= "firing" then return end

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

-- Draw side cannons on turret
function LaserSystem:drawCannons(tower)
    if self.cannonExtend <= 0 and self.chargeGlow <= 0 then return end

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
    local currentYOffset = startYOffset - (startYOffset - finalYOffset) * self.cannonExtend

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
    if self.chargeGlow > 0 then
        local glowIntensity = self.chargeGlow

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

-- Check if laser is currently active (not ready)
function LaserSystem:isActive()
    return self.state ~= "ready"
end

-- Get current state for UI
function LaserSystem:getState()
    return self.state
end

return LaserSystem
