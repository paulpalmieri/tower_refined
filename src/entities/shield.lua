-- src/entities/shield.lua
-- Energy shield - circular barrier around turret that kills enemies on contact

local Shield = Object:extend()

function Shield:new(turret)
    self.turret = turret
    self.x = turret.x
    self.y = turret.y

    -- Charges
    self.charges = 0
    self.maxCharges = 0
    self.active = false

    -- Radius
    self.baseRadius = SHIELD_BASE_RADIUS
    self.radius = self.baseRadius
    self.radiusMultiplier = 1.0

    -- Visual state
    self.hitFlashTimer = 0
    self.hitPulses = {}  -- Active hit pulses (expand outward from impact)
end

function Shield:setCharges(current, max)
    self.charges = current
    self.maxCharges = max
    self.active = self.charges > 0
end

function Shield:setRadius(multiplier)
    self.radiusMultiplier = multiplier
    self.radius = self.baseRadius * self.radiusMultiplier
end

function Shield:update(dt)
    -- Follow turret position
    self.x = self.turret.x
    self.y = self.turret.y

    -- Update active state
    self.active = self.charges > 0

    -- Decay hit flash
    if self.hitFlashTimer > 0 then
        self.hitFlashTimer = self.hitFlashTimer - dt
        if self.hitFlashTimer < 0 then
            self.hitFlashTimer = 0
        end
    end

    -- Update hit pulses (expanding rings from kills)
    for i = #self.hitPulses, 1, -1 do
        local pulse = self.hitPulses[i]
        pulse.progress = pulse.progress + dt * 3  -- Fast expansion
        if pulse.progress >= 1 then
            table.remove(self.hitPulses, i)
        end
    end
end

function Shield:checkEnemyCollision(enemy)
    if not self.active or self.charges <= 0 then return false end
    if enemy.dead then return false end

    local dx = enemy.x - self.x
    local dy = enemy.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Enemy hitbox approximation
    local enemyRadius = enemy.size * enemy.scale * 0.5

    return dist <= self.radius + enemyRadius
end

function Shield:consumeCharge()
    if self.charges > 0 then
        self.charges = self.charges - 1
        self.active = self.charges > 0

        -- Trigger visual feedback
        self.hitFlashTimer = SHIELD_HIT_FLASH_DURATION

        -- Add expanding hit pulse
        table.insert(self.hitPulses, {progress = 0})
    end
end

function Shield:draw()
    if not self.active or self.charges <= 0 then return end

    local r = self.radius

    -- Charge-based intensity (dimmer with fewer charges)
    local chargeRatio = self.charges / self.maxCharges
    local baseAlpha = 0.3 + chargeRatio * 0.4

    love.graphics.setBlendMode("add")

    -- ===================
    -- STATIC BASE LAYERS (the shield boundary)
    -- ===================

    -- Outer blue glow (soft ambient)
    love.graphics.setColor(
        SHIELD_COLOR_OUTER[1],
        SHIELD_COLOR_OUTER[2],
        SHIELD_COLOR_OUTER[3],
        baseAlpha * 0.1
    )
    love.graphics.setLineWidth(16)
    love.graphics.circle("line", self.x, self.y, r + 6)

    -- Mid cyan ring
    love.graphics.setColor(
        SHIELD_COLOR_MID[1],
        SHIELD_COLOR_MID[2],
        SHIELD_COLOR_MID[3],
        baseAlpha * 0.2
    )
    love.graphics.setLineWidth(8)
    love.graphics.circle("line", self.x, self.y, r)

    -- Inner fill (very subtle)
    love.graphics.setColor(
        SHIELD_COLOR_FILL[1],
        SHIELD_COLOR_FILL[2],
        SHIELD_COLOR_FILL[3],
        baseAlpha * 0.03
    )
    love.graphics.circle("fill", self.x, self.y, r)

    -- ===================
    -- MAIN BOUNDARY RING (crisp edge)
    -- ===================
    local boundaryColor
    if self.hitFlashTimer > 0 then
        -- White flash on hit
        local flashIntensity = self.hitFlashTimer / SHIELD_HIT_FLASH_DURATION
        boundaryColor = {
            SHIELD_COLOR_INNER[1] + (1 - SHIELD_COLOR_INNER[1]) * flashIntensity,
            SHIELD_COLOR_INNER[2] + (1 - SHIELD_COLOR_INNER[2]) * flashIntensity,
            SHIELD_COLOR_INNER[3] + (1 - SHIELD_COLOR_INNER[3]) * flashIntensity,
        }
    else
        boundaryColor = SHIELD_COLOR_INNER
    end

    love.graphics.setColor(boundaryColor[1], boundaryColor[2], boundaryColor[3], baseAlpha * 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, r)

    -- ===================
    -- HIT PULSES (expanding rings from kills)
    -- ===================
    for _, pulse in ipairs(self.hitPulses) do
        local t = pulse.progress
        local hitRadius = r * (0.3 + t * 0.9)  -- Start at 30%, expand past boundary
        local hitAlpha = (1 - t) * 0.8  -- Fade out as it expands

        -- Bright white-cyan expanding ring
        love.graphics.setColor(0.8, 1, 1, hitAlpha * baseAlpha)
        love.graphics.setLineWidth(4 * (1 - t * 0.5))  -- Thins as it expands
        love.graphics.circle("line", self.x, self.y, hitRadius)

        -- Inner glow
        love.graphics.setColor(1, 1, 1, hitAlpha * baseAlpha * 0.5)
        love.graphics.setLineWidth(8 * (1 - t * 0.5))
        love.graphics.circle("line", self.x, self.y, hitRadius)
    end

    love.graphics.setBlendMode("alpha")
    love.graphics.setLineWidth(1)
end

function Shield:getChargeRatio()
    if self.maxCharges == 0 then return 0 end
    return self.charges / self.maxCharges
end

return Shield
