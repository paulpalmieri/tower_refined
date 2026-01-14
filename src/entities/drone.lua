-- drone.lua
-- Small purple turret that orbits the main turret and shoots XP shards

local Drone = Object:extend()

-- Purple neon colors (matches collectible shards)
local DRONE_COLOR = {0.70, 0.20, 1.00}    -- Bright purple
local DRONE_FILL = {0.15, 0.04, 0.20}     -- Dark purple fill

-- Dimensions (smaller than main turret)
local BASE_RADIUS = 12
local BARREL_LENGTH = 18
local BARREL_WIDTH = 5
local BARREL_BACK = 5

-- Orbit parameters
local ORBIT_RADIUS = 80
local ORBIT_SPEED = 0.5  -- Radians per second

function Drone:new(parentTurret, orbitIndex, totalDrones)
    self.parent = parentTurret
    self.orbitIndex = orbitIndex or 0

    -- Space drones evenly around orbit
    local spacing = (2 * math.pi) / (totalDrones or 1)
    self.orbitAngle = orbitIndex * spacing

    -- Position (calculated from orbit)
    self.x = 0
    self.y = 0
    self:updateOrbitPosition()

    -- Targeting and firing
    self.angle = -math.pi / 2  -- Start facing up
    self.targetAngle = self.angle
    self.fireTimer = 0
    self.fireRate = DRONE_BASE_FIRE_RATE

    -- Visual feedback
    self.muzzleFlash = 0
    self.gunKick = 0

    -- Lighting
    self.lightId = nil

    self.dead = false
end

function Drone:updateOrbitPosition()
    self.x = self.parent.x + math.cos(self.orbitAngle) * ORBIT_RADIUS
    self.y = self.parent.y + math.sin(self.orbitAngle) * ORBIT_RADIUS
end

function Drone:update(dt, collectibleShards)
    -- Update orbit position
    self.orbitAngle = self.orbitAngle + ORBIT_SPEED * dt
    self:updateOrbitPosition()

    -- Find nearest idle shard to target
    local target = self:findNearestShard(collectibleShards)

    -- Aim at target or maintain current angle
    if target then
        self.targetAngle = math.atan2(target.y - self.y, target.x - self.x)
    end

    -- Smooth rotation (like turret)
    local angleDiff = self.targetAngle - self.angle
    while angleDiff > math.pi do angleDiff = angleDiff - 2 * math.pi end
    while angleDiff < -math.pi do angleDiff = angleDiff + 2 * math.pi end

    local rotateAmount = DRONE_ROTATION_SPEED * dt
    if math.abs(angleDiff) < rotateAmount then
        self.angle = self.targetAngle
    elseif angleDiff > 0 then
        self.angle = self.angle + rotateAmount
    else
        self.angle = self.angle - rotateAmount
    end

    -- Normalize angle
    while self.angle > math.pi do self.angle = self.angle - 2 * math.pi end
    while self.angle < -math.pi do self.angle = self.angle + 2 * math.pi end

    -- Fire timer cooldown
    if self.fireTimer > 0 then
        self.fireTimer = self.fireTimer - dt
    end

    -- Visual feedback decay
    if self.muzzleFlash > 0 then
        self.muzzleFlash = self.muzzleFlash - dt
    end

    if self.gunKick > 0 then
        self.gunKick = self.gunKick - dt * GUN_KICK_DECAY
        if self.gunKick < 0 then self.gunKick = 0 end
    end
end

function Drone:findNearestShard(shards)
    if not shards then return nil end

    local nearest = nil
    local nearestDist = math.huge

    for _, shard in ipairs(shards) do
        if shard.state == "idle" and not shard.dead then
            local dx = shard.x - self.x
            local dy = shard.y - self.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < nearestDist then
                nearest = shard
                nearestDist = dist
            end
        end
    end

    return nearest
end

function Drone:canFire()
    return self.fireTimer <= 0
end

function Drone:fire()
    if not self:canFire() then return nil end

    self.fireTimer = self.fireRate
    self.muzzleFlash = 0.08
    self.gunKick = GUN_KICK_AMOUNT * 0.5  -- Less kick for smaller drone

    -- Calculate muzzle position
    local muzzleX = self.x + math.cos(self.angle) * BARREL_LENGTH
    local muzzleY = self.y + math.sin(self.angle) * BARREL_LENGTH

    -- Create purple projectile
    local proj = Projectile(muzzleX, muzzleY, self.angle, DRONE_PROJECTILE_SPEED, 1)
    proj.isDrone = true  -- Flag for purple rendering

    return proj
end

function Drone:draw()
    -- ===================
    -- 1. CIRCLE BASE
    -- ===================
    -- Base glow
    love.graphics.setColor(DRONE_COLOR[1], DRONE_COLOR[2], DRONE_COLOR[3], 0.15)
    love.graphics.circle("fill", self.x, self.y, BASE_RADIUS + 6)

    -- Base fill
    love.graphics.setColor(DRONE_FILL[1], DRONE_FILL[2], DRONE_FILL[3], 1)
    love.graphics.circle("fill", self.x, self.y, BASE_RADIUS)

    -- Base border
    love.graphics.setColor(DRONE_COLOR[1], DRONE_COLOR[2], DRONE_COLOR[3], 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", self.x, self.y, BASE_RADIUS)
    love.graphics.setLineWidth(1)

    -- ===================
    -- 2. BARREL
    -- ===================
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)

    local kickBack = self.gunKick * 5
    local halfWidth = BARREL_WIDTH / 2

    local barrelStart = -kickBack - BARREL_BACK
    local barrelTotal = BARREL_LENGTH + BARREL_BACK

    -- Barrel glow
    love.graphics.setColor(DRONE_COLOR[1], DRONE_COLOR[2], DRONE_COLOR[3], 0.2)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", barrelStart, -halfWidth - 1, barrelTotal, BARREL_WIDTH + 2)

    -- Barrel fill
    love.graphics.setColor(DRONE_COLOR[1], DRONE_COLOR[2], DRONE_COLOR[3], 1)
    love.graphics.rectangle("fill", barrelStart, -halfWidth, barrelTotal, BARREL_WIDTH)

    -- Barrel border
    love.graphics.setColor(DRONE_COLOR[1], DRONE_COLOR[2], DRONE_COLOR[3], 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", barrelStart, -halfWidth, barrelTotal, BARREL_WIDTH)

    love.graphics.setLineWidth(1)
    love.graphics.pop()
end

function Drone:getMuzzleTip()
    local tipX = self.x + math.cos(self.angle) * BARREL_LENGTH
    local tipY = self.y + math.sin(self.angle) * BARREL_LENGTH
    return tipX, tipY
end

return Drone
