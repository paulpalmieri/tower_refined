# CLAUDE.md - Tower Idle Roguelite

## Quick Reference

```bash
# Run the game
love .

# Lint code (run after every change)
luacheck .
```

## Game Overview

A Vampire Survivors-style auto-shooting roguelite with a neon geometric aesthetic. An auto-firing turret defends against continuous waves of geometric enemies. The player unlocks abilities and upgrades through a skill tree between runs.

**Core Fantasy:** "I am an immovable force. Enemies pour in and disintegrate before reaching me."

**Visual Style:** Matrix-inspired neon green on black, geometric shapes (triangles, squares, pentagons, hexagons, heptagons).

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
gameState: "intro" | "playing" | "gameover" | "skilltree" | "settings"

intro     -> (any key / auto)    -> playing
playing   -> (tower HP = 0)      -> gameover
playing   -> (press ESC)         -> gameover
gameover  -> (press S)           -> skilltree
gameover  -> (press R)           -> playing (new run)
skilltree -> (press R / confirm) -> playing (new run)
settings  -> (press ESC)         -> (previous state)
```

### Entity Ownership

| Entity | Storage | Managed In |
|--------|---------|------------|
| Tower | `tower` (single) | main.lua |
| Enemies | `enemies[]` | main.lua |
| Composite Enemies | `compositeEnemies[]` | main.lua |
| Projectiles | `projectiles[]` | main.lua |
| Drone Projectiles | `droneProjectiles[]` | main.lua |
| Particles | `particles[]` | main.lua |
| Chunks | `chunks[]` | main.lua |
| Collectible Shards | `collectibleShards[]` | main.lua |
| Drones | `drones[]` | main.lua |
| Silos | `silos[]` | main.lua |
| Missiles | `missiles[]` | main.lua |

---

## Module Map

| File | Purpose |
|------|---------|
| `main.lua` | Entry point, game loop, UI |
| `src/config.lua` | All gameplay constants |
| `src/audio.lua` | Sound effects and music system |
| `src/camera.lua` | Camera positioning and transforms |
| `src/composite_templates.lua` | Composite enemy type definitions |
| `src/debris_manager.lua` | Debris and particle spawning |
| `src/debug_console.lua` | Runtime debug console |
| `src/feedback.lua` | Screen shake and hit-stop |
| `src/intro.lua` | Intro cinematic sequence |
| `src/lighting.lua` | Simple additive glow lights |
| `src/postfx.lua` | Post-processing effects (bloom, CRT, glitch) |
| `src/settings_menu.lua` | Settings menu UI |

### Entities

| File | Purpose |
|------|---------|
| `src/entities/enemy.lua` | Base geometric enemy |
| `src/entities/composite_enemy.lua` | Hierarchical multi-part enemies |
| `src/entities/turret.lua` | Tower entity |
| `src/entities/projectile.lua` | Bullet entity |
| `src/entities/missile.lua` | Homing missiles from silos |
| `src/entities/drone.lua` | Orbiting XP collector drones |
| `src/entities/shield.lua` | Protective shield around turret |
| `src/entities/silo.lua` | Missile launch silos |
| `src/entities/particle.lua` | Short-lived visual sparks |
| `src/entities/chunk.lua` | Persistent debris fragments |
| `src/entities/flying_part.lua` | Detached enemy parts |
| `src/entities/collectible_shard.lua` | Polygon currency drops |
| `src/entities/damagenumber.lua` | Floating damage text |

### Skill Tree

| File | Purpose |
|------|---------|
| `src/skilltree/init.lua` | Skill tree main module |
| `src/skilltree/node.lua` | Individual skill node class |
| `src/skilltree/node_data.lua` | Skill definitions and effects |
| `src/skilltree/transition.lua` | Screen transition animations |
| `src/skilltree/canvas.lua` | Skill tree rendering |

---

## Code Style

### Naming Conventions
- **UPPER_SNAKE_CASE**: Constants (`TOWER_HP`, `MISSILE_SPEED`)
- **PascalCase**: Classes (`Enemy`, `Turret`, `CompositeEnemy`)
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

Screen shake and hit-stop for game feel. Entry point: `Feedback:trigger(preset_name, context)`

**Available Presets:**
- `small_hit` - Per-bullet impact (shake + brief freeze)
- `enemy_death` - Enemy killed
- `tower_damage` - Tower hit
- `laser_charge` - Laser charging (subtle shake)
- `laser_fire` - Laser firing (stronger shake + brief freeze)
- `laser_continuous` - During laser beam (sustained shake)
- `plasma_charge` - Plasma missile charging
- `plasma_fire` - Plasma missile firing (strong shake + freeze)
- `shield_kill` - Enemy killed by shield
- `missile_launch` - Silo missile launch
- `missile_impact` - Missile explosion on hit

**Context for damage scaling:**
```lua
Feedback:trigger("small_hit", {
    damage_dealt = amount,
    max_hp = enemy.maxHp,
})
```

---

## Skill Tree System

Persistent progression between runs. Skills unlock abilities and stat boosts.

**Key Features:**
- Node-based skill graph with prerequisites
- Polygon currency earned during runs
- Abilities unlocked: Shield, Drones, Silos, stat upgrades
- Smooth camera transitions and visual feedback

---

## Drone System

Orbiting drones that collect polygon shards and fire at collectibles.

**Behavior:**
- Orbit around turret at configurable radius
- Auto-target and fire at nearby collectible shards
- Drone projectiles only hit shards, not enemies
- Shards fragment when hit by drone projectiles

---

## Silo System

Missile silos that launch homing missiles at enemies.

**Behavior:**
- Silos positioned around turret in a ring
- Animated hatch open/close sequence
- Missiles home in on random enemies
- Orange visual theme distinct from main turret

---

## Composite Enemy System

Hierarchical enemies made of multiple attached shapes.

**Features:**
- Parent-child hierarchy (children orbit parent)
- Damage cascades through hierarchy
- Children detach and become independent on parent death
- Templates defined in `composite_templates.lua`

---

## Post-Processing Effects

Visual effects applied to the game render. All configurable in `src/config.lua`.

**Effects:**
- Bloom (glow around bright elements)
- CRT scanlines and curvature
- Chromatic aberration (RGB split)
- Heat distortion (subtle wave effect)
- Glitch effect (digital noise)

---

## Lighting System

Simple additive glow on key game elements.

**Light Types:**
- Tower glow (pulsing)
- Projectile glow (follows bullet)
- Muzzle flash (brief cone)
- Missile glow (orange)
- Drone glow (purple)

---

## Debris Manager

Spawns visual effects for impacts and death.

**Methods:**
- `spawnImpactBurst(x, y, angle)` - Green particles at bullet hit
- `spawnMinorSpatter(x, y, angle, intensity, color)` - Spark particles on hit
- `spawnExplosionBurst(x, y, angle, shape, color, velocity)` - Death explosion
- `spawnBloodParticles(x, y, angle, shape, color, intensity)` - Shape-matching hit particles
- `spawnTrailSparks(x, y)` - Trailing sparks from moving chunks
- `spawnShieldKillBurst(x, y, angle, enemyColor)` - Electric burst on shield kill
- `spawnMissileExplosion(x, y, angle)` - Orange explosion for missiles

---

## Key Constants

All in `src/config.lua`:

| Category | Examples |
|----------|----------|
| Tower | `TOWER_HP`, `TOWER_FIRE_RATE`, `PROJECTILE_SPEED` |
| Enemy Types | `ENEMY_TYPES` table (basic, fast, tank, brute, elite) |
| Lighting | `PROJECTILE_LIGHT_*`, `MUZZLE_FLASH_*`, `TOWER_LIGHT_*` |
| Chunks | `CHUNK_FRICTION`, `CHUNK_SETTLE_DELAY` |
| Laser Beam | `LASER_CHARGE_TIME`, `LASER_FIRE_TIME`, `LASER_DAMAGE_PER_SEC` |
| Plasma | `PLASMA_CHARGE_TIME`, `PLASMA_COOLDOWN_TIME`, `PLASMA_DAMAGE` |
| Drone | `DRONE_BASE_FIRE_RATE`, `DRONE_PROJECTILE_SPEED`, `DRONE_COLOR` |
| Silo/Missile | `SILO_BASE_FIRE_RATE`, `MISSILE_SPEED`, `MISSILE_DAMAGE` |
| Collectibles | `POLYGON_*` constants for currency shards |
| Shield | `SHIELD_BASE_RADIUS`, `SHIELD_COLOR_*` |
| Post-FX | `BLOOM_*`, `CRT_*`, `GLITCH_*`, `HEAT_DISTORTION_*` |
| Composite | `COMPOSITE_*` for hierarchical enemies |

---

## Controls

| Key | Action |
|-----|--------|
| `1` | Activate Laser Beam |
| `2` | Activate Plasma Missile |
| `Z` | Cycle game speed (0x/0.1x/0.5x/1x/3x/5x) |
| `X` | Toggle auto-aim / manual aim |
| `R` | Restart run |
| `S` (gameover) | Open skill tree |
| `O` | Open settings menu |
| `B` | Toggle fullscreen |
| `ESC` | End run / Quit |
| Arrow keys | Navigate menus |
| Enter/Space | Confirm selection |

### Debug Controls

| Key | Action |
|-----|--------|
| `U` | Toggle performance overlay |
| `G` | Toggle god mode |
| `` ` `` | Toggle debug console |

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
