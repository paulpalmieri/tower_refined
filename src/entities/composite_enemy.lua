-- composite_enemy.lua
-- Composite enemies with child shapes attached to their sides

local CompositeEnemy = Object:extend()

-- Get shape order (number of sides) for validation
local function getShapeOrder(shapeName)
    local shape = ENEMY_SHAPES[shapeName]
    return shape and #shape or 0
end

function CompositeEnemy:new(x, y, template, depth, parent, parentSide)
    self.x = x
    self.y = y
    self.depth = depth or 0
    self.parent = parent
    self.parentSide = parentSide

    -- Parse template data
    local shapeName = template.core or template.shape or "triangle"
    local shape = ENEMY_SHAPES[shapeName]

    self.shapeName = shapeName
    self.numParts = #shape
    self.hp = self.numParts
    self.maxHp = self.numParts

    -- Size calculation based on depth
    self.baseSize = template.baseSize or 14
    if depth > 0 then
        self.baseSize = self.baseSize * math.pow(COMPOSITE_SIZE_RATIO, depth)
    end
    self.scale = template.scale or 1.0
    self.size = self.baseSize

    -- Color is always determined by shape (consistent across all composites)
    self.color = SHAPE_COLORS[shapeName] or {1, 0, 0}

    -- Speed (reduced per depth layer)
    local baseSpeed = template.speed or 45
    self.speed = baseSpeed * math.pow(COMPOSITE_SPEED_PENALTY, depth)
    self.speed = self.speed * lume.random(1 - SPEED_VARIATION, 1 + SPEED_VARIATION)

    -- Parts system (same as regular enemy)
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
    self.hitFlashTimer = 0  -- Full-body flash on any hit
    self.knockbackX = 0
    self.knockbackY = 0
    self.rotation = 0
    self.rotationSpeed = lume.random(-1, 1)

    -- World transform (updated from parent chain)
    self.worldX = x
    self.worldY = y
    self.worldRotation = 0

    -- Children attached to sides
    self.children = {}

    -- Create children from template
    -- Rule: Only lower-order shapes can attach to higher-order shapes
    local parentOrder = getShapeOrder(shapeName)
    if template.children and depth < COMPOSITE_MAX_DEPTH then
        for _, childDef in ipairs(template.children) do
            local childOrder = getShapeOrder(childDef.shape)
            -- Skip invalid children (same or higher order than parent)
            if childOrder < parentOrder then
                local childTemplate = {
                    shape = childDef.shape,
                    -- Color is determined by shape, not inherited
                    baseSize = self.baseSize,
                    scale = self.scale,
                    speed = baseSpeed,
                    children = childDef.children,
                }
                local child = CompositeEnemy(0, 0, childTemplate, depth + 1, self, childDef.side)
                self.children[childDef.side] = child
            end
        end
    end
end

-- Update world position from parent chain
function CompositeEnemy:updateWorldTransform()
    if self.parent then
        -- Get parent's side info for our attachment point
        local cx, cy, nx, ny = self.parent:getSideInfo(self.parentSide)

        -- Position at center of parent's side, offset outward
        local offset = self.size * self.scale * COMPOSITE_CHILD_OFFSET
        self.worldX = cx + nx * offset
        self.worldY = cy + ny * offset

        -- Rotation faces outward from parent
        self.worldRotation = math.atan2(ny, nx) + math.pi / 2
    else
        -- Root node uses local position
        self.worldX = self.x
        self.worldY = self.y
        self.worldRotation = self.rotation
    end

    -- Update all children recursively
    for _, child in pairs(self.children) do
        if not child.dead then
            child:updateWorldTransform()
        end
    end
end

function CompositeEnemy:update(dt)
    if self.dead then return end

    -- Only root node moves toward tower
    if not self.parent then
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

        -- Update hit flash timer
        if self.hitFlashTimer > 0 then
            self.hitFlashTimer = self.hitFlashTimer - dt
        end

        -- Apply knockback
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

        -- Update world transforms for entire hierarchy
        self:updateWorldTransform()
    else
        -- Child nodes: update flash timers only
        for i = 1, self.numParts do
            if self.parts[i].flashTimer > 0 then
                self.parts[i].flashTimer = self.parts[i].flashTimer - dt
            end
        end
        if self.coreFlashTimer > 0 then
            self.coreFlashTimer = self.coreFlashTimer - dt
        end
        if self.hitFlashTimer > 0 then
            self.hitFlashTimer = self.hitFlashTimer - dt
        end
    end

    -- Update children recursively
    for _, child in pairs(self.children) do
        if not child.dead then
            child:update(dt)
        end
    end
end

-- ===================
-- GEOMETRY HELPERS
-- ===================

function CompositeEnemy:getSideVertices(sideIndex)
    local shape = ENEMY_SHAPES[self.shapeName]
    local radius = self.size * self.scale

    local v1Idx = sideIndex
    local v2Idx = (sideIndex % #shape) + 1

    local v1 = shape[v1Idx]
    local v2 = shape[v2Idx]

    -- Use world transform
    local cos_r = math.cos(self.worldRotation)
    local sin_r = math.sin(self.worldRotation)

    local x1 = self.worldX + (v1[1] * cos_r - v1[2] * sin_r) * radius
    local y1 = self.worldY + (v1[1] * sin_r + v1[2] * cos_r) * radius
    local x2 = self.worldX + (v2[1] * cos_r - v2[2] * sin_r) * radius
    local y2 = self.worldY + (v2[1] * sin_r + v2[2] * cos_r) * radius

    return x1, y1, x2, y2
end

function CompositeEnemy:getSideInfo(sideIndex)
    local x1, y1, x2, y2 = self:getSideVertices(sideIndex)

    local cx = (x1 + x2) / 2
    local cy = (y1 + y2) / 2
    local length = math.sqrt((x2-x1)^2 + (y2-y1)^2)

    local dx = x2 - x1
    local dy = y2 - y1
    local nx = -dy / length
    local ny = dx / length

    -- Check if it points away from center
    local toCenterX = self.worldX - cx
    local toCenterY = self.worldY - cy
    if nx * toCenterX + ny * toCenterY > 0 then
        nx, ny = -nx, -ny
    end

    return cx, cy, nx, ny, length
end

-- Calculate torque impulse based on hit position relative to center
-- Physics: torque = r x v (2D cross product)
function CompositeEnemy:calculateTorqueImpulse(hitX, hitY, bulletVx, bulletVy, impactVelocity)
    -- Vector from enemy center to hit point (use world coordinates)
    local rx = hitX - self.worldX
    local ry = hitY - self.worldY

    -- 2D cross product gives torque direction and magnitude
    local torque = rx * bulletVy - ry * bulletVx

    -- Scale by velocity ratio
    local velocityRatio = impactVelocity / PROJECTILE_SPEED

    -- Moment of inertia based on size (larger = more resistant)
    local effectiveSize = self.size * self.scale
    local momentOfInertia = 1 + (effectiveSize * TORQUE_SIZE_FACTOR)

    return torque * TORQUE_BASE_SCALE * velocityRatio / momentOfInertia
end

-- ===================
-- DRAWING
-- ===================

function CompositeEnemy:draw()
    if self.dead then return end

    -- Draw this node's shape
    self:drawSelf()

    -- Draw all children on top
    for _, child in pairs(self.children) do
        if not child.dead then
            child:draw()
        end
    end
end

function CompositeEnemy:drawSelf()
    local shape = ENEMY_SHAPES[self.shapeName]
    local radius = self.size * self.scale
    local coreRadius = radius * 0.92

    -- Compute full-body hit flash intensity (0 to 1)
    local hitFlash = 0
    if self.hitFlashTimer > 0 then
        hitFlash = self.hitFlashTimer / HIT_FLASH_DURATION
    end

    -- Build vertices using world transform
    local verts = {}
    for _, v in ipairs(shape) do
        local rx = v[1] * math.cos(self.worldRotation) - v[2] * math.sin(self.worldRotation)
        local ry = v[1] * math.sin(self.worldRotation) + v[2] * math.cos(self.worldRotation)
        table.insert(verts, self.worldX + rx * radius)
        table.insert(verts, self.worldY + ry * radius)
    end

    local coreVerts = {}
    for _, v in ipairs(shape) do
        local rx = v[1] * math.cos(self.worldRotation) - v[2] * math.sin(self.worldRotation)
        local ry = v[1] * math.sin(self.worldRotation) + v[2] * math.cos(self.worldRotation)
        table.insert(coreVerts, self.worldX + rx * coreRadius)
        table.insert(coreVerts, self.worldY + ry * coreRadius)
    end

    local baseColor = self.color

    -- Apply hit flash to base color (lerp toward white)
    local drawColor = baseColor
    if hitFlash > 0 then
        drawColor = {
            lume.lerp(baseColor[1], 1, hitFlash),
            lume.lerp(baseColor[2], 1, hitFlash),
            lume.lerp(baseColor[3], 1, hitFlash),
        }
    end

    -- Outer glow
    love.graphics.setColor(drawColor[1], drawColor[2], drawColor[3], 0.15 + hitFlash * 0.3)
    love.graphics.setLineWidth(8)
    love.graphics.polygon("line", verts)

    -- Mid glow
    love.graphics.setColor(drawColor[1], drawColor[2], drawColor[3], 0.25 + hitFlash * 0.3)
    love.graphics.setLineWidth(4)
    love.graphics.polygon("line", verts)

    -- Dark fill (core) - flash white when hit through gap OR full-body hit
    local coreColor = drawColor
    if self.coreFlashTimer > 0 then
        local flashIntensity = self.coreFlashTimer / CORE_FLASH_DURATION
        coreColor = {
            lume.lerp(drawColor[1], 1, flashIntensity),
            lume.lerp(drawColor[2], 1, flashIntensity),
            lume.lerp(drawColor[3], 1, flashIntensity),
        }
    end
    -- Core fill brightness increases during hit flash
    local coreBrightness = 0.15 + hitFlash * 0.4
    love.graphics.setColor(coreColor[1] * coreBrightness, coreColor[2] * coreBrightness, coreColor[3] * coreBrightness, 0.9)
    love.graphics.polygon("fill", coreVerts)

    -- Thick border for alive sides
    love.graphics.setLineWidth(3)
    for i = 1, self.numParts do
        local part = self.parts[i]
        if part.alive then
            local x1, y1, x2, y2 = self:getSideVertices(i)

            -- Determine side color (flash red when hit, but override with white during full-body hit flash)
            local sideColor
            if hitFlash > 0 then
                -- Full-body hit flash overrides per-side flash
                sideColor = {
                    lume.lerp(drawColor[1] * 0.7, 1, hitFlash),
                    lume.lerp(drawColor[2] * 0.7, 1, hitFlash),
                    lume.lerp(drawColor[3] * 0.7, 1, hitFlash),
                }
            elseif part.flashTimer > 0 then
                local flashIntensity = part.flashTimer / PART_FLASH_DURATION
                sideColor = {
                    lume.lerp(baseColor[1] * 0.7, 1, flashIntensity),
                    lume.lerp(baseColor[2] * 0.7, 0.3, flashIntensity),
                    lume.lerp(baseColor[3] * 0.7, 0.3, flashIntensity),
                }
            else
                sideColor = {drawColor[1] * 0.7, drawColor[2] * 0.7, drawColor[3] * 0.7}
            end

            love.graphics.setColor(sideColor[1], sideColor[2], sideColor[3], 1)
            love.graphics.line(x1, y1, x2, y2)
        end
    end

    love.graphics.setLineWidth(1)
end

-- ===================
-- COLLISION DETECTION
-- ===================

-- Line segment intersection helper
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

-- Check collision point for this node only
function CompositeEnemy:checkPointCollision(px, py, radius)
    local dx = px - self.worldX
    local dy = py - self.worldY
    local dist = math.sqrt(dx * dx + dy * dy)
    local hitRadius = self.size * self.scale + (radius or 5)
    return dist < hitRadius
end

-- Hierarchical collision: check outermost children first (they act as shields)
-- Returns: hitNode, hitSide, hitX, hitY, isGapHit
function CompositeEnemy:findHitNode(bulletX, bulletY, prevX, prevY)
    if self.dead then return nil end

    -- First check all children (they shield the parent)
    -- Sort children by distance from bullet to check nearest first
    local childrenList = {}
    for side, child in pairs(self.children) do
        if not child.dead then
            table.insert(childrenList, {child = child, side = side})
        end
    end

    -- Sort by distance to bullet
    table.sort(childrenList, function(a, b)
        local distA = math.sqrt((a.child.worldX - bulletX)^2 + (a.child.worldY - bulletY)^2)
        local distB = math.sqrt((b.child.worldX - bulletX)^2 + (b.child.worldY - bulletY)^2)
        return distA < distB
    end)

    -- Check children recursively
    for _, childData in ipairs(childrenList) do
        local hitNode, hitSide, hitX, hitY, isGapHit = childData.child:findHitNode(bulletX, bulletY, prevX, prevY)
        if hitNode then
            return hitNode, hitSide, hitX, hitY, isGapHit
        end
    end

    -- No child hit, check this node
    -- First do a broad-phase check
    if not self:checkPointCollision(bulletX, bulletY, 10) then
        return nil
    end

    -- Ray intersection for precise hit
    local bestSide = nil
    local bestT = math.huge
    local hitX, hitY = bulletX, bulletY

    for i = 1, self.numParts do
        -- Skip sides that have children attached (they're shielded)
        if not self.children[i] or self.children[i].dead then
            local x1, y1, x2, y2 = self:getSideVertices(i)
            local ix, iy, t = lineIntersect(prevX, prevY, bulletX, bulletY, x1, y1, x2, y2)

            if ix and t < bestT then
                bestT = t
                bestSide = i
                hitX, hitY = ix, iy
            end
        end
    end

    if bestSide then
        if self.parts[bestSide].alive then
            return self, bestSide, hitX, hitY, false
        else
            return self, nil, hitX, hitY, true  -- Gap hit
        end
    end

    return nil
end

-- ===================
-- DAMAGE SYSTEM
-- ===================

function CompositeEnemy:destroyPart(sideIndex, bulletAngle, bulletVelocity)
    if not self.parts[sideIndex] or not self.parts[sideIndex].alive then
        return nil
    end

    self.parts[sideIndex].alive = false
    self.alivePartCount = self.alivePartCount - 1

    local cx, cy, nx, ny, length = self:getSideInfo(sideIndex)

    local baseSpeed = PART_FLY_SPEED
    local inheritSpeed = (bulletVelocity or PROJECTILE_SPEED) * PART_FLY_SPEED_INHERIT
    local totalSpeed = baseSpeed + inheritSpeed

    local baseAngle = bulletAngle or lume.random(0, math.pi * 2)
    local spreadAngle = baseAngle + lume.random(-0.3, 0.3)
    local vx = math.cos(spreadAngle) * totalSpeed
    local vy = math.sin(spreadAngle) * totalSpeed

    return {
        x = cx,
        y = cy,
        length = length,
        vx = vx,
        vy = vy,
        rotation = math.atan2(ny, nx) + math.pi/2,
        color = self.color,
    }
end

function CompositeEnemy:findClosestAlivePart(hitX, hitY)
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

-- Take damage on this specific node
function CompositeEnemy:takeDamageOnNode(amount, angle, impactData)
    if self.dead then return false, {}, false, {} end

    local impactVelocity = PROJECTILE_SPEED
    local hitX, hitY = self.worldX, self.worldY

    if impactData then
        impactVelocity = impactData.velocity or PROJECTILE_SPEED
        hitX = impactData.bulletX or self.worldX
        hitY = impactData.bulletY or self.worldY
    end
    local isGapHit = impactData and impactData.isGapHit or false

    if isGapHit then
        self.coreFlashTimer = CORE_FLASH_DURATION
    end

    -- Apply damage
    local finalDamage = amount
    if isGapHit then
        finalDamage = amount * GAP_DAMAGE_BONUS
    end

    local oldHp = self.hp
    local newHp = oldHp - finalDamage

    -- Count parts to break
    local partsToBreak = 0
    local thresholdStart = math.floor(oldHp)
    local thresholdEnd = math.max(1, math.ceil(newHp))

    for threshold = thresholdStart, thresholdEnd + 1, -1 do
        if threshold > 1 and threshold > newHp and threshold <= oldHp then
            partsToBreak = partsToBreak + 1
        end
    end

    self.hp = newHp

    -- Trigger full-body hit flash
    self.hitFlashTimer = HIT_FLASH_DURATION

    -- Break parts
    local flyingPartsData = {}
    local detachedChildren = {}

    for _ = 1, partsToBreak do
        local closestPart = self:findClosestAlivePart(hitX, hitY)
        if closestPart then
            self.parts[closestPart].flashTimer = PART_FLASH_DURATION
            local partData = self:destroyPart(closestPart, angle, impactVelocity)
            if partData then
                table.insert(flyingPartsData, partData)
            end
            -- Note: Children on destroyed sides stay attached until core dies
        end
    end

    -- Apply knockback and torque to the ROOT node (whole composite moves/rotates together)
    if angle then
        local root = self:getRoot()
        local knockbackForce = 800 * (finalDamage / self.maxHp)
        root.knockbackX = root.knockbackX + math.cos(angle) * knockbackForce
        root.knockbackY = root.knockbackY + math.sin(angle) * knockbackForce

        -- Apply physics-based torque to root (so entire composite rotates)
        local bulletVx = math.cos(angle) * impactVelocity
        local bulletVy = math.sin(angle) * impactVelocity
        local torqueImpulse = self:calculateTorqueImpulse(hitX, hitY, bulletVx, bulletVy, impactVelocity)
        root.rotationSpeed = root.rotationSpeed + torqueImpulse

        -- Clamp rotation speed to prevent infinite spin
        root.rotationSpeed = lume.clamp(root.rotationSpeed, -TORQUE_MAX_ROTATION_SPEED, TORQUE_MAX_ROTATION_SPEED)

        -- Green impact burst at hit location
        DebrisManager:spawnImpactBurst(hitX, hitY, angle)

        -- Spawn blood particles (shape-matching)
        local velocityRatio = impactVelocity / PROJECTILE_SPEED
        local damageRatio = finalDamage / PROJECTILE_DAMAGE
        local intensity = IMPACT_BASE_INTENSITY
            + (velocityRatio - 1) * IMPACT_VELOCITY_SCALE
            + (damageRatio - 1) * IMPACT_DAMAGE_SCALE
        intensity = math.max(0.2, math.min(intensity, IMPACT_MAX_INTENSITY))
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

    -- Check death
    if self.hp <= 0 then
        -- Only detach children if THIS is the root (core) node
        -- If a child node dies, it just dies - no detaching
        if not self.parent then
            -- Core died: detach all remaining children as independent enemies
            -- Push them outward from core like an explosion
            for side, child in pairs(self.children) do
                if not child.dead then
                    child:detach(self.worldX, self.worldY)
                    table.insert(detachedChildren, child)
                    self.children[side] = nil
                end
            end
        end

        self:die(angle, impactData)
        return true, flyingPartsData, isGapHit, detachedChildren
    end

    return false, flyingPartsData, isGapHit, detachedChildren
end

-- Get the root node of this composite hierarchy
function CompositeEnemy:getRoot()
    if self.parent then
        return self.parent:getRoot()
    end
    return self
end

-- Detach this node from parent and become independent enemy
-- coreX, coreY: position of the exploding core to push away from
function CompositeEnemy:detach(coreX, coreY)
    if not self.parent then return end

    -- Copy world position to local position
    self.x = self.worldX
    self.y = self.worldY
    self.rotation = self.worldRotation

    -- Push outward from core position (like explosion)
    local dx = self.worldX - (coreX or self.worldX)
    local dy = self.worldY - (coreY or self.worldY)
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 0.1 then
        -- Normalize and apply outward force
        local outwardAngle = math.atan2(dy, dx)
        -- Add slight random spread to the outward direction
        outwardAngle = outwardAngle + lume.random(-0.3, 0.3)
        self.knockbackX = math.cos(outwardAngle) * COMPOSITE_DETACH_SCATTER
        self.knockbackY = math.sin(outwardAngle) * COMPOSITE_DETACH_SCATTER
    else
        -- Fallback to random if too close to core
        local randomAngle = lume.random(0, math.pi * 2)
        self.knockbackX = math.cos(randomAngle) * COMPOSITE_DETACH_SCATTER
        self.knockbackY = math.sin(randomAngle) * COMPOSITE_DETACH_SCATTER
    end

    -- Apply rotation spin (random direction, consistent magnitude)
    local spinDirection = lume.random() > 0.5 and 1 or -1
    self.rotationSpeed = spinDirection * COMPOSITE_DETACH_SPIN

    -- Clear parent reference
    self.parent = nil
    self.parentSide = nil
end

function CompositeEnemy:die(angle, impactData)
    self.dead = true
    Sounds.playEnemyDeath()

    angle = angle or lume.random(0, math.pi * 2)

    local impactVelocity = PROJECTILE_SPEED
    local overkillDamage = 0
    if impactData then
        impactVelocity = impactData.velocity or PROJECTILE_SPEED
        overkillDamage = impactData.overkillDamage or 0
    end

    local explosionVelocity = EXPLOSION_BASE_VELOCITY
        + (impactVelocity - PROJECTILE_SPEED) * EXPLOSION_VELOCITY_INHERIT
        + math.min(0.5, overkillDamage / self.maxHp) * 50

    explosionVelocity = math.min(math.max(EXPLOSION_BASE_VELOCITY, explosionVelocity), EXPLOSION_MAX_VELOCITY)
    DebrisManager:spawnExplosionBurst(self.worldX, self.worldY, angle, self.shapeName, self.color, explosionVelocity)
end

-- ===================
-- TOWER COLLISION
-- ===================

function CompositeEnemy:checkTowerCollision()
    if self.dead then return false end

    -- Check root node collision
    local dx = self.worldX - tower.x
    local dy = self.worldY - tower.y
    local dist = math.sqrt(dx * dx + dy * dy)
    local collisionDist = 23 + self.size * self.scale * 0.5

    if dist < collisionDist then
        return true
    end

    -- Check children
    for _, child in pairs(self.children) do
        if not child.dead and child:checkTowerCollision() then
            return true
        end
    end

    return false
end

function CompositeEnemy:distanceTo(x, y)
    local dx = self.worldX - x
    local dy = self.worldY - y
    return math.sqrt(dx * dx + dy * dy)
end

-- Get all children that should be detached (for collecting after death)
function CompositeEnemy:collectAllChildren()
    local allChildren = {}
    for side, child in pairs(self.children) do
        if not child.dead then
            table.insert(allChildren, child)
            -- Recursively collect grandchildren
            local grandchildren = child:collectAllChildren()
            for _, gc in ipairs(grandchildren) do
                table.insert(allChildren, gc)
            end
        end
    end
    return allChildren
end

return CompositeEnemy
