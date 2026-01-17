-- turret.lua
-- Simple Neon Turret - Circle base + Rectangle barrel

local Turret = Object:extend()

-- Simple neon colors
local BASE_COLOR = {0.00, 1.00, 0.00}       -- Bright green
local BASE_FILL = {0.00, 0.15, 0.00}        -- Dark green fill
local BARREL_COLOR = {0.00, 1.00, 0.00}     -- Bright green

-- Dimensions (scaled ~0.67x for larger play area)
local BASE_RADIUS = 23
local BARREL_LENGTH = 33
local BARREL_WIDTH = 9
local BARREL_BACK = 10  -- How far barrel extends behind center

function Turret:new(x, y)
    self.x = x
    self.y = y
    self.angle = -math.pi / 2
    self.targetAngle = self.angle
    self.fireTimer = 0
    self.hp = TOWER_HP
    self.maxHp = TOWER_HP

    self.fireRate = TOWER_FIRE_RATE
    self.damage = PROJECTILE_DAMAGE
    self.projectileSpeed = PROJECTILE_SPEED

    self.muzzleFlash = 0
    self.gunKick = 0
    self.damageFlinch = 0
end

function Turret:update(dt, targetX, targetY)
    if targetX and targetY then
        self.targetAngle = math.atan2(targetY - self.y, targetX - self.x)
    end

    -- Smooth rotation
    local angleDiff = self.targetAngle - self.angle
    while angleDiff > math.pi do angleDiff = angleDiff - 2 * math.pi end
    while angleDiff < -math.pi do angleDiff = angleDiff + 2 * math.pi end

    local rotateAmount = TURRET_ROTATION_SPEED * dt
    if math.abs(angleDiff) < rotateAmount then
        self.angle = self.targetAngle
    elseif angleDiff > 0 then
        self.angle = self.angle + rotateAmount
    else
        self.angle = self.angle - rotateAmount
    end

    while self.angle > math.pi do self.angle = self.angle - 2 * math.pi end
    while self.angle < -math.pi do self.angle = self.angle + 2 * math.pi end

    if self.fireTimer > 0 then
        self.fireTimer = self.fireTimer - dt
    end

    if self.muzzleFlash > 0 then
        self.muzzleFlash = self.muzzleFlash - dt
    end

    if self.gunKick > 0 then
        self.gunKick = self.gunKick - dt * GUN_KICK_DECAY
        if self.gunKick < 0 then self.gunKick = 0 end
    end

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

    Sounds.playShoot()

    local muzzleX = self.x + math.cos(self.angle) * BARREL_LENGTH
    local muzzleY = self.y + math.sin(self.angle) * BARREL_LENGTH

    return Projectile(muzzleX, muzzleY, self.angle, self.projectileSpeed, self.damage)
end

function Turret:drawBaseOnly()
    local flinchX = self.damageFlinch * math.cos(self.angle + math.pi) * 2
    local flinchY = self.damageFlinch * math.sin(self.angle + math.pi) * 2
    local drawX = self.x + flinchX
    local drawY = self.y + flinchY

    -- Base glow
    love.graphics.setColor(BASE_COLOR[1], BASE_COLOR[2], BASE_COLOR[3], 0.15)
    love.graphics.circle("fill", drawX, drawY, BASE_RADIUS + 8)

    -- Base fill
    love.graphics.setColor(BASE_FILL[1], BASE_FILL[2], BASE_FILL[3], 1)
    love.graphics.circle("fill", drawX, drawY, BASE_RADIUS)

    -- Base border
    love.graphics.setColor(BASE_COLOR[1], BASE_COLOR[2], BASE_COLOR[3], 0.7)
    love.graphics.setLineWidth(4)
    love.graphics.circle("line", drawX, drawY, BASE_RADIUS)
    love.graphics.setLineWidth(1)
end

function Turret:draw(barrelExtendOverride)
    local flinchX = self.damageFlinch * math.cos(self.angle + math.pi) * 2
    local flinchY = self.damageFlinch * math.sin(self.angle + math.pi) * 2
    local drawX = self.x + flinchX
    local drawY = self.y + flinchY

    -- ===================
    -- 1. CIRCLE BASE (behind barrel)
    -- ===================
    -- Base glow
    love.graphics.setColor(BASE_COLOR[1], BASE_COLOR[2], BASE_COLOR[3], 0.15)
    love.graphics.circle("fill", drawX, drawY, BASE_RADIUS + 8)

    -- Base fill
    love.graphics.setColor(BASE_FILL[1], BASE_FILL[2], BASE_FILL[3], 1)
    love.graphics.circle("fill", drawX, drawY, BASE_RADIUS)

    -- Base border
    love.graphics.setColor(BASE_COLOR[1], BASE_COLOR[2], BASE_COLOR[3], 0.7)
    love.graphics.setLineWidth(4)
    love.graphics.circle("line", drawX, drawY, BASE_RADIUS)
    love.graphics.setLineWidth(1)

    -- ===================
    -- 2. BARREL (on top)
    -- ===================
    local barrelExt = barrelExtendOverride or 1.0
    if barrelExt <= 0 then
        return  -- Skip barrel entirely if not extended
    end

    love.graphics.push()
    love.graphics.translate(drawX, drawY)
    love.graphics.rotate(self.angle)

    local kickBack = self.gunKick * 10
    local halfWidth = BARREL_WIDTH / 2

    -- Scale barrel dimensions by extension amount
    local effectiveLength = BARREL_LENGTH * barrelExt
    local effectiveBack = BARREL_BACK * barrelExt
    local barrelStart = -kickBack - effectiveBack
    local barrelTotal = effectiveLength + effectiveBack

    -- Barrel glow (draw along X-axis to match firing direction)
    love.graphics.setColor(BARREL_COLOR[1], BARREL_COLOR[2], BARREL_COLOR[3], 0.2)
    love.graphics.setLineWidth(8)
    love.graphics.rectangle("line", barrelStart, -halfWidth - 2, barrelTotal, BARREL_WIDTH + 4)

    -- Barrel fill
    love.graphics.setColor(BARREL_COLOR[1], BARREL_COLOR[2], BARREL_COLOR[3], 1)
    love.graphics.rectangle("fill", barrelStart, -halfWidth, barrelTotal, BARREL_WIDTH)

    -- Barrel border
    love.graphics.setColor(BARREL_COLOR[1], BARREL_COLOR[2], BARREL_COLOR[3], 0.6)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", barrelStart, -halfWidth, barrelTotal, BARREL_WIDTH)

    love.graphics.setLineWidth(1)
    love.graphics.pop()
end

function Turret:takeDamage(amount)
    self.hp = self.hp - amount
    self.damageFlinch = 1.0
    Feedback:trigger("tower_damage")

    if self.hp <= 0 then
        self.hp = 0
        return true
    end
    return false
end

function Turret:getHpPercent()
    return self.hp / self.maxHp
end

-- Returns the visual muzzle position (accounting for flinch only, not kick)
function Turret:getMuzzleTip()
    local flinchX = self.damageFlinch * math.cos(self.angle + math.pi) * 2
    local flinchY = self.damageFlinch * math.sin(self.angle + math.pi) * 2
    local drawX = self.x + flinchX
    local drawY = self.y + flinchY

    -- Use BARREL_LENGTH directly - don't follow kick animation
    local tipX = drawX + math.cos(self.angle) * BARREL_LENGTH
    local tipY = drawY + math.sin(self.angle) * BARREL_LENGTH

    return tipX, tipY
end

return Turret
