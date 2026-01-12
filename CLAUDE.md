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
| `R` | Restart run |
| `ESC` | Quit |
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
- Hitstop, slow-mo effects

---

## See Also

- `GAME_DESIGN.md` - Design ideas and future plans
