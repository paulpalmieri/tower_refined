-- silo.lua
-- Missile silo that orbits the turret and fires homing missiles

local Silo = Object:extend()

-- States: "closed", "opening", "ready", "closing"
-- Animation: hatch splits horizontally in middle, halves slide left/right apart

function Silo:new(parentTurret, orbitIndex, totalSilos)
    self.parent = parentTurret
    self.orbitIndex = orbitIndex or 0

    -- Position on circle around turret
    local spacing = (2 * math.pi) / totalSilos
    self.orbitAngle = orbitIndex * spacing
    self.x = 0
    self.y = 0
    self:updateOrbitPosition()

    -- Hatch animation state
    self.state = "closed"
    self.hatchOpenAmount = 0  -- 0 = closed, 1 = fully open
    self.stateTimer = 0

    -- Firing state
    self.fireTimer = math.random() * SILO_BASE_FIRE_RATE  -- Stagger initial fires
    self.fireRate = SILO_BASE_FIRE_RATE
    self.doubleShot = false  -- From silo_double_fire upgrade

    -- Visual
    self.glowPulse = math.random() * math.pi * 2  -- Randomize starting phase

    self.dead = false
end

function Silo:updateOrbitPosition()
    self.x = self.parent.x + math.cos(self.orbitAngle) * SILO_ORBIT_RADIUS
    self.y = self.parent.y + math.sin(self.orbitAngle) * SILO_ORBIT_RADIUS
end

function Silo:update(dt)
    self:updateOrbitPosition()
    self.glowPulse = self.glowPulse + dt * 3

    -- Fire rate countdown
    if self.fireTimer > 0 then
        self.fireTimer = self.fireTimer - dt
    end

    -- State machine for hatch animation
    if self.state == "closed" then
        -- Ready to fire when timer expires
        if self.fireTimer <= 0 then
            self.state = "opening"
            self.stateTimer = 0
        end
    elseif self.state == "opening" then
        self.stateTimer = self.stateTimer + dt
        self.hatchOpenAmount = math.min(1, self.stateTimer / SILO_HATCH_OPEN_TIME)
        if self.hatchOpenAmount >= 1 then
            self.state = "ready"
            self.stateTimer = 0
        end
    elseif self.state == "ready" then
        self.stateTimer = self.stateTimer + dt
        if self.stateTimer >= SILO_FIRE_DELAY then
            -- Return missile data for main.lua to spawn
            return self:prepareFire()
        end
    elseif self.state == "closing" then
        self.stateTimer = self.stateTimer + dt
        self.hatchOpenAmount = math.max(0, 1 - self.stateTimer / SILO_HATCH_CLOSE_TIME)
        if self.hatchOpenAmount <= 0 then
            self.state = "closed"
            self.stateTimer = 0
        end
    end

    return nil
end

function Silo:prepareFire()
    self.fireTimer = self.fireRate
    self.state = "closing"
    self.stateTimer = 0

    -- Return missile spawn data
    local missileCount = self.doubleShot and 2 or 1
    return {
        x = self.x,
        y = self.y,
        count = missileCount,
    }
end

function Silo:draw()
    local radius = SILO_SIZE / 2

    -- Base circle (the hole)
    love.graphics.setColor(SILO_COLOR[1], SILO_COLOR[2], SILO_COLOR[3], 1)
    love.graphics.circle("fill", self.x, self.y, radius)

    -- Hatch cover (shrinks as it slides below)
    local coverRadius = radius * (1 - self.hatchOpenAmount)
    if coverRadius > 0 then
        love.graphics.setColor(SILO_FILL_COLOR[1], SILO_FILL_COLOR[2], SILO_FILL_COLOR[3], 1)
        love.graphics.circle("fill", self.x, self.y, coverRadius)
    end
end

return Silo
