-- src/config.lua
-- All game tuning constants in one place
-- Currently exports as globals for backward compatibility

-- ===================
-- WINDOW
-- ===================
WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600
CENTER_X = WINDOW_WIDTH / 2
CENTER_Y = WINDOW_HEIGHT / 2

-- ===================
-- TOWER
-- ===================
TOWER_HP = 100
TOWER_FIRE_RATE = 0.3          -- Seconds between shots
PROJECTILE_SPEED = 500
PROJECTILE_DAMAGE = 1

-- ===================
-- ENEMIES
-- ===================
BASIC_HP = 10
BASIC_SPEED = 45
FAST_HP = 5
FAST_SPEED = 100
TANK_HP = 25
TANK_SPEED = 25

-- ===================
-- VISUAL GROUNDING
-- ===================
SHADOW_OFFSET_X = 2              -- Light from upper-left
SHADOW_OFFSET_Y = 3
SHADOW_ALPHA = 0.3
BOB_AMPLITUDE = 1.5              -- Pixels of vertical bob
SPAWN_LAND_DURATION = 0.25       -- Landing animation time
SPAWN_LAND_SCALE = 1.5           -- Start bigger, shrink to normal
SPAWN_LAND_ALPHA = 0.3           -- Start transparent

-- ===================
-- CHAOS
-- ===================
SPEED_VARIATION = 0.15           -- +/- speed variance per enemy

-- ===================
-- DUST PARTICLES
-- ===================
DUST_SPAWN_CHANCE = 1.0          -- Chance to spawn dust on footstep
DUST_FADE_TIME = 0.6             -- How long dust lingers
DUST_SPEED = 40                  -- Dust drift speed
DUST_COUNT = 3                   -- Particles per footstep
DUST_SIZE_MIN = 2                -- Min particle size
DUST_SIZE_MAX = 4                -- Max particle size

-- ===================
-- KNOCKBACK
-- ===================
KNOCKBACK_FORCE = 120
KNOCKBACK_DURATION = 0.12

-- ===================
-- SPAWNING (continuous)
-- ===================
SPAWN_RATE = 1.5           -- Base enemies per second
MAX_ENEMIES = 40           -- Cap on screen
SPAWN_RATE_INCREASE = 0.08 -- Increase per second of game time

-- ===================
-- BLOB APPEARANCE
-- ===================
BLOB_PIXEL_SIZE = 3            -- Screen pixels per blob "cell"

-- ===================
-- HIT FEEDBACK
-- ===================
BLOB_FLASH_DURATION = 0.05

-- ===================
-- PARTICLE PHYSICS
-- ===================
PIXEL_SCATTER_VELOCITY = 350      -- Fast initial launch for limbs
DEATH_BURST_VELOCITY = 450        -- Even faster on death
PIXEL_FADE_TIME = 0.4             -- Blood fades faster
CHUNK_FRICTION = 12.0             -- High friction = fast settle

-- ===================
-- SCREEN SHAKE
-- ===================
SCREEN_SHAKE_INTENSITY = 5
SCREEN_SHAKE_ON_HIT = 1.5
SCREEN_SHAKE_DURATION = 0.12

-- ===================
-- DAMAGE NUMBERS
-- ===================
DAMAGE_NUMBER_RISE_SPEED = 40
DAMAGE_NUMBER_FADE_TIME = 0.6

-- ===================
-- DEAD LIMB COLORS (for settled chunks)
-- ===================
CORPSE_DESATURATION = 0.7      -- 0=full color, 1=grayscale
CORPSE_DARKENING = 0.4         -- 1=bright, 0=black
CORPSE_BLUE_TINT = 0.1         -- Slight ghostly blue/purple shift

-- ===================
-- LIMB CHUNK SETTINGS
-- ===================
MIN_CHUNK_PIXELS = 9                 -- Minimum pixels per limb (~3x3 equivalent)
CHUNK_SHAPE_IRREGULARITY = 0.35      -- 0=tight clusters, 1=very irregular
CHUNK_NEIGHBOR_WEIGHT = 2.0          -- Priority for adjacent pixels (organic clumping)

-- ===================
-- COLLISION
-- ===================
ENEMY_CONTACT_DAMAGE = 10
ENEMY_CONTACT_RADIUS = 30

-- ===================
-- ACTIVE SKILL (Nuke)
-- ===================
NUKE_DAMAGE = 50
NUKE_RADIUS = 150
NUKE_COOLDOWN = 10.0

-- ===================
-- GAME SPEED
-- ===================
GAME_SPEEDS = {1, 3, 5}

-- ===================
-- TURRET VISUAL
-- ===================
TURRET_SCALE = 1.5                -- Overall turret size
GUN_KICK_AMOUNT = 4               -- Recoil distance in pixels
GUN_KICK_DECAY = 25               -- Recoil recovery speed

-- ===================
-- SOUND
-- ===================
SOUND_SHOOT_VOLUME = 0.5
