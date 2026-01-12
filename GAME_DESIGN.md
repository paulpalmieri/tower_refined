# Tower Idle Roguelite - Game Design

## Core Fantasy

"I am an immovable force. Enemies pour in and disintegrate before reaching me."

---

## Core Loop

1. Tower auto-fires at nearest enemy
2. Enemies spawn continuously and move toward tower
3. Kill enemies to earn gold
4. Survive as long as possible
5. On death, spend gold on persistent upgrades
6. Start new run with upgrades applied

---

## Current Upgrades

| Upgrade | Effect | Tiers |
|---------|--------|-------|
| Fire Rate | Increases attack speed | 5 |
| Damage | Increases projectile damage | 5 |
| HP | Increases tower health | 5 |
| Nuke Cooldown | Reduces nuke cooldown | 5 |

---

## Enemy Types

| Type | Color | HP | Speed | Notes |
|------|-------|-----|-------|-------|
| Basic | Red | 10 | 45 | Standard enemy |
| Fast | Green | 5 | 100 | Quick but fragile |
| Tank | Blue | 25 | 25 | Slow but durable |

Spawn rates scale with game time.

---

## Meta-Progression

Gold earned persists between runs. Upgrades purchased in the shop apply at the start of each new run.

---

## Future Ideas

<!-- Add design ideas here -->

---

## Removed Systems

The following systems were removed to simplify the core experience:

- **XP/Leveling**: No in-run progression
- **Power Selection**: No card choices on level-up
- **Burn DoT**: No fire damage over time
- **Pierce**: Projectiles don't pass through enemies
- **Ricochet**: Projectiles don't bounce between enemies
- **Multishot**: Single projectile per shot
