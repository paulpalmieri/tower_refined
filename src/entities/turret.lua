-- turret.lua
-- Flak Cannon turret - heavy single barrel

local Turret = Object:extend()

-- ===================
-- FLAK CANNON COLORS (Olive-Steel)
-- ===================
local TURRET_COLORS = {
    -- Base (olive-grey)
    baseDark = {0.30, 0.31, 0.28},
    baseMid = {0.38, 0.39, 0.35},
    baseLight = {0.46, 0.47, 0.42},
    -- Platform
    platformDark = {0.28, 0.29, 0.26},
    platform = {0.35, 0.36, 0.32},
    -- Foundation
    foundationDark = {0.26, 0.27, 0.24},
    foundation = {0.32, 0.33, 0.30},
    -- Barrel (dark steel)
    barrelDark = {0.24, 0.26, 0.28},
    barrelMid = {0.32, 0.34, 0.36},
    barrelLight = {0.40, 0.42, 0.44},
    -- Breech
    breechDark = {0.26, 0.28, 0.30},
    breech = {0.34, 0.36, 0.38},
    breechLight = {0.42, 0.44, 0.46},
    -- Muzzle
    muzzle = {0.12, 0.12, 0.14},
    mount = {0.30, 0.32, 0.34},
}

-- ===================
-- BASE SPRITE (static, doesn't rotate)
-- Large base with counterweight - circular track for turret rotation
-- ===================
local BASE_SPRITE = {
    -- Rotation track ring (turret housing sits on this)
    {-5, -3, "foundationDark"}, {-4, -3, "foundation"}, {-3, -3, "foundation"}, {-2, -3, "foundation"}, {-1, -3, "foundation"}, {0, -3, "foundation"}, {1, -3, "foundation"}, {2, -3, "foundation"}, {3, -3, "foundation"}, {4, -3, "foundationDark"},
    {-6, -2, "foundationDark"}, {-5, -2, "foundation"}, {4, -2, "foundation"}, {5, -2, "foundationDark"},
    {-6, -1, "foundationDark"}, {-5, -1, "foundation"}, {4, -1, "foundation"}, {5, -1, "foundationDark"},
    {-6, 0, "foundationDark"}, {-5, 0, "foundation"}, {4, 0, "foundation"}, {5, 0, "foundationDark"},
    {-6, 1, "foundationDark"}, {-5, 1, "foundation"}, {4, 1, "foundation"}, {5, 1, "foundationDark"},
    {-6, 2, "foundationDark"}, {-5, 2, "foundation"}, {4, 2, "foundation"}, {5, 2, "foundationDark"},
    {-5, 3, "foundationDark"}, {-4, 3, "foundation"}, {-3, 3, "foundation"}, {-2, 3, "foundation"}, {-1, 3, "foundation"}, {0, 3, "foundation"}, {1, 3, "foundation"}, {2, 3, "foundation"}, {3, 3, "foundation"}, {4, 3, "foundationDark"},

    -- Counterweight mass (extends behind mount) - rows 4 to 9
    {-7, 4, "platformDark"}, {-6, 4, "platform"}, {-5, 4, "platform"}, {-4, 4, "platform"}, {-3, 4, "platform"}, {-2, 4, "platform"}, {-1, 4, "platform"}, {0, 4, "platform"}, {1, 4, "platform"}, {2, 4, "platform"}, {3, 4, "platform"}, {4, 4, "platform"}, {5, 4, "platform"}, {6, 4, "platformDark"},
    {-8, 5, "platformDark"}, {-7, 5, "platform"}, {-6, 5, "platform"}, {-5, 5, "platform"}, {-4, 5, "platform"}, {-3, 5, "platform"}, {-2, 5, "platform"}, {-1, 5, "platform"}, {0, 5, "platform"}, {1, 5, "platform"}, {2, 5, "platform"}, {3, 5, "platform"}, {4, 5, "platform"}, {5, 5, "platform"}, {6, 5, "platform"}, {7, 5, "platformDark"},
    {-8, 6, "platformDark"}, {-7, 6, "platform"}, {-6, 6, "platform"}, {-5, 6, "platform"}, {-4, 6, "platform"}, {-3, 6, "platform"}, {-2, 6, "platform"}, {-1, 6, "platform"}, {0, 6, "platform"}, {1, 6, "platform"}, {2, 6, "platform"}, {3, 6, "platform"}, {4, 6, "platform"}, {5, 6, "platform"}, {6, 6, "platform"}, {7, 6, "platformDark"},
    {-8, 7, "foundationDark"}, {-7, 7, "foundation"}, {-6, 7, "foundation"}, {-5, 7, "foundation"}, {-4, 7, "foundation"}, {-3, 7, "foundation"}, {-2, 7, "foundation"}, {-1, 7, "foundation"}, {0, 7, "foundation"}, {1, 7, "foundation"}, {2, 7, "foundation"}, {3, 7, "foundation"}, {4, 7, "foundation"}, {5, 7, "foundation"}, {6, 7, "foundation"}, {7, 7, "foundationDark"},
    {-7, 8, "foundationDark"}, {-6, 8, "foundation"}, {-5, 8, "foundation"}, {-4, 8, "foundation"}, {-3, 8, "foundation"}, {-2, 8, "foundation"}, {-1, 8, "foundation"}, {0, 8, "foundation"}, {1, 8, "foundation"}, {2, 8, "foundation"}, {3, 8, "foundation"}, {4, 8, "foundation"}, {5, 8, "foundation"}, {6, 8, "foundationDark"},
    {-6, 9, "foundationDark"}, {-5, 9, "foundationDark"}, {-4, 9, "foundationDark"}, {-3, 9, "foundationDark"}, {-2, 9, "foundationDark"}, {-1, 9, "foundationDark"}, {0, 9, "foundationDark"}, {1, 9, "foundationDark"}, {2, 9, "foundationDark"}, {3, 9, "foundationDark"}, {4, 9, "foundationDark"}, {5, 9, "foundationDark"},
}

-- ===================
-- BARREL SPRITE (rotates) - Tapered design
-- Breech: 5px wide, Main shaft: 3px wide, Muzzle: 5px wide
-- ===================
local BARREL_LENGTH = 19

local BARREL_SPRITE = {
    -- === MUZZLE (5px wide, flared) === rows -19 to -16
    -- Muzzle opening (dark bore)
    {-2, -19, "muzzle"}, {-1, -19, "muzzle"}, {0, -19, "muzzle"}, {1, -19, "muzzle"}, {2, -19, "muzzle"},
    -- Muzzle rim (reinforced ring)
    {-2, -18, "barrelLight"}, {-1, -18, "barrelLight"}, {0, -18, "barrelLight"}, {1, -18, "barrelLight"}, {2, -18, "barrelLight"},
    -- Muzzle taper down
    {-2, -17, "barrelDark"}, {-1, -17, "barrelMid"}, {0, -17, "barrelLight"}, {1, -17, "barrelMid"}, {2, -17, "barrelDark"},
    {-1, -16, "barrelMid"}, {0, -16, "barrelLight"}, {1, -16, "barrelMid"},

    -- === MAIN BARREL SHAFT (3px wide) === rows -15 to -8
    {-1, -15, "barrelDark"}, {0, -15, "barrelLight"}, {1, -15, "barrelDark"},
    {-1, -14, "barrelDark"}, {0, -14, "barrelMid"}, {1, -14, "barrelDark"},
    {-1, -13, "barrelDark"}, {0, -13, "barrelLight"}, {1, -13, "barrelDark"},
    -- Reinforcement band
    {-1, -12, "barrelLight"}, {0, -12, "barrelLight"}, {1, -12, "barrelLight"},
    {-1, -11, "barrelDark"}, {0, -11, "barrelMid"}, {1, -11, "barrelDark"},
    {-1, -10, "barrelDark"}, {0, -10, "barrelLight"}, {1, -10, "barrelDark"},
    {-1, -9, "barrelDark"}, {0, -9, "barrelMid"}, {1, -9, "barrelDark"},
    {-1, -8, "barrelDark"}, {0, -8, "barrelLight"}, {1, -8, "barrelDark"},

    -- === BARREL TAPER TO BREECH (3px to 5px) === rows -7 to -6
    {-1, -7, "barrelMid"}, {0, -7, "barrelLight"}, {1, -7, "barrelMid"},
    {-2, -6, "barrelDark"}, {-1, -6, "barrelMid"}, {0, -6, "barrelLight"}, {1, -6, "barrelMid"}, {2, -6, "barrelDark"},

    -- === BREECH (5px wide, chunky) === rows -5 to -2
    {-2, -5, "breechDark"}, {-1, -5, "breech"}, {0, -5, "breechLight"}, {1, -5, "breech"}, {2, -5, "breechDark"},
    {-2, -4, "breechDark"}, {-1, -4, "breechLight"}, {0, -4, "breechLight"}, {1, -4, "breechLight"}, {2, -4, "breechDark"},
    {-2, -3, "breechDark"}, {-1, -3, "breech"}, {0, -3, "breechLight"}, {1, -3, "breech"}, {2, -3, "breechDark"},
    {-2, -2, "breechDark"}, {-1, -2, "breech"}, {0, -2, "breech"}, {1, -2, "breech"}, {2, -2, "breechDark"},

    -- === TURRET HOUSING (rotates with barrel, sits on track) === rows -1 to 3
    -- Top rim
    {-4, -1, "baseDark"}, {-3, -1, "baseMid"}, {-2, -1, "baseLight"}, {-1, -1, "baseLight"}, {0, -1, "baseLight"}, {1, -1, "baseLight"}, {2, -1, "baseMid"}, {3, -1, "baseDark"},
    -- Housing body (circular, fills the track)
    {-4, 0, "baseDark"}, {-3, 0, "baseMid"}, {-2, 0, "baseLight"}, {-1, 0, "baseLight"}, {0, 0, "baseLight"}, {1, 0, "baseLight"}, {2, 0, "baseMid"}, {3, 0, "baseDark"},
    {-4, 1, "baseDark"}, {-3, 1, "baseMid"}, {-2, 1, "baseMid"}, {-1, 1, "baseLight"}, {0, 1, "baseLight"}, {1, 1, "baseMid"}, {2, 1, "baseMid"}, {3, 1, "baseDark"},
    {-4, 2, "baseDark"}, {-3, 2, "baseMid"}, {-2, 2, "baseMid"}, {-1, 2, "baseMid"}, {0, 2, "baseMid"}, {1, 2, "baseMid"}, {2, 2, "baseMid"}, {3, 2, "baseDark"},
    -- Bottom rim
    {-3, 3, "baseDark"}, {-2, 3, "baseDark"}, {-1, 3, "baseDark"}, {0, 3, "baseDark"}, {1, 3, "baseDark"}, {2, 3, "baseDark"},
}

-- ===================
-- TURRET CLASS
-- ===================

function Turret:new(x, y)
    self.x = x
    self.y = y
    self.angle = -math.pi / 2  -- Point upward by default
    self.fireTimer = 0
    self.hp = TOWER_HP
    self.maxHp = TOWER_HP

    -- Stats (can be modified by upgrades)
    self.fireRate = TOWER_FIRE_RATE
    self.damage = PROJECTILE_DAMAGE
    self.projectileSpeed = PROJECTILE_SPEED

    -- Visual effects
    self.muzzleFlash = 0
    self.glowPulse = 0
    self.gunKick = 0

    -- Enhanced visual effects
    self.damageFlinch = 0
    self.statusBlink = 0
end

function Turret:update(dt, targetX, targetY)
    -- Point toward target
    if targetX and targetY then
        self.angle = math.atan2(targetY - self.y, targetX - self.x)
    end

    -- Fire timer
    if self.fireTimer > 0 then
        self.fireTimer = self.fireTimer - dt
    end

    -- Muzzle flash decay
    if self.muzzleFlash > 0 then
        self.muzzleFlash = self.muzzleFlash - dt
    end

    -- Gun kick decay
    if self.gunKick > 0 then
        self.gunKick = self.gunKick - dt * GUN_KICK_DECAY
        if self.gunKick < 0 then self.gunKick = 0 end
    end

    -- Glow pulse animation
    self.glowPulse = self.glowPulse + dt * 2

    -- Status blink
    self.statusBlink = (self.statusBlink + dt) % 1.0

    -- Damage flinch decay
    if self.damageFlinch > 0 then
        self.damageFlinch = self.damageFlinch - dt * 15
        if self.damageFlinch < 0 then self.damageFlinch = 0 end
    end
end

function Turret:canFire()
    return self.fireTimer <= 0
end

function Turret:fire()
    if not self:canFire() then return nil end

    self.fireTimer = self.fireRate
    self.muzzleFlash = 0.1
    self.gunKick = GUN_KICK_AMOUNT

    -- Play shooting sound
    Sounds.playShoot()

    -- Calculate muzzle position
    local gunLength = BARREL_LENGTH * BLOB_PIXEL_SIZE * TURRET_SCALE
    local muzzleX = self.x + math.cos(self.angle) * gunLength
    local muzzleY = self.y + math.sin(self.angle) * gunLength

    -- Create projectile
    local projectile = Projectile(
        muzzleX,
        muzzleY,
        self.angle,
        self.projectileSpeed,
        self.damage
    )

    return projectile
end

function Turret:draw()
    local ps = BLOB_PIXEL_SIZE * TURRET_SCALE
    local hpPercent = self:getHpPercent()

    -- Calculate damage flinch offset
    local flinchX = self.damageFlinch * math.cos(self.angle + math.pi) * 2
    local flinchY = self.damageFlinch * math.sin(self.angle + math.pi) * 2

    -- Draw base (static, doesn't rotate)
    for _, def in ipairs(BASE_SPRITE) do
        local ox, oy, colorKey = def[1], def[2], def[3]
        local color = TURRET_COLORS[colorKey]
        if color then
            love.graphics.setColor(color[1], color[2], color[3])
            love.graphics.rectangle("fill",
                self.x + ox * ps - ps / 2 + flinchX,
                self.y + oy * ps - ps / 2 + flinchY,
                ps, ps)
        end
    end

    -- Draw status lights (HP indicator)
    local statusColor
    if hpPercent > 0.5 then
        statusColor = {0.2, 0.8, 0.3}  -- Green
    elseif hpPercent > 0.25 then
        statusColor = {0.9, 0.8, 0.2}  -- Yellow
    else
        statusColor = {0.9, 0.25, 0.2}  -- Red
    end

    local statusAlpha = 1.0
    if hpPercent <= 0.25 then
        statusAlpha = self.statusBlink < 0.5 and 1.0 or 0.3
    elseif hpPercent <= 0.5 then
        statusAlpha = 0.7 + math.sin(self.statusBlink * math.pi * 2) * 0.3
    end

    -- Status lights on counterweight (wider part of base)
    love.graphics.setColor(statusColor[1], statusColor[2], statusColor[3], statusAlpha)
    love.graphics.rectangle("fill", self.x + 4 * ps - ps / 2 + flinchX, self.y + 4 * ps - ps / 2 + flinchY, ps, ps)
    love.graphics.rectangle("fill", self.x - 5 * ps - ps / 2 + flinchX, self.y + 4 * ps - ps / 2 + flinchY, ps, ps)

    -- Draw rotating parts (barrel)
    love.graphics.push()
    love.graphics.translate(self.x + flinchX, self.y + flinchY)
    love.graphics.rotate(self.angle + math.pi / 2)  -- Adjust for sprite pointing up

    -- Calculate gun kick offset (kicks backward = +y in local space)
    local kickOffset = self.gunKick * ps

    -- Draw barrel with kick offset
    for _, def in ipairs(BARREL_SPRITE) do
        local ox, oy, colorKey = def[1], def[2], def[3]
        local color = TURRET_COLORS[colorKey]
        if color then
            love.graphics.setColor(color[1], color[2], color[3])
            love.graphics.rectangle("fill",
                ox * ps - ps / 2,
                oy * ps - ps / 2 + kickOffset,
                ps, ps)
        end
    end

    -- Muzzle flash (single barrel)
    if self.muzzleFlash > 0 then
        local flashIntensity = self.muzzleFlash / 0.1
        local muzzleY = -(BARREL_LENGTH + 1) * ps + kickOffset

        -- Outer glow
        love.graphics.setColor(1, 0.5, 0.1, flashIntensity * 0.3)
        love.graphics.circle("fill", 0, muzzleY, ps * 4)

        -- Mid glow
        love.graphics.setColor(1, 0.7, 0.2, flashIntensity * 0.6)
        love.graphics.circle("fill", 0, muzzleY, ps * 2.5)

        -- Inner flash
        love.graphics.setColor(1, 0.9, 0.4, flashIntensity * 0.9)
        love.graphics.circle("fill", 0, muzzleY, ps * 1.5)

        -- Core
        love.graphics.setColor(1, 1, 0.9, flashIntensity)
        love.graphics.circle("fill", 0, muzzleY, ps * 0.8)

        -- Directional spike
        love.graphics.setColor(1, 0.95, 0.6, flashIntensity * 0.7)
        local spikeLength = ps * 4 * flashIntensity
        love.graphics.polygon("fill",
            -ps * 0.4, muzzleY,
            0, muzzleY - spikeLength,
            ps * 0.4, muzzleY
        )
    end

    love.graphics.pop()

    -- Subtle glow ring around base
    local glowAlpha = 0.08 + math.sin(self.glowPulse) * 0.04
    local glowSize = 4.0 + math.sin(self.glowPulse * 0.5) * 0.3
    love.graphics.setColor(0.4, 0.5, 0.6, glowAlpha)
    love.graphics.circle("fill", self.x + flinchX, self.y + flinchY, ps * glowSize)
end

function Turret:takeDamage(amount)
    self.hp = self.hp - amount
    self.damageFlinch = 1.0

    -- Screen shake when tower takes damage
    triggerScreenShake(SCREEN_SHAKE_INTENSITY * 1.5, SCREEN_SHAKE_DURATION)

    if self.hp <= 0 then
        self.hp = 0
        return true
    end
    return false
end

function Turret:getHpPercent()
    return self.hp / self.maxHp
end

return Turret
