-- src/prototype/pathfinding.lua
-- A* pathfinding for tower defense grid

local Pathfinding = {}

-- Priority queue implementation (min-heap)
local PriorityQueue = {}
PriorityQueue.__index = PriorityQueue

function PriorityQueue:new()
    return setmetatable({heap = {}, size = 0}, PriorityQueue)
end

function PriorityQueue:push(item, priority)
    self.size = self.size + 1
    self.heap[self.size] = {item = item, priority = priority}
    self:bubbleUp(self.size)
end

function PriorityQueue:pop()
    if self.size == 0 then return nil end

    local root = self.heap[1].item
    self.heap[1] = self.heap[self.size]
    self.heap[self.size] = nil
    self.size = self.size - 1

    if self.size > 0 then
        self:bubbleDown(1)
    end

    return root
end

function PriorityQueue:isEmpty()
    return self.size == 0
end

function PriorityQueue:bubbleUp(index)
    while index > 1 do
        local parent = math.floor(index / 2)
        if self.heap[index].priority < self.heap[parent].priority then
            self.heap[index], self.heap[parent] = self.heap[parent], self.heap[index]
            index = parent
        else
            break
        end
    end
end

function PriorityQueue:bubbleDown(index)
    while true do
        local smallest = index
        local left = index * 2
        local right = index * 2 + 1

        if left <= self.size and self.heap[left].priority < self.heap[smallest].priority then
            smallest = left
        end
        if right <= self.size and self.heap[right].priority < self.heap[smallest].priority then
            smallest = right
        end

        if smallest ~= index then
            self.heap[index], self.heap[smallest] = self.heap[smallest], self.heap[index]
            index = smallest
        else
            break
        end
    end
end

-- Heuristic: Manhattan distance
local function heuristic(x1, y1, x2, y2)
    return math.abs(x1 - x2) + math.abs(y1 - y2)
end

-- Get neighbors (4-directional)
local function getNeighbors(grid, x, y)
    local neighbors = {}
    local directions = {
        {0, -1},  -- up
        {0, 1},   -- down
        {-1, 0},  -- left
        {1, 0},   -- right
    }

    for _, dir in ipairs(directions) do
        local nx, ny = x + dir[1], y + dir[2]
        if grid:isWalkable(nx, ny) then
            table.insert(neighbors, {x = nx, y = ny})
        end
    end

    return neighbors
end

-- A* pathfinding
-- Returns a list of {x, y} grid coordinates from start to goal, or nil if no path
function Pathfinding.findPath(grid, startX, startY, goalX, goalY)
    -- Quick check: if goal is not walkable, no path
    if not grid:isWalkable(goalX, goalY) then
        return nil
    end

    local openSet = PriorityQueue:new()
    local cameFrom = {}
    local gScore = {}
    local fScore = {}
    local closedSet = {}

    local startKey = startY .. "," .. startX
    gScore[startKey] = 0
    fScore[startKey] = heuristic(startX, startY, goalX, goalY)

    openSet:push({x = startX, y = startY}, fScore[startKey])

    while not openSet:isEmpty() do
        local current = openSet:pop()
        local currentKey = current.y .. "," .. current.x

        -- Goal reached
        if current.x == goalX and current.y == goalY then
            -- Reconstruct path
            local path = {}
            local node = current
            while node do
                table.insert(path, 1, {x = node.x, y = node.y})
                local nodeKey = node.y .. "," .. node.x
                node = cameFrom[nodeKey]
            end
            return path
        end

        closedSet[currentKey] = true

        local neighbors = getNeighbors(grid, current.x, current.y)
        for _, neighbor in ipairs(neighbors) do
            local neighborKey = neighbor.y .. "," .. neighbor.x

            if not closedSet[neighborKey] then
                local tentativeG = (gScore[currentKey] or math.huge) + 1

                if tentativeG < (gScore[neighborKey] or math.huge) then
                    cameFrom[neighborKey] = current
                    gScore[neighborKey] = tentativeG
                    fScore[neighborKey] = tentativeG + heuristic(neighbor.x, neighbor.y, goalX, goalY)

                    openSet:push(neighbor, fScore[neighborKey])
                end
            end
        end
    end

    -- No path found
    return nil
end

-- Find path from any spawn point to base
-- Returns the path and the spawn point used, or nil if no path exists
function Pathfinding.findPathToBase(grid, spawnX, spawnY)
    -- Find path to center of base row
    local baseX = math.floor(grid.cols / 2)
    local baseY = grid.baseRow

    -- Base row is marked as zone 3 (not walkable by default in our isWalkable)
    -- We need to find path to the row ABOVE the base
    local targetY = grid.baseRow  -- Actually the base row should be walkable for enemies

    return Pathfinding.findPath(grid, spawnX, spawnY, baseX, targetY)
end

-- Check if any path exists from spawn to base
-- Used to prevent blocking placements
function Pathfinding.hasValidPath(grid)
    -- Check from center of spawn zone
    local spawnX = math.floor(grid.cols / 2)
    local spawnY = grid.spawnRows  -- Bottom of spawn zone

    local path = Pathfinding.findPathToBase(grid, spawnX, spawnY)
    return path ~= nil
end

-- Validate tower placement won't block all paths
function Pathfinding.canPlaceTowerAt(grid, x, y)
    -- First check basic placement rules
    if not grid:canPlaceTower(x, y) then
        return false
    end

    -- Temporarily place tower
    grid.cells[y][x] = 1

    -- Check if path still exists
    local hasPath = Pathfinding.hasValidPath(grid)

    -- Remove temporary tower
    grid.cells[y][x] = 0

    return hasPath
end

-- Get flow field for all cells pointing toward base
-- Returns a table of {dx, dy} directions for each cell
function Pathfinding.computeFlowField(grid)
    local flowField = {}
    local baseX = math.floor(grid.cols / 2)
    local baseY = grid.baseRow

    -- BFS from base to all cells
    local queue = {{x = baseX, y = baseY}}
    local distance = {}
    distance[baseY .. "," .. baseX] = 0

    local directions = {
        {0, -1},  -- up
        {0, 1},   -- down
        {-1, 0},  -- left
        {1, 0},   -- right
    }

    -- BFS to compute distances
    local head = 1
    while head <= #queue do
        local current = queue[head]
        head = head + 1
        local currentKey = current.y .. "," .. current.x
        local currentDist = distance[currentKey]

        for _, dir in ipairs(directions) do
            local nx, ny = current.x + dir[1], current.y + dir[2]
            local neighborKey = ny .. "," .. nx

            if grid:isWalkable(nx, ny) and not distance[neighborKey] then
                distance[neighborKey] = currentDist + 1
                table.insert(queue, {x = nx, y = ny})
            end
        end
    end

    -- Compute flow directions
    for y = 1, grid.rows do
        flowField[y] = {}
        for x = 1, grid.cols do
            local key = y .. "," .. x

            if distance[key] then
                local bestDir = {dx = 0, dy = 0}
                local bestDist = distance[key]

                for _, dir in ipairs(directions) do
                    local nx, ny = x + dir[1], y + dir[2]
                    local neighborKey = ny .. "," .. nx
                    local neighborDist = distance[neighborKey]

                    if neighborDist and neighborDist < bestDist then
                        bestDist = neighborDist
                        bestDir = {dx = dir[1], dy = dir[2]}
                    end
                end

                flowField[y][x] = bestDir
            else
                flowField[y][x] = nil  -- Unreachable
            end
        end
    end

    return flowField
end

return Pathfinding
