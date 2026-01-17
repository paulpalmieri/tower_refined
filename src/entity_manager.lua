-- entity_manager.lua
-- Centralized management of all game entities

local EntityManager = {
    -- Singleton entities
    tower = nil,
    damageAura = nil,

    -- Entity collections (arrays)
    collections = {
        enemies = {},
        compositeEnemies = {},
        projectiles = {},
        particles = {},
        damageNumbers = {},
        chunks = {},
        flyingParts = {},
        dustParticles = {},
        collectibleShards = {},
        drones = {},
        droneProjectiles = {},
        silos = {},
        missiles = {},
        enemyProjectiles = {},
        aoeWarnings = {},
    },
}

-- Initialize the entity manager
function EntityManager:init()
    self:reset()
end

-- Reset all entities (call between runs)
function EntityManager:reset()
    self.tower = nil
    self.damageAura = nil

    for name, _ in pairs(self.collections) do
        self.collections[name] = {}
    end

    -- Update global references for backwards compatibility
    self:syncGlobals()
end

-- Add an entity to a collection
function EntityManager:add(collectionName, entity)
    local collection = self.collections[collectionName]
    if collection then
        table.insert(collection, entity)
    else
        error("Unknown collection: " .. tostring(collectionName))
    end
end

-- Get a collection by name
function EntityManager:get(collectionName)
    return self.collections[collectionName]
end

-- Get the tower
function EntityManager:getTower()
    return self.tower
end

-- Set the tower
function EntityManager:setTower(t)
    self.tower = t
    _G.tower = t  -- Sync global
end

-- Get the damage aura
function EntityManager:getDamageAura()
    return self.damageAura
end

-- Set the damage aura
function EntityManager:setDamageAura(aura)
    self.damageAura = aura
    _G.damageAura = aura  -- Sync global
end

-- Remove dead entities from a specific collection
-- Returns count of removed entities
function EntityManager:removeDeadFrom(collectionName)
    local collection = self.collections[collectionName]
    if not collection then return 0 end

    local removed = 0
    for i = #collection, 1, -1 do
        if collection[i].dead then
            table.remove(collection, i)
            removed = removed + 1
        end
    end
    return removed
end

-- Remove dead entities from all collections
function EntityManager:removeDeadFromAll()
    local totalRemoved = 0
    for name, _ in pairs(self.collections) do
        totalRemoved = totalRemoved + self:removeDeadFrom(name)
    end
    return totalRemoved
end

-- Get total entity count across all collections
function EntityManager:getTotalCount()
    local count = 0
    for _, collection in pairs(self.collections) do
        count = count + #collection
    end
    if self.tower then count = count + 1 end
    if self.damageAura then count = count + 1 end
    return count
end

-- Get count for a specific collection
function EntityManager:getCount(collectionName)
    local collection = self.collections[collectionName]
    return collection and #collection or 0
end

-- Clear a specific collection
function EntityManager:clear(collectionName)
    if self.collections[collectionName] then
        self.collections[collectionName] = {}
        -- Sync global
        _G[collectionName] = self.collections[collectionName]
    end
end

-- Sync all collections to global namespace for backwards compatibility
-- This allows existing code to continue using global arrays
function EntityManager:syncGlobals()
    for name, collection in pairs(self.collections) do
        _G[name] = collection
    end
    _G.tower = self.tower
    _G.damageAura = self.damageAura
end

-- Iterate over entities in a collection with optional predicate
function EntityManager:forEach(collectionName, callback, predicate)
    local collection = self.collections[collectionName]
    if not collection then return end

    for _, entity in ipairs(collection) do
        if not predicate or predicate(entity) then
            callback(entity)
        end
    end
end

-- Find first entity matching predicate
function EntityManager:find(collectionName, predicate)
    local collection = self.collections[collectionName]
    if not collection then return nil end

    for _, entity in ipairs(collection) do
        if predicate(entity) then
            return entity
        end
    end
    return nil
end

-- Find all entities matching predicate
function EntityManager:findAll(collectionName, predicate)
    local collection = self.collections[collectionName]
    if not collection then return {} end

    local results = {}
    for _, entity in ipairs(collection) do
        if predicate(entity) then
            table.insert(results, entity)
        end
    end
    return results
end

-- Get all alive (not dead) entities from a collection
function EntityManager:getAlive(collectionName)
    return self:findAll(collectionName, function(e) return not e.dead end)
end

return EntityManager
