-- collectible_shard.lua
-- Shootable currency shards dropped on enemy death

local CollectibleShard = Object:extend()

function CollectibleShard:new(params)
    self.x = params.x or 0
    self.y = params.y or 0
    self.size = params.size or 18
    self.shapeName = params.shapeName or "triangle"
    self.value = params.value or 1

    -- Ejection velocity (shard shoots out from enemy)
    self.vx = params.vx or 0
    self.vy = params.vy or 0

    -- Fragment flag (smaller pieces after shattering)
    self.isFragment = params.isFragment or false

    self.color = POLYGON_COLOR
    self.rotation = lume.random(0, math.pi * 2)
    self.rotationSpeed = lume.random(-2, 2)

    -- State: "idle" (shootable), "caught" (attracted to turret)
    self.state = "idle"
    self.catchTime = 0
    self.startX = 0
    self.startY = 0
    self.targetX = CENTER_X
    self.targetY = CENTER_Y

    -- Visual feedback
    self.pulseTimer = lume.random(0, math.pi * 2)
    self.dead = false
    self.lightId = nil

    -- Spawn immunity (prevents immediate hit by projectile that killed enemy)
    self.spawnTime = 0
    self.spawnImmunity = params.isFragment and 0 or 0.15  -- Fragments have no immunity
end

function CollectibleShard:update(dt)
    -- Track spawn time for immunity
    self.spawnTime = self.spawnTime + dt

    -- Always animate rotation and pulse
    self.rotation = self.rotation + self.rotationSpeed * dt
    self.pulseTimer = self.pulseTimer + dt * POLYGON_PULSE_SPEED

    if self.state == "idle" then
        -- Apply ejection velocity with friction
        self.vx = self.vx * (1 - POLYGON_EJECT_FRICTION * dt)
        self.vy = self.vy * (1 - POLYGON_EJECT_FRICTION * dt)
        self.x = self.x + self.vx * dt
        self.y = self.y + self.vy * dt

    elseif self.state == "caught" then
        self.catchTime = self.catchTime + dt

        -- Smoothstep easing for nice acceleration
        local progress = math.min(1, self.catchTime / POLYGON_MAGNET_TIME)
        local eased = progress * progress * (3 - 2 * progress)

        -- Lerp toward turret
        self.x = lume.lerp(self.startX, self.targetX, eased)
        self.y = lume.lerp(self.startY, self.targetY, eased)

        -- Spin faster when attracted
        self.rotationSpeed = self.rotationSpeed + dt * 20

        -- Check if reached turret
        local dist = math.sqrt((self.x - self.targetX)^2 + (self.y - self.targetY)^2)
        if dist < 20 or progress >= 1 then
            self.dead = true
            return self.value  -- Signal collection with value
        end
    end

    return nil  -- No collection this frame
end

function CollectibleShard:draw()
    local pulse = 1 + math.sin(self.pulseTimer) * POLYGON_PULSE_AMOUNT
    local glowIntensity = POLYGON_BASE_GLOW

    -- Build vertices for shape
    local shape = ENEMY_SHAPES[self.shapeName]
    if not shape then return end

    local verts = {}
    for _, v in ipairs(shape) do
        local rx = v[1] * math.cos(self.rotation) - v[2] * math.sin(self.rotation)
        local ry = v[1] * math.sin(self.rotation) + v[2] * math.cos(self.rotation)
        table.insert(verts, self.x + rx * self.size * pulse)
        table.insert(verts, self.y + ry * self.size * pulse)
    end

    -- Outer glow (pulsing)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], glowIntensity * 0.2 * pulse)
    love.graphics.setLineWidth(12)
    love.graphics.polygon("line", verts)

    -- Mid glow
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], glowIntensity * 0.4)
    love.graphics.setLineWidth(6)
    love.graphics.polygon("line", verts)

    -- Inner glow
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], glowIntensity * 0.6)
    love.graphics.setLineWidth(3)
    love.graphics.polygon("line", verts)

    -- Fill (semi-transparent dark purple)
    love.graphics.setColor(self.color[1] * 0.15, self.color[2] * 0.15, self.color[3] * 0.15, 0.8)
    love.graphics.polygon("fill", verts)

    -- Border (bright)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 1)
    love.graphics.setLineWidth(2)
    love.graphics.polygon("line", verts)

    love.graphics.setLineWidth(1)
end

function CollectibleShard:checkProjectileHit(projX, projY)
    -- Can't be hit during spawn immunity
    if self.spawnTime < self.spawnImmunity then
        return false
    end

    -- Circular hit test for projectile collision
    local dist = math.sqrt((projX - self.x)^2 + (projY - self.y)^2)
    return dist < self.size * 1.2
end

function CollectibleShard:shatter(targetX, targetY)
    -- Returns array of 3 fragment shards, each worth 1/3 value
    local fragments = {}
    local fragmentValue = math.ceil(self.value / 3)
    local fragmentSize = self.size * POLYGON_FRAGMENT_SIZE_RATIO

    -- Calculate angle toward turret for spread direction
    local baseAngle = math.atan2(targetY - self.y, targetX - self.x)

    -- Create 3 fragments with spread
    local spreadAngles = {-POLYGON_FRAGMENT_SPREAD, 0, POLYGON_FRAGMENT_SPREAD}

    for _, spreadOffset in ipairs(spreadAngles) do
        local frag = CollectibleShard({
            x = self.x,
            y = self.y,
            size = fragmentSize,
            shapeName = self.shapeName,
            value = fragmentValue,
            isFragment = true,
        })

        -- Set fragment to caught state immediately
        frag.state = "caught"
        frag.startX = self.x
        frag.startY = self.y
        frag.targetX = targetX
        frag.targetY = targetY
        frag.catchTime = 0

        -- Add slight offset to target based on spread angle
        local spreadDist = 30
        frag.targetX = targetX + math.cos(baseAngle + spreadOffset + math.pi) * spreadDist * math.abs(spreadOffset)
        frag.targetY = targetY + math.sin(baseAngle + spreadOffset + math.pi) * spreadDist * math.abs(spreadOffset)

        -- Faster spin for fragments
        frag.rotationSpeed = lume.random(-8, 8)

        table.insert(fragments, frag)
    end

    return fragments
end

function CollectibleShard:catch(targetX, targetY)
    if self.state ~= "idle" then return false end

    self.state = "caught"
    self.catchTime = 0
    self.startX = self.x
    self.startY = self.y
    self.targetX = targetX or CENTER_X
    self.targetY = targetY or CENTER_Y

    return true
end

return CollectibleShard
