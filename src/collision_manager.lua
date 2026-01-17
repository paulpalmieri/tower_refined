-- collision_manager.lua
-- Centralized collision detection and handling

local CollisionManager = {}

-- Initialize the manager
function CollisionManager:init()
    -- Nothing to initialize currently
end

-- Process projectile vs regular enemy collisions
-- Returns: {hits = {}, kills = {}, flyingParts = {}, shardsToSpawn = {}, goldEarned = 0}
function CollisionManager:processProjectileVsEnemies(projectiles, enemies, stats)
    local results = {
        hits = {},
        kills = {},
        flyingParts = {},
        shardsToSpawn = {},
        goldEarned = 0,
        damageNumbers = {},
    }

    for i = #projectiles, 1, -1 do
        local proj = projectiles[i]

        -- Track hit enemies to prevent double-hits
        proj.hitEnemies = proj.hitEnemies or {}

        for _, enemy in ipairs(enemies) do
            if proj:checkCollision(enemy) and not enemy.dead and not proj.hitEnemies[enemy] then
                -- Mark as hit
                proj.hitEnemies[enemy] = true

                -- Calculate actual bullet speed for dynamic effects
                local bulletSpeed = math.sqrt(proj.vx * proj.vx + proj.vy * proj.vy)

                -- Pass position data for ray-based side detection
                local killed, flyingPartsData, isGapHit = enemy:takeDamage(proj.damage, proj.angle, {
                    velocity = bulletSpeed,
                    vx = proj.vx,
                    vy = proj.vy,
                    bulletX = proj.x,
                    bulletY = proj.y,
                    prevX = proj.prevX,
                    prevY = proj.prevY,
                })

                -- Collect flying parts
                for _, partData in ipairs(flyingPartsData) do
                    table.insert(results.flyingParts, partData)
                end

                -- Record damage number
                local displayDamage = math.floor(proj.damage * (isGapHit and GAP_DAMAGE_BONUS or 1))
                table.insert(results.damageNumbers, {
                    x = proj.x,
                    y = proj.y - 10,
                    amount = displayDamage,
                    type = isGapHit and "crit" or nil,
                })

                -- Record hit
                table.insert(results.hits, {
                    projectile = proj,
                    enemy = enemy,
                    isGapHit = isGapHit,
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

                -- Only destroy projectile if not piercing
                if not proj.piercing then
                    proj.dead = true
                    break
                end
            end
        end
    end

    return results
end

-- Process projectile vs composite enemy collisions
-- Returns: {hits = {}, kills = {}, flyingParts = {}, shardsToSpawn = {}, goldEarned = 0, detachedChildren = {}}
function CollisionManager:processProjectileVsComposites(projectiles, compositeEnemies, stats)
    local results = {
        hits = {},
        kills = {},
        flyingParts = {},
        shardsToSpawn = {},
        goldEarned = 0,
        damageNumbers = {},
        detachedChildren = {},
    }

    for i = #projectiles, 1, -1 do
        local proj = projectiles[i]
        if proj.dead then goto continue end

        proj.hitComposites = proj.hitComposites or {}

        for _, composite in ipairs(compositeEnemies) do
            if not composite.dead and not proj.hitComposites[composite] then
                -- Find which node gets hit (outermost children first)
                local hitNode, _, hitX, hitY, isGapHit = composite:findHitNode(
                    proj.x, proj.y, proj.prevX, proj.prevY
                )

                if hitNode then
                    proj.hitComposites[composite] = true

                    -- Calculate bullet speed
                    local bulletSpeed = math.sqrt(proj.vx * proj.vx + proj.vy * proj.vy)

                    -- Deal damage to the specific node hit
                    local killed, flyingPartsData, _, detachedChildren = hitNode:takeDamageOnNode(
                        proj.damage, proj.angle, {
                            velocity = bulletSpeed,
                            bulletX = proj.x,
                            bulletY = proj.y,
                            prevX = proj.prevX,
                            prevY = proj.prevY,
                            isGapHit = isGapHit,
                        }
                    )

                    -- Collect flying parts
                    for _, partData in ipairs(flyingPartsData) do
                        table.insert(results.flyingParts, partData)
                    end

                    -- Collect detached children
                    for _, child in ipairs(detachedChildren) do
                        table.insert(results.detachedChildren, child)
                    end

                    -- Record damage number
                    local displayDamage = math.floor(proj.damage * (isGapHit and GAP_DAMAGE_BONUS or 1))
                    table.insert(results.damageNumbers, {
                        x = hitX,
                        y = hitY - 10,
                        amount = displayDamage,
                        type = isGapHit and "crit" or nil,
                    })

                    -- Record hit
                    table.insert(results.hits, {
                        projectile = proj,
                        composite = composite,
                        hitNode = hitNode,
                        isGapHit = isGapHit,
                    })

                    if killed then
                        table.insert(results.kills, hitNode)
                        local goldAmount = math.floor(GOLD_PER_KILL * stats.goldMultiplier)
                        results.goldEarned = results.goldEarned + goldAmount

                        table.insert(results.damageNumbers, {
                            x = hitNode.worldX,
                            y = hitNode.worldY - 20,
                            amount = goldAmount,
                            type = "gold",
                        })

                        table.insert(results.shardsToSpawn, {
                            x = hitNode.worldX,
                            y = hitNode.worldY,
                            shapeName = hitNode.shapeName,
                            count = hitNode.maxHp,
                        })

                        Feedback:trigger("enemy_death")
                    end

                    -- Destroy projectile if not piercing
                    if not proj.piercing then
                        proj.dead = true
                        break
                    end
                end
            end
        end

        ::continue::
    end

    return results
end

-- Process missile vs enemy collisions
-- Returns: {hits = {}, kills = {}, flyingParts = {}, shardsToSpawn = {}, goldEarned = 0}
function CollisionManager:processMissileVsEnemies(missiles, enemies, stats)
    local results = {
        hits = {},
        kills = {},
        flyingParts = {},
        shardsToSpawn = {},
        goldEarned = 0,
        damageNumbers = {},
    }

    for i = #missiles, 1, -1 do
        local missile = missiles[i]

        for _, enemy in ipairs(enemies) do
            if missile:checkCollision(enemy) then
                -- Deal damage
                local killed, flyingPartsData = enemy:takeDamage(missile.damage, missile.angle)

                -- Collect flying parts
                for _, partData in ipairs(flyingPartsData) do
                    table.insert(results.flyingParts, partData)
                end

                -- Spawn explosion
                DebrisManager:spawnMissileExplosion(missile.x, missile.y, missile.angle)

                -- Record damage number
                table.insert(results.damageNumbers, {
                    x = missile.x,
                    y = missile.y - 10,
                    amount = missile.damage,
                })

                -- Record hit
                table.insert(results.hits, {
                    missile = missile,
                    enemy = enemy,
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

                Feedback:trigger("missile_impact")
                missile.dead = true
                break
            end
        end
    end

    return results
end

-- Process drone projectile vs shard collisions
-- Returns: {hits = {}, fragments = {}}
function CollisionManager:processDroneProjectileVsShards(droneProjectiles, collectibleShards, tower)
    local results = {
        hits = {},
        fragments = {},
        shardsToRemove = {},
    }

    for i = #droneProjectiles, 1, -1 do
        local proj = droneProjectiles[i]

        -- Track hit shards
        proj.hitShards = proj.hitShards or {}

        for _, shard in ipairs(collectibleShards) do
            if shard.state == "idle" and not shard.dead and not proj.hitShards[shard] then
                if shard:checkProjectileHit(proj.x, proj.y) then
                    proj.hitShards[shard] = true

                    -- Shatter the shard
                    local fragments = shard:shatter(tower.x, tower.y)
                    for _, frag in ipairs(fragments) do
                        table.insert(results.fragments, frag)
                    end

                    -- Record hit
                    table.insert(results.hits, {
                        projectile = proj,
                        shard = shard,
                    })

                    table.insert(results.shardsToRemove, shard)
                    proj.dead = true
                    break
                end
            end
        end
    end

    return results
end

-- Process enemy projectile vs tower collisions
-- Returns: {hits = {}, towerDamage = 0}
function CollisionManager:processEnemyProjectileVsTower(enemyProjectiles, tower, godMode)
    local results = {
        hits = {},
        towerDamage = 0,
        towerDestroyed = false,
    }

    for i = #enemyProjectiles, 1, -1 do
        local proj = enemyProjectiles[i]

        if proj:checkTowerCollision(tower) then
            if not godMode then
                local destroyed = tower:takeDamage(proj.damage)
                results.towerDamage = results.towerDamage + proj.damage
                results.towerDestroyed = results.towerDestroyed or destroyed
            end

            -- Record hit
            table.insert(results.hits, {
                projectile = proj,
                damage = proj.damage,
            })

            -- Spawn impact particles
            DebrisManager:spawnSquareImpact(proj.x, proj.y, proj.angle,
                proj.projectileType == "mini_hex" and SHAPE_COLORS.hexagon or SHAPE_COLORS.square)
            Feedback:trigger("enemy_projectile_hit")
            proj.dead = true
        end
    end

    return results
end

-- Process shield vs enemy collisions
-- Returns: {kills = {}, flyingParts = {}, shardsToSpawn = {}, goldEarned = 0}
function CollisionManager:processShieldVsEnemies(shield, enemies, tower, stats)
    local results = {
        kills = {},
        flyingParts = {},
        shardsToSpawn = {},
        goldEarned = 0,
        damageNumbers = {},
    }

    if not shield then return results end

    for _, enemy in ipairs(enemies) do
        if not enemy.dead and shield:checkEnemyCollision(enemy) then
            -- Shield kills enemy instantly
            shield:consumeCharge()

            -- Calculate angle from turret to enemy for effects
            local deathAngle = math.atan2(enemy.y - tower.y, enemy.x - tower.x)

            -- Spawn shield kill burst particles
            DebrisManager:spawnShieldKillBurst(enemy.x, enemy.y, deathAngle, enemy.color)

            -- Trigger feedback
            Feedback:trigger("shield_kill")

            -- Kill enemy with enhanced explosion
            enemy:die(deathAngle, {velocity = PROJECTILE_SPEED * 1.5})

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

-- Process enemy vs tower pad collisions
-- Returns: {collisions = {}, towerDamage = 0, towerDestroyed = false}
function CollisionManager:processEnemyVsTower(enemies, tower, godMode)
    local results = {
        collisions = {},
        towerDamage = 0,
        towerDestroyed = false,
    }

    local padHalfSize = TOWER_PAD_SIZE * BLOB_PIXEL_SIZE * TURRET_SCALE

    for _, enemy in ipairs(enemies) do
        if enemy.dead then goto continue end

        local dx = math.abs(enemy.x - tower.x)
        local dy = math.abs(enemy.y - tower.y)

        if dx <= padHalfSize + 5 and dy <= padHalfSize + 5 then
            -- Calculate damage (triangle kamikaze deals explosion damage)
            local contactDamage = ENEMY_CONTACT_DAMAGE
            local isKamikaze = false

            if enemy.shapeName == "triangle" and enemy.isCharging then
                contactDamage = TRIANGLE_EXPLOSION_DAMAGE
                isKamikaze = true
                -- Spawn kamikaze explosion effect
                DebrisManager:spawnKamikazeExplosion(enemy.x, enemy.y, TRIANGLE_EXPLOSION_RADIUS)
                Feedback:trigger("kamikaze_explosion")
            end

            if not godMode then
                local destroyed = tower:takeDamage(contactDamage)
                results.towerDamage = results.towerDamage + contactDamage
                results.towerDestroyed = results.towerDestroyed or destroyed
            end

            -- Calculate angle from tower to enemy for death explosion direction
            local deathAngle = math.atan2(enemy.y - tower.y, enemy.x - tower.x)
            enemy:die(deathAngle)

            table.insert(results.collisions, {
                enemy = enemy,
                damage = contactDamage,
                isKamikaze = isKamikaze,
            })
        end

        ::continue::
    end

    return results
end

-- Process composite enemy vs tower collisions
-- Returns: {collisions = {}, towerDamage = 0, towerDestroyed = false}
function CollisionManager:processCompositeVsTower(compositeEnemies, tower, godMode)
    local results = {
        collisions = {},
        towerDamage = 0,
        towerDestroyed = false,
    }

    for _, composite in ipairs(compositeEnemies) do
        if composite.dead then goto continue end

        if composite:checkTowerCollision() then
            if not godMode then
                local destroyed = tower:takeDamage(ENEMY_CONTACT_DAMAGE)
                results.towerDamage = results.towerDamage + ENEMY_CONTACT_DAMAGE
                results.towerDestroyed = results.towerDestroyed or destroyed
            end

            -- Kill the composite and all children
            local deathAngle = math.atan2(composite.worldY - tower.y, composite.worldX - tower.x)
            composite:die(deathAngle)

            table.insert(results.collisions, {
                composite = composite,
                damage = ENEMY_CONTACT_DAMAGE,
            })
        end

        ::continue::
    end

    return results
end

-- Process AoE warning triggers
-- Returns: {triggered = {}, towerDamage = 0, towerDestroyed = false}
function CollisionManager:processAoEWarnings(aoeWarnings, tower, godMode, gameDt)
    local results = {
        triggered = {},
        towerDamage = 0,
        towerDestroyed = false,
    }

    for i = #aoeWarnings, 1, -1 do
        local warning = aoeWarnings[i]
        local triggeredDamage = warning:update(gameDt)

        if triggeredDamage then
            -- Check if tower is inside the damage zone
            if warning:containsPoint(tower.x, tower.y) then
                if not godMode then
                    local destroyed = tower:takeDamage(triggeredDamage)
                    results.towerDamage = results.towerDamage + triggeredDamage
                    results.towerDestroyed = results.towerDestroyed or destroyed
                end
            end

            -- Spawn trigger effect
            DebrisManager:spawnPentagonTrigger(warning.x, warning.y, warning.radius, warning.color)
            Feedback:trigger("aoe_trigger")

            table.insert(results.triggered, warning)
        end
    end

    return results
end

-- Process projectile vs shard collisions (main projectiles catch shards)
-- Returns: {catches = {}}
function CollisionManager:processProjectileVsShards(projectiles, collectibleShards, tower)
    local results = {
        catches = {},
    }

    for _, proj in ipairs(projectiles) do
        if proj.dead then goto continue end

        proj.hitShards = proj.hitShards or {}

        for _, shard in ipairs(collectibleShards) do
            if shard.state == "idle" and not proj.hitShards[shard] and shard:checkProjectileHit(proj.x, proj.y) then
                proj.hitShards[shard] = true
                -- Send shard directly to turret
                shard:catch(tower.x, tower.y)

                table.insert(results.catches, {
                    projectile = proj,
                    shard = shard,
                })
            end
        end

        ::continue::
    end

    return results
end

return CollisionManager
