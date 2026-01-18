-- src/prototype/wave_manager.lua
-- Spawns enemies based on what player has "sent"

local WaveManager = {}
WaveManager.__index = WaveManager

function WaveManager:new(grid)
    local self = setmetatable({}, WaveManager)

    self.grid = grid
    self.waveNumber = 0
    self.waveTimer = 0
    self.waveDuration = 15.0     -- Seconds between waves
    self.spawnTimer = 0
    self.spawnInterval = 1.0     -- Seconds between spawns within a wave
    self.spawning = false

    -- Current wave composition
    self.waveQueue = {}

    return self
end

function WaveManager:update(dt, economy, creeps)
    self.waveTimer = self.waveTimer + dt

    -- Start new wave
    if self.waveTimer >= self.waveDuration and not self.spawning then
        self:startWave(economy)
    end

    -- Spawn creeps from queue
    if self.spawning then
        self.spawnTimer = self.spawnTimer + dt

        if self.spawnTimer >= self.spawnInterval and #self.waveQueue > 0 then
            self.spawnTimer = 0
            self:spawnNext(creeps)
        end

        if #self.waveQueue == 0 then
            self.spawning = false
        end
    end
end

function WaveManager:startWave(economy)
    self.waveNumber = self.waveNumber + 1
    self.waveTimer = 0
    self.spawnTimer = 0
    self.spawning = true

    -- Build wave based on what's been sent
    self.waveQueue = self:buildWaveQueue(economy)

    -- Adjust spawn interval based on wave size
    local queueSize = #self.waveQueue
    if queueSize > 0 then
        -- Try to spread spawns across ~80% of wave duration
        self.spawnInterval = math.max(0.3, (self.waveDuration * 0.8) / queueSize)
    end
end

function WaveManager:buildWaveQueue(economy)
    local queue = {}
    local Creep = require("src.prototype.creep")

    -- Base wave: always some triangles
    local baseTriangles = 3 + self.waveNumber

    for _ = 1, baseTriangles do
        table.insert(queue, "triangle")
    end

    -- Add creeps based on what's been sent
    -- More you've sent = more you face

    -- Triangles: 1 per 2 sent
    local extraTriangles = math.floor(economy.sent.triangle / 2)
    for _ = 1, extraTriangles do
        table.insert(queue, "triangle")
    end

    -- Squares: 1 per 3 sent
    local squares = math.floor(economy.sent.square / 3) + (economy.sent.square > 0 and 1 or 0)
    for _ = 1, squares do
        table.insert(queue, "square")
    end

    -- Pentagons: 1 per 4 sent
    local pentagons = math.floor(economy.sent.pentagon / 4) + (economy.sent.pentagon > 0 and 1 or 0)
    for _ = 1, pentagons do
        table.insert(queue, "pentagon")
    end

    -- Hexagons: 1 per 5 sent
    local hexagons = math.floor(economy.sent.hexagon / 5) + (economy.sent.hexagon > 0 and 1 or 0)
    for _ = 1, hexagons do
        table.insert(queue, "hexagon")
    end

    -- Shuffle the queue for variety
    for i = #queue, 2, -1 do
        local j = math.random(i)
        queue[i], queue[j] = queue[j], queue[i]
    end

    return queue
end

function WaveManager:spawnNext(creeps)
    if #self.waveQueue == 0 then return end

    local creepType = table.remove(self.waveQueue, 1)
    local Creep = require("src.prototype.creep")

    -- Random spawn point along top
    local spawnPoints = self.grid:getSpawnPoints()
    local spawnPoint = spawnPoints[math.random(#spawnPoints)]

    local creep = Creep(spawnPoint.x, spawnPoint.y, creepType)
    table.insert(creeps, creep)
end

function WaveManager:getWaveProgress()
    return self.waveTimer / self.waveDuration
end

function WaveManager:getTimeUntilWave()
    return math.max(0, self.waveDuration - self.waveTimer)
end

function WaveManager:getQueuePreview()
    -- Return count of each type in queue
    local preview = {
        triangle = 0,
        square = 0,
        pentagon = 0,
        hexagon = 0,
    }

    for _, creepType in ipairs(self.waveQueue) do
        preview[creepType] = preview[creepType] + 1
    end

    return preview
end

return WaveManager
