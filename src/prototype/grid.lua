-- src/prototype/grid.lua
-- Grid system for tower defense prototype

local Grid = {}
Grid.__index = Grid

-- Grid configuration
Grid.CELL_SIZE = 40
Grid.PLAY_AREA_WIDTH_RATIO = 0.70
Grid.PANEL_WIDTH_RATIO = 0.30

function Grid:new(screenWidth, screenHeight)
    local self = setmetatable({}, Grid)

    -- Calculate dimensions
    self.screenWidth = screenWidth
    self.screenHeight = screenHeight
    self.playAreaWidth = math.floor(screenWidth * Grid.PLAY_AREA_WIDTH_RATIO)
    self.panelWidth = screenWidth - self.playAreaWidth

    -- Grid dimensions (leave room for UI at bottom)
    self.uiHeight = 80
    self.gridHeight = screenHeight - self.uiHeight

    -- Calculate grid size
    self.cellSize = Grid.CELL_SIZE
    self.cols = math.floor(self.playAreaWidth / self.cellSize)
    self.rows = math.floor(self.gridHeight / self.cellSize)

    -- Center grid in play area
    self.offsetX = math.floor((self.playAreaWidth - (self.cols * self.cellSize)) / 2)
    self.offsetY = math.floor((self.gridHeight - (self.rows * self.cellSize)) / 2)

    -- Grid state: 0 = empty, 1 = tower, 2 = spawn zone, 3 = base zone
    self.cells = {}
    for y = 1, self.rows do
        self.cells[y] = {}
        for x = 1, self.cols do
            self.cells[y][x] = 0
        end
    end

    -- Define spawn zone (top 2 rows)
    self.spawnRows = 2
    for y = 1, self.spawnRows do
        for x = 1, self.cols do
            self.cells[y][x] = 2  -- spawn zone
        end
    end

    -- Define base zone (bottom row)
    self.baseRow = self.rows
    for x = 1, self.cols do
        self.cells[self.baseRow][x] = 3  -- base zone
    end

    -- Towers placed on grid (for quick lookup)
    self.towers = {}

    -- Path cache (invalidated when towers change)
    self.pathCache = nil
    self.pathValid = false

    return self
end

-- Convert grid coords to screen position (center of cell)
function Grid:gridToScreen(gridX, gridY)
    local screenX = self.offsetX + (gridX - 0.5) * self.cellSize
    local screenY = self.offsetY + (gridY - 0.5) * self.cellSize
    return screenX, screenY
end

-- Convert screen position to grid coords
function Grid:screenToGrid(screenX, screenY)
    local gridX = math.floor((screenX - self.offsetX) / self.cellSize) + 1
    local gridY = math.floor((screenY - self.offsetY) / self.cellSize) + 1
    return gridX, gridY
end

-- Check if grid coords are valid
function Grid:isValidCell(x, y)
    return x >= 1 and x <= self.cols and y >= 1 and y <= self.rows
end

-- Check if a cell is walkable (not a tower)
function Grid:isWalkable(x, y)
    if not self:isValidCell(x, y) then
        return false
    end
    local cell = self.cells[y][x]
    return cell ~= 1  -- 1 = tower
end

-- Check if a cell can have a tower placed
function Grid:canPlaceTower(x, y)
    if not self:isValidCell(x, y) then
        return false
    end
    local cell = self.cells[y][x]
    -- Can't place on existing tower, spawn zone, or base zone
    if cell ~= 0 then
        return false
    end
    return true
end

-- Place a tower at grid position
function Grid:placeTower(x, y, tower)
    if not self:canPlaceTower(x, y) then
        return false
    end

    self.cells[y][x] = 1
    self.towers[y .. "," .. x] = tower
    self.pathValid = false  -- Invalidate path cache

    return true
end

-- Remove a tower from grid position
function Grid:removeTower(x, y)
    if not self:isValidCell(x, y) then
        return false
    end

    if self.cells[y][x] == 1 then
        self.cells[y][x] = 0
        self.towers[y .. "," .. x] = nil
        self.pathValid = false
        return true
    end
    return false
end

-- Get tower at position
function Grid:getTowerAt(x, y)
    return self.towers[y .. "," .. x]
end

-- Get all spawn points (centers of spawn zone cells)
function Grid:getSpawnPoints()
    local points = {}
    for x = 1, self.cols do
        local screenX, screenY = self:gridToScreen(x, 1)
        table.insert(points, {x = screenX, y = screenY, gridX = x, gridY = 1})
    end
    return points
end

-- Get base position (center of base zone)
function Grid:getBasePosition()
    local centerX = math.floor(self.cols / 2)
    return self:gridToScreen(centerX, self.baseRow)
end

-- Check if position is in base zone
function Grid:isInBaseZone(gridX, gridY)
    return gridY >= self.baseRow
end

-- Draw the grid
function Grid:draw()
    -- Draw grid background
    love.graphics.setColor(0.02, 0.02, 0.04)
    love.graphics.rectangle("fill", 0, 0, self.playAreaWidth, self.gridHeight)

    -- Draw cells
    for y = 1, self.rows do
        for x = 1, self.cols do
            local screenX = self.offsetX + (x - 1) * self.cellSize
            local screenY = self.offsetY + (y - 1) * self.cellSize
            local cell = self.cells[y][x]

            -- Cell background based on type
            if cell == 2 then
                -- Spawn zone - dark red tint
                love.graphics.setColor(0.15, 0.02, 0.02)
                love.graphics.rectangle("fill", screenX + 1, screenY + 1,
                    self.cellSize - 2, self.cellSize - 2)
            elseif cell == 3 then
                -- Base zone - dark green tint
                love.graphics.setColor(0.02, 0.15, 0.02)
                love.graphics.rectangle("fill", screenX + 1, screenY + 1,
                    self.cellSize - 2, self.cellSize - 2)
            end
        end
    end

    -- Draw grid lines
    love.graphics.setColor(0.0, 0.25, 0.0, 0.5)
    love.graphics.setLineWidth(1)

    -- Vertical lines
    for x = 0, self.cols do
        local screenX = self.offsetX + x * self.cellSize
        love.graphics.line(screenX, self.offsetY, screenX, self.offsetY + self.rows * self.cellSize)
    end

    -- Horizontal lines
    for y = 0, self.rows do
        local screenY = self.offsetY + y * self.cellSize
        love.graphics.line(self.offsetX, screenY, self.offsetX + self.cols * self.cellSize, screenY)
    end

    -- Draw zone labels
    love.graphics.setColor(0.5, 0.1, 0.1, 0.8)
    love.graphics.printf("VOID", self.offsetX, self.offsetY + 5,
        self.cols * self.cellSize, "center")

    love.graphics.setColor(0.1, 0.5, 0.1, 0.8)
    love.graphics.printf("BASE", self.offsetX,
        self.offsetY + (self.rows - 1) * self.cellSize + 10,
        self.cols * self.cellSize, "center")
end

-- Draw hover highlight for cell under mouse
function Grid:drawHover(mouseX, mouseY, canAfford)
    local gridX, gridY = self:screenToGrid(mouseX, mouseY)

    if self:isValidCell(gridX, gridY) then
        local screenX = self.offsetX + (gridX - 1) * self.cellSize
        local screenY = self.offsetY + (gridY - 1) * self.cellSize

        local canPlace = self:canPlaceTower(gridX, gridY) and canAfford

        if canPlace then
            love.graphics.setColor(0.0, 1.0, 0.0, 0.3)
        else
            love.graphics.setColor(1.0, 0.0, 0.0, 0.3)
        end

        love.graphics.rectangle("fill", screenX + 1, screenY + 1,
            self.cellSize - 2, self.cellSize - 2)

        -- Draw border
        if canPlace then
            love.graphics.setColor(0.0, 1.0, 0.0, 0.8)
        else
            love.graphics.setColor(1.0, 0.0, 0.0, 0.8)
        end
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", screenX + 1, screenY + 1,
            self.cellSize - 2, self.cellSize - 2)
    end
end

return Grid
