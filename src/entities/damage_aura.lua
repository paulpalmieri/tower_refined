-- src/entities/damage_aura.lua
-- Static damage field around turret that deals periodic damage to enemies

local DamageAura = Object:extend()

function DamageAura:new(turret)
    self.turret = turret
    self.x = turret.x
    self.y = turret.y

    -- Stats (can be modified by upgrades)
    self.baseRadius = AURA_BASE_RADIUS
    self.radius = self.baseRadius
    self.radiusMult = 1.0
    self.baseDamage = AURA_BASE_DAMAGE
    self.damage = self.baseDamage
    self.damageMult = 1.0
    self.tickInterval = AURA_TICK_INTERVAL

    -- Timing
    self.tickTimer = 0
    self.justTicked = false  -- For visual feedback

    -- Visual state
    self.pulsePhase = 0
    self.tickFlash = 0       -- Flash intensity on damage tick
    self.ringExpand = 0      -- Expanding ring on tick
end

function DamageAura:setStats(damageMult, radiusMult)
    self.damageMult = damageMult
    self.radiusMult = radiusMult
    self.damage = self.baseDamage * self.damageMult
    self.radius = self.baseRadius * self.radiusMult
end

function DamageAura:update(dt)
    -- Follow turret
    self.x = self.turret.x
    self.y = self.turret.y

    -- Visual pulse
    self.pulsePhase = self.pulsePhase + dt * 2

    -- Tick timer
    self.tickTimer = self.tickTimer + dt
    self.justTicked = false

    if self.tickTimer >= self.tickInterval then
        self.tickTimer = self.tickTimer - self.tickInterval
        self.justTicked = true
        self.tickFlash = 1.0
        self.ringExpand = 0
    end

    -- Decay visual effects
    if self.tickFlash > 0 then
        self.tickFlash = self.tickFlash - dt * 3
        if self.tickFlash < 0 then self.tickFlash = 0 end
    end

    if self.ringExpand < 1 then
        self.ringExpand = self.ringExpand + dt * 2
        if self.ringExpand > 1 then self.ringExpand = 1 end
    end
end

-- Check and damage enemies in range
-- Returns list of {enemy, damage} for each enemy hit
function DamageAura:damageEnemiesInRange(enemies)
    if not self.justTicked then return {} end

    local hits = {}

    for _, enemy in ipairs(enemies) do
        if not enemy.dead then
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)

            -- Enemy hitbox approximation
            local enemyRadius = enemy.size * enemy.scale * 0.5

            if dist <= self.radius + enemyRadius then
                table.insert(hits, {enemy = enemy, damage = self.damage})
            end
        end
    end

    return hits
end

function DamageAura:draw()
    local r = self.radius
    local pulse = math.sin(self.pulsePhase) * 0.1 + 1.0

    love.graphics.setBlendMode("add")

    -- Outer glow (soft ambient)
    love.graphics.setColor(
        AURA_COLOR[1],
        AURA_COLOR[2],
        AURA_COLOR[3],
        0.05 + self.tickFlash * 0.1
    )
    love.graphics.circle("fill", self.x, self.y, r * pulse * 1.2)

    -- Main aura fill (very subtle)
    love.graphics.setColor(
        AURA_COLOR[1],
        AURA_COLOR[2],
        AURA_COLOR[3],
        0.03 + self.tickFlash * 0.15
    )
    love.graphics.circle("fill", self.x, self.y, r * pulse)

    -- Concentric rings (pulsing)
    for i = 1, 3 do
        local ringPhase = self.pulsePhase + i * math.pi / 3
        local ringPulse = math.sin(ringPhase) * 0.5 + 0.5
        local ringRadius = r * (0.3 + i * 0.25)

        love.graphics.setColor(
            AURA_COLOR[1],
            AURA_COLOR[2],
            AURA_COLOR[3],
            (0.1 + ringPulse * 0.1) + self.tickFlash * 0.2
        )
        love.graphics.setLineWidth(1 + ringPulse)
        love.graphics.circle("line", self.x, self.y, ringRadius * pulse)
    end

    -- Outer boundary ring
    love.graphics.setColor(
        AURA_COLOR[1],
        AURA_COLOR[2],
        AURA_COLOR[3],
        0.25 + self.tickFlash * 0.3
    )
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, r * pulse)

    -- Expanding damage ring on tick
    if self.ringExpand < 1 then
        local expandRadius = r * self.ringExpand * 1.5
        local alpha = (1 - self.ringExpand) * 0.6

        love.graphics.setColor(AURA_COLOR[1], AURA_COLOR[2], AURA_COLOR[3], alpha)
        love.graphics.setLineWidth(3 * (1 - self.ringExpand))
        love.graphics.circle("line", self.x, self.y, expandRadius)
    end

    love.graphics.setBlendMode("alpha")
    love.graphics.setLineWidth(1)
end

-- Get progress toward next tick (0-1)
function DamageAura:getTickProgress()
    return self.tickTimer / self.tickInterval
end

return DamageAura
