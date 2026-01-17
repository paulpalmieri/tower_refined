# Tower Idle Roguelite

A Vampire Survivors-style auto-shooting roguelite with a neon geometric aesthetic. Your turret auto-fires at waves of geometric enemies (triangles, squares, pentagons) while you unlock abilities and upgrades through a skill tree.

**Core Fantasy:** "I am an immovable force. Enemies pour in and disintegrate before reaching me."

## Features

- Auto-targeting turret with satisfying projectile feedback
- Five enemy types: Basic (triangle), Fast (square), Tank (pentagon), Brute (hexagon), Elite (heptagon)
- Neon geometric visual style with post-processing effects (bloom, CRT scanlines, chromatic aberration)
- Skill tree progression system with persistent unlocks
- Special abilities: Laser Beam, Plasma Missile, Shield, Drones, Missile Silos
- Screen shake, knockback, and damage numbers for game feel

## Requirements

- [LOVE2D](https://love2d.org/) (latest stable version)

## Installation

```bash
git clone <repo-url>
cd tower_refined
love .
```

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
| `G` | Toggle god mode |
| `F3` | Toggle debug overlay |
| `` ` `` | Toggle debug console |

## Project Structure

```
tower_refined/
├── main.lua                    # Entry point and game loop
├── conf.lua                    # LOVE2D window config
├── src/
│   ├── config.lua              # All tuning constants
│   ├── audio.lua               # Sound effects system
│   ├── camera.lua              # Camera and screen shake
│   ├── debris_manager.lua      # Visual debris and particles
│   ├── debug_console.lua       # Runtime debug console
│   ├── feedback.lua            # Screen shake and hit-stop
│   ├── intro.lua               # Intro sequence
│   ├── lighting.lua            # Additive glow lights
│   ├── postfx.lua              # Post-processing effects
│   ├── settings_menu.lua       # Settings UI
│   ├── composite_templates.lua # Composite enemy definitions
│   ├── entities/
│   │   ├── enemy.lua           # Base enemy entity
│   │   ├── composite_enemy.lua # Hierarchical composite enemies
│   │   ├── turret.lua          # Tower entity
│   │   ├── projectile.lua      # Bullet entity
│   │   ├── missile.lua         # Homing missiles
│   │   ├── drone.lua           # Orbiting collector drones
│   │   ├── shield.lua          # Protective shield
│   │   ├── silo.lua            # Missile silos
│   │   ├── particle.lua        # Short-lived particles
│   │   ├── chunk.lua           # Persistent debris
│   │   ├── flying_part.lua     # Detached enemy parts
│   │   ├── collectible_shard.lua # Polygon currency drops
│   │   └── damagenumber.lua    # Floating damage text
│   └── skilltree/
│       ├── init.lua            # Skill tree main module
│       ├── node.lua            # Skill node class
│       ├── node_data.lua       # Skill definitions
│       ├── transition.lua      # Screen transitions
│       └── canvas.lua          # Skill tree rendering
├── assets/                     # Sound effects and fonts
└── lib/
    ├── classic.lua             # OOP library
    └── lume.lua                # Utility functions
```

## Development

```bash
# Run the game
love .

# Lint code (requires luacheck)
luacheck .
```

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.

## License

MIT
