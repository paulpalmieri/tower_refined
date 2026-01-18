-- main_prototype.lua
-- Void TD Prototype - Entry point
-- Run with: love . --prototype (or rename to main.lua temporarily)

local Grid = require("src.prototype.grid")
local Pathfinding = require("src.prototype.pathfinding")
local Tower = require("src.prototype.tower")
local Creep = require("src.prototype.creep")
local Economy = require("src.prototype.economy")
local WaveManager = require("src.prototype.wave_manager")
local UIPanel = require("src.prototype.ui_panel")

-- Game state
local grid
local economy
local waveManager
local uiPanel
local flowField

-- Entity lists
local towers = {}
local creeps = {}
local projectiles = {}

-- Screen dimensions
local SCREEN_WIDTH = 1600
local SCREEN_HEIGHT = 900

function love.load()
    love.window.setTitle("Void TD - Prototype")
    love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT)

    -- Initialize systems
    grid = Grid:new(SCREEN_WIDTH, SCREEN_HEIGHT)
    economy = Economy:new()
    waveManager = WaveManager:new(grid)

    -- UI Panel on right side
    uiPanel = UIPanel:new(grid.playAreaWidth, grid.panelWidth, SCREEN_HEIGHT)

    -- Initial flow field
    flowField = Pathfinding.computeFlowField(grid)

    -- Set font
    love.graphics.setFont(love.graphics.newFont(14))
end

function love.update(dt)
    -- Cap dt to prevent spiral of death
    dt = math.min(dt, 1/30)

    -- Update economy
    economy:update(dt)

    -- Update wave manager
    waveManager:update(dt, economy, creeps)

    -- Update towers
    for _, tower in ipairs(towers) do
        tower:update(dt, creeps, projectiles)
    end

    -- Update projectiles
    for i = #projectiles, 1, -1 do
        local proj = projectiles[i]
        proj:update(dt, creeps, grid)
        if proj.dead then
            table.remove(projectiles, i)
        end
    end

    -- Update creeps
    for i = #creeps, 1, -1 do
        local creep = creeps[i]
        creep:update(dt, grid, flowField)

        if creep.dead then
            if creep.reachedBase then
                -- Lost a life
                if economy:loseLife() then
                    -- Game over - for now just reset
                    resetGame()
                    return
                end
            else
                -- Killed - get reward
                economy:addGold(creep.reward)
            end
            table.remove(creeps, i)
        end
    end

    -- Update UI
    local mx, my = love.mouse.getPosition()
    uiPanel:update(mx, my)
end

function love.draw()
    -- Draw grid (play area)
    grid:draw()

    -- Draw flow field (debug - comment out for cleaner look)
    -- drawFlowField()

    -- Draw towers
    for _, tower in ipairs(towers) do
        tower:draw()
    end

    -- Draw creeps
    for _, creep in ipairs(creeps) do
        creep:draw()
    end

    -- Draw projectiles
    for _, proj in ipairs(projectiles) do
        proj:draw()
    end

    -- Draw hover preview for tower placement
    local mx, my = love.mouse.getPosition()
    if mx < grid.playAreaWidth then
        local canAfford = economy:canAfford(Tower.TYPES[uiPanel.selectedTower].cost)
        grid:drawHover(mx, my, canAfford)

        -- Draw tower preview
        local gridX, gridY = grid:screenToGrid(mx, my)
        if Pathfinding.canPlaceTowerAt(grid, gridX, gridY) and canAfford then
            local screenX, screenY = grid:gridToScreen(gridX, gridY)
            local stats = Tower.TYPES[uiPanel.selectedTower]

            -- Range preview
            love.graphics.setColor(stats.color[1], stats.color[2], stats.color[3], 0.15)
            love.graphics.circle("fill", screenX, screenY, stats.range)
            love.graphics.setColor(stats.color[1], stats.color[2], stats.color[3], 0.4)
            love.graphics.circle("line", screenX, screenY, stats.range)
        end
    end

    -- Draw UI panel
    uiPanel:draw(economy)

    -- Draw top HUD
    drawHUD()

    -- Draw bottom status bar
    drawStatusBar()
end

function drawHUD()
    local y = grid.gridHeight + 10

    -- Gold
    local goldColor = economy.goldFlash > 0 and {1, 1, 0.5} or {1, 0.9, 0.2}
    love.graphics.setColor(goldColor)
    love.graphics.print("GOLD: " .. math.floor(economy.gold), 20, y)

    -- Income
    local incomeColor = economy.incomeFlash > 0 and {0.5, 1, 0.5} or {0.3, 0.8, 0.3}
    love.graphics.setColor(incomeColor)
    love.graphics.print("+" .. economy.income .. "/tick", 150, y)

    -- Income timer bar
    local barX = 260
    local barWidth = 150
    local barHeight = 16
    local progress = economy:getIncomeProgress()

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", barX, y + 2, barWidth, barHeight)

    love.graphics.setColor(0.3, 0.8, 0.3)
    love.graphics.rectangle("fill", barX, y + 2, barWidth * progress, barHeight)

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("line", barX, y + 2, barWidth, barHeight)

    local timeLeft = math.ceil(economy.incomeTick - economy.incomeTimer)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(timeLeft .. "s", barX, y + 2, barWidth, "center")

    -- Lives
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.print("LIVES: " .. economy.lives, 450, y)

    -- Wave info
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("WAVE: " .. waveManager.waveNumber, 580, y)

    local waveTime = math.ceil(waveManager:getTimeUntilWave())
    love.graphics.print("Next: " .. waveTime .. "s", 680, y)
end

function drawStatusBar()
    local y = grid.gridHeight + 40

    -- Instructions
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Click grid to place tower | 1-4: Select tower | Q-R: Send enemies | ESC: Quit", 20, y)
end

function drawFlowField()
    love.graphics.setColor(0.2, 0.4, 0.2, 0.5)
    for y = 1, grid.rows do
        for x = 1, grid.cols do
            if flowField[y] and flowField[y][x] then
                local flow = flowField[y][x]
                if flow.dx ~= 0 or flow.dy ~= 0 then
                    local screenX, screenY = grid:gridToScreen(x, y)
                    local arrowLen = grid.cellSize * 0.3

                    love.graphics.line(
                        screenX, screenY,
                        screenX + flow.dx * arrowLen,
                        screenY + flow.dy * arrowLen
                    )
                end
            end
        end
    end
end

function love.mousepressed(x, y, button)
    if button ~= 1 then return end

    -- Check UI panel first
    if x >= grid.playAreaWidth then
        local result = uiPanel:handleClick(x, y, economy)
        if result then
            if result.action == "send_enemy" then
                economy:sendCreep(result.type)
            end
        end
        return
    end

    -- Place tower on grid
    local gridX, gridY = grid:screenToGrid(x, y)
    local towerStats = Tower.TYPES[uiPanel.selectedTower]

    if economy:canAfford(towerStats.cost) and Pathfinding.canPlaceTowerAt(grid, gridX, gridY) then
        -- Place tower
        local screenX, screenY = grid:gridToScreen(gridX, gridY)
        local tower = Tower(screenX, screenY, uiPanel.selectedTower, gridX, gridY)

        if grid:placeTower(gridX, gridY, tower) then
            table.insert(towers, tower)
            economy:spendGold(towerStats.cost)

            -- Recompute flow field
            flowField = Pathfinding.computeFlowField(grid)
        end
    end
end

function love.keypressed(key)
    -- Tower selection (1-4)
    local towerKeys = {["1"] = "basic", ["2"] = "rapid", ["3"] = "sniper", ["4"] = "splash"}
    if towerKeys[key] then
        uiPanel.selectedTower = towerKeys[key]
        return
    end

    -- Enemy sending (Q, W, E, R)
    local enemyKeys = {q = "triangle", w = "square", e = "pentagon", r = "hexagon"}
    if enemyKeys[key] then
        economy:sendCreep(enemyKeys[key])
        return
    end

    -- Quit
    if key == "escape" then
        love.event.quit()
    end

    -- Debug: Reset
    if key == "f5" then
        resetGame()
    end
end

function resetGame()
    towers = {}
    creeps = {}
    projectiles = {}

    grid = Grid:new(SCREEN_WIDTH, SCREEN_HEIGHT)
    economy = Economy:new()
    waveManager = WaveManager:new(grid)

    flowField = Pathfinding.computeFlowField(grid)
end

-- Return module for potential require() use
return {
    load = love.load,
    update = love.update,
    draw = love.draw,
    mousepressed = love.mousepressed,
    keypressed = love.keypressed,
}
