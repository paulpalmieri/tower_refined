-- ability_manager.lua
-- Manages ability synchronization and enemy attack processing

local AbilityManager = {}

-- Initialize the manager
function AbilityManager:init()
    -- Nothing to initialize currently
end

-- Sync roguelite abilities mid-run (called when upgrades are selected)
-- This updates tower, drones, silos, shields, and damage aura based on current stats
function AbilityManager:syncRogueliteAbilities(tower, stats, drones, silos, damageAura, Roguelite, Lighting, Drone, Silo, Shield, DamageAura)
    local rs = Roguelite.runtimeStats

    -- Update tower fire rate with roguelite multiplier
    tower.fireRate = TOWER_FIRE_RATE / (stats.fireRate * rs.fireRateMult)
    tower.projectileSpeed = PROJECTILE_SPEED * stats.projectileSpeed * rs.projectileSpeedMult

    -- Sync shield
    if rs.shieldCharges > 0 then
        if not tower.shield then
            tower.shield = Shield(tower)
        end
        tower.shield:setCharges(rs.shieldCharges, rs.shieldCharges)
        tower.shield:setRadius(stats.shieldRadius)
    end

    -- Sync drones
    local currentDroneCount = #drones
    local targetDroneCount = stats.droneCount + rs.droneCount
    local newDrones = {}

    if targetDroneCount > currentDroneCount then
        -- Add new drones
        for i = currentDroneCount + 1, targetDroneCount do
            local drone = Drone(tower, i - 1, targetDroneCount)
            drone.fireRate = DRONE_BASE_FIRE_RATE / stats.droneFireRate

            -- Add drone glow light
            drone.lightId = Lighting:addLight({
                x = drone.x,
                y = drone.y,
                radius = DRONE_LIGHT_RADIUS,
                intensity = DRONE_LIGHT_INTENSITY,
                color = DRONE_COLOR,
                owner = drone,
                pulse = 2,
                pulseAmount = 0.15,
            })

            table.insert(newDrones, drone)
            table.insert(drones, drone)
        end

        -- Reposition existing drones for even spacing
        for i, drone in ipairs(drones) do
            drone.orbitIndex = i - 1
            local spacing = (2 * math.pi) / targetDroneCount
            drone.orbitAngle = (i - 1) * spacing
            drone:updateOrbitPosition()
        end
    end

    -- Sync silos
    local currentSiloCount = #silos
    local targetSiloCount = stats.siloCount + rs.siloCount
    local newSilos = {}

    if targetSiloCount > currentSiloCount then
        -- Add new silos
        for i = currentSiloCount + 1, targetSiloCount do
            local silo = Silo(tower, i - 1, targetSiloCount)
            silo.fireRate = SILO_BASE_FIRE_RATE / stats.siloFireRate
            silo.doubleShot = stats.siloDoubleShot
            table.insert(newSilos, silo)
            table.insert(silos, silo)
        end

        -- Reposition existing silos for even spacing
        for i, silo in ipairs(silos) do
            silo.orbitIndex = i - 1
            local spacing = (2 * math.pi) / targetSiloCount
            silo.orbitAngle = (i - 1) * spacing
            silo:updateOrbitPosition()
        end
    end

    -- Sync damage aura
    local newDamageAura = damageAura
    if rs.auraEnabled and not damageAura then
        newDamageAura = DamageAura(tower)
    end
    if newDamageAura then
        newDamageAura:setStats(rs.auraDamageMult, rs.auraRadiusMult)
    end

    return {
        newDrones = newDrones,
        newSilos = newSilos,
        damageAura = newDamageAura,
    }
end

-- Process enemy attack flags and generate attack data
-- Returns: {projectiles = {}, aoeWarnings = {}, miniHexSpawns = {}}
function AbilityManager:processEnemyAttacks(enemies, tower, EnemyProjectile)
    local results = {
        projectiles = {},
        aoeWarnings = {},
        miniHexSpawns = {},
    }

    for _, enemy in ipairs(enemies) do
        if enemy.dead then goto continue end

        -- Square: Fire projectile at tower
        if enemy.shouldFireProjectile then
            local angle = math.atan2(tower.y - enemy.y, tower.x - enemy.x)
            local proj = EnemyProjectile(enemy.x, enemy.y, angle, SQUARE_PROJECTILE_SPEED, SQUARE_PROJECTILE_DAMAGE, "square_bolt")
            table.insert(results.projectiles, proj)

            -- Muzzle flash effect
            DebrisManager:spawnSquareMuzzleFlash(enemy.x, enemy.y, angle)
        end

        -- Pentagon: Create AoE warning at tower position
        if enemy.shouldCreateTelegraph then
            table.insert(results.aoeWarnings, {
                x = tower.x,
                y = tower.y,
                radius = PENTAGON_AOE_RADIUS,
                duration = PENTAGON_TELEGRAPH_TIME,
                damage = PENTAGON_AOE_DAMAGE,
            })
        end

        -- Hexagon: Spawn mini-hex swarm
        if enemy.shouldSpawnMiniHex then
            for j = 1, HEXAGON_MINI_COUNT do
                local spreadAngle = (j - 1) / HEXAGON_MINI_COUNT * math.pi * 2 + lume.random(-0.3, 0.3)
                local proj = EnemyProjectile(enemy.x, enemy.y, spreadAngle, HEXAGON_MINI_SPEED, HEXAGON_MINI_DAMAGE, "mini_hex")
                proj.target = tower  -- Home toward tower
                table.insert(results.projectiles, proj)
            end

            -- Spawn burst effect
            DebrisManager:spawnMiniHexBurst(enemy.x, enemy.y, enemy.color)
        end

        ::continue::
    end

    return results
end

-- Process damage aura effects
-- Returns: {kills = {}, flyingParts = {}, shardsToSpawn = {}, goldEarned = 0}
function AbilityManager:processDamageAura(damageAura, enemies, stats, gameDt)
    local results = {
        kills = {},
        flyingParts = {},
        shardsToSpawn = {},
        goldEarned = 0,
        damageNumbers = {},
    }

    if not damageAura then return results end

    damageAura:update(gameDt)

    -- Apply damage to enemies in range
    local hits = damageAura:damageEnemiesInRange(enemies)
    for _, hit in ipairs(hits) do
        local enemy = hit.enemy
        local damage = hit.damage

        -- Apply damage
        local killed, flyingPartsData = enemy:takeDamage(damage, nil)

        -- Collect flying parts
        for _, partData in ipairs(flyingPartsData) do
            table.insert(results.flyingParts, partData)
        end

        -- Show damage number
        table.insert(results.damageNumbers, {
            x = enemy.x,
            y = enemy.y - 10,
            amount = math.floor(damage),
        })

        if killed then
            table.insert(results.kills, enemy)
            local goldAmount = math.floor(GOLD_PER_KILL * stats.goldMultiplier)
            results.goldEarned = results.goldEarned + goldAmount

            table.insert(results.damageNumbers, {
                x = enemy.x,
                y = enemy.y - 20,
                amount = goldAmount,
                type = "gold",
            })

            table.insert(results.shardsToSpawn, {
                x = enemy.x,
                y = enemy.y,
                shapeName = enemy.shapeName,
                count = enemy.maxHp,
            })
        end
    end

    return results
end

return AbilityManager
