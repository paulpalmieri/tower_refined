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
BASIC_SPEED = 55
FAST_HP = 5
FAST_SPEED = 100
TANK_HP = 25
TANK_SPEED = 35

-- ===================
-- VISUAL GROUNDING
-- ===================
SHADOW_OFFSET_X = 2              -- Light from upper-left
SHADOW_OFFSET_Y = 3
SHADOW_ALPHA = 0.3
BOB_AMPLITUDE = 1.5              -- Pixels of vertical bob
SWAY_AMPLITUDE = 1.2             -- Pixels of side-to-side sway (perpendicular to movement)
SPAWN_LAND_DURATION = 0.0        -- Landing animation disabled
SPAWN_LAND_SCALE = 1.0           -- No zoom effect
SPAWN_LAND_ALPHA = 1.0           -- No fade-in

-- ===================
-- SPAWNING DISTANCE
-- ===================
SPAWN_DISTANCE = 500             -- Spawn well outside screen

-- ===================
-- LIGHTING SYSTEM
-- ===================
-- Vignette (edge darkening)
VIGNETTE_STRENGTH = 0.3          -- Edge darkness (0=none, 1=black)
VIGNETTE_START = 0.6             -- Distance from center to start (0-1)
VIGNETTE_FALLOFF = 1.5           -- Sharpness of falloff

-- Projectile lights
PROJECTILE_LIGHT_RADIUS = 60
PROJECTILE_LIGHT_INTENSITY = 0.7
PROJECTILE_LIGHT_COLOR = {1, 0.9, 0.7}  -- Warm yellow

-- Muzzle flash
MUZZLE_FLASH_RADIUS = 40           -- Small, tight flash
MUZZLE_FLASH_INTENSITY = 1.0
MUZZLE_FLASH_DURATION = 0.06
MUZZLE_FLASH_COLOR = {1, 0.8, 0.4}  -- Warm yellow-orange

-- Eye glow (sprite edge glow, not point lights)
EYE_LIGHT_RADIUS = 8                -- Very small, just for shadow interaction
EYE_LIGHT_INTENSITY = 0.2           -- Subtle
EYE_LIGHT_COLOR = {1.0, 0.15, 0.05} -- Deep red (used for sprite outline glow)
EYE_LIGHT_FLICKER = 0.1
EYE_LIGHT_VARIANCE = 0.2            -- Per-enemy variation

-- Enemy body glow (subtle emanation of enemy color)
ENEMY_GLOW_RADIUS = 35              -- Soft halo around enemy
ENEMY_GLOW_INTENSITY = 0.25         -- Subtle, not overpowering
ENEMY_GLOW_FLICKER = 0.05           -- Very slight flicker for life

-- Enemy shading
ENEMY_SHADE_CONTRAST = 0.35         -- How much darker the bottom is (0=flat, 1=very dark)
ENEMY_SHADE_HIGHLIGHT = 0.15        -- How much brighter the top is

-- Tower base glow
TOWER_LIGHT_RADIUS = 120
TOWER_LIGHT_INTENSITY = 0.3
TOWER_LIGHT_COLOR = {0.4, 0.5, 0.6}  -- Cool blue-grey
TOWER_LIGHT_PULSE_SPEED = 2.0
TOWER_LIGHT_PULSE_AMOUNT = 0.2

-- Nuke light
NUKE_LIGHT_RADIUS = 300
NUKE_LIGHT_INTENSITY = 2.5
NUKE_LIGHT_COLOR = {1, 0.8, 0.3}

-- Shadow settings
SHADOW_MAX_OFFSET = 8
SHADOW_BASE_ALPHA = 0.35
SHADOW_GLOBAL_ANGLE = -0.7        -- Radians, fallback direction

-- Performance
LIGHTING_CIRCLE_SEGMENTS = 10
LIGHTING_MIN_INTENSITY = 0.05

-- ===================
-- CHAOS
-- ===================
SPEED_VARIATION = 0.15           -- +/- speed variance per enemy

-- ===================
-- ANIMATION
-- ===================
-- Animation speed scales with movement speed so legs match actual travel
-- Derived from fast enemies: animSpeed 1.5 at speed 100 feels good
ANIM_SPEED_SCALE = 0.007         -- animSpeed = speed * this value (slower walk cycle)

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
KNOCKBACK_FORCE = 500
KNOCKBACK_DURATION = 0.5

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
LIMB_VELOCITY_RATIO = 0.9         -- Limbs launch at 90% of bullet speed
DEATH_BURST_RATIO = 1.0           -- Death burst at 100% of bullet speed
PIXEL_FADE_TIME = 0.4             -- Blood fades faster
CHUNK_FRICTION = 25.0             -- Very high friction = "punch out then stick"

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
TOWER_PAD_SIZE = 16              -- Half-size in turret pixels (matches SUPPORT_SPRITE)
-- Actual collision box is TOWER_PAD_SIZE * BLOB_PIXEL_SIZE * TURRET_SCALE from center

-- ===================
-- ACTIVE SKILL (Nuke)
-- ===================
NUKE_DAMAGE = 50
NUKE_RADIUS = 150
NUKE_COOLDOWN = 10.0

-- ===================
-- GOLD
-- ===================
GOLD_PER_KILL = 1

-- ===================
-- GAME SPEED
-- ===================
GAME_SPEEDS = {1, 3, 5}

-- ===================
-- TURRET VISUAL
-- ===================
TURRET_SCALE = 1.0                -- Overall turret size (matches enemy pixel density)
TURRET_ROTATION_SPEED = 8.0       -- Radians per second (fast but visible rotation)
GUN_KICK_AMOUNT = 4               -- Recoil distance in pixels
GUN_KICK_DECAY = 25               -- Recoil recovery speed

-- ===================
-- SOUND
-- ===================
SOUND_SHOOT_VOLUME = 0.5

-- ===================
-- DISMEMBERMENT THRESHOLDS
-- ===================
DISMEMBER_THRESHOLDS = {0.75, 0.50, 0.25}  -- HP% that trigger limb ejection
MINOR_SPATTER_THRESHOLD = 0.10              -- Damage < 10% max_hp = minor spatter

-- ===================
-- BLOOD TRAIL SETTINGS
-- ===================
BLOOD_TRAIL_INTERVAL = 0.05       -- Spawn interval while chunk moving (seconds)
BLOOD_TRAIL_INTENSITY = 0.3       -- Particle count multiplier
BLOOD_TRAIL_SIZE_MIN = 1          -- Min blood particle size
BLOOD_TRAIL_SIZE_MAX = 2          -- Max blood particle size

-- ===================
-- CHUNK SETTLE TIMING
-- ===================
CHUNK_SETTLE_DELAY = 0.15         -- Delay after stopping before color fade
CHUNK_SETTLE_VELOCITY = 30        -- Velocity threshold to consider "stopped"

-- ===================
-- SCOPE CURSOR (Manual Aiming Mode)
-- ===================
SCOPE_INNER_RADIUS = 4
SCOPE_OUTER_RADIUS = 12
SCOPE_GAP = 3
SCOPE_LINE_LENGTH = 6
SCOPE_COLOR = {1, 0.3, 0.3, 0.8}  -- Red, semi-transparent
