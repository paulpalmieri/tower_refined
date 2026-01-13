-- src/monster_spec.lua
-- Table-driven monster definitions
-- Generic system for defining enemy types, parts, and dismemberment thresholds

local MonsterSpec = {}

-- ===================
-- LAYER DEFINITIONS
-- ===================
-- Layer destruction order (lower = destroyed first on damage)
MonsterSpec.LAYER_ORDER = {
    horn = 1,
    leg = 2,
    outer = 3,
    inner = 4,
    eye = 5,
    core = 6,
}

-- ===================
-- COLOR PALETTES
-- ===================
MonsterSpec.palettes = {
    basic = {
        horn = {0.55, 0.15, 0.15},
        hornLight = {0.7, 0.25, 0.2},
        body = {0.85, 0.28, 0.32},
        bodyLight = {0.95, 0.4, 0.42},
        bodyDark = {0.65, 0.18, 0.22},
        bodyInner = {0.75, 0.22, 0.26},
        core = {0.4, 0.08, 0.12},
        eyeWhite = {1.0, 0.95, 0.7},
        eyePupil = {0.15, 0.08, 0.08},
        leg = {0.6, 0.2, 0.22},
        legDark = {0.45, 0.15, 0.18},
        tail = {0.7, 0.2, 0.22},
        tailTip = {0.5, 0.12, 0.15},
    },
    fast = {
        horn = {0.15, 0.45, 0.15},
        hornLight = {0.2, 0.6, 0.25},
        body = {0.28, 0.75, 0.32},
        bodyLight = {0.4, 0.88, 0.45},
        bodyDark = {0.18, 0.55, 0.22},
        bodyInner = {0.22, 0.65, 0.26},
        core = {0.08, 0.35, 0.12},
        eyeWhite = {1.0, 0.95, 0.7},
        eyePupil = {0.08, 0.15, 0.08},
        leg = {0.2, 0.5, 0.22},
        legDark = {0.15, 0.38, 0.18},
        tail = {0.2, 0.6, 0.22},
        tailTip = {0.12, 0.42, 0.15},
    },
    tank = {
        horn = {0.15, 0.15, 0.55},
        hornLight = {0.2, 0.25, 0.7},
        body = {0.28, 0.32, 0.85},
        bodyLight = {0.4, 0.45, 0.95},
        bodyDark = {0.18, 0.22, 0.65},
        bodyInner = {0.22, 0.26, 0.75},
        core = {0.08, 0.12, 0.4},
        eyeWhite = {1.0, 0.95, 0.7},
        eyePupil = {0.08, 0.08, 0.15},
        leg = {0.2, 0.22, 0.6},
        legDark = {0.15, 0.18, 0.45},
        tail = {0.2, 0.22, 0.7},
        tailTip = {0.12, 0.15, 0.5},
    },
}

-- ===================
-- PART DEFINITIONS
-- ===================
-- Maps HP thresholds to which layers should be ejected
-- When HP crosses a threshold, the corresponding layers get forced off
MonsterSpec.parts = {
    -- At 75% HP: horns break off first
    {
        name = "horns",
        threshold = 0.75,
        layers = {"horn"},
        priority = 1,  -- Lower = eject first
    },
    -- At 50% HP: legs break off
    {
        name = "legs",
        threshold = 0.50,
        layers = {"leg"},
        priority = 2,
    },
    -- At 25% HP: outer body chunks
    {
        name = "outer_body",
        threshold = 0.25,
        layers = {"outer"},
        priority = 3,
    },
    -- At 0% (death): everything remaining
    {
        name = "core_remains",
        threshold = 0,
        layers = {"inner", "eye", "core"},
        priority = 4,
    },
}

-- ===================
-- ENEMY TYPE STATS
-- ===================
MonsterSpec.stats = {
    basic = {
        hp = 10,
        speed = 45,
        scale = 1.0,
        animSpeed = 1.0,
    },
    fast = {
        hp = 5,
        speed = 100,
        scale = 0.7,
        animSpeed = 1.5,
    },
    tank = {
        hp = 25,
        speed = 25,
        scale = 1.4,
        animSpeed = 0.7,
    },
}

-- ===================
-- HELPER FUNCTIONS
-- ===================

--- Get the color palette for an enemy type
--- @param enemyType string "basic", "fast", or "tank"
--- @return table Color palette
function MonsterSpec.getPalette(enemyType)
    return MonsterSpec.palettes[enemyType] or MonsterSpec.palettes.basic
end

--- Get the stats for an enemy type
--- @param enemyType string "basic", "fast", or "tank"
--- @return table Stats {hp, speed, scale, animSpeed}
function MonsterSpec.getStats(enemyType)
    return MonsterSpec.stats[enemyType] or MonsterSpec.stats.basic
end

--- Get layer destruction order value
--- @param layerName string Layer name
--- @return number Order value (lower = destroyed first)
function MonsterSpec.getLayerOrder(layerName)
    return MonsterSpec.LAYER_ORDER[layerName] or 3
end

--- Get the part definition for a given HP threshold
--- @param threshold number HP percentage (0.75, 0.50, 0.25, 0)
--- @return table|nil Part definition or nil
function MonsterSpec.getPartForThreshold(threshold)
    for _, part in ipairs(MonsterSpec.parts) do
        if part.threshold == threshold then
            return part
        end
    end
    return nil
end

--- Check if a layer belongs to a specific part
--- @param layerName string The layer to check
--- @param partName string The part name to check against
--- @return boolean
function MonsterSpec.layerBelongsToPart(layerName, partName)
    for _, part in ipairs(MonsterSpec.parts) do
        if part.name == partName then
            for _, layer in ipairs(part.layers) do
                if layer == layerName then
                    return true
                end
            end
            return false
        end
    end
    return false
end

--- Get all layers for a threshold
--- @param threshold number HP percentage
--- @return table Array of layer names
function MonsterSpec.getLayersForThreshold(threshold)
    local part = MonsterSpec.getPartForThreshold(threshold)
    if part then
        return part.layers
    end
    return {}
end

return MonsterSpec
