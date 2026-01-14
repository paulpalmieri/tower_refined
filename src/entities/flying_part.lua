-- flying_part.lua
-- A destroyed enemy side that flies off, settles, then fades over 10 seconds

local FlyingPart = Object:extend()

function FlyingPart:new(params)
    self.x = params.x or 0
    self.y = params.y or 0
    self.length = params.length or 20

    -- Velocity
    self.vx = params.vx or 0
    self.vy = params.vy or 0

    -- Rotation and spin
    self.rotation = params.rotation or 0
    self.spinSpeed = lume.random(PART_SPIN_SPEED_MIN, PART_SPIN_SPEED_MAX)
    if lume.random() > 0.5 then self.spinSpeed = -self.spinSpeed end

    -- Color (from enemy)
    local color = params.color or {1, 0, 0}
    self.color = {color[1], color[2], color[3]}

    -- Settled color (desaturated, darkened)
    local gray = (color[1] + color[2] + color[3]) / 3
    self.settledColor = {
        (color[1] * 0.3 + gray * 0.7) * 0.4,
        (color[2] * 0.3 + gray * 0.7) * 0.4,
        (color[3] * 0.3 + gray * 0.7) * 0.4,
    }

    -- State
    self.settled = false
    self.settleTimer = 0
    self.fadeTimer = 0
    self.alpha = 1.0
    self.dead = false

    -- Line width (matches enemy border)
    self.lineWidth = params.lineWidth or 4
end

function FlyingPart:update(dt)
    if self.dead then return end

    -- Fading phase (after settled and waited)
    if self.settled and self.settleTimer >= PART_SETTLE_TIME then
        self.fadeTimer = self.fadeTimer + dt
        self.alpha = 1.0 - (self.fadeTimer / PART_FADE_DURATION)
        if self.alpha <= 0 then
            self.dead = true
        end
        return
    end

    -- Settling phase (stopped moving, waiting to fade)
    if self.settled then
        self.settleTimer = self.settleTimer + dt
        return
    end

    -- Flying phase
    -- Spin
    self.rotation = self.rotation + self.spinSpeed * dt

    -- Friction
    self.vx = self.vx * (1 - PART_FRICTION * dt)
    self.vy = self.vy * (1 - PART_FRICTION * dt)

    -- Move
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Check if settled
    local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
    if speed < PART_SETTLE_VELOCITY then
        self.settled = true
        self.settleTimer = 0
    end
end

function FlyingPart:draw()
    if self.dead then return end

    -- Choose color based on state
    local color
    local alpha
    if not self.settled then
        color = self.color
        alpha = 1.0
    elseif self.settleTimer < PART_SETTLE_TIME then
        color = self.settledColor
        alpha = 0.7  -- Slightly dimmed while waiting to fade
    else
        color = self.settledColor
        alpha = self.alpha
    end

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)

    -- Draw line segment (the "side")
    local halfLen = self.length / 2

    -- Outer glow (when flying)
    if not self.settled then
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.3)
        love.graphics.setLineWidth(self.lineWidth + 6)
        love.graphics.line(-halfLen, 0, halfLen, 0)
    end

    -- Main line
    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.setLineWidth(self.lineWidth)
    love.graphics.line(-halfLen, 0, halfLen, 0)

    -- Core highlight (when flying)
    if not self.settled then
        love.graphics.setColor(1, 1, 1, alpha * 0.5)
        love.graphics.setLineWidth(self.lineWidth * 0.5)
        love.graphics.line(-halfLen, 0, halfLen, 0)
    end

    love.graphics.setLineWidth(1)
    love.graphics.pop()
end

return FlyingPart
