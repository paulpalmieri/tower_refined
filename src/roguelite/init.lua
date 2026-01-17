-- src/roguelite/init.lua
-- Core roguelite progression system - XP, levels, and upgrades during runs

local UpgradePool = require "src.roguelite.upgrade_pool"

local Roguelite = {
    -- XP and level tracking
    currentXP = 0,
    xpToNextLevel = 0,
    level = 1,

    -- Upgrade tracking
    majorUpgrades = {},     -- List of major upgrade IDs acquired
    minorUpgrades = {},     -- Map of minor upgrade ID -> stack count
    maxMajorUpgrades = 4,   -- Cap on major upgrades per run

    -- Runtime stat multipliers (applied on top of skill tree)
    runtimeStats = {
        damageMult = 1.0,
        fireRateMult = 1.0,
        projectileSpeedMult = 1.0,
        pickupRadiusMult = 1.0,
        -- Major ability stats
        shieldCharges = 0,
        siloCount = 0,
        droneCount = 0,
        auraEnabled = false,
        auraDamageMult = 1.0,
        auraRadiusMult = 1.0,
    },

    -- Level-up state
    levelUpPending = false,
    pendingChoices = {},    -- 5 upgrade options to choose from
    selectedIndex = 1,      -- Currently highlighted choice (1-5)
}

-- Calculate XP required for a specific level
function Roguelite:getXPForLevel(level)
    -- Formula: base * 1.5^(level-1)
    return math.floor(XP_BASE_REQUIREMENT * math.pow(XP_SCALING_FACTOR, level - 1))
end

-- Check if a level is a major upgrade level
function Roguelite:isMajorLevel(level)
    for _, majorLevel in ipairs(MAJOR_UPGRADE_LEVELS) do
        if level == majorLevel then
            return true
        end
    end
    return false
end

-- Reset all roguelite state for a new run
function Roguelite:reset()
    self.currentXP = 0
    self.level = 1
    self.xpToNextLevel = self:getXPForLevel(2)

    self.majorUpgrades = {}
    self.minorUpgrades = {}

    self.runtimeStats = {
        damageMult = 1.0,
        fireRateMult = 1.0,
        projectileSpeedMult = 1.0,
        pickupRadiusMult = 1.0,
        shieldCharges = 0,
        siloCount = 0,
        droneCount = 0,
        auraEnabled = false,
        auraDamageMult = 1.0,
        auraRadiusMult = 1.0,
    }

    self.levelUpPending = false
    self.pendingChoices = {}
    self.selectedIndex = 1
end

-- Add XP and check for level up
-- Returns true if level up triggered
function Roguelite:addXP(amount)
    self.currentXP = self.currentXP + amount

    -- Check for level up
    if self.currentXP >= self.xpToNextLevel then
        self.currentXP = self.currentXP - self.xpToNextLevel
        self.level = self.level + 1
        self.xpToNextLevel = self:getXPForLevel(self.level + 1)

        -- Generate upgrade choices and pause game
        self:triggerLevelUp()
        return true
    end

    return false
end

-- Trigger the level-up selection screen
function Roguelite:triggerLevelUp()
    self.levelUpPending = true
    self.selectedIndex = 1
    self.pendingChoices = self:generateUpgradeChoices()
end

-- Generate 5 upgrade choices based on current state
function Roguelite:generateUpgradeChoices()
    local choices = {}
    local isMajor = self:isMajorLevel(self.level)
    local canPickMajor = #self.majorUpgrades < self.maxMajorUpgrades

    -- If it's a major level and we can still pick majors, offer majors
    -- Otherwise, offer minors
    local pool
    if isMajor and canPickMajor then
        pool = UpgradePool:getAvailableMajors(self.majorUpgrades)
    else
        pool = UpgradePool:getAvailableMinors(self.majorUpgrades, self.minorUpgrades)
    end

    -- Shuffle and pick up to 5
    local shuffled = {}
    for _, upgrade in ipairs(pool) do
        table.insert(shuffled, upgrade)
    end

    -- Fisher-Yates shuffle
    for i = #shuffled, 2, -1 do
        local j = math.random(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    -- Take up to LEVELUP_CHOICES
    for i = 1, math.min(LEVELUP_CHOICES, #shuffled) do
        table.insert(choices, shuffled[i])
    end

    -- If we don't have enough options, pad with reroll/skip options
    while #choices < LEVELUP_CHOICES do
        table.insert(choices, {
            id = "skip",
            name = "Skip",
            description = "Skip this upgrade",
            icon = "skip",
            isMajor = false,
        })
    end

    return choices
end

-- Select an upgrade by index (1-5)
function Roguelite:selectUpgrade(index)
    if not self.levelUpPending then return end
    if index < 1 or index > #self.pendingChoices then return end

    local upgrade = self.pendingChoices[index]

    if upgrade.id ~= "skip" then
        self:applyUpgrade(upgrade)
    end

    -- Clear level-up state
    self.levelUpPending = false
    self.pendingChoices = {}
    self.selectedIndex = 1
end

-- Apply an upgrade's effects
function Roguelite:applyUpgrade(upgrade)
    if upgrade.isMajor then
        -- Track major upgrade
        table.insert(self.majorUpgrades, upgrade.id)

        -- Apply major upgrade effect
        if upgrade.id == "shield" then
            self.runtimeStats.shieldCharges = 2
        elseif upgrade.id == "missile_silo" then
            self.runtimeStats.siloCount = 1
        elseif upgrade.id == "xp_drone" then
            self.runtimeStats.droneCount = 1
        elseif upgrade.id == "damage_aura" then
            self.runtimeStats.auraEnabled = true
        end
    else
        -- Track minor upgrade stack count
        if not self.minorUpgrades[upgrade.id] then
            self.minorUpgrades[upgrade.id] = 0
        end
        self.minorUpgrades[upgrade.id] = self.minorUpgrades[upgrade.id] + 1

        -- Apply minor upgrade effect
        if upgrade.id == "fire_rate_up" then
            self.runtimeStats.fireRateMult = self.runtimeStats.fireRateMult * 1.15
        elseif upgrade.id == "damage_up" then
            self.runtimeStats.damageMult = self.runtimeStats.damageMult * 1.20
        elseif upgrade.id == "projectile_speed_up" then
            self.runtimeStats.projectileSpeedMult = self.runtimeStats.projectileSpeedMult * 1.15
        elseif upgrade.id == "pickup_radius_up" then
            self.runtimeStats.pickupRadiusMult = self.runtimeStats.pickupRadiusMult * 1.25
        elseif upgrade.id == "shield_charge" then
            self.runtimeStats.shieldCharges = self.runtimeStats.shieldCharges + 1
        elseif upgrade.id == "missile_count" then
            self.runtimeStats.siloCount = self.runtimeStats.siloCount + 1
        elseif upgrade.id == "drone_count" then
            self.runtimeStats.droneCount = self.runtimeStats.droneCount + 1
        elseif upgrade.id == "aura_damage" then
            self.runtimeStats.auraDamageMult = self.runtimeStats.auraDamageMult * 1.25
        elseif upgrade.id == "aura_radius" then
            self.runtimeStats.auraRadiusMult = self.runtimeStats.auraRadiusMult * 1.20
        end
    end
end

-- Check if a major upgrade has been acquired
function Roguelite:hasMajorUpgrade(upgradeId)
    for _, id in ipairs(self.majorUpgrades) do
        if id == upgradeId then
            return true
        end
    end
    return false
end

-- Get XP progress as a ratio (0-1)
function Roguelite:getXPProgress()
    if self.xpToNextLevel <= 0 then return 1 end
    return self.currentXP / self.xpToNextLevel
end

-- Move selection left/right in level-up UI
function Roguelite:moveSelection(delta)
    if not self.levelUpPending then return end

    self.selectedIndex = self.selectedIndex + delta
    if self.selectedIndex < 1 then
        self.selectedIndex = #self.pendingChoices
    elseif self.selectedIndex > #self.pendingChoices then
        self.selectedIndex = 1
    end
end

-- Confirm current selection
function Roguelite:confirmSelection()
    if not self.levelUpPending then return end
    self:selectUpgrade(self.selectedIndex)
end

return Roguelite
