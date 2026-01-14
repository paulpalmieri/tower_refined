-- src/skilltree/node.lua
-- SkillNode class for individual skill tree nodes

local Object = require "lib.classic"

local SkillNode = Object:extend()

function SkillNode:new(def)
    self.id = def.id
    self.gridX = def.gridX
    self.gridY = def.gridY
    self.name = def.name
    self.icon = def.icon
    self.maxLevel = def.maxLevel
    self.costs = def.costs or {}
    self.effects = def.effects or {}
    self.connections = def.connections or {}
    self.branch = def.branch
    self.placeholder = def.placeholder or false

    -- Runtime state
    self.currentLevel = 0
    self.hovered = false
    self.selected = false
end

function SkillNode:getWorldPosition(cellSize)
    return self.gridX * cellSize, self.gridY * cellSize
end

function SkillNode:getNextCost()
    if self.currentLevel >= self.maxLevel then
        return nil
    end
    return self.costs[self.currentLevel + 1]
end

function SkillNode:canPurchase(gold, allNodes)
    -- Placeholder nodes can never be purchased
    if self.placeholder then
        return false
    end

    -- Check if already maxed
    if self.currentLevel >= self.maxLevel then
        return false
    end

    -- Check gold
    local cost = self:getNextCost()
    if not cost or gold < cost then
        return false
    end

    -- Check if any connected node is purchased (reachability)
    return self:isReachable(allNodes)
end

function SkillNode:isReachable(allNodes)
    -- Turret is always reachable
    if self.id == "turret" then
        return true
    end

    -- Check if any connected node is purchased
    for _, connId in ipairs(self.connections) do
        local connNode = allNodes[connId]
        if connNode and connNode.currentLevel > 0 then
            return true
        end
    end

    return false
end

function SkillNode:purchase()
    if self.currentLevel < self.maxLevel then
        self.currentLevel = self.currentLevel + 1
        return self.costs[self.currentLevel]
    end
    return 0
end

function SkillNode:getBorderColor(gold, allNodes)
    -- Placeholder nodes are always grey
    if self.placeholder then
        return {0.3, 0.3, 0.3}
    end

    -- Green = purchased (has at least 1 level)
    if self.currentLevel > 0 then
        return NEON_PRIMARY
    end

    -- Grey = unreachable
    if not self:isReachable(allNodes) then
        return {0.3, 0.3, 0.3}
    end

    -- Red = can't afford
    local cost = self:getNextCost()
    if cost and gold < cost then
        return NEON_RED
    end

    -- White = available to purchase
    return {1, 1, 1}
end

function SkillNode:isMaxed()
    return self.currentLevel >= self.maxLevel
end

function SkillNode:getCurrentEffect()
    if self.currentLevel == 0 or not self.effects or not self.effects.values then
        return nil
    end
    return self.effects.values[self.currentLevel]
end

function SkillNode:getNextEffect()
    if self.currentLevel >= self.maxLevel or not self.effects or not self.effects.values then
        return nil
    end
    return self.effects.values[self.currentLevel + 1]
end

return SkillNode
