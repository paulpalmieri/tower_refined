# Tower Idle Roguelite

A single-tower idle roguelite where an auto-firing turret defends against waves of blob enemies.

## Features

- Auto-targeting turret with satisfying projectile feedback
- Three enemy types: Basic (swarm), Fast (pressure), Tank (threatening)
- Pixel-art enemies with destructible limbs and death bursts
- Level-up power selection (Ricochet, Multi-shot, Ignite)
- Meta-progression shop with tiered upgrades
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
| `1` | Activate Nuke (area damage) |
| `S` | Cycle game speed (1x/3x/5x) or open shop |
| `R` | Restart run |
| `ESC` | Quit |
| Arrow keys | Navigate menus |
| Enter/Space | Confirm selection |

## Project Structure

```
tower_refined/
├── main.lua              # Entry point and game loop
├── conf.lua              # LOVE2D window config
├── src/
│   ├── config.lua        # All tuning constants
│   ├── audio.lua         # Sound effects system
│   └── entities/
│       ├── blob.lua      # Enemy entity
│       ├── turret.lua    # Tower entity
│       ├── projectile.lua# Bullet entity
│       ├── particle.lua  # Blood spray particles
│       ├── chunk.lua     # Limb debris
│       └── damagenumber.lua # Floating damage text
├── assets/
│   └── gun_sound.mp3     # Shooting sound effect
└── lib/
    ├── classic.lua       # OOP library
    └── lume.lua          # Utility functions
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
