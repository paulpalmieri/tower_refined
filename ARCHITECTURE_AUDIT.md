# Architecture Audit Report: Tower Refined

**Date:** January 17, 2026
**Auditor:** Senior Software Architect Review
**Codebase:** Tower Refined (Vampire Survivors-style auto-shooter)

---

## Executive Summary

This audit identifies significant architectural debt in the Tower Refined codebase. The game is functional but has accumulated coupling and complexity that will impede future development. The primary issues are:

1. **God object problem** - `main.lua` at 2,977 lines handles too many responsibilities
2. **Tight coupling** - Entities directly call global systems (Lighting, Feedback, DebrisManager)
3. **Duplicated patterns** - Collision detection repeated 5+ times with near-identical logic
4. **Flag-based anti-patterns** - Enemies signal actions via flags processed by main.lua
5. **No centralized entity management** - 9+ separate arrays with manual lifecycle handling

**Recommendation:** Prioritize extraction of EntityManager and CollisionManager to reduce main.lua complexity by 40-50%.

---

## Table of Contents

1. [Critical Issues](#1-critical-issues)
2. [High Priority Issues](#2-high-priority-issues)
3. [Medium Priority Issues](#3-medium-priority-issues)
4. [Low Priority Issues](#4-low-priority-issues)
5. [Action Items Summary](#5-action-items-summary)
6. [Proposed Architecture](#6-proposed-architecture)

---

## 1. Critical Issues

### 1.1 God Object: main.lua (2,977 lines)

**Location:** `main.lua`

**Problem:** The main file violates single responsibility principle massively:
- 31 entity manager loops in update/draw
- 15+ independent update functions for different entity types
- 9 global entity arrays with no centralized management
- Complex collision detection duplicated across 5+ loops
- State machines for laser, plasma, and game-over mixed together

**Current Structure:**
```lua
-- Lines 104-132: 17 global entity arrays
tower = nil
enemies = {}
compositeEnemies = {}
projectiles = {}
particles = {}
damageNumbers = {}
chunks = {}
flyingParts = {}
dustParticles = {}
collectibleShards = {}
drones = {}
droneProjectiles = {}
silos = {}
missiles = {}
enemyProjectiles = {}
aoeWarnings = {}
damageAura = nil
```

**Impact:**
- Impossible to understand game flow
- Cannot test subsystems in isolation
- Adding features requires understanding entire 3,000-line file
- High regression risk on any change

**Action Item 1.1:** Extract EntityManager
```lua
-- Proposed: src/managers/entity_manager.lua
local EntityManager = {}

function EntityManager:init()
    self.collections = {
        enemies = {},
        compositeEnemies = {},
        projectiles = {},
        particles = {},
        -- etc.
    }
end

function EntityManager:add(type, entity)
    table.insert(self.collections[type], entity)
end

function EntityManager:updateAll(dt)
    for name, collection in pairs(self.collections) do
        self:updateCollection(name, collection, dt)
    end
end

function EntityManager:removeDeadEntities()
    for name, collection in pairs(self.collections) do
        for i = #collection, 1, -1 do
            if collection[i].dead then
                table.remove(collection, i)
            end
        end
    end
end

function EntityManager:reset()
    for name, collection in pairs(self.collections) do
        self.collections[name] = {}
    end
end

return EntityManager
```

---

### 1.2 Duplicated Collision Detection (5+ patterns)

**Locations:**
- `main.lua:2312-2357` - Projectile vs Enemy
- `main.lua:2362-2420` - Projectile vs CompositeEnemy
- `main.lua:2111-2142` - Missile vs Enemy
- `main.lua:2031-2060` - Drone Projectile vs Shard
- `main.lua:2448-2460` - Enemy Projectile vs Tower

**Problem:** Near-identical collision handling repeated with slight variations:
```lua
-- Pattern repeated 5 times:
for _, enemy in ipairs(enemies) do
    if proj:checkCollision(enemy) and not enemy.dead and not proj.hitEnemies[enemy] then
        proj.hitEnemies[enemy] = true
        local killed = enemy:takeDamage(proj.damage, proj.angle, {...})
        spawnDamageNumber(...)
        if killed then
            -- Kill handling
        end
        if not proj.piercing then proj.dead = true break end
    end
end
```

**Impact:**
- Changing kill behavior requires 5+ edits
- Easy to miss one instance when fixing bugs
- 200+ lines of duplication

**Action Item 1.2:** Create CollisionManager
```lua
-- Proposed: src/managers/collision_manager.lua
local CollisionManager = {}

CollisionManager.handlers = {
    projectile_enemy = function(proj, enemy, context)
        if proj:checkCollision(enemy) and not enemy.dead then
            return CollisionManager:handleDamage(proj, enemy, context)
        end
        return false
    end,
    -- Additional handlers...
}

function CollisionManager:checkAll(entities, context)
    local results = {}

    -- Projectiles vs Enemies
    for _, proj in ipairs(entities.projectiles) do
        for _, enemy in ipairs(entities.enemies) do
            self.handlers.projectile_enemy(proj, enemy, context)
        end
    end

    return results
end

function CollisionManager:handleDamage(source, target, context)
    local killed, flyingParts = target:takeDamage(source.damage, source.angle, context)
    context.onDamage(source, target, killed, flyingParts)
    return killed
end

return CollisionManager
```

---

### 1.3 Entity Tight Coupling to Global Systems

**Locations:**
- `src/entities/enemy.lua:652-663` - DebrisManager, Feedback calls
- `src/entities/turret.lua:247,317,370-371,419` - Feedback calls
- `src/entities/composite_enemy.lua:601-615` - Same pattern

**Problem:** Entities directly call global singletons:
```lua
-- In enemy.lua:takeDamage()
DebrisManager:spawnImpactBurst(hitX, hitY, angle)
DebrisManager:spawnBloodParticles(hitX, hitY, angle, self.shapeName, self.color, intensity)
Feedback:trigger("small_hit", {
    damage_dealt = actualDamage,
    max_hp = self.maxHp,
})
```

**Impact:**
- Cannot swap effect implementations
- Cannot disable effects for performance testing
- Entities are untestable in isolation
- Circular dependency risk

**Action Item 1.3:** Inject dependencies or use events
```lua
-- Option A: Dependency injection
function Enemy:new(x, y, config, services)
    self.services = services  -- {debris, feedback, lighting}
end

function Enemy:takeDamage(damage, angle, context)
    -- ...
    if self.services.debris then
        self.services.debris:spawnImpactBurst(hitX, hitY, angle)
    end
end

-- Option B: Event emission (preferred)
function Enemy:takeDamage(damage, angle, context)
    -- ...
    self:emit("damage_taken", {
        x = hitX, y = hitY,
        angle = angle,
        damage = actualDamage,
        maxHp = self.maxHp,
        shape = self.shapeName,
        color = self.color,
    })
end
```

---

## 2. High Priority Issues

### 2.1 State Machine Sprawl

**Locations:**
- `main.lua:427-870` - Laser beam system (5 states, 8 draw functions)
- `main.lua:782-870` - Plasma missile system (3 states)
- `main.lua:151-159,1697-1738,2487-2504` - Game over animation (6 phases)

**Problem:** State machines are not self-contained:
```lua
-- Laser state spread across main.lua:
laserBeam = {
    state = "ready",  -- ready/deploying/charging/firing/retracting
    progress = 0,
    chargeProgress = 0,
    -- 20+ properties...
}

function updateLaser(dt) ... end      -- Line 546
function drawLaserBeam() ... end      -- Line 720
function drawLaserCannons() ... end   -- Called from draw
function drawLaserChargeEffect() ...  -- Called from draw
-- 5 more laser-related functions
```

**Action Item 2.1:** Extract state machines to classes
```lua
-- Proposed: src/systems/laser_system.lua
local LaserSystem = Object:extend()

LaserSystem.STATES = {
    READY = "ready",
    DEPLOYING = "deploying",
    CHARGING = "charging",
    FIRING = "firing",
    RETRACTING = "retracting",
}

function LaserSystem:new(tower)
    self.tower = tower
    self.state = self.STATES.READY
    self.stateHandlers = {
        [self.STATES.READY] = self.updateReady,
        [self.STATES.DEPLOYING] = self.updateDeploying,
        -- etc.
    }
end

function LaserSystem:update(dt)
    local handler = self.stateHandlers[self.state]
    if handler then handler(self, dt) end
end

function LaserSystem:draw()
    -- All laser drawing consolidated here
end

function LaserSystem:activate()
    if self.state == self.STATES.READY then
        self.state = self.STATES.DEPLOYING
    end
end

return LaserSystem
```

---

### 2.2 Flag-Based Attack Anti-Pattern

**Location:** `src/entities/enemy.lua:50-62`, `main.lua:2217-2243`

**Problem:** Enemies set flags, main.lua processes them:
```lua
-- In enemy.lua
self.shouldFireProjectile = false
self.shouldCreateTelegraph = false
self.shouldSpawnMiniHex = false
self.shouldExplode = false

-- In main.lua (processing loop)
if enemy.shouldFireProjectile then
    local proj = EnemyProjectile(...)
    table.insert(enemyProjectiles, proj)
    DebrisManager:spawnSquareMuzzleFlash(...)
end
```

**Impact:**
- Attack implementation split between enemy.lua and main.lua
- Adding new attack requires edits in both files
- Cannot test enemy attacks in isolation

**Action Item 2.2:** Give enemies attack methods or use events
```lua
-- Option A: Direct attack methods
function Enemy:fireProjectile()
    return EnemyProjectile(self.x, self.y, self.attackAngle, self.projectileSpeed)
end

-- In main.lua update loop:
local newProjectile = enemy:tryAttack()
if newProjectile then
    table.insert(enemyProjectiles, newProjectile)
end

-- Option B: Event-based (preferred)
function Enemy:update(dt)
    if self:shouldAttack() then
        EventBus:emit("enemy_attack", {
            type = "projectile",
            enemy = self,
            x = self.x, y = self.y,
            angle = self.attackAngle,
        })
    end
end

-- Listener in main.lua:
EventBus:on("enemy_attack", function(data)
    if data.type == "projectile" then
        local proj = EnemyProjectile(data.x, data.y, data.angle)
        EntityManager:add("enemyProjectiles", proj)
    end
end)
```

---

### 2.3 Roguelite Ability Syncing in main.lua

**Location:** `main.lua:1746-1821` (syncRogueliteAbilities function)

**Problem:** 75-line function in main.lua creates/updates abilities:
```lua
function syncRogueliteAbilities()
    local rs = Roguelite.runtimeStats

    tower.fireRate = TOWER_FIRE_RATE / (stats.fireRate * rs.fireRateMult)
    tower.projectileSpeed = PROJECTILE_SPEED * stats.projectileSpeed * rs.projectileSpeedMult

    if rs.shieldCharges > 0 then
        if not tower.shield then
            tower.shield = Shield(tower)
        end
        tower.shield:setCharges(rs.shieldCharges, rs.shieldCharges)
    end

    -- 50 more lines handling drones, silos, damage aura...
end
```

**Impact:**
- Main.lua must know implementation details of every ability
- Adding new ability requires editing main.lua
- Cannot test abilities independently

**Action Item 2.3:** Create AbilityManager with self-spawning abilities
```lua
-- Proposed: src/systems/ability_manager.lua
local AbilityManager = {}

AbilityManager.abilities = {
    shield = require("src.abilities.shield_ability"),
    drone = require("src.abilities.drone_ability"),
    silo = require("src.abilities.silo_ability"),
    aura = require("src.abilities.aura_ability"),
}

function AbilityManager:sync(tower, stats, runtimeStats)
    for name, ability in pairs(self.abilities) do
        ability:sync(tower, stats, runtimeStats)
    end
end

function AbilityManager:update(dt)
    for name, ability in pairs(self.abilities) do
        ability:update(dt)
    end
end

-- Example ability (src/abilities/drone_ability.lua):
local DroneAbility = {}

function DroneAbility:sync(tower, stats, runtimeStats)
    local targetCount = stats.droneCount + runtimeStats.droneCount
    while #self.drones < targetCount do
        self:spawnDrone(tower)
    end
end

function DroneAbility:spawnDrone(tower)
    local drone = Drone(tower, #self.drones, self.targetCount)
    table.insert(self.drones, drone)
end

return DroneAbility
```

---

### 2.4 No Event System

**Problem:** Tight coupling throughout codebase because there's no way to communicate between systems without direct function calls.

**Examples of missing events:**
- `entity_killed` - Multiple systems need to know (XP, stats, effects)
- `upgrade_applied` - Triggers ability syncing
- `damage_dealt` - Triggers visual effects, numbers
- `wave_complete` - Triggers spawn changes
- `game_over` - Triggers cleanup, transitions

**Action Item 2.4:** Implement simple EventBus
```lua
-- Proposed: src/event_bus.lua
local EventBus = {
    listeners = {}
}

function EventBus:on(event, callback)
    self.listeners[event] = self.listeners[event] or {}
    table.insert(self.listeners[event], callback)
end

function EventBus:off(event, callback)
    local list = self.listeners[event]
    if list then
        for i = #list, 1, -1 do
            if list[i] == callback then
                table.remove(list, i)
            end
        end
    end
end

function EventBus:emit(event, data)
    local list = self.listeners[event]
    if list then
        for _, callback in ipairs(list) do
            callback(data)
        end
    end
end

function EventBus:reset()
    self.listeners = {}
end

return EventBus
```

---

## 3. Medium Priority Issues

### 3.1 Composite Enemy Duplication

**Location:** `main.lua:2359-2420`, `src/entities/composite_enemy.lua`

**Problem:** CompositeEnemy collision handling duplicates regular Enemy logic:
```lua
-- Regular enemy collision (lines 2312-2357)
for _, enemy in ipairs(enemies) do
    if proj:checkCollision(enemy) ... end
end

-- Composite collision (lines 2362-2420) - nearly identical
for _, composite in ipairs(compositeEnemies) do
    local hitNode = composite:findHitNode(proj.x, proj.y)
    if hitNode and proj:checkCollision(hitNode) ... end
end
```

**Action Item 3.1:** Create shared damage/collision interface
```lua
-- Both Enemy and CompositeEnemy implement IDamageable:
IDamageable = {
    checkCollision = function(self, other) end,
    takeDamage = function(self, damage, angle, context) end,
    isDead = function(self) end,
}

-- CollisionManager checks all damageables uniformly
function CollisionManager:checkProjectilesVsTargets(projectiles, targets)
    for _, proj in ipairs(projectiles) do
        for _, target in ipairs(targets) do
            if target:checkCollision(proj) then
                target:takeDamage(proj.damage, proj.angle, self.context)
            end
        end
    end
end
```

---

### 3.2 Inconsistent Entity Interfaces

**Problem:** Entities have different lifecycle patterns:

| Entity | update() returns | Cleanup method |
|--------|------------------|----------------|
| Particle | nothing | check .dead |
| Shard | collected value | check .dead |
| Silo | fire data | check state |
| Drone | nothing | check .dead |
| Missile | nothing | check .dead |

**Action Item 3.2:** Standardize entity interface
```lua
-- All entities implement:
Entity = Object:extend()

function Entity:update(dt)
    -- Returns nothing, sets self.dead when finished
end

function Entity:draw() end

function Entity:isDead()
    return self.dead
end

function Entity:cleanup()
    -- Release resources (lights, sounds, etc.)
end
```

---

### 3.3 Projectile Type Embedded in Single Class

**Location:** `src/entities/projectile.lua`

**Problem:** One class handles 3 visual styles:
```lua
local ENERGY_BOLT = {...}   -- Main turret
local PLASMA_BOLT = {...}   -- Plasma system
local DRONE_BOLT = {...}    -- Drone projectiles
```

**Action Item 3.3:** Consider projectile type hierarchy
```lua
-- Base class
Projectile = Object:extend()

-- Subclasses
StandardProjectile = Projectile:extend()
PlasmaProjectile = Projectile:extend()
DroneProjectile = Projectile:extend()

-- Or use composition:
function Projectile:new(x, y, angle, speed, damage, visualType)
    self.visual = ProjectileVisuals[visualType] or ProjectileVisuals.standard
end
```

---

### 3.4 Roguelite Upgrade If-Else Chain

**Location:** `src/roguelite/init.lua:171-220`

**Problem:** 40+ line if-else chain for upgrade application:
```lua
function Roguelite:applyUpgrade(upgrade)
    if upgrade.id == "shield" then
        self.runtimeStats.shieldCharges = 2
    elseif upgrade.id == "missile_silo" then
        self.runtimeStats.siloCount = self.runtimeStats.siloCount + 1
    elseif upgrade.id == "xp_drone" then
        self.runtimeStats.droneCount = self.runtimeStats.droneCount + 1
    -- 30+ more elseif blocks...
    end
end
```

**Action Item 3.4:** Use upgrade objects with apply() method
```lua
-- Proposed: src/roguelite/upgrades/shield_upgrade.lua
local ShieldUpgrade = {
    id = "shield",
    isMajor = true,

    apply = function(self, runtimeStats)
        runtimeStats.shieldCharges = 2
    end
}

-- In Roguelite:
function Roguelite:applyUpgrade(upgrade)
    if upgrade.apply then
        upgrade:apply(self.runtimeStats)
    end
end
```

---

## 4. Low Priority Issues

### 4.1 Monolithic Configuration

**Location:** `src/config.lua` (580+ lines)

**Problem:** All constants in one file mixing gameplay, visuals, audio, and effects.

**Action Item 4.1:** Split by concern
```
src/config/
  game_config.lua      -- TOWER_HP, SPAWN_RATE, etc.
  visual_config.lua    -- Colors, sizes, animations
  audio_config.lua     -- Volume levels
  postfx_config.lua    -- Bloom, CRT, glitch settings
  feedback_config.lua  -- Shake/hit-stop presets
```

---

### 4.2 Inconsistent Module Lifecycle

**Problem:** Modules have different init/reset/update patterns:

| Module | init() | reset() | update() |
|--------|--------|---------|----------|
| Camera | ✓ | ✗ | ✓ |
| Lighting | ✓ | ✓ | ✓ |
| Feedback | ✗ | ✓ | ✓ |
| PostFX | ✓ | ✗ | ✓ |
| DebrisManager | ✓ | ✓ | ✗ |

**Action Item 4.2:** Standardize module interface
```lua
-- All modules implement:
Module.init = function() end
Module.reset = function() end
Module.update = function(dt) end
Module.draw = function() end  -- if visual
```

---

### 4.3 Global Namespace Pollution

**Problem:** 100+ global constants from config.lua

**Action Item 4.3:** Namespace constants
```lua
-- Instead of:
TOWER_HP = 100
TOWER_FIRE_RATE = 0.15

-- Use:
Config.Tower = {
    HP = 100,
    FIRE_RATE = 0.15,
}
```

---

## 5. Action Items Summary

### Critical (Do First)

| ID | Action | Effort | Impact |
|----|--------|--------|--------|
| 1.1 | Extract EntityManager | 2-3 hrs | Reduces main.lua by 30% |
| 1.2 | Create CollisionManager | 3-4 hrs | Eliminates 200+ lines duplication |
| 1.3 | Decouple entity → global calls | 2-3 hrs | Enables testing, swappable effects |

### High Priority (Do Next)

| ID | Action | Effort | Impact |
|----|--------|--------|--------|
| 2.1 | Extract state machines | 2-3 hrs each | Removes 3 systems from main.lua |
| 2.2 | Fix flag-based attacks | 2 hrs | Enemy attacks self-contained |
| 2.3 | Create AbilityManager | 3-4 hrs | Removes 75-line sync function |
| 2.4 | Implement EventBus | 2 hrs | Foundation for decoupling |

### Medium Priority (Subsequent)

| ID | Action | Effort | Impact |
|----|--------|--------|--------|
| 3.1 | Unify Enemy/Composite collision | 2 hrs | 150 lines reduction |
| 3.2 | Standardize entity interface | 1-2 hrs | Consistent lifecycle |
| 3.3 | Projectile type hierarchy | 1-2 hrs | Clearer intent |
| 3.4 | Upgrade objects | 2 hrs | Remove if-else chain |

### Low Priority (Polish)

| ID | Action | Effort | Impact |
|----|--------|--------|--------|
| 4.1 | Split config.lua | 1-2 hrs | Better organization |
| 4.2 | Standardize module lifecycle | 1 hr | Predictable patterns |
| 4.3 | Namespace globals | 1 hr | Cleaner global scope |

---

## 6. Proposed Architecture

### Current vs Proposed Structure

```
CURRENT:
main.lua (2,977 lines - god object)
├── 17 global entity arrays
├── 5 collision detection loops
├── 3 state machines (laser, plasma, gameOver)
├── syncRogueliteAbilities (75 lines)
├── Entity update loops (31 loops)
└── All UI and game state

PROPOSED:
main.lua (~500 lines - orchestration only)
├── love.load() - initialize managers
├── love.update() - delegate to managers
├── love.draw() - delegate to managers
└── love.keypressed() - input routing

src/managers/
├── entity_manager.lua      -- All entity arrays, lifecycle
├── collision_manager.lua   -- All collision detection
├── ability_manager.lua     -- Shield, drone, silo, aura
└── spawn_manager.lua       -- Enemy wave spawning

src/systems/
├── laser_system.lua        -- Laser state machine
├── plasma_system.lua       -- Plasma state machine
├── game_over_system.lua    -- Game over animation
└── upgrade_system.lua      -- Upgrade application

src/core/
├── event_bus.lua           -- Event communication
├── game_state.lua          -- State machine for game modes
└── services.lua            -- Dependency injection container
```

### Proposed Dependency Flow

```
                    ┌─────────────┐
                    │   main.lua  │
                    │ (orchestrator)
                    └──────┬──────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │EntityManager│ │CollisionMgr │ │AbilityManager│
    └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
           │               │               │
           │               │               │
           ▼               ▼               ▼
    ┌─────────────────────────────────────────────┐
    │                  EventBus                    │
    │    (entity_killed, damage_dealt, etc.)      │
    └─────────────────────────────────────────────┘
           │               │               │
           ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ Lighting │    │ Feedback │    │DebrisMgr │
    │(listener)│    │(listener)│    │(listener)│
    └──────────┘    └──────────┘    └──────────┘
```

### Example Refactored Update Loop

```lua
-- Proposed main.lua love.update()
function love.update(dt)
    if gameState ~= "playing" then return end

    local gameDt = dt * gameSpeed

    -- Single-line delegations instead of 200+ lines
    SpawnManager:update(gameDt)
    EntityManager:updateAll(gameDt)
    CollisionManager:checkAll(EntityManager.collections)
    AbilityManager:update(gameDt)

    LaserSystem:update(gameDt)
    PlasmaSystem:update(gameDt)

    Camera:update(tower.x, tower.y, gameDt)
    Feedback:update(gameDt)
    Lighting:update(gameDt)
end
```

---

## 7. Refactoring Progress

**Last Updated:** January 17, 2026

### Completed Phases

| Phase | Description | Status | Lines Saved |
|-------|-------------|--------|-------------|
| 1 | EventBus implementation | ✅ Complete | Foundation |
| 2 | EntityManager extraction | ✅ Complete | ~100 lines |
| 3 | State Machines (Laser, Plasma, GameOver) | ✅ Complete | ~400 lines |
| 4 | CollisionManager & AbilityManager creation | ✅ Complete | Foundation |
| 5 | Entity Decoupling (events for effects) | ✅ Complete | Cleaner code |
| 6 | Manager Integration into main.lua | ✅ Complete | ~232 lines |

### Line Count Progress

| Milestone | main.lua Lines |
|-----------|----------------|
| Original (audit start) | 2,977 |
| After Phase 1-5 | 2,553 |
| After Phase 6 | **2,321** |
| Target | ~1,800 |

**Total reduction so far: 656 lines (22%)**

### Phase 6 Details (Just Completed)

Replaced 12 inline collision loops with manager calls:

| Collision Type | Manager Method |
|----------------|----------------|
| Drone projectile vs shard | `CollisionManager:processDroneProjectileVsShards()` |
| Missile vs enemy | `CollisionManager:processMissileVsEnemies()` |
| Shield vs enemy | `CollisionManager:processShieldVsEnemies()` |
| Enemy attacks | `AbilityManager:processEnemyAttacks()` |
| Enemy vs tower | `CollisionManager:processEnemyVsTower()` |
| Composite vs tower | `CollisionManager:processCompositeVsTower()` |
| Projectile vs enemy | `CollisionManager:processProjectileVsEnemies()` |
| Projectile vs composite | `CollisionManager:processProjectileVsComposites()` |
| Projectile vs shard | `CollisionManager:processProjectileVsShards()` |
| Enemy projectile vs tower | `CollisionManager:processEnemyProjectileVsTower()` |
| AoE warnings | `CollisionManager:processAoEWarnings()` |
| Damage aura | `AbilityManager:processDamageAura()` |

Added helper functions:
- `processCollisionResults()` - Handles flying parts, shards, damage numbers, gold/kills
- `checkTowerDestroyed()` - Triggers game over on tower destruction

### Remaining Work

#### Phase 7: Replace syncRogueliteAbilities (Estimated: ~50 lines saved)
- Current: 75-line function in main.lua creates/updates abilities
- Action: Use `AbilityManager:syncRogueliteAbilities()` (already implemented)
- Replace inline function with manager call

#### Phase 8: Entity Array Migration to EntityManager (Estimated: ~100 lines saved)
- Move 17 global arrays to EntityManager
- Replace direct array access with manager methods
- Consolidate cleanup loops

#### Phase 9: Spawn System Extraction (Estimated: ~100 lines saved)
- Extract enemy spawning logic to SpawnManager
- Move wave progression logic out of main.lua
- Consolidate spawn rate calculations

#### Phase 10: UI/Draw Consolidation (Estimated: ~200 lines saved)
- Extract HUD drawing to separate module
- Consolidate draw state handling
- Remove draw code from main.lua

### Current Architecture

```
src/
├── event_bus.lua           ✅ Implemented
├── entity_manager.lua      ✅ Implemented (not fully integrated)
├── collision_manager.lua   ✅ Implemented & Integrated
├── ability_manager.lua     ✅ Implemented & Integrated
├── systems/
│   ├── laser_system.lua    ✅ Implemented
│   ├── plasma_system.lua   ✅ Implemented
│   └── gameover_system.lua ✅ Implemented
└── entities/               ✅ Decoupled via events
```

---

## Conclusion

The Tower Refined codebase has reached a critical inflection point. The ~~2,977-line~~ **2,321-line** main.lua is still the primary source of complexity but significant progress has been made.

**Completed:**

1. ✅ **Week 1:** Extract EntityManager and CollisionManager
2. ✅ **Week 2:** Implement EventBus and decouple entity → global calls
3. ✅ **Week 3:** Extract state machines (Laser, Plasma, GameOver)
4. ✅ **Week 4:** Create AbilityManager, integrate collision managers

**Next steps:**

5. **Phase 7:** Replace syncRogueliteAbilities with AbilityManager call
6. **Phase 8:** Migrate entity arrays to EntityManager
7. **Phase 9:** Extract SpawnManager
8. **Phase 10:** UI/Draw consolidation

Each phase can be tested independently. The game should remain functional throughout refactoring by maintaining the same external behavior while improving internal structure.

**Expected outcome:** main.lua reduced to ~1,500-1,800 lines, subsystems testable in isolation, adding new features no longer requires understanding entire codebase.

---

*End of Architecture Audit Report*
