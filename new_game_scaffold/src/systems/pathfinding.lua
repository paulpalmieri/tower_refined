-- src/systems/pathfinding.lua
-- A* pathfinding and flow field computation
--
-- Adapted from prototype. See MIGRATION.md.

local Pathfinding = {}

-- TODO: Port from src/prototype/pathfinding.lua
-- Key functions:
--   Pathfinding.findPath(grid, startX, startY, goalX, goalY)
--   Pathfinding.computeFlowField(grid)
--   Pathfinding.canPlaceTowerAt(grid, x, y)

function Pathfinding.computeFlowField(grid)
    -- Placeholder - implement from prototype
    return {}
end

function Pathfinding.canPlaceTowerAt(grid, x, y)
    -- Placeholder - implement from prototype
    return grid.canPlaceTower and grid:canPlaceTower(x, y)
end

return Pathfinding
