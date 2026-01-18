# Tower Idle Roguelite

## Quick Start

```bash
love .              # Run the game
```

**Tuning workflow:** Edit `tweaks.lua`, press `F5` in-game to hot-reload.

---

## What This Is

A Vampire Survivors-style auto-shooter. A turret auto-fires at waves of geometric enemies. Between runs, players spend polygon currency in a skill tree.

**Core loop:** Survive → collect polygons → unlock skills → run again with new abilities.

---

## Architecture Overview

```
main.lua (~1,750 lines)
    ↓ requires
src/config.lua          -- All tuning constants
src/entity_manager.lua  -- Entity arrays (enemies, projectiles, etc.)
src/collision_manager.lua -- All collision detection
src/spawn_manager.lua   -- Enemy wave spawning
src/ability_manager.lua -- Roguelite ability sync
src/event_bus.lua       -- Pub/sub for decoupling
src/systems/*.lua       -- State machines (laser, plasma, gameover)
src/entities/*.lua      -- Entity classes
src/skilltree/*.lua     -- Persistent progression
```

---

## Key Files by Purpose

### Core Game Loop
| File | Lines | Purpose |
|------|-------|---------|
| `main.lua` | ~1,750 | Entry point, orchestrates everything |
| `src/config.lua` | ~570 | All gameplay constants |
| `tweaks.lua` | ~40 | Hot-reloadable config overrides |

### Managers (Orchestration)
| File | Purpose |
|------|---------|
| `src/entity_manager.lua` | Owns all entity arrays, syncs to globals |
| `src/collision_manager.lua` | All collision detection in one place |
| `src/spawn_manager.lua` | Enemy wave spawning logic |
| `src/ability_manager.lua` | Roguelite ability application |
| `src/event_bus.lua` | Simple pub/sub for entity communication |

### State Machines
| File | Purpose |
|------|---------|
| `src/systems/laser_system.lua` | Laser beam (5 states) |
| `src/systems/plasma_system.lua` | Plasma missile (3 states) |
| `src/systems/gameover_system.lua` | Game over animation (5 phases) |

### Entities
| File | Purpose |
|------|---------|
| `src/entities/enemy.lua` | Base geometric enemy (~725 lines) |
| `src/entities/composite_enemy.lua` | Multi-part hierarchical enemies (~770 lines) |
| `src/entities/turret.lua` | The tower/player (~500 lines) |
| `src/entities/projectile.lua` | Bullets |
| `src/entities/drone.lua` | Orbiting polygon collectors |
| `src/entities/silo.lua` | Missile launchers |
| `src/entities/shield.lua` | Protective shield |

### Visual Systems
| File | Purpose |
|------|---------|
| `src/debris_manager.lua` | Particle/chunk spawning |
| `src/feedback.lua` | Screen shake and hit-stop |
| `src/lighting.lua` | Additive glow system |
| `src/postfx.lua` | Bloom, CRT, glitch effects |
| `src/hud.lua` | UI rendering |

### Progression
| File | Purpose |
|------|---------|
| `src/skilltree/init.lua` | Skill tree UI and logic |
| `src/skilltree/node_data.lua` | Skill definitions |
| `src/roguelite/init.lua` | Per-run progression (XP, levels) |
| `src/roguelite/levelup_ui.lua` | Level-up upgrade selection |

---

## Code Patterns

### Entity Lifecycle
```lua
-- Create
local enemy = Enemy(x, y, "basic")
table.insert(enemies, enemy)

-- Update (in game loop)
enemy:update(dt)

-- Remove when dead (iterate backwards)
for i = #enemies, 1, -1 do
    if enemies[i].dead then
        table.remove(enemies, i)
    end
end
```

### Event Bus (Decoupling)
```lua
-- Emit from entity
EventBus:emit("enemy_death", { x = self.x, y = self.y, shape = self.shapeName })

-- Listen in main.lua
EventBus:on("enemy_death", function(data)
    DebrisManager:spawnExplosionBurst(data.x, data.y, ...)
end)
```

### Feedback System
```lua
Feedback:trigger("small_hit", { damage_dealt = dmg, max_hp = enemy.maxHp })
Feedback:trigger("enemy_death")
Feedback:trigger("laser_fire")
```

---

## Naming Conventions

- `UPPER_SNAKE_CASE` — Constants (`TOWER_HP`, `SPAWN_RATE`)
- `PascalCase` — Classes (`Enemy`, `Turret`, `CollisionManager`)
- `camelCase` — Local variables and functions
- 4-space indentation

---

## Game State Machine

```
gameState: "intro" | "playing" | "gameover" | "skilltree" | "settings"

intro     → playing     (any key or auto-complete)
playing   → gameover    (tower HP = 0 or ESC)
gameover  → skilltree   (press S)
gameover  → playing     (press R, new run)
skilltree → playing     (confirm selection)
```

---

## Key Controls

| Key | Action |
|-----|--------|
| `1` | Activate Laser |
| `2` | Activate Plasma |
| `Z` | Cycle game speed |
| `R` | Restart run |
| `S` | Skill tree (from gameover) |
| `B` | Toggle fullscreen |
| `F5` | Hot-reload `tweaks.lua` |
| `U` | Performance overlay |
| `G` | God mode |

---

## Hot-Reload Tweaks

Edit `tweaks.lua` to override any config value:

```lua
return {
    KNOCKBACK_BASE_FORCE = 1200,  -- Default: 800
    SPAWN_RATE = 0.2,             -- Default: 0.4
    BLOOM_INTENSITY = 2.0,        -- Default: 1.5
}
```

Press `F5` in-game to apply changes instantly.

---

## Common Tasks

### Add a new enemy type
1. Add shape to `ENEMY_SHAPES` in `config.lua`
2. Add type to `ENEMY_TYPES` in `config.lua`
3. Add color to `SHAPE_COLORS` in `config.lua`
4. If special attack: add to `enemy.lua` attack logic

### Add a new ability
1. Add constants to `config.lua`
2. Add skill node in `src/skilltree/node_data.lua`
3. Handle in `ability_manager.lua` sync function
4. Create entity class if needed in `src/entities/`

### Add visual feedback
1. Use `Feedback:trigger(preset, context)` for shake/freeze
2. Use `DebrisManager:spawn*()` for particles
3. Use `Lighting:add*()` for glow effects

---

## Architecture Principles

1. **Globals for simplicity** — Entity arrays and constants are global for easy access
2. **EntityManager syncs to globals** — Collections are accessible as `enemies`, `projectiles`, etc.
3. **EventBus for decoupling** — Entities emit events, managers listen and respond
4. **State machines for complex behavior** — Laser, plasma, gameover use explicit state handling
5. **Config for all tuning** — No magic numbers in code, everything in `config.lua`
6. **Tweaks for experimentation** — Override config at runtime without restarting
