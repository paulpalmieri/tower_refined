-- src/roguelite/upgrade_pool.lua
-- Definitions for all major and minor upgrades

local UpgradePool = {}

-- Major upgrades (one-time abilities, max 4 per run)
UpgradePool.majors = {
    {
        id = "shield",
        name = "Energy Shield",
        description = "Protective barrier with 2 charges",
        icon = "shield",
        isMajor = true,
    },
    {
        id = "missile_silo",
        name = "Missile Silo",
        description = "Deploy 1 homing missile silo",
        icon = "silo",
        isMajor = true,
    },
    {
        id = "xp_drone",
        name = "XP Drone",
        description = "Orbiting drone collects nearby shards",
        icon = "drone",
        isMajor = true,
    },
    {
        id = "damage_aura",
        name = "Damage Aura",
        description = "Static field deals damage every 3s",
        icon = "aura",
        isMajor = true,
    },
}

-- Minor upgrades (stackable stat boosts)
UpgradePool.minors = {
    -- Basic stat upgrades (always available)
    {
        id = "fire_rate_up",
        name = "Rapid Fire",
        description = "+15% fire rate",
        icon = "fire_rate",
        isMajor = false,
        maxStacks = 10,
        prerequisite = nil,
    },
    {
        id = "damage_up",
        name = "Damage Boost",
        description = "+20% damage",
        icon = "damage",
        isMajor = false,
        maxStacks = 10,
        prerequisite = nil,
    },
    {
        id = "projectile_speed_up",
        name = "Velocity",
        description = "+15% bullet speed",
        icon = "projectile_speed",
        isMajor = false,
        maxStacks = 8,
        prerequisite = nil,
    },
    {
        id = "pickup_radius_up",
        name = "Magnetism",
        description = "+25% pickup radius",
        icon = "pickup_radius",
        isMajor = false,
        maxStacks = 6,
        prerequisite = nil,
    },
    -- Conditional upgrades (require specific major)
    {
        id = "shield_charge",
        name = "Shield Cell",
        description = "+1 shield charge",
        icon = "shield",
        isMajor = false,
        maxStacks = 10,
        prerequisite = "shield",
    },
    {
        id = "missile_count",
        name = "Extra Silo",
        description = "+1 missile silo",
        icon = "silo",
        isMajor = false,
        maxStacks = 5,
        prerequisite = "missile_silo",
    },
    {
        id = "drone_count",
        name = "Extra Drone",
        description = "+1 orbiting drone",
        icon = "drone",
        isMajor = false,
        maxStacks = 4,
        prerequisite = "xp_drone",
    },
    {
        id = "aura_damage",
        name = "Aura Intensity",
        description = "+25% aura damage",
        icon = "aura",
        isMajor = false,
        maxStacks = 8,
        prerequisite = "damage_aura",
    },
    {
        id = "aura_radius",
        name = "Aura Range",
        description = "+20% aura radius",
        icon = "aura",
        isMajor = false,
        maxStacks = 6,
        prerequisite = "damage_aura",
    },
}

-- Get available major upgrades (not yet acquired)
function UpgradePool:getAvailableMajors(acquiredMajors)
    local available = {}

    for _, upgrade in ipairs(self.majors) do
        local acquired = false
        for _, id in ipairs(acquiredMajors) do
            if id == upgrade.id then
                acquired = true
                break
            end
        end

        if not acquired then
            table.insert(available, upgrade)
        end
    end

    return available
end

-- Get available minor upgrades (checking prerequisites and max stacks)
function UpgradePool:getAvailableMinors(acquiredMajors, minorStacks)
    local available = {}

    -- Helper to check if a major is acquired
    local function hasMajor(majorId)
        for _, id in ipairs(acquiredMajors) do
            if id == majorId then
                return true
            end
        end
        return false
    end

    for _, upgrade in ipairs(self.minors) do
        local canAdd = true

        -- Check prerequisite
        if upgrade.prerequisite then
            if not hasMajor(upgrade.prerequisite) then
                canAdd = false
            end
        end

        -- Check max stacks
        if canAdd and upgrade.maxStacks then
            local currentStacks = minorStacks[upgrade.id] or 0
            if currentStacks >= upgrade.maxStacks then
                canAdd = false
            end
        end

        if canAdd then
            -- Create a copy with current stack count for display
            local upgradeCopy = {}
            for k, v in pairs(upgrade) do
                upgradeCopy[k] = v
            end
            upgradeCopy.currentStacks = minorStacks[upgrade.id] or 0
            table.insert(available, upgradeCopy)
        end
    end

    return available
end

return UpgradePool
