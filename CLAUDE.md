# CLAUDE.md - Tower Idle Roguelite

## Quick Reference

```bash
# Run the game
love .

# Lint code (run after every change)
luacheck .
```

## Game Overview

A single-tower idle roguelite. An auto-firing turret defends against continuous waves of devil enemies. The player spends gold on meta-progression upgrades between runs.

**Fantasy:** "I am an immovable force. Enemies pour in and disintegrate before reaching me."

**Feel targets:** Vampire Survivors chaos + idle accumulation. Heavy, punchy impacts despite small fast projectiles.

---

## Tech Stack

| Component | Choice |
|-----------|--------|
| Framework | LOVE2D (Lua 5.1) |
| OOP | classic.lua (`Object:extend()`) |
| Utilities | lume.lua (functional helpers, random, clamp) |
| Art | Procedural pixel art (no external sprites) |

---

## Architecture

### Data Flow

```
love.load() -> Sounds.init(), initGround(), startNewRun()
                                              |
                                    Creates tower, resets state
                                              |
love.update(dt) -> Spawns enemies (continuous, based on gameTime)
                -> Tower auto-targets nearest enemy
                -> Tower fires projectiles when ready
                -> Enemies move toward tower
                -> Projectiles check collision -> damage enemies
                -> Tower HP check (gameover trigger)
                              |
love.draw() -> Render layers: Ground -> Chunks -> Dust -> Enemies -> Tower -> Projectiles -> Effects -> UI
```

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
| Damage Numbers | `damageNumbers[]` | main.lua |
| Dust | `dustParticles[]` | main.lua |

---

## Module Map

| File | Purpose | Key Exports |
|------|---------|-------------|
| `main.lua` | Entry point, game loop, state management, UI | Game state, spawn/update/draw loops |
| `src/config.lua` | All gameplay constants | Global constants |
| `src/entities/enemy.lua` | Enemy entity (pixel devil with animation) | `Enemy` class |
| `src/entities/turret.lua` | Tower entity (flak cannon turret) | `Turret` class |
| `src/entities/projectile.lua` | Bullet entity with trail | `Projectile` class |
| `src/entities/particle.lua` | Short-lived blood spray | `Particle` class |
| `src/entities/chunk.lua` | Permanent limb chunks (corpse debris) | `Chunk` class |
| `src/entities/damagenumber.lua` | Floating damage text | `DamageNumber` class |
| `src/audio.lua` | Audio system with pooling | `Sounds` singleton |
| `src/feedback.lua` | Centralized feedback system (shake, hit-stop, tweens) | `Feedback` singleton |
| `src/debris_manager.lua` | Centralized debris spawning (blood, limbs, corpses) | `DebrisManager` singleton |
| `src/monster_spec.lua` | Table-driven enemy definitions (parts, colors, layers) | `MonsterSpec` table |
| `conf.lua` | LOVE2D window configuration | n/a |
| `lib/classic.lua` | OOP base class | `Object` |
| `lib/lume.lua` | Utility functions | `lume` |

---

## Code Style

### Naming Conventions
- **UPPER_SNAKE_CASE**: Constants (e.g., `TOWER_HP`, `BASIC_SPEED`)
- **PascalCase**: Classes (e.g., `Enemy`, `Turret`, `Projectile`)
- **camelCase**: Local variables and functions (e.g., `screenShake`, `updateParticles`)
- **snake_case**: Rarely used, avoid introducing

### Indentation
- 4 spaces (no tabs)

### Module Pattern
All entity classes use classic.lua OOP:
```lua
ClassName = Object:extend()

function ClassName:new(params)
    -- Initialize instance
end

function ClassName:update(dt)
    -- Per-frame logic
end

function ClassName:draw()
    -- Rendering
end
```

### Entity Lifecycle
1. Create with `Entity(params)` or `Entity:new(params)`
2. Add to array: `table.insert(entities, entity)`
3. Update: iterate and call `entity:update(dt)`
4. Draw: iterate and call `entity:draw()`
5. Remove: iterate backwards, check `entity.dead`, use `table.remove(entities, i)`

### Feedback System
- **NEVER** trigger animations, shakes, or time effects directly in entity code
- **ALWAYS** use `Feedback:trigger(preset_name, context)` for all juice effects
- The `Feedback` module (`src/feedback.lua`) is the single source of truth for:
  - Screen shake
  - Hit-stop (time dilation)
  - Global visual effects
- Per-entity effects (flash timers, gun kick) remain in entity code
- Available presets: `small_hit`, `medium_hit`, `big_hit`, `minor_spatter`, `limb_break`, `total_collapse`, `enemy_death`, `tower_damage`, `nuke_explosion`
- Presets combine multiple channels (shake + hit-stop) in one trigger

#### Damage-Aware Context
When triggering feedback for combat events, pass a context table:
```lua
Feedback:trigger("preset_name", {
    damage_dealt = amount,
    current_hp = enemy.hp,
    max_hp = enemy.maxHp,
    impact_angle = bulletAngle,
    impact_x = hitX,
    impact_y = hitY,
    enemy = enemyRef
})
```
The system automatically scales shake intensity based on damage percentage.

### Dismemberment System
Enemies progressively lose body parts as they take damage:

**Health Thresholds (src/config.lua):**
- 75% HP: Horns break off
- 50% HP: Legs break off
- 25% HP: Outer body chunks
- 0% HP: Total collapse (death burst)

**Part Layers (src/monster_spec.lua):**
| Layer | Priority | Threshold |
|-------|----------|-----------|
| horn | 1 (first) | 75% |
| leg | 2 | 50% |
| outer | 3 | 25% |
| inner | 4 | 0% |
| eye | 5 | 0% |
| core | 6 (last) | 0% |

**Key Methods:**
- `Enemy:ejectLimbAtThreshold(threshold, angle)` - Force eject pixels of specified layer
- `Enemy:forceDismember()` - Debug: eject next available limb
- `Feedback:checkThresholdCrossed(oldPercent, newPercent)` - Detect HP threshold crossing

### Debris Manager
Centralized spawning for all gore effects (`src/debris_manager.lua`):
- `DebrisManager:spawnMinorSpatter(x, y, angle, intensity)` - Small blood particles
- `DebrisManager:spawnLimb(x, y, angle, pixels, velocity)` - Multi-pixel limb chunk
- `DebrisManager:spawnCorpseExplosion(x, y, angle, parts, velocity)` - Death burst
- `DebrisManager:spawnBloodTrail(x, y)` - Called by moving chunks

---

## Key Constants (Tuning Values)

All gameplay constants are defined in `src/config.lua`. Key categories:

| Category | Examples |
|----------|----------|
| Tower | `TOWER_HP`, `TOWER_FIRE_RATE`, `PROJECTILE_SPEED` |
| Enemies | `BASIC_HP/SPEED`, `FAST_HP/SPEED`, `TANK_HP/SPEED` |
| Combat | `KNOCKBACK_FORCE`, `SCREEN_SHAKE_INTENSITY` |
| Spawning | `SPAWN_RATE`, `MAX_ENEMIES`, `SPAWN_RATE_INCREASE` |
| Visuals | `BLOB_PIXEL_SIZE`, `TURRET_SCALE`, `PIXEL_FADE_TIME` |
| Nuke | `NUKE_DAMAGE`, `NUKE_RADIUS`, `NUKE_COOLDOWN` |
| Dismemberment | `DISMEMBER_THRESHOLDS`, `MINOR_SPATTER_THRESHOLD`, `CHUNK_SETTLE_DELAY` |
| Blood Trails | `BLOOD_TRAIL_INTERVAL`, `BLOOD_TRAIL_INTENSITY`, `BLOOD_TRAIL_SIZE_MIN/MAX` |

---

## Shop Upgrades

Four persistent upgrades available between runs:

| Upgrade | Effect |
|---------|--------|
| Fire Rate | Increases tower attack speed |
| Damage | Increases projectile damage |
| HP | Increases tower health |
| Nuke Cooldown | Reduces nuke ability cooldown |

Each upgrade has 5 tiers with increasing costs.

---

## Linting

The project uses luacheck. Run after every code change:

```bash
luacheck .
```

Configuration in `.luacheckrc`:
- **Fix:** Undefined variables, unused variables, overwritten before use
- **Ignore:** Unused function arguments (Love2D callbacks), line length, whitespace

When adding new globals, add them to `.luacheckrc` `globals` table.

---

## Development Workflow

**The AI agent cannot run or see the game.**

### Pattern

1. Agent builds ONE milestone
2. Agent says: "Ready for testing. Run `love .` and check: [specific things]"
3. Human tests, gives feedback on feel
4. Agent iterates or moves on

### Agent Rules

- Stop at each milestone - don't barrel through
- Ask about feel, not just "does it work"
- Provide tuning values as constants, expect human to adjust
- When unsure about scope, ask
- Run `luacheck .` after making changes

---

## Controls

| Key | Action |
|-----|--------|
| `1` | Activate Nuke (area damage around tower) |
| `S` (playing) | Cycle game speed (1x / 3x / 5x) |
| `S` (gameover) | Open shop |
| `G` | Toggle god mode (tower invincibility) |
| `R` | Restart run |
| `ESC` | Quit |
| `F3` | Toggle debug overlay (shows Feedback + Debris stats) |
| `D` (debug mode) | Force dismember nearest enemy |
| Arrow keys | Navigate shop menu |
| Enter/Space | Confirm selection |

---

## Known Issues / Technical Debt

1. **Global pollution**: Many global variables (constants + state + functions)
2. **Monolithic main.lua**: ~1000 lines, handles too many responsibilities

---

## Out of Scope (Not For Prototype)

- Multiple towers or tower placement
- Boss enemies
- Sound for hit/death (stubs exist, intentionally empty)
- Save/load

---

## See Also

- `GAME_DESIGN.md` - Design ideas and future plans
