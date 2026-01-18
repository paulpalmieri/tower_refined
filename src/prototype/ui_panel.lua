-- src/prototype/ui_panel.lua
-- Right-side UI panel for tower/enemy selection

local UIPanel = {}
UIPanel.__index = UIPanel

local Tower = require("src.prototype.tower")
local Creep = require("src.prototype.creep")

function UIPanel:new(x, width, height)
    local self = setmetatable({}, UIPanel)

    self.x = x
    self.width = width
    self.height = height

    self.padding = 15
    self.buttonHeight = 70
    self.buttonSpacing = 10

    -- Tower buttons
    self.towerButtons = {}
    local towerTypes = {"basic", "rapid", "sniper", "splash"}
    local buttonY = 50

    for i, towerType in ipairs(towerTypes) do
        local stats = Tower.TYPES[towerType]
        table.insert(self.towerButtons, {
            type = towerType,
            x = x + self.padding,
            y = buttonY + (i - 1) * (self.buttonHeight + self.buttonSpacing),
            width = width - self.padding * 2,
            height = self.buttonHeight,
            stats = stats,
            hovered = false,
        })
    end

    -- Enemy (send) buttons
    self.enemyButtons = {}
    local enemyTypes = {"triangle", "square", "pentagon", "hexagon"}
    local enemyStartY = height / 2 + 30

    for i, enemyType in ipairs(enemyTypes) do
        local stats = Creep.TYPES[enemyType]
        table.insert(self.enemyButtons, {
            type = enemyType,
            x = x + self.padding,
            y = enemyStartY + (i - 1) * (self.buttonHeight + self.buttonSpacing),
            width = width - self.padding * 2,
            height = self.buttonHeight,
            stats = stats,
            hovered = false,
        })
    end

    self.selectedTower = "basic"
    self.hoveredButton = nil

    return self
end

function UIPanel:update(mouseX, mouseY)
    self.hoveredButton = nil

    -- Check tower buttons
    for _, btn in ipairs(self.towerButtons) do
        btn.hovered = self:isPointInButton(mouseX, mouseY, btn)
        if btn.hovered then
            self.hoveredButton = btn
        end
    end

    -- Check enemy buttons
    for _, btn in ipairs(self.enemyButtons) do
        btn.hovered = self:isPointInButton(mouseX, mouseY, btn)
        if btn.hovered then
            self.hoveredButton = btn
        end
    end
end

function UIPanel:isPointInButton(x, y, btn)
    return x >= btn.x and x <= btn.x + btn.width and
           y >= btn.y and y <= btn.y + btn.height
end

function UIPanel:handleClick(mouseX, mouseY, economy)
    -- Check tower buttons
    for _, btn in ipairs(self.towerButtons) do
        if self:isPointInButton(mouseX, mouseY, btn) then
            self.selectedTower = btn.type
            return {action = "select_tower", type = btn.type}
        end
    end

    -- Check enemy buttons
    for _, btn in ipairs(self.enemyButtons) do
        if self:isPointInButton(mouseX, mouseY, btn) then
            if economy:canAfford(btn.stats.sendCost) then
                return {action = "send_enemy", type = btn.type}
            end
        end
    end

    return nil
end

function UIPanel:draw(economy)
    -- Panel background
    love.graphics.setColor(0.05, 0.05, 0.08)
    love.graphics.rectangle("fill", self.x, 0, self.width, self.height)

    -- Panel border
    love.graphics.setColor(0.0, 0.5, 0.0)
    love.graphics.setLineWidth(2)
    love.graphics.line(self.x, 0, self.x, self.height)

    -- Section: Towers
    love.graphics.setColor(0.0, 0.8, 0.0)
    love.graphics.printf("TOWERS", self.x, 15, self.width, "center")

    for _, btn in ipairs(self.towerButtons) do
        self:drawTowerButton(btn, economy)
    end

    -- Section divider
    local dividerY = self.height / 2
    love.graphics.setColor(0.0, 0.4, 0.0)
    love.graphics.line(self.x + self.padding, dividerY, self.x + self.width - self.padding, dividerY)

    -- Section: Enemies to send
    love.graphics.setColor(0.8, 0.3, 0.3)
    love.graphics.printf("SEND TO VOID", self.x, dividerY + 8, self.width, "center")

    for _, btn in ipairs(self.enemyButtons) do
        self:drawEnemyButton(btn, economy)
    end
end

function UIPanel:drawTowerButton(btn, economy)
    local stats = btn.stats
    local canAfford = economy:canAfford(stats.cost)
    local isSelected = (self.selectedTower == btn.type)

    -- Button background
    if isSelected then
        love.graphics.setColor(0.0, 0.3, 0.0)
    elseif btn.hovered and canAfford then
        love.graphics.setColor(0.1, 0.2, 0.1)
    else
        love.graphics.setColor(0.08, 0.08, 0.1)
    end
    love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 5, 5)

    -- Border
    if isSelected then
        love.graphics.setColor(0.0, 1.0, 0.0)
    elseif canAfford then
        love.graphics.setColor(stats.color)
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
    end
    love.graphics.setLineWidth(isSelected and 3 or 1)
    love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height, 5, 5)

    -- Tower preview circle
    love.graphics.setColor(stats.color)
    love.graphics.circle("fill", btn.x + 30, btn.y + btn.height / 2, 12)

    -- Name and cost
    local textColor = canAfford and {1, 1, 1} or {0.4, 0.4, 0.4}
    love.graphics.setColor(textColor)
    love.graphics.print(stats.name, btn.x + 50, btn.y + 10)

    love.graphics.setColor(1, 0.9, 0.2)
    love.graphics.print(stats.cost .. "g", btn.x + 50, btn.y + 28)

    -- Stats
    love.graphics.setColor(0.6, 0.6, 0.6)
    local statText = string.format("DMG:%d  RNG:%d", stats.damage, stats.range)
    love.graphics.print(statText, btn.x + 50, btn.y + 46)

    -- Hotkey hint
    local index = 0
    for i, b in ipairs(self.towerButtons) do
        if b == btn then index = i break end
    end
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.print("[" .. index .. "]", btn.x + btn.width - 25, btn.y + 10)
end

function UIPanel:drawEnemyButton(btn, economy)
    local stats = btn.stats
    local canAfford = economy:canAfford(stats.sendCost)
    local sentCount = economy.sent[btn.type] or 0

    -- Button background
    if btn.hovered and canAfford then
        love.graphics.setColor(0.2, 0.1, 0.1)
    else
        love.graphics.setColor(0.1, 0.05, 0.05)
    end
    love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 5, 5)

    -- Border
    if canAfford then
        love.graphics.setColor(stats.color)
    else
        love.graphics.setColor(0.3, 0.2, 0.2)
    end
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height, 5, 5)

    -- Shape preview
    self:drawShapePreview(btn.x + 30, btn.y + btn.height / 2, stats.sides, 12, stats.color)

    -- Name and cost
    local textColor = canAfford and {1, 1, 1} or {0.4, 0.4, 0.4}
    love.graphics.setColor(textColor)
    love.graphics.print(stats.name, btn.x + 50, btn.y + 10)

    love.graphics.setColor(1, 0.9, 0.2)
    love.graphics.print(stats.sendCost .. "g", btn.x + 50, btn.y + 28)

    -- Income gain
    love.graphics.setColor(0.3, 1.0, 0.3)
    love.graphics.print("+" .. stats.income .. "/tick", btn.x + 110, btn.y + 28)

    -- Sent count
    if sentCount > 0 then
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Sent: " .. sentCount, btn.x + 50, btn.y + 46)
    end

    -- Hotkey hint
    local keys = {"Q", "W", "E", "R"}
    local index = 0
    for i, b in ipairs(self.enemyButtons) do
        if b == btn then index = i break end
    end
    if index > 0 and index <= #keys then
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.print("[" .. keys[index] .. "]", btn.x + btn.width - 25, btn.y + 10)
    end
end

function UIPanel:drawShapePreview(x, y, sides, size, color)
    local vertices = {}
    for i = 1, sides do
        local angle = (i - 1) * (2 * math.pi / sides) - math.pi / 2
        table.insert(vertices, x + math.cos(angle) * size)
        table.insert(vertices, y + math.sin(angle) * size)
    end

    love.graphics.setColor(color)
    if #vertices >= 6 then
        love.graphics.polygon("fill", vertices)
    end
end

function UIPanel:getSelectedTowerStats()
    return Tower.TYPES[self.selectedTower]
end

return UIPanel
