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

    -- Movement
    self.moveSpeed = PLAYER_MOVE_SPEED

    -- Dash state
    self.dash = {
        state = "ready",  -- "ready"|"anticipation"|"dashing"|"recovery"
        timer = 0,
        charges = DASH_MAX_CHARGES,
        rechargeTimer = 0,
        startX = 0, startY = 0,
        targetX = 0, targetY = 0,
        directionAngle = 0,
        scaleX = 1.0, scaleY = 1.0,
        afterimages = {},
        afterimageTimer = 0,
    }
end

function Turret:update(dt, targetX, targetY)
    -- Update dash system
    self:updateDash(dt)

    -- WASD movement (only when not dashing)
    if self.dash.state == "ready" then
        local moveX, moveY = 0, 0
        if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
            moveY = -1
        end
        if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
            moveY = 1
        end
        if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
            moveX = -1
        end
        if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
            moveX = 1
        end

        -- Normalize diagonal movement
        if moveX ~= 0 and moveY ~= 0 then
            local len = math.sqrt(moveX * moveX + moveY * moveY)
            moveX = moveX / len
            moveY = moveY / len
        end

        -- Apply movement
        self.x = self.x + moveX * self.moveSpeed * dt
        self.y = self.y + moveY * self.moveSpeed * dt
    end

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

    local muzzleX = self.x + math.cos(self.angle) * BARREL_LENGTH
    local muzzleY = self.y + math.sin(self.angle) * BARREL_LENGTH

    -- Emit fire event (handles sound)
    EventBus:emit("projectile_fire", {
        x = muzzleX,
        y = muzzleY,
        angle = self.angle,
    })

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

    -- Apply dash squash/stretch transformation
    love.graphics.push()
    love.graphics.translate(drawX, drawY)

    -- Rotate to dash direction, apply scale, rotate back
    if self.dash.state ~= "ready" then
        love.graphics.rotate(self.dash.directionAngle)
        love.graphics.scale(self.dash.scaleX, self.dash.scaleY)
        love.graphics.rotate(-self.dash.directionAngle)
    end

    -- Translate back so drawing is centered at origin
    love.graphics.translate(-drawX, -drawY)

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
        love.graphics.pop()
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

    -- Pop the dash transform
    love.graphics.pop()
end

function Turret:takeDamage(amount)
    self.hp = self.hp - amount
    self.damageFlinch = 1.0

    -- Emit tower damage event (handles feedback)
    EventBus:emit("tower_damage", {
        damage = amount,
        currentHp = self.hp,
        maxHp = self.maxHp,
    })

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

-- ===================
-- DASH SYSTEM
-- ===================

-- Easing functions
local function easeOutQuad(t)
    return 1 - (1 - t) * (1 - t)
end

local function easeOutExpo(t)
    return t == 1 and 1 or 1 - math.pow(2, -10 * t)
end

--- Try to initiate a dash in the given direction
function Turret:tryDash(dirX, dirY)
    -- Can't dash if no charges or already dashing
    if self.dash.charges <= 0 or self.dash.state ~= "ready" then
        return false
    end

    -- Normalize direction
    local len = math.sqrt(dirX * dirX + dirY * dirY)
    if len < 0.001 then
        return false
    end
    dirX = dirX / len
    dirY = dirY / len

    -- Consume charge
    self.dash.charges = self.dash.charges - 1

    -- Set up dash
    self.dash.state = "anticipation"
    self.dash.timer = 0
    self.dash.startX = self.x
    self.dash.startY = self.y
    self.dash.targetX = self.x + dirX * DASH_DISTANCE
    self.dash.targetY = self.y + dirY * DASH_DISTANCE
    self.dash.directionAngle = math.atan2(dirY, dirX)
    self.dash.afterimages = {}
    self.dash.afterimageTimer = 0

    -- Emit dash launch event (handles feedback)
    EventBus:emit("dash_launch", {
        x = self.x,
        y = self.y,
        angle = self.dash.directionAngle,
    })

    return true
end

--- Update dash state machine
function Turret:updateDash(dt)
    -- Recharge charges when not at max
    if self.dash.charges < DASH_MAX_CHARGES then
        self.dash.rechargeTimer = self.dash.rechargeTimer + dt
        if self.dash.rechargeTimer >= DASH_RECHARGE_TIME then
            self.dash.rechargeTimer = self.dash.rechargeTimer - DASH_RECHARGE_TIME
            self.dash.charges = self.dash.charges + 1
        end
    else
        self.dash.rechargeTimer = 0
    end

    -- Update afterimages (fade them out)
    for i = #self.dash.afterimages, 1, -1 do
        local img = self.dash.afterimages[i]
        img.life = img.life - dt
        if img.life <= 0 then
            table.remove(self.dash.afterimages, i)
        end
    end

    -- State machine
    if self.dash.state == "ready" then
        -- Reset scale when ready
        self.dash.scaleX = 1.0
        self.dash.scaleY = 1.0
        return
    end

    self.dash.timer = self.dash.timer + dt

    if self.dash.state == "anticipation" then
        -- Wind-up squash phase
        local t = math.min(self.dash.timer / DASH_ANTICIPATION_TIME, 1.0)
        local easedT = easeOutQuad(t)

        -- Squash in direction of movement, stretch perpendicular
        self.dash.scaleX = 1.0 - (1.0 - DASH_SQUASH_AMOUNT) * easedT
        -- Volume preservation: scaleY = 1 / scaleX (approximately)
        self.dash.scaleY = 1.0 + (1.0 - DASH_SQUASH_AMOUNT) * easedT * 0.5

        if self.dash.timer >= DASH_ANTICIPATION_TIME then
            -- Transition to dashing
            self.dash.state = "dashing"
            self.dash.timer = 0

            -- Emit dash start event (handles launch particles)
            EventBus:emit("dash_start", {
                x = self.x,
                y = self.y,
                angle = self.dash.directionAngle,
            })
        end

    elseif self.dash.state == "dashing" then
        -- Main movement phase
        local t = math.min(self.dash.timer / DASH_DURATION, 1.0)
        local easedT = easeOutExpo(t)

        -- Lerp position
        self.x = self.dash.startX + (self.dash.targetX - self.dash.startX) * easedT
        self.y = self.dash.startY + (self.dash.targetY - self.dash.startY) * easedT

        -- Stretch during dash with bell curve (starts stretched, peaks, then returns)
        -- Use a parabola that peaks at t=0.3 for fast start feel
        local stretchT = 1 - (t - 0.3) * (t - 0.3) / 0.49  -- Parabola peaking at t=0.3
        stretchT = math.max(0, stretchT)
        self.dash.scaleX = 1.0 + (DASH_STRETCH_AMOUNT - 1.0) * stretchT
        -- Volume preservation
        self.dash.scaleY = 1.0 / math.sqrt(self.dash.scaleX)

        -- Spawn afterimages
        self.dash.afterimageTimer = self.dash.afterimageTimer + dt
        if self.dash.afterimageTimer >= DASH_AFTERIMAGE_INTERVAL then
            self.dash.afterimageTimer = self.dash.afterimageTimer - DASH_AFTERIMAGE_INTERVAL
            table.insert(self.dash.afterimages, {
                x = self.x,
                y = self.y,
                angle = self.angle,
                life = DASH_AFTERIMAGE_LIFETIME,
                maxLife = DASH_AFTERIMAGE_LIFETIME,
            })
            -- Cap afterimages at 5
            while #self.dash.afterimages > 5 do
                table.remove(self.dash.afterimages, 1)
            end
        end

        if self.dash.timer >= DASH_DURATION then
            -- Transition to recovery
            self.dash.state = "recovery"
            self.dash.timer = 0

            -- Ensure we're at target position
            self.x = self.dash.targetX
            self.y = self.dash.targetY

            -- Emit dash land event (handles feedback and landing particles)
            EventBus:emit("dash_land", {
                x = self.x,
                y = self.y,
                angle = self.dash.directionAngle,
            })
        end

    elseif self.dash.state == "recovery" then
        -- Landing settle phase with damped spring oscillation
        local t = math.min(self.dash.timer / DASH_RECOVERY_TIME, 1.0)

        -- Damped spring: starts squashed, oscillates to 1.0
        local springT = t * DASH_RECOVERY_TIME
        local decay = math.exp(-DASH_SPRING_DAMPING * springT)
        local oscillation = math.cos(DASH_SPRING_FREQUENCY * springT * math.pi * 2)
        local springValue = 1.0 + (DASH_OVERSHOOT_SQUASH - 1.0) * decay * oscillation

        self.dash.scaleX = springValue
        self.dash.scaleY = 2.0 - springValue  -- Inverse for volume preservation

        if self.dash.timer >= DASH_RECOVERY_TIME then
            -- Return to ready state
            self.dash.state = "ready"
            self.dash.timer = 0
            self.dash.scaleX = 1.0
            self.dash.scaleY = 1.0
        end
    end
end

--- Draw afterimages (call before drawing turret)
function Turret:drawAfterimages()
    for _, img in ipairs(self.dash.afterimages) do
        local alpha = (img.life / img.maxLife) * 0.4

        love.graphics.push()
        love.graphics.translate(img.x, img.y)

        -- Draw simplified base only (green tinted ghost)
        love.graphics.setColor(0, 1, 0, alpha * 0.3)
        love.graphics.circle("fill", 0, 0, BASE_RADIUS)
        love.graphics.setColor(0, 1, 0, alpha)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", 0, 0, BASE_RADIUS)
        love.graphics.setLineWidth(1)

        love.graphics.pop()
    end
end

--- Check if currently dashing
function Turret:isDashing()
    return self.dash.state ~= "ready"
end

--- Get dash charge info for UI
function Turret:getDashInfo()
    return {
        charges = self.dash.charges,
        maxCharges = DASH_MAX_CHARGES,
        rechargeProgress = self.dash.rechargeTimer / DASH_RECHARGE_TIME,
    }
end

return Turret
