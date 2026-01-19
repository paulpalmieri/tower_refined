-- src/prototype/creep.lua
-- Enemy creep that follows pathfinding flow field

local Object = require("lib.classic")

local Creep = Object:extend()

-- Creep types (these are what you "send" to increase income)
Creep.TYPES = {
    triangle = {
        name = "Triangle",
        sides = 3,
        hp = 30,
        speed = 60,
        reward = 5,       -- gold on kill
        income = 5,       -- income per tick when sent
        sendCost = 50,    -- cost to send
        color = {1.0, 0.3, 0.3},
        size = 12,
    },
    square = {
        name = "Square",
        sides = 4,
        hp = 60,
        speed = 50,
        reward = 10,
        income = 15,
        sendCost = 150,
        color = {0.3, 0.8, 1.0},
        size = 14,
    },
    pentagon = {
        name = "Pentagon",
        sides = 5,
        hp = 120,
        speed = 40,
        reward = 20,
        income = 40,
        sendCost = 400,
        color = {1.0, 1.0, 0.3},
        size = 16,
    },
    hexagon = {
        name = "Hexagon",
        sides = 6,
        hp = 250,
        speed = 30,
        reward = 50,
        income = 100,
        sendCost = 1000,
        color = {1.0, 0.5, 0.0},
        size = 20,
    },
}

function Creep:new(x, y, creepType)
    self.x = x
    self.y = y
    self.creepType = creepType or "triangle"

    local stats = Creep.TYPES[self.creepType]
    self.name = stats.name
    self.sides = stats.sides
    self.maxHp = stats.hp
    self.hp = self.maxHp
    self.speed = stats.speed
    self.reward = stats.reward
    self.color = stats.color
    self.size = stats.size
    self.radius = stats.size

    self.dead = false
    self.reachedBase = false

    -- Movement
    self.vx = 0
    self.vy = 0
    self.rotation = 0
    self.rotationSpeed = 1 + math.random() * 2

    -- Visual feedback
    self.flashTime = 0
    self.scale = 1
end

function Creep:update(dt, grid, flowField)
    if self.dead then return end

    -- Update flash
    if self.flashTime > 0 then
        self.flashTime = self.flashTime - dt
    end

    -- Get current grid position
    local gridX, gridY = grid:screenToGrid(self.x, self.y)

    -- Check if reached base
    if grid:isInBaseZone(gridX, gridY) then
        self.reachedBase = true
        self.dead = true
        return
    end

    -- Get flow direction
    local flow = nil
    if flowField and flowField[gridY] then
        flow = flowField[gridY][gridX]
    end

    if flow and (flow.dx ~= 0 or flow.dy ~= 0) then
        -- Move toward flow direction (cell center biased)
        local targetX, targetY = grid:gridToScreen(gridX + flow.dx, gridY + flow.dy)

        local dx = targetX - self.x
        local dy = targetY - self.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist > 0 then
            self.vx = (dx / dist) * self.speed
            self.vy = (dy / dist) * self.speed
        end
    else
        -- No flow, move straight down as fallback
        self.vx = 0
        self.vy = self.speed
    end

    -- Apply movement
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Rotate for visual flair
    self.rotation = self.rotation + self.rotationSpeed * dt
end

function Creep:takeDamage(amount)
    self.hp = self.hp - amount
    self.flashTime = 0.1
    self.scale = 1.2  -- Pop effect

    if self.hp <= 0 then
        self.dead = true
    end
end

function Creep:draw()
    if self.dead then return end

    -- Update scale (spring back)
    if self.scale > 1 then
        self.scale = self.scale - (self.scale - 1) * 0.2
        if self.scale < 1.01 then self.scale = 1 end
    end

    local size = self.size * self.scale

    -- Build polygon vertices
    local vertices = {}
    for i = 1, self.sides do
        local angle = self.rotation + (i - 1) * (2 * math.pi / self.sides) - math.pi / 2
        table.insert(vertices, self.x + math.cos(angle) * size)
        table.insert(vertices, self.y + math.sin(angle) * size)
    end

    -- Draw glow
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.3)
    love.graphics.circle("fill", self.x, self.y, size * 1.5)

    -- Draw shape
    if self.flashTime > 0 then
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(self.color)
    end

    if #vertices >= 6 then
        love.graphics.polygon("fill", vertices)
    end

    -- Draw outline
    love.graphics.setColor(self.color[1] * 0.5, self.color[2] * 0.5, self.color[3] * 0.5)
    love.graphics.setLineWidth(2)
    if #vertices >= 6 then
        love.graphics.polygon("line", vertices)
    end

    -- Health bar
    if self.hp < self.maxHp then
        local barWidth = size * 2
        local barHeight = 4
        local barX = self.x - barWidth / 2
        local barY = self.y - size - 8

        -- Background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

        -- Health
        local healthRatio = self.hp / self.maxHp
        love.graphics.setColor(1 - healthRatio, healthRatio, 0)
        love.graphics.rectangle("fill", barX, barY, barWidth * healthRatio, barHeight)
    end
end

return Creep
