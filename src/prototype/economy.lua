-- src/prototype/economy.lua
-- Gold and income system

local Economy = {}
Economy.__index = Economy

function Economy:new()
    local self = setmetatable({}, Economy)

    self.gold = 500           -- Starting gold
    self.income = 10          -- Base income per tick
    self.incomeTimer = 0      -- Time until next income tick
    self.incomeTick = 10.0    -- Seconds between income ticks

    self.lives = 20           -- Lives before game over

    -- Track what's been sent (determines wave composition)
    self.sent = {
        triangle = 0,
        square = 0,
        pentagon = 0,
        hexagon = 0,
    }

    -- Visual feedback
    self.goldFlash = 0
    self.incomeFlash = 0

    return self
end

function Economy:update(dt)
    -- Update income timer
    self.incomeTimer = self.incomeTimer + dt

    if self.incomeTimer >= self.incomeTick then
        self.incomeTimer = self.incomeTimer - self.incomeTick
        self:collectIncome()
    end

    -- Update flashes
    if self.goldFlash > 0 then
        self.goldFlash = self.goldFlash - dt * 5
    end
    if self.incomeFlash > 0 then
        self.incomeFlash = self.incomeFlash - dt * 5
    end
end

function Economy:collectIncome()
    self.gold = self.gold + self.income
    self.goldFlash = 1
end

function Economy:addGold(amount)
    self.gold = self.gold + amount
    self.goldFlash = 1
end

function Economy:spendGold(amount)
    if self.gold >= amount then
        self.gold = self.gold - amount
        return true
    end
    return false
end

function Economy:canAfford(amount)
    return self.gold >= amount
end

function Economy:sendCreep(creepType)
    local Creep = require("src.prototype.creep")
    local stats = Creep.TYPES[creepType]

    if not stats then return false end

    if self:spendGold(stats.sendCost) then
        self.sent[creepType] = self.sent[creepType] + 1
        self.income = self.income + stats.income
        self.incomeFlash = 1
        return true
    end

    return false
end

function Economy:loseLife()
    self.lives = self.lives - 1
    return self.lives <= 0  -- Returns true if game over
end

function Economy:getIncomeProgress()
    return self.incomeTimer / self.incomeTick
end

function Economy:getTotalSent()
    local total = 0
    for _, count in pairs(self.sent) do
        total = total + count
    end
    return total
end

-- Get wave difficulty based on what's been sent
function Economy:getWaveDifficulty()
    local difficulty = 0
    local Creep = require("src.prototype.creep")

    for creepType, count in pairs(self.sent) do
        local stats = Creep.TYPES[creepType]
        if stats then
            difficulty = difficulty + (count * stats.hp)
        end
    end

    return difficulty
end

return Economy
