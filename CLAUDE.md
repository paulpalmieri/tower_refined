# CLAUDE.md — Tower Idle Roguelite

## Game Overview

A single-tower idle roguelite. An auto-firing turret defends against waves of blob enemies. The player makes build choices on level-up and spends gold on meta-progression between runs.

**Fantasy:** "I am an immovable force. Enemies pour in and disintegrate before reaching me."

**Feel targets:** Vampire Survivors chaos + idle accumulation. Heavy, punchy impacts despite small fast projectiles.

---

## Tech Stack

- **Framework:** Love2D (latest stable)
- **Language:** Lua
- **Art:** Pixel art drawn in code, no external sprites

### Libraries (Use These)

| Library | Purpose | URL |
|---------|---------|-----|
| **classic** | OOP classes | https://github.com/rxi/classic/ |
| **lume** | Utility functions | https://github.com/rxi/lume/ |
| **flux** | Tweening/easing | https://github.com/rxi/flux |
| **bump** | AABB collision | https://github.com/kikito/bump.lua |

Add more only when needed. Start flat: `main.lua` + `lib/` folder. Refactor when files get too big.

---

## Development Workflow

**The AI agent cannot run or see the game.**

### Pattern

1. Agent builds ONE milestone
2. Agent says: "Ready for testing. Run `love .` and check: [specific things]"
3. Human tests, gives feedback on feel
4. Agent iterates or moves on

### Agent Rules

- Stop at each milestone — don't barrel through
- Ask about feel, not just "does it work"
- Provide tuning values as constants, expect human to adjust
- When unsure about scope, ask
- **Run the linter after making changes** (see below)

### Linting

Run `luacheck .` after making code changes to catch errors before testing.

```bash
luacheck .
```

The project uses [luacheck](https://github.com/mpeterv/luacheck) configured for Love2D. Configuration is in `.luacheckrc`.

**What to fix:**
- Undefined variables (typos, missing requires)
- Unused variables (dead code)
- Overwritten variables before use

**What's ignored:**
- Unused function arguments (common in Love2D callbacks)
- Line length warnings
- Whitespace issues

When adding new globals (classes, constants, functions accessed across files), add them to `.luacheckrc` in the `globals` table.

---

## MVP Scope (Build This)

### Arena
- Single screen, circular arena
- Dark background with fog/vignette at edges
- Tower (turret) fixed in center

### Tower
- Pixel art turret: recognizable gun on a base
- Auto-targets nearest enemy
- Auto-fires small, fast projectiles
- Has HP — run ends at 0
- Visual damage as HP drops (optional for prototype)

### Projectile
- Small, fast
- Weight comes from *feedback*, not size
- Has a subtle trail
- On hit: impact particles, screen shake

### Enemies (3 types for prototype)
- **Basic:** slow, low HP, comes in swarms
- **Fast:** quick, low HP, pressure
- **Tank:** slow, high HP, threatening

All enemies are pixel blobs:
- Walk toward tower
- Take damage → outer chunks break off, core exposed
- Death → burst into pixels, chunks linger briefly then fade
- Spawn from fog at screen edges (random points)
- No health bars — body damage IS the health indicator

### Damage Feedback
- Pixels chip off on hit
- Enemy flashes white on hit
- Screen shake on kills (subtle)
- Damage numbers (white, simple)
- Chunks/pixels scatter on death, fade after ~1 second

### Waves
- Wave counter UI
- Enemies spawn, wave ends when all dead
- Difficulty scales with wave number
- Early runs die around wave 3-5

### In-Run Progression
- Enemies drop XP
- XP bar fills → level up
- Level 2: pick 1 of 3 powers
- Other levels: passive stat boost (auto-applied for prototype)

**Prototype powers (pick ONE to implement first):**
1. **Ricochet** — projectiles bounce to nearby enemy
2. **Multi-shot** — fire 2 projectiles instead of 1
3. **Fire** — projectiles ignite, DOT damage

### Meta-Progression (Minimal)
- Run ends → earn gold based on waves reached
- Shop: buy ONE meaningful upgrade
- First upgrades are behavior changes, not +5% stats
- Examples: "projectiles pierce 1 enemy", "chance to ricochet", "fire rate +50%"

### Active Skill (Simple)
- Press "1" → nuke explosion around tower
- Cooldown-based
- Just one for testing feel

---

## Prototype Build Order

### Phase 1: Core Feel (START HERE)

**1.1 — Pixel blob**
- Draw a blob entity as a cluster of pixels
- Click to damage → chunks break off, scatter
- Blob has "core" (different color) revealed as outer layer destroyed
- Death → full burst, pixels fade

**Checkpoint:** Is destroying the blob satisfying?

**1.2 — Turret**
- Draw pixel art turret (center screen)
- Auto-fires toward mouse (temporary, for testing projectile feel)
- Projectile: small, fast, has trail
- On hit: particles, screen shake, blob takes chunk damage

**Checkpoint:** Does shooting feel impactful?

**1.3 — Enemy movement**
- Blob spawns at fog edge
- Walks toward turret
- Dies from projectile hits
- Damage numbers on hit

**Checkpoint:** Does the full loop (spawn → walk → get shot → die) feel good?

### Phase 2: Wave Loop

**2.1 — Wave spawner**
- Spawn N enemies
- Wave ends when all dead
- Next wave: more enemies, more HP

**2.2 — Tower HP**
- Enemy contact damages tower
- Tower death ends run
- Taking damage feels bad (screen effect, sound concept)

**2.3 — Enemy types**
- Add Fast enemy (quicker, less HP)
- Add Tank enemy (slower, more HP, bigger blob)

**Checkpoint:** Is there tension? Do enemy types feel different?

### Phase 3: Progression

**3.1 — XP and level up**
- Enemies drop XP
- XP bar fills
- Level up pauses game, shows 3 power choices

**3.2 — One power**
- Implement ONE power (ricochet recommended — visual and satisfying)
- Power changes projectile behavior

**3.3 — Passives**
- Other level-ups give flat stat boost
- Damage +10%, fire rate +10%, etc.

**Checkpoint:** Does leveling feel rewarding? Does the power change gameplay?

### Phase 4: Meta Loop

**4.1 — Run end**
- Tower dies → show results (wave reached, enemies killed)
- Gold earned

**4.2 — Upgrade shop**
- One screen, 3 upgrade options
- Buy → gold deducted → upgrade applied to next run

**4.3 — New run**
- Start with upgrades applied
- Feel the difference

**Checkpoint:** Does the loop (run → die → upgrade → run stronger) feel complete?

---

## Key Tuning Values

Expose these as constants for easy adjustment:

```lua
-- Tower
TOWER_HP = 100
TOWER_FIRE_RATE = 0.5 -- seconds between shots
PROJECTILE_SPEED = 400
PROJECTILE_DAMAGE = 10

-- Enemies
BASIC_HP = 30
BASIC_SPEED = 50
FAST_HP = 15
FAST_SPEED = 120
TANK_HP = 100
TANK_SPEED = 25

-- Feel
SCREEN_SHAKE_INTENSITY = 3
SCREEN_SHAKE_DURATION = 0.1
PIXEL_SCATTER_VELOCITY = 100
PIXEL_FADE_TIME = 1.0
DAMAGE_NUMBER_RISE_SPEED = 30
DAMAGE_NUMBER_FADE_TIME = 0.5

-- Progression
XP_PER_ENEMY = 10
XP_TO_LEVEL = 100 -- scales with level
GOLD_PER_WAVE = 5
```

---

## Do NOT Build (Out of Scope)

- Multiple towers or tower placement
- Boss enemies (later)
- Full power/passive/active system (3 powers max for prototype)
- Synergies between powers
- Color-coded damage numbers
- Hitstop, slow-mo effects
- Blood pools, arena damage
- Glowing eyes in fog (later polish)
- Sound (note where it would go, don't implement)
- Save/load (just restart between tests)

---

## Future Ideas (Ignore Until MVP Done)

Captured for later, not for prototype:

**Enemies:**
- Cute devil aesthetic with horns
- Horns/limbs destroyed progressively
- Boss every 10 waves with mechanics
- Behavior differences (dodge, charge, spawn others)

**Powers:**
- Lightning chain
- Explosive/AOE
- Vampiric (kills heal tower)
- Full synergy system (fire + ricochet + multi-shot)

**Actives:**
- Choices at level 5, 15, 25
- Synergies with powers

**Meta:**
- Full skill tree
- Unlock new powers for pool
- Run modifiers
- Start at wave X
- Artifacts from boss kills

**Polish:**
- Lighting/shadows
- Glowing eyes in fog before enemies emerge
- Blood pools that fade
- Sound design (meaty, crunchy, arcade)
- Hitstop on big kills

**Endgame:**
- Wave 100 boss
- Endless mode
- Victory lap mode (replay levels overpowered)

---

## First Session Goal

End session 1 with:
- A pixel blob you can click to destroy
- Chunks break off, core is exposed
- Death burst scatters pixels
- It feels *good*

That's it. Make destruction satisfying before anything else.
