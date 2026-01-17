-- missile.lua
-- Homing missile fired from silos, targets random enemies

local Missile = Object:extend()

function Missile:new(x, y)
    self.x = x
    self.y = y
    self.angle = -math.pi / 2  -- Start facing up
    self.speed = MISSILE_SPEED
    self.damage = MISSILE_DAMAGE
    self.dead = false

    -- Velocity (will be updated by homing)
    self.vx = math.cos(self.angle) * self.speed
    self.vy = math.sin(self.angle) * self.speed

    -- Homing target (assigned by main.lua)
    self.target = nil

    -- Previous position for collision
    self.prevX = x
    self.prevY = y

    -- Trail for visual effect
    self.trail = {}
    self.trailLength = MISSILE_TRAIL_LENGTH

    -- Pulse animation
    self.pulse = 0
end

function Missile:update(dt)
    -- Store position for trail
    table.insert(self.trail, 1, {x = self.x, y = self.y})
    if #self.trail > self.trailLength then
        table.remove(self.trail)
    end

    -- Store previous position for collision
    self.prevX = self.x
    self.prevY = self.y

    -- Homing behavior
    if self.target and not self.target.dead then
        local targetAngle = math.atan2(self.target.y - self.y, self.target.x - self.x)

        -- Calculate angle difference
        local angleDiff = targetAngle - self.angle
        while angleDiff > math.pi do angleDiff = angleDiff - 2 * math.pi end
        while angleDiff < -math.pi do angleDiff = angleDiff + 2 * math.pi end

        -- Smooth turn towards target
        local turnAmount = MISSILE_TURN_RATE * dt
        if math.abs(angleDiff) < turnAmount then
            self.angle = targetAngle
        elseif angleDiff > 0 then
            self.angle = self.angle + turnAmount
        else
            self.angle = self.angle - turnAmount
        end

        -- Normalize angle
        while self.angle > math.pi do self.angle = self.angle - 2 * math.pi end
        while self.angle < -math.pi do self.angle = self.angle + 2 * math.pi end
    end

    -- Update velocity based on current angle
    self.vx = math.cos(self.angle) * self.speed
    self.vy = math.sin(self.angle) * self.speed

    -- Move
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Pulse animation
    self.pulse = self.pulse + dt * 12

    -- Check bounds (generous margin for homing)
    local left, top, right, bottom = Camera:getBounds()
    local margin = 100
    if self.x < left - margin or self.x > right + margin or
       self.y < top - margin or self.y > bottom + margin then
        self.dead = true
    end
end

function Missile:draw()
    local width = 12   -- Scaled ~0.67x
    local height = 4   -- Scaled ~0.67x

    -- ===================
    -- 1. DRAW SEGMENTED FADING TRAIL (matches main bullet style)
    -- ===================
    if #self.trail >= 2 then
        local prevX, prevY = self.x, self.y
        for i, pos in ipairs(self.trail) do
            local alpha = (1 - i / #self.trail) * 0.5
            local lineWidth = (1 - i / #self.trail) * 4 + 1
            love.graphics.setColor(MISSILE_COLOR[1], MISSILE_COLOR[2], MISSILE_COLOR[3], alpha)
            love.graphics.setLineWidth(lineWidth)
            love.graphics.line(prevX, prevY, pos.x, pos.y)
            prevX, prevY = pos.x, pos.y
        end
        love.graphics.setLineWidth(1)
    end

    -- ===================
    -- 2. DRAW RECTANGULAR MISSILE (matches main bullet proportions)
    -- ===================
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle)

    -- Rectangular glow layers (bloom will soften these)
    love.graphics.setColor(MISSILE_COLOR[1], MISSILE_COLOR[2], MISSILE_COLOR[3], 0.15)
    love.graphics.rectangle("fill", -width/2 - 6, -height/2 - 4, width + 12, height + 8)
    love.graphics.setColor(MISSILE_COLOR[1], MISSILE_COLOR[2], MISSILE_COLOR[3], 0.3)
    love.graphics.rectangle("fill", -width/2 - 3, -height/2 - 2, width + 6, height + 4)

    -- Solid core
    love.graphics.setColor(MISSILE_CORE_COLOR[1], MISSILE_CORE_COLOR[2], MISSILE_CORE_COLOR[3], 1)
    love.graphics.rectangle("fill", -width/2, -height/2, width, height)

    love.graphics.pop()
end

function Missile:checkCollision(enemy)
    if enemy.dead then return false end

    local dx = self.x - enemy.x
    local dy = self.y - enemy.y
    local dist = math.sqrt(dx * dx + dy * dy)

    local hitRadius = enemy.size * enemy.scale + MISSILE_SIZE
    return dist < hitRadius
end

return Missile
