-- damagenumber.lua
-- Floating damage numbers

local DamageNumber = Object:extend()

function DamageNumber:new(x, y, amount, textType)
    self.x = x
    self.y = y
    self.amount = amount
    self.textType = textType or "damage"  -- "damage", "crit", or "gold"

    -- Add random horizontal offset
    self.x = self.x + lume.random(-10, 10)

    -- Animation
    self.age = 0
    self.lifetime = DAMAGE_NUMBER_FADE_TIME
    self.dead = false

    -- Rise speed (fast at first, slows down)
    self.vy = -DAMAGE_NUMBER_RISE_SPEED

    -- Scale pop effect
    self.scale = 1.5
end

function DamageNumber:update(dt)
    self.age = self.age + dt

    if self.age >= self.lifetime then
        self.dead = true
        return
    end

    -- Rise and slow down
    self.y = self.y + self.vy * dt
    self.vy = self.vy * 0.95

    -- Scale settles to 1.0
    self.scale = 1.0 + 0.5 * math.max(0, 1 - self.age * 10)
end

function DamageNumber:draw()
    local alpha = 1 - (self.age / self.lifetime)
    alpha = alpha * alpha  -- Ease out

    local color = {1, 1, 1}  -- Default white for damage
    local text = tostring(self.amount)

    if self.textType == "crit" then
        color = {1, 0.8, 0.2}    -- Yellow for crit/nuke
    elseif self.textType == "gold" then
        color = {1, 0.85, 0.2}   -- Gold color
        text = "+" .. self.amount
    elseif self.textType == "polygon" then
        color = POLYGON_COLOR    -- Purple
        text = "+P" .. self.amount
    end

    love.graphics.setColor(color[1], color[2], color[3], alpha)

    -- Draw with scale
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.scale(self.scale, self.scale)
    love.graphics.print(text, -textWidth / 2, -textHeight / 2)
    love.graphics.pop()
end

return DamageNumber
