-- aoe_warning.lua
-- Telegraphed danger zone for pentagon AoE attack

local AoEWarning = Object:extend()

function AoEWarning:new(x, y, radius, warningTime, damage)
    self.x = x
    self.y = y
    self.radius = radius or PENTAGON_AOE_RADIUS
    self.warningTime = warningTime or PENTAGON_TELEGRAPH_TIME
    self.damage = damage or PENTAGON_AOE_DAMAGE
    self.timer = 0
    self.dead = false
    self.triggered = false

    -- Visual
    self.pulseTimer = 0
    self.color = {1.0, 1.0, 0.0}  -- Yellow (pentagon color)
end

function AoEWarning:update(dt)
    self.timer = self.timer + dt
    self.pulseTimer = self.pulseTimer + dt * 8  -- Faster pulse as time runs out

    -- Check if warning period is over
    if self.timer >= self.warningTime then
        self.triggered = true
        self.dead = true
        return self.damage  -- Return damage to be applied
    end

    return nil
end

function AoEWarning:draw()
    local progress = self.timer / self.warningTime
    local pulse = math.sin(self.pulseTimer * (1 + progress * 2)) * 0.5 + 0.5

    -- Pentagon shape for the warning zone
    local verts = {}
    for i = 0, 4 do
        local angle = (i / 5) * math.pi * 2 - math.pi / 2
        table.insert(verts, self.x + math.cos(angle) * self.radius)
        table.insert(verts, self.y + math.sin(angle) * self.radius)
    end

    -- Outer pulse ring (expanding)
    local outerRadius = self.radius * (1 + pulse * 0.15)
    local outerVerts = {}
    for i = 0, 4 do
        local angle = (i / 5) * math.pi * 2 - math.pi / 2
        table.insert(outerVerts, self.x + math.cos(angle) * outerRadius)
        table.insert(outerVerts, self.y + math.sin(angle) * outerRadius)
    end

    -- Faint outer glow
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.15 * pulse)
    love.graphics.polygon("fill", outerVerts)

    -- Fill that grows with progress (danger zone filling up)
    local fillRadius = self.radius * progress
    local fillVerts = {}
    for i = 0, 4 do
        local angle = (i / 5) * math.pi * 2 - math.pi / 2
        table.insert(fillVerts, self.x + math.cos(angle) * fillRadius)
        table.insert(fillVerts, self.y + math.sin(angle) * fillRadius)
    end

    -- Danger fill (red-tinted as it fills)
    local redTint = progress * 0.5
    love.graphics.setColor(self.color[1], self.color[2] * (1 - redTint), self.color[3] * (1 - redTint), 0.25 + progress * 0.25)
    if #fillVerts >= 6 then  -- Need at least 3 points for polygon
        love.graphics.polygon("fill", fillVerts)
    end

    -- Warning outline (pulsing)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.6 + pulse * 0.4)
    love.graphics.setLineWidth(2 + progress * 2)
    love.graphics.polygon("line", verts)

    -- Inner fill outline showing fill progress
    if fillRadius > 5 then
        love.graphics.setColor(1, 0.5, 0.0, 0.5 + progress * 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.polygon("line", fillVerts)
    end

    -- Center marker
    love.graphics.setColor(1, 1, 1, 0.5 * pulse)
    love.graphics.circle("fill", self.x, self.y, 3 + pulse * 2)

    love.graphics.setLineWidth(1)
end

function AoEWarning:containsPoint(px, py)
    -- Check if point is within the pentagon radius (simplified as circle)
    local dx = px - self.x
    local dy = py - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    return dist < self.radius
end

return AoEWarning
