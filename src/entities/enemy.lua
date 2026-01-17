-- enemy.lua
-- Neon Geometric Enemies

local Enemy = Object:extend()

function Enemy:new(x, y, scale, enemyType)
    self.x = x
    self.y = y
    self.enemyType = enemyType or "basic"

    -- Get stats from config
    local stats = ENEMY_TYPES[self.enemyType] or ENEMY_TYPES.basic
    self.shapeName = stats.shape
    self.speed = stats.speed * lume.random(1 - SPEED_VARIATION, 1 + SPEED_VARIATION)
    self.scale = scale or stats.scale
    self.baseScale = self.scale
    self.size = stats.baseSize
    self.color = stats.color

    -- Parts system (each side is a breakable part)
    local shape = ENEMY_SHAPES[self.shapeName]
    self.numParts = #shape

    -- HP = number of sides (parts)
    -- Triangle: 3 HP, Square: 4 HP, Pentagon: 5 HP
    self.hp = self.numParts
    self.maxHp = self.numParts

    self.parts = {}
    for i = 1, self.numParts do
        self.parts[i] = {
            alive = true,
            flashTimer = 0,
        }
    end
    self.alivePartCount = self.numParts
    self.coreFlashTimer = 0

    -- State
    self.dead = false
    self.flashTimer = 0
    self.knockbackX = 0
    self.knockbackY = 0

    -- Simple rotation for visual interest
    self.rotation = 0
    self.rotationSpeed = lume.random(-1, 1)
end

function Enemy:update(dt)
    if self.dead then return end

    -- Rotate slowly
    self.rotation = self.rotation + self.rotationSpeed * dt

    -- Update part flash timers
    for i = 1, self.numParts do
        if self.parts[i].flashTimer > 0 then
            self.parts[i].flashTimer = self.parts[i].flashTimer - dt
        end
    end

    -- Update core flash timer
    if self.coreFlashTimer > 0 then
        self.coreFlashTimer = self.coreFlashTimer - dt
    end

    -- Apply knockback (fast decay for punchy feel)
    if self.knockbackX ~= 0 or self.knockbackY ~= 0 then
        self.x = self.x + self.knockbackX * dt
        self.y = self.y + self.knockbackY * dt
        self.knockbackX = self.knockbackX * (1 - 12 * dt)
        self.knockbackY = self.knockbackY * (1 - 12 * dt)
        if math.abs(self.knockbackX) < 1 then self.knockbackX = 0 end
        if math.abs(self.knockbackY) < 1 then self.knockbackY = 0 end
    end

    -- Move toward tower
    local dx = tower.x - self.x
    local dy = tower.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 5 then
        local moveX = (dx / dist) * self.speed * dt
        local moveY = (dy / dist) * self.speed * dt
        self.x = self.x + moveX
        self.y = self.y + moveY
    end
end

function Enemy:draw()
    if self.dead then return end

    local shape = ENEMY_SHAPES[self.shapeName]
    local radius = self.size * self.scale
    local coreRadius = radius * 0.92  -- Slightly smaller for core fill

    -- Build vertices for outline
    local verts = {}
    for _, v in ipairs(shape) do
        local rx = v[1] * math.cos(self.rotation) - v[2] * math.sin(self.rotation)
        local ry = v[1] * math.sin(self.rotation) + v[2] * math.cos(self.rotation)
        table.insert(verts, self.x + rx * radius)
        table.insert(verts, self.y + ry * radius)
    end

    -- Build vertices for core (slightly smaller)
    local coreVerts = {}
    for _, v in ipairs(shape) do
        local rx = v[1] * math.cos(self.rotation) - v[2] * math.sin(self.rotation)
        local ry = v[1] * math.sin(self.rotation) + v[2] * math.cos(self.rotation)
        table.insert(coreVerts, self.x + rx * coreRadius)
        table.insert(coreVerts, self.y + ry * coreRadius)
    end

    local baseColor = self.color

    -- Outer glow (all sides, creates "skeleton" effect)
    love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], 0.15)
    love.graphics.setLineWidth(12)
    love.graphics.polygon("line", verts)

    -- Mid glow (all sides)
    love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], 0.25)
    love.graphics.setLineWidth(6)
    love.graphics.polygon("line", verts)

    -- Dark fill (core) - flash white when hit through gap
    local coreColor = baseColor
    if self.coreFlashTimer > 0 then
        local flashIntensity = self.coreFlashTimer / CORE_FLASH_DURATION
        coreColor = {
            lume.lerp(baseColor[1], 1, flashIntensity),
            lume.lerp(baseColor[2], 1, flashIntensity),
            lume.lerp(baseColor[3], 1, flashIntensity),
        }
    end
    love.graphics.setColor(coreColor[1] * 0.15, coreColor[2] * 0.15, coreColor[3] * 0.15, 0.9)
    love.graphics.polygon("fill", coreVerts)

    -- Thick border - ONLY ALIVE SIDES with per-side flash
    love.graphics.setLineWidth(4)
    for i = 1, self.numParts do
        local part = self.parts[i]
        if part.alive then
            local x1, y1, x2, y2 = self:getSideVertices(i)

            -- Determine side color (flash red when hit)
            local sideColor
            if part.flashTimer > 0 then
                local flashIntensity = part.flashTimer / PART_FLASH_DURATION
                sideColor = {
                    lume.lerp(baseColor[1] * 0.7, 1, flashIntensity),
                    lume.lerp(baseColor[2] * 0.7, 0.3, flashIntensity),
                    lume.lerp(baseColor[3] * 0.7, 0.3, flashIntensity),
                }
            else
                sideColor = {baseColor[1] * 0.7, baseColor[2] * 0.7, baseColor[3] * 0.7}
            end

            love.graphics.setColor(sideColor[1], sideColor[2], sideColor[3], 1)
            love.graphics.line(x1, y1, x2, y2)
        end
    end

    love.graphics.setLineWidth(1)
end

-- ===================
-- DYNAMIC IMPACT CALCULATIONS
-- ===================

-- Calculate dynamic knockback force based on bullet velocity and damage
function Enemy:calculateKnockback(damage, impactVelocity)
    local velocityRatio = impactVelocity / PROJECTILE_SPEED
    local damageRatio = damage / PROJECTILE_DAMAGE

    -- Velocity scales linearly, damage with reduced power (velocity-focused)
    local multiplier = velocityRatio * math.pow(damageRatio, KNOCKBACK_DAMAGE_SCALE)
    multiplier = math.min(multiplier, KNOCKBACK_MAX_MULTIPLIER)

    return KNOCKBACK_BASE_FORCE * multiplier
end

-- Calculate dynamic particle intensity based on bullet velocity and damage
function Enemy:calculateIntensity(damage, impactVelocity)
    local velocityRatio = impactVelocity / PROJECTILE_SPEED
    local damageRatio = damage / PROJECTILE_DAMAGE

    -- Velocity-focused blend
    local intensity = IMPACT_BASE_INTENSITY
        + (velocityRatio - 1) * IMPACT_VELOCITY_SCALE
        + (damageRatio - 1) * IMPACT_DAMAGE_SCALE

    return math.max(0.2, math.min(intensity, IMPACT_MAX_INTENSITY))
end

-- Calculate dynamic explosion velocity based on bullet velocity and overkill damage
function Enemy:calculateExplosionVelocity(impactVelocity, overkillDamage)
    -- Overkill bonus (killing blow dealt more damage than remaining HP)
    local overkillBonus = 0
    if overkillDamage and overkillDamage > 0 then
        overkillBonus = math.min(0.5, overkillDamage / self.maxHp) * 50
    end

    local explosionVelocity = EXPLOSION_BASE_VELOCITY
        + (impactVelocity - PROJECTILE_SPEED) * EXPLOSION_VELOCITY_INHERIT
        + overkillBonus

    return math.min(math.max(EXPLOSION_BASE_VELOCITY, explosionVelocity), EXPLOSION_MAX_VELOCITY)
end

-- ===================
-- PARTS SYSTEM - GEOMETRY HELPERS
-- ===================

--- Get the world-space vertices of a specific side (line segment)
function Enemy:getSideVertices(sideIndex)
    local shape = ENEMY_SHAPES[self.shapeName]
    local radius = self.size * self.scale

    -- Get the two vertex indices for this side
    local v1Idx = sideIndex
    local v2Idx = (sideIndex % #shape) + 1

    local v1 = shape[v1Idx]
    local v2 = shape[v2Idx]

    -- Apply rotation and position
    local cos_r = math.cos(self.rotation)
    local sin_r = math.sin(self.rotation)

    local x1 = self.x + (v1[1] * cos_r - v1[2] * sin_r) * radius
    local y1 = self.y + (v1[1] * sin_r + v1[2] * cos_r) * radius
    local x2 = self.x + (v2[1] * cos_r - v2[2] * sin_r) * radius
    local y2 = self.y + (v2[1] * sin_r + v2[2] * cos_r) * radius

    return x1, y1, x2, y2
end

--- Get the center point, normal, and length of a side
function Enemy:getSideInfo(sideIndex)
    local x1, y1, x2, y2 = self:getSideVertices(sideIndex)

    -- Center point
    local cx = (x1 + x2) / 2
    local cy = (y1 + y2) / 2

    -- Length
    local length = math.sqrt((x2-x1)^2 + (y2-y1)^2)

    -- Outward normal (perpendicular to side, pointing away from center)
    local dx = x2 - x1
    local dy = y2 - y1
    local nx = -dy / length
    local ny = dx / length

    -- Check if it points away from center
    local toCenterX = self.x - cx
    local toCenterY = self.y - cy
    if nx * toCenterX + ny * toCenterY > 0 then
        nx, ny = -nx, -ny
    end

    return cx, cy, nx, ny, length
end

--- Check if all parts are destroyed
function Enemy:allPartsDestroyed()
    return self.alivePartCount <= 0
end

--- Find the closest alive part to a given point
--- Returns: sideIndex or nil if no parts alive
function Enemy:findClosestAlivePart(hitX, hitY)
    local bestSide = nil
    local bestDist = math.huge

    for i = 1, self.numParts do
        if self.parts[i].alive then
            local cx, cy = self:getSideInfo(i)
            local dist = math.sqrt((cx - hitX)^2 + (cy - hitY)^2)
            if dist < bestDist then
                bestDist = dist
                bestSide = i
            end
        end
    end

    return bestSide
end

-- ===================
-- PARTS SYSTEM - HIT DETECTION
-- ===================

--- Line segment intersection helper
local function lineIntersect(x1, y1, x2, y2, x3, y3, x4, y4)
    local d = (x1-x2)*(y3-y4) - (y1-y2)*(x3-x4)
    if math.abs(d) < 0.0001 then return nil end

    local t = ((x1-x3)*(y3-y4) - (y1-y3)*(x3-x4)) / d
    local u = -((x1-x2)*(y1-y3) - (y1-y2)*(x1-x3)) / d

    if t >= 0 and t <= 1 and u >= 0 and u <= 1 then
        return x1 + t*(x2-x1), y1 + t*(y2-y1), t
    end
    return nil
end

--- Find which side (if any) a bullet hits using ray intersection
--- Returns: sideIndex, hitX, hitY, isGapHit
function Enemy:findHitSideByRay(bulletX, bulletY, prevX, prevY)
    local bestSide = nil
    local bestT = math.huge
    local hitX, hitY = bulletX, bulletY

    for i = 1, self.numParts do
        local x1, y1, x2, y2 = self:getSideVertices(i)
        local ix, iy, t = lineIntersect(prevX, prevY, bulletX, bulletY, x1, y1, x2, y2)

        if ix and t < bestT then
            bestT = t
            bestSide = i
            hitX, hitY = ix, iy
        end
    end

    if bestSide then
        if self.parts[bestSide].alive then
            return bestSide, hitX, hitY, false
        else
            return nil, hitX, hitY, true  -- Gap hit
        end
    end

    return nil, bulletX, bulletY, false
end

--- Fallback: find side using direction-based approach
function Enemy:findHitSideByDirection(bulletX, bulletY, bulletAngle)
    local bestSide = nil
    local bestDot = -math.huge

    -- Bullet incoming direction (reversed)
    local bulletDirX = -math.cos(bulletAngle)
    local bulletDirY = -math.sin(bulletAngle)

    for i = 1, self.numParts do
        local _, _, nx, ny, _ = self:getSideInfo(i)

        -- Dot product of bullet direction with side's outward normal
        local dot = bulletDirX * nx + bulletDirY * ny

        if dot > bestDot then
            bestDot = dot
            bestSide = i
        end
    end

    if bestSide then
        local cx, cy, _, _, _ = self:getSideInfo(bestSide)
        if self.parts[bestSide].alive then
            return bestSide, cx, cy, false
        else
            return nil, cx, cy, true  -- Gap hit
        end
    end

    return nil, bulletX, bulletY, false
end

-- ===================
-- PARTS SYSTEM - DESTRUCTION
-- ===================

--- Destroy a specific side and return data for spawning a flying part
function Enemy:destroyPart(sideIndex, bulletAngle, bulletVelocity)
    if not self.parts[sideIndex] or not self.parts[sideIndex].alive then
        return nil
    end

    -- Mark as destroyed
    self.parts[sideIndex].alive = false
    self.alivePartCount = self.alivePartCount - 1

    -- Get side geometry
    local cx, cy, nx, ny, length = self:getSideInfo(sideIndex)

    -- Calculate part velocity (in bullet direction with some spread)
    local baseSpeed = PART_FLY_SPEED
    local inheritSpeed = (bulletVelocity or PROJECTILE_SPEED) * PART_FLY_SPEED_INHERIT
    local totalSpeed = baseSpeed + inheritSpeed

    -- Direction: mostly in bullet direction, slightly outward
    -- If no bullet angle provided (e.g., laser), use random outward direction
    local baseAngle = bulletAngle or lume.random(0, math.pi * 2)
    local spreadAngle = baseAngle + lume.random(-0.3, 0.3)
    local vx = math.cos(spreadAngle) * totalSpeed
    local vy = math.sin(spreadAngle) * totalSpeed

    -- Return part data (will be used to create FlyingPart in main.lua)
    return {
        x = cx,
        y = cy,
        length = length,
        vx = vx,
        vy = vy,
        rotation = math.atan2(ny, nx) + math.pi/2,  -- Align with original orientation
        color = self.color,
    }
end

function Enemy:takeDamage(amount, angle, impactData)
    if self.dead then return false, {}, false end

    -- Extract impact data
    local impactVelocity = PROJECTILE_SPEED
    local bulletX, bulletY = self.x, self.y
    local prevX, prevY = bulletX, bulletY

    if impactData then
        impactVelocity = impactData.velocity or PROJECTILE_SPEED
        bulletX = impactData.bulletX or self.x
        bulletY = impactData.bulletY or self.y
        prevX = impactData.prevX or bulletX
        prevY = impactData.prevY or bulletY
    end

    -- Find impact point using ray detection (for visual effects and proximity)
    local hitSide, hitX, hitY, isGapHit = self:findHitSideByRay(bulletX, bulletY, prevX, prevY)

    -- If no ray intersection found, fall back to direction-based detection
    if not hitSide and not isGapHit then
        local _
        _, hitX, hitY, isGapHit = self:findHitSideByDirection(bulletX, bulletY, angle or 0)
    end

    -- Apply damage bonus for gap hits
    local finalDamage = amount
    if isGapHit then
        finalDamage = amount * GAP_DAMAGE_BONUS
        self.coreFlashTimer = CORE_FLASH_DURATION
    end

    -- Calculate HP thresholds to determine how many parts to break
    -- Each integer HP above 1 corresponds to a part
    -- HP thresholds: maxHp, maxHp-1, ..., 2 (HP=1 is the core with no part)
    local oldHp = self.hp
    local newHp = oldHp - finalDamage

    -- Count how many HP thresholds we cross (each integer above 1)
    local partsToBreak = 0
    local thresholdStart = math.floor(oldHp)
    local thresholdEnd = math.max(1, math.ceil(newHp))

    for threshold = thresholdStart, thresholdEnd + 1, -1 do
        if threshold > 1 and threshold > newHp and threshold <= oldHp then
            partsToBreak = partsToBreak + 1
        end
    end

    -- Apply damage to HP
    self.hp = newHp

    -- Break the required number of parts, selecting closest to impact point
    local flyingPartsData = {}
    for _ = 1, partsToBreak do
        local closestPart = self:findClosestAlivePart(hitX, hitY)
        if closestPart then
            self.parts[closestPart].flashTimer = PART_FLASH_DURATION
            local partData = self:destroyPart(closestPart, angle, impactVelocity)
            if partData then
                table.insert(flyingPartsData, partData)
            end
        end
    end

    -- Impact stagger: spin increase and displacement when parts break off
    if partsToBreak > 0 then
        -- Add rotation speed (cumulative, keeps sign but increases magnitude)
        local spinIncrease = lume.random(IMPACT_SPIN_INCREASE_MIN, IMPACT_SPIN_INCREASE_MAX) * partsToBreak
        if self.rotationSpeed >= 0 then
            self.rotationSpeed = self.rotationSpeed + spinIncrease
        else
            self.rotationSpeed = self.rotationSpeed - spinIncrease
        end

        -- Perpendicular displacement (left or right of bullet path)
        if angle then
            local perpAngle = angle + (lume.randomchoice({-1, 1}) * math.pi / 2)
            self.x = self.x + math.cos(perpAngle) * IMPACT_DISPLACEMENT * partsToBreak
            self.y = self.y + math.sin(perpAngle) * IMPACT_DISPLACEMENT * partsToBreak
        end
    end

    -- Dynamic knockback based on velocity and damage
    if angle then
        local knockbackForce = self:calculateKnockback(finalDamage, impactVelocity)
        self.knockbackX = math.cos(angle) * knockbackForce
        self.knockbackY = math.sin(angle) * knockbackForce

        -- Green impact burst at hit location
        DebrisManager:spawnImpactBurst(hitX, hitY, angle)
    end

    -- Spawn blood particles (shape-matching)
    if angle then
        local intensity = self:calculateIntensity(finalDamage, impactVelocity)
        DebrisManager:spawnBloodParticles(hitX, hitY, angle, self.shapeName, self.color, intensity)
    end

    -- Trigger feedback (screen shake)
    if finalDamage >= 0.5 then
        Feedback:trigger("small_hit", {
            damage_dealt = finalDamage,
            current_hp = self.hp,
            max_hp = self.maxHp,
            impact_angle = angle,
            impact_x = hitX,
            impact_y = hitY,
        })
    end

    -- Check death condition: HP depleted (core destroyed)
    if self.hp <= 0 then
        local overkill = math.abs(math.min(0, self.hp))
        self:die(angle, {
            velocity = impactVelocity,
            overkillDamage = overkill,
        })
        return true, flyingPartsData, isGapHit
    end

    return false, flyingPartsData, isGapHit
end

function Enemy:die(angle, impactData)
    self.dead = true
    Sounds.playEnemyDeath()

    angle = angle or lume.random(0, math.pi * 2)

    -- Calculate dynamic explosion velocity
    local impactVelocity = PROJECTILE_SPEED
    local overkillDamage = 0
    if impactData then
        impactVelocity = impactData.velocity or PROJECTILE_SPEED
        overkillDamage = impactData.overkillDamage or 0
    end

    local explosionVelocity = self:calculateExplosionVelocity(impactVelocity, overkillDamage)
    DebrisManager:spawnExplosionBurst(self.x, self.y, angle, self.shapeName, self.color, explosionVelocity)
end

function Enemy:checkTowerCollision()
    if self.dead then return false end

    local dx = self.x - tower.x
    local dy = self.y - tower.y
    local dist = math.sqrt(dx * dx + dy * dy)

    local collisionDist = 35 + self.size * self.scale * 0.5

    return dist < collisionDist
end

function Enemy:distanceTo(x, y)
    local dx = self.x - x
    local dy = self.y - y
    return math.sqrt(dx * dx + dy * dy)
end

return Enemy
