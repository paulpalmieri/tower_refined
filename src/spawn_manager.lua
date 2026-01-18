-- spawn_manager.lua
-- Handles enemy spawning logic and wave progression

local SpawnManager = {
    spawnAccumulator = 0,
    currentSpawnRate = 0,
    gameTime = 0,
}

-- Initialize the spawn manager
function SpawnManager:init()
    self:reset()
end

-- Reset spawn state (call at start of each run)
function SpawnManager:reset()
    self.spawnAccumulator = 0
    self.currentSpawnRate = SPAWN_RATE
    self.gameTime = 0
end

-- Get a random spawn position from screen edges
function SpawnManager:getEdgeSpawnPosition()
    local left, top, right, bottom = Camera:getBounds()
    local margin = 100  -- Spawn margin outside visible area

    -- Pick random edge (0=top, 1=right, 2=bottom, 3=left)
    local edge = math.random(0, 3)
    local x, y

    if edge == 0 then  -- Top
        x = lume.random(left - margin, right + margin)
        y = top - margin
    elseif edge == 1 then  -- Right
        x = right + margin
        y = lume.random(top - margin, bottom + margin)
    elseif edge == 2 then  -- Bottom
        x = lume.random(left - margin, right + margin)
        y = bottom + margin
    else  -- Left
        x = left - margin
        y = lume.random(top - margin, bottom + margin)
    end

    return x, y
end

-- Spawn a regular enemy
function SpawnManager:spawnEnemy()
    local x, y = self:getEdgeSpawnPosition()

    -- Determine enemy type - all types available from start
    local enemyType = "basic"
    local roll = lume.random()

    -- Fixed spawn weights: 40% basic, 25% fast, 18% tank, 12% brute, 5% elite
    if roll < 0.05 then
        enemyType = "elite"
    elseif roll < 0.17 then
        enemyType = "brute"
    elseif roll < 0.35 then
        enemyType = "tank"
    elseif roll < 0.60 then
        enemyType = "fast"
    end

    local enemy = Enemy(x, y, 1.0, enemyType)
    table.insert(enemies, enemy)
    return enemy
end

-- Spawn a composite enemy from a template
function SpawnManager:spawnCompositeEnemy(templateName)
    local template = COMPOSITE_TEMPLATES[templateName]
    if not template then return nil end

    local x, y = self:getEdgeSpawnPosition()
    local composite = CompositeEnemy(x, y, template, 0)
    table.insert(compositeEnemies, composite)
    return composite
end

-- Spawn a random composite enemy based on game time
function SpawnManager:spawnRandomComposite()
    -- Available templates weighted by difficulty
    local templates = {"half_shielded_square", "shielded_square"}

    -- Add harder templates as game progresses
    if self.gameTime > 45 then
        table.insert(templates, "shielded_pentagon")
    end
    if self.gameTime > 90 then
        table.insert(templates, "half_shielded_hexagon")
    end
    if self.gameTime > 150 then
        table.insert(templates, "shielded_hexagon")
    end

    local templateName = templates[math.random(#templates)]
    return self:spawnCompositeEnemy(templateName)
end

-- Update spawn system and spawn enemies as needed
-- Returns: number of enemies spawned this frame
function SpawnManager:update(gameDt)
    self.gameTime = self.gameTime + gameDt
    self.currentSpawnRate = SPAWN_RATE + (self.gameTime * SPAWN_RATE_INCREASE)

    local totalEnemyCount = #enemies + #compositeEnemies
    self.spawnAccumulator = self.spawnAccumulator + gameDt * self.currentSpawnRate

    local spawned = 0
    while self.spawnAccumulator >= 1 and totalEnemyCount < MAX_ENEMIES do
        self.spawnAccumulator = self.spawnAccumulator - 1

        -- 15% chance to spawn composite (after 10 seconds), otherwise regular enemy
        if self.gameTime > 10 and lume.random() < 0.15 then
            self:spawnRandomComposite()
        else
            self:spawnEnemy()
        end

        totalEnemyCount = totalEnemyCount + 1
        spawned = spawned + 1
    end

    return spawned
end

-- Get current game time
function SpawnManager:getGameTime()
    return self.gameTime
end

-- Get current spawn rate
function SpawnManager:getSpawnRate()
    return self.currentSpawnRate
end

return SpawnManager
