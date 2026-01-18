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

function EntityManager:init()
    self:reset()
end

function EntityManager:reset()
    self.tower = nil
    self.damageAura = nil
    for name, _ in pairs(self.collections) do
        self.collections[name] = {}
    end
    self:syncGlobals()
end

function EntityManager:add(collectionName, entity)
    local collection = self.collections[collectionName]
    if collection then
        table.insert(collection, entity)
    end
end

function EntityManager:get(collectionName)
    return self.collections[collectionName]
end

function EntityManager:getTower()
    return self.tower
end

function EntityManager:setTower(t)
    self.tower = t
    _G.tower = t
end

function EntityManager:getDamageAura()
    return self.damageAura
end

function EntityManager:setDamageAura(aura)
    self.damageAura = aura
    _G.damageAura = aura
end

function EntityManager:getTotalCount()
    local count = 0
    for _, collection in pairs(self.collections) do
        count = count + #collection
    end
    if self.tower then count = count + 1 end
    if self.damageAura then count = count + 1 end
    return count
end

function EntityManager:syncGlobals()
    for name, collection in pairs(self.collections) do
        _G[name] = collection
    end
    _G.tower = self.tower
    _G.damageAura = self.damageAura
end

return EntityManager
