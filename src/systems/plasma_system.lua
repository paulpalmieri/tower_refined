-- plasma_system.lua
-- Manages the plasma missile active ability state machine

local PlasmaSystem = {
    state = "ready",      -- "ready", "charging", "cooldown"
    timer = 0,            -- Time in current state
    chargeProgress = 0,   -- 0-1, how far charge has progressed (back to front)
}

-- Initialize the system
function PlasmaSystem:init()
    self:reset()
end

-- Reset state (call between runs)
function PlasmaSystem:reset()
    self.state = "ready"
    self.timer = 0
    self.chargeProgress = 0
end

-- Check if the plasma can be activated
function PlasmaSystem:canActivate()
    return self.state == "ready"
end

-- Activate the plasma ability
function PlasmaSystem:activate()
    if not self:canActivate() then return false end

    self.state = "charging"
    self.timer = 0
    self.chargeProgress = 0

    -- Play charge sound immediately when starting
    Sounds.playPlasmaFire()
    return true
end

-- Fire the plasma missile
-- Returns projectile data to be created by main.lua
function PlasmaSystem:fire(tower, stats)
    local muzzleX, muzzleY = tower:getMuzzleTip()

    -- Create plasma projectile data with upgraded stats
    local plasmaSpeed = PLASMA_MISSILE_SPEED * stats.plasmaSpeed
    local plasmaDamage = PLASMA_DAMAGE * stats.plasmaDamage
    local plasmaSize = PLASMA_MISSILE_SIZE * stats.plasmaSize

    return {
        x = muzzleX,
        y = muzzleY,
        angle = tower.angle,
        speed = plasmaSpeed,
        damage = plasmaDamage,
        size = plasmaSize,
        isPlasma = true,
        piercing = true,
        trailLength = 12,
        light = {
            radius = PLASMA_LIGHT_RADIUS,
            intensity = PLASMA_LIGHT_INTENSITY,
            color = PLASMA_COLOR,
            pulse = 8,
            pulseAmount = 0.3,
        },
        muzzleFlash = {
            x = muzzleX,
            y = muzzleY,
            radius = 80,
            intensity = 1.0,
            color = PLASMA_COLOR,
            duration = 0.15,
        },
    }
end

-- Update the plasma state machine
-- Returns data when plasma fires, nil otherwise
function PlasmaSystem:update(dt, tower, stats)
    -- Calculate scaled times based on upgrades
    local chargeTime = PLASMA_CHARGE_TIME
    local cooldownTime = PLASMA_COOLDOWN_TIME * stats.plasmaCooldown

    if self.state == "ready" then
        return nil
    elseif self.state == "charging" then
        self.timer = self.timer + dt
        self.chargeProgress = math.min(1, self.timer / chargeTime)

        -- Subtle shake during charge
        if self.timer > chargeTime * 0.5 then
            Feedback:trigger("plasma_charge")
        end

        if self.timer >= chargeTime then
            -- Fire the plasma missile
            local projectileData = self:fire(tower, stats)
            self.state = "cooldown"
            self.timer = 0
            self.chargeProgress = 0

            -- Trigger feedback
            Feedback:trigger("plasma_fire")

            return projectileData
        end
    elseif self.state == "cooldown" then
        self.timer = self.timer + dt
        if self.timer >= cooldownTime then
            self.state = "ready"
            self.timer = 0
        end
    end

    return nil
end

-- Draw the plasma barrel charge effect
function PlasmaSystem:drawBarrelCharge(tower)
    if self.chargeProgress <= 0 then return end

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
    local chargeLength = barrelTotal * self.chargeProgress

    -- Purple glow intensity increases as charge progresses
    local glowIntensity = 0.4 + self.chargeProgress * 0.6
    local pulseTime = love.timer.getTime() * 10
    local pulse = 1 + math.sin(pulseTime) * 0.15 * self.chargeProgress

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
    if self.chargeProgress > 0.05 then
        local sparkX = barrelStart + chargeLength
        local sparkSize = 3 + math.sin(pulseTime * 2) * 2 + self.chargeProgress * 3
        love.graphics.setColor(1, 1, 1, glowIntensity)
        love.graphics.circle("fill", sparkX, 0, sparkSize)
    end

    love.graphics.pop()
end

-- Check if plasma is currently active (not ready)
function PlasmaSystem:isActive()
    return self.state ~= "ready"
end

-- Get current state for UI
function PlasmaSystem:getState()
    return self.state
end

-- Get charge progress (0-1) for UI
function PlasmaSystem:getChargeProgress()
    return self.chargeProgress
end

return PlasmaSystem
