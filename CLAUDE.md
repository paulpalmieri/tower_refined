# CLAUDE.md - Tower Idle Roguelite

## Quick Reference

```bash
# Run the game
love .

# Lint code (run after every change)
luacheck .
```

## Game Overview

A single-tower idle roguelite with a neon geometric aesthetic. An auto-firing turret defends against continuous waves of geometric enemies. The player spends gold on meta-progression upgrades between runs.

**Fantasy:** "I am an immovable force. Enemies pour in and disintegrate before reaching me."

**Visual Style:** Matrix-inspired neon green on black, geometric shapes (triangles, squares, pentagons).

---

## Tech Stack

| Component | Choice |
|-----------|--------|
| Framework | LOVE2D (Lua 5.1) |
| OOP | classic.lua (`Object:extend()`) |
| Utilities | lume.lua (functional helpers, random, clamp) |
| Art | Procedural neon geometric shapes |

---

## Architecture

### State Machine

```
gameState: "playing" | "gameover" | "shop"

playing   -> (tower HP = 0)     -> gameover
gameover  -> (press S)          -> shop
gameover  -> (press R)          -> playing (new run)
shop      -> (press R)          -> playing (new run)
```

### Entity Ownership

| Entity | Storage | Managed In |
|--------|---------|------------|
| Tower | `tower` (single) | main.lua |
| Enemies | `enemies[]` | main.lua |
| Projectiles | `projectiles[]` | main.lua |
| Particles | `particles[]` | main.lua |
| Chunks | `chunks[]` | main.lua |

---

## Module Map

| File | Purpose |
|------|---------|
| `main.lua` | Entry point, game loop, UI |
| `src/config.lua` | All gameplay constants |
| `src/entities/enemy.lua` | Geometric enemies with shard system |
| `src/entities/turret.lua` | Tower entity |
| `src/entities/projectile.lua` | Bullet entity |
| `src/entities/particle.lua` | Short-lived sparks |
| `src/entities/chunk.lua` | Permanent debris fragments |
| `src/feedback.lua` | Screen shake and hit-stop |
| `src/debris_manager.lua` | Debris spawning |
| `src/lighting.lua` | Simple additive glow lights |
| `src/monster_spec.lua` | Enemy type definitions |

---

## Code Style

### Naming Conventions
- **UPPER_SNAKE_CASE**: Constants (`TOWER_HP`, `SHARD_VELOCITY`)
- **PascalCase**: Classes (`Enemy`, `Turret`)
- **camelCase**: Local variables and functions

### Indentation
- 4 spaces (no tabs)

### Entity Lifecycle
1. Create with `Entity(params)`
2. Add to array: `table.insert(entities, entity)`
3. Update: `entity:update(dt)`
4. Draw: `entity:draw()`
5. Remove: iterate backwards, check `entity.dead`, use `table.remove`

---

## Feedback System

Simple screen shake and hit-stop. Entry point: `Feedback:trigger(preset_name, context)`

**Available Presets:**
- `small_hit` - Per-bullet impact (shake + brief freeze)
- `enemy_death` - Enemy killed
- `tower_damage` - Tower hit
- `laser_charge` - Laser charging (subtle shake)
- `laser_fire` - Laser firing (stronger shake + brief freeze)

**Context for damage scaling:**
```lua
Feedback:trigger("small_hit", {
    damage_dealt = amount,
    max_hp = enemy.maxHp,
})
```

---

## Shard System

Enemies drop shards (smaller copies of themselves) at HP thresholds:

**Thresholds:** 75%, 50%, 25% HP
- Enemy shrinks when shard ejects
- Shard flies in bullet direction, then settles
- One-shot kills eject all shards at once

**Key Constants:**
```lua
SHARD_THRESHOLDS = {0.75, 0.50, 0.25}
SHARD_SHRINK_FACTOR = 0.85
SHARD_SIZE_RATIO = 0.4
SHARD_VELOCITY = 200
```

---

## Lighting System

Simple additive glow on tower, bullets, and muzzle flash.

**Light Types:**
- Tower glow (pulsing)
- Projectile glow (follows bullet)
- Muzzle flash (brief cone)

---

## Debris Manager

Spawns visual effects for impacts and death.

**Methods:**
- `spawnMinorSpatter(x, y, angle, intensity, color)` - Spark particles on hit
- `spawnExplosionBurst(x, y, angle, color, velocity)` - Death explosion
- `spawnShard(x, y, angle, shape, color, size, velocity)` - Shard fragment
- `spawnTrailSparks(x, y)` - Trailing sparks from moving chunks

---

## Key Constants

All in `src/config.lua`:

| Category | Examples |
|----------|----------|
| Tower | `TOWER_HP`, `TOWER_FIRE_RATE`, `PROJECTILE_SPEED` |
| Enemies | `BASIC_HP/SPEED`, `FAST_HP/SPEED`, `TANK_HP/SPEED` |
| Shard System | `SHARD_THRESHOLDS`, `SHARD_SHRINK_FACTOR`, `SHARD_VELOCITY` |
| Lighting | `PROJECTILE_LIGHT_*`, `MUZZLE_FLASH_*`, `TOWER_LIGHT_*` |
| Chunks | `CHUNK_FRICTION`, `CHUNK_SETTLE_DELAY` |
| Laser Beam | `LASER_CHARGE_TIME`, `LASER_FIRE_TIME`, `LASER_DAMAGE_PER_SEC` |

---

## Controls

| Key | Action |
|-----|--------|
| `1` | Activate Laser Beam |
| `S` (playing) | Cycle game speed (1x / 3x / 5x) |
| `S` (gameover) | Open shop |
| `G` | Toggle god mode |
| `A` | Toggle auto-fire / manual aim |
| `R` | Restart run |
| `ESC` | Quit |
| `F3` | Toggle debug overlay |
| Arrow keys | Navigate shop |
| Enter/Space | Confirm selection |

---

## Linting

```bash
luacheck .
```

When adding new globals, add them to `.luacheckrc`.

---

## Development Workflow

1. Agent builds ONE milestone
2. Agent says: "Ready for testing. Run `love .` and check: [specific things]"
3. Human tests, gives feedback
4. Agent iterates or moves on

**Agent Rules:**
- Stop at each milestone
- Ask about feel, not just "does it work"
- Run `luacheck .` after changes
