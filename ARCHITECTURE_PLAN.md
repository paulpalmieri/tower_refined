# Architecture Plan

**Last Updated:** January 18, 2026

---

## Current State

The codebase has been through two major refactoring phases:

### Phase 1: Manager Extraction (Completed)
- Extracted EntityManager, CollisionManager, SpawnManager, AbilityManager
- Extracted LaserSystem, PlasmaSystem, GameOverSystem state machines
- Extracted HUD rendering
- Added EventBus for entity decoupling
- **Result:** main.lua reduced from ~3,000 to ~1,800 lines (40% reduction)

### Phase 2: Cleanup (Completed January 2026)
- Removed luacheck linter (556 globals were unmanageable)
- Deleted debug_console.lua (1,013 lines) — replaced with `tweaks.lua` hot-reload
- Removed unused config constants
- Simplified EntityManager (189 → 89 lines)
- Simplified EventBus (89 → 48 lines)
- Updated CLAUDE.md for LLM clarity

---

## Current File Sizes

| File | Lines | Notes |
|------|-------|-------|
| main.lua | ~1,750 | Acceptable size |
| composite_enemy.lua | ~770 | Complex feature, justified |
| enemy.lua | ~725 | Core gameplay, could split attacks |
| skilltree/init.lua | ~943 | Large but feature-complete |
| collision_manager.lua | ~566 | 10 collision types |
| turret.lua | ~500 | Player entity |
| debris_manager.lua | ~491 | Many spawn methods |
| config.lua | ~570 | All tuning constants |
| entity_manager.lua | 89 | Lean |
| event_bus.lua | 48 | Minimal |

---

## Architecture Decisions

### Why Globals?
Entity arrays (`enemies`, `projectiles`, etc.) are global for simplicity:
- Direct access from any module without import chains
- EntityManager syncs collections to `_G` automatically
- Trade-off: Less encapsulation, but easier to understand and modify

### Why No Linter?
- 556 globals made luacheck configuration unwieldy
- Every constant addition required `.luacheckrc` update
- LLMs can catch actual errors during code review
- Hot-reload tweaks system provides runtime validation

### Why Hot-Reload Tweaks Instead of Debug Console?
- Debug console was 1,013 lines of UI code
- `tweaks.lua` is a simple Lua table (readable, editable)
- F5 to reload is faster than UI interaction
- Same tuning capability, 95% less code

---

## Optional Future Improvements

These are **not necessary** — the codebase is production-ready. Only pursue if specific pain points emerge.

### Split Large Entity Files
If `enemy.lua` or `composite_enemy.lua` become hard to navigate:
- Extract attack patterns to `src/attacks/triangle_attack.lua`, etc.
- Extract visual/animation code to separate modules
- **Trigger:** When adding new enemy types becomes difficult

### Config Organization
If `config.lua` becomes hard to navigate:
```
src/config/
├── game.lua      (Tower, spawning, collision)
├── visual.lua    (Colors, sizes, animations)
├── enemies.lua   (ENEMY_TYPES, ENEMY_SHAPES, attacks)
├── abilities.lua (Laser, plasma, shield, drone, silo)
└── postfx.lua    (Bloom, CRT, glitch)
```
- **Trigger:** When finding constants becomes a bottleneck

### Event Consistency
Managers still directly call `Feedback:trigger()` and `DebrisManager:spawn*()`:
- Could convert to events for full decoupling
- Would enable testing managers in isolation
- **Trigger:** When unit testing becomes a priority

### Upgrade Objects Pattern
`Roguelite:applyUpgrade()` uses if-else chain:
```lua
if upgrade.id == "shield" then ...
elseif upgrade.id == "silo" then ...
```
Could use upgrade objects with `apply()` method:
```lua
function ShieldUpgrade:apply(stats)
    stats.shieldCharges = 2
end
```
- **Trigger:** When adding many new upgrades

---

## What NOT to Do

1. **Don't add abstractions without pain** — Current code is direct and readable
2. **Don't namespace constants** — `TOWER_HP` is clearer than `Config.Tower.HP`
3. **Don't add dependency injection** — Globals work fine for this project size
4. **Don't create interfaces/protocols** — Lua's duck typing is sufficient
5. **Don't split small files** — Aim for cohesion, not arbitrary line limits

---

## Development Workflow

1. Run `love .` to test
2. Edit `tweaks.lua` for tuning, press F5 to reload
3. Check CLAUDE.md for architecture guidance
4. Use EventBus for new cross-cutting concerns
5. Add constants to config.lua, not inline

---

## Summary

The architecture is **clean, simple, and LLM-friendly**:
- Files are reasonably sized (largest ~1,750 lines)
- Clear separation of concerns (managers, systems, entities)
- Minimal abstraction (globals, direct calls)
- Hot-reload for rapid iteration
- Documentation focused on practical patterns

**Status: Ready for feature development.**
