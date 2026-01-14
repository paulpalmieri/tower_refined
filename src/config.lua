-- src/config.lua
-- All game tuning constants

-- ===================
-- WINDOW
-- ===================
WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600
CENTER_X = WINDOW_WIDTH / 2
CENTER_Y = WINDOW_HEIGHT / 2

-- Scaling system (for fullscreen/resolution independence)
-- These are updated at runtime in main.lua
SCALE_X = 1
SCALE_Y = 1
SCALE = 1  -- Uniform scale (uses the smaller of X/Y to maintain aspect ratio)
OFFSET_X = 0  -- Letterbox/pillarbox offset
OFFSET_Y = 0

-- ===================
-- NEON COLOR PALETTE
-- ===================
NEON_PRIMARY = {0.00, 1.00, 0.00}
NEON_PRIMARY_DIM = {0.00, 0.60, 0.00}
NEON_CYAN = {0.00, 0.90, 0.90}
NEON_YELLOW = {0.90, 0.90, 0.00}
NEON_RED = {0.90, 0.20, 0.20}
NEON_BACKGROUND = {0.05, 0.01, 0.03}
NEON_GRID = {0.00, 0.15, 0.00}

-- Grid settings
GRID_SIZE = 40
GRID_LINE_WIDTH = 1

-- ===================
-- TOWER
-- ===================
TOWER_HP = 100
TOWER_FIRE_RATE = 0.2
PROJECTILE_SPEED = 700
PROJECTILE_DAMAGE = 1

-- ===================
-- ENEMY SHAPES (vertices normalized, pointing up)
-- ===================
ENEMY_SHAPES = {
    triangle = {
        {0, -1},
        {-0.866, 0.5},
        {0.866, 0.5},
    },
    square = {
        {-0.707, -0.707},
        {0.707, -0.707},
        {0.707, 0.707},
        {-0.707, 0.707},
    },
    pentagon = {
        {0, -1},
        {0.951, -0.309},
        {0.588, 0.809},
        {-0.588, 0.809},
        {-0.951, -0.309},
    },
}

-- ===================
-- ENEMY TYPES
-- ===================
ENEMY_TYPES = {
    basic = {
        shape = "triangle",
        -- hp calculated from shape: 1 + sides
        speed = 55,
        scale = 1.0,
        baseSize = 18,
        color = {1.00, 0.00, 0.00},  -- Red
    },
    fast = {
        shape = "square",
        -- hp calculated from shape: 1 + sides
        speed = 100,
        scale = 0.8,
        baseSize = 14,
        color = {0.00, 1.00, 1.00},  -- Cyan
    },
    tank = {
        shape = "pentagon",
        -- hp calculated from shape: 1 + sides
        speed = 35,
        scale = 1.4,
        baseSize = 24,
        color = {1.00, 1.00, 0.00},  -- Yellow
    },
}

SPEED_VARIATION = 0.15

-- ===================
-- LIGHTING
-- ===================
-- Projectile lights
PROJECTILE_LIGHT_RADIUS = 22
PROJECTILE_LIGHT_INTENSITY = 0.6
PROJECTILE_LIGHT_COLOR = {0.2, 1, 0.4}

-- Muzzle flash
MUZZLE_FLASH_RADIUS = 40
MUZZLE_FLASH_INTENSITY = 1.0
MUZZLE_FLASH_DURATION = 0.06
MUZZLE_FLASH_COLOR = {0.4, 1, 0.6}

-- Tower glow
TOWER_LIGHT_RADIUS = 120
TOWER_LIGHT_INTENSITY = 0.3
TOWER_LIGHT_COLOR = {0.1, 0.5, 0.2}
TOWER_LIGHT_PULSE_SPEED = 2.0
TOWER_LIGHT_PULSE_AMOUNT = 0.2

-- ===================
-- KNOCKBACK (Dynamic)
-- ===================
KNOCKBACK_BASE_FORCE = 800        -- Baseline knockback at 1x velocity, 1x damage
KNOCKBACK_VELOCITY_SCALE = 1.0    -- Linear velocity scaling (velocity-focused)
KNOCKBACK_DAMAGE_SCALE = 0.3      -- Reduced damage scaling (velocity-focused)
KNOCKBACK_MAX_MULTIPLIER = 3.0    -- Cap to prevent absurd knockback
KNOCKBACK_DURATION = 0.5

-- ===================
-- SPAWNING
-- ===================
SPAWN_RATE = 1.5
MAX_ENEMIES = 40
SPAWN_RATE_INCREASE = 0.08
SPAWN_DISTANCE = 500

-- ===================
-- HIT FEEDBACK
-- ===================
BLOB_FLASH_DURATION = 0.05
BLOB_PIXEL_SIZE = 3

-- ===================
-- PARTS SYSTEM (breakable sides)
-- ===================
PART_FLY_SPEED = 250               -- Base velocity when part flies off
PART_FLY_SPEED_INHERIT = 0.4       -- How much bullet velocity transfers to part
PART_SPIN_SPEED_MIN = 5            -- Minimum rotation speed (radians/sec)
PART_SPIN_SPEED_MAX = 12           -- Maximum rotation speed (radians/sec)
PART_SETTLE_TIME = 1.5             -- Seconds before part starts fading
PART_FADE_DURATION = 10.0          -- Seconds to fully fade out
PART_FRICTION = 20.0               -- Friction coefficient for flying parts
PART_SETTLE_VELOCITY = 25          -- Speed threshold to consider settled
GAP_DAMAGE_BONUS = 1.5             -- 50% bonus when bullet passes through gap
PART_FLASH_DURATION = 0.08         -- Duration of side flash on hit
CORE_FLASH_DURATION = 0.12         -- Duration of core flash on gap hit

-- Impact stagger (when parts break off)
IMPACT_SPIN_INCREASE_MIN = 1.5     -- Min rotation speed added per part lost (rad/s)
IMPACT_SPIN_INCREASE_MAX = 3.0     -- Max rotation speed added per part lost (rad/s)
IMPACT_DISPLACEMENT = 8            -- Random displacement distance when part lost

-- ===================
-- IMPACT EFFECTS (Dynamic)
-- ===================
IMPACT_BASE_INTENSITY = 0.5       -- Baseline particle intensity
IMPACT_VELOCITY_SCALE = 0.7       -- Strong velocity contribution (velocity-focused)
IMPACT_DAMAGE_SCALE = 0.3         -- Weaker damage contribution (velocity-focused)
IMPACT_MAX_INTENSITY = 1.5        -- Cap intensity

-- ===================
-- DEATH EXPLOSION (Dynamic)
-- ===================
EXPLOSION_BASE_VELOCITY = 150     -- Base velocity for death fragments
EXPLOSION_VELOCITY_INHERIT = 0.4  -- How much bullet velocity transfers to explosion
EXPLOSION_MAX_VELOCITY = 350      -- Cap explosion velocity

-- ===================
-- CHUNK PHYSICS
-- ===================
CHUNK_FRICTION = 25.0
CHUNK_SETTLE_DELAY = 0.15
CHUNK_SETTLE_VELOCITY = 30
BLOOD_TRAIL_INTERVAL = 0.05

-- Corpse appearance
CORPSE_DESATURATION = 0.7
CORPSE_DARKENING = 0.4

-- ===================
-- COLLISION
-- ===================
ENEMY_CONTACT_DAMAGE = 10
TOWER_PAD_SIZE = 16

-- ===================
-- LASER BEAM
-- ===================
LASER_DEPLOY_TIME = 1.2      -- Side cannons slide in (slower for drama)
LASER_CHARGE_TIME = 0.8      -- Charging phase (fast buildup)
LASER_FIRE_TIME = 5.0        -- Firing duration (seconds)
LASER_RETRACT_TIME = 0.3     -- Side cannons retract (seconds)
LASER_DAMAGE_PER_SEC = 10    -- DPS to enemies in beam
LASER_BEAM_LENGTH = 600      -- How far the beam reaches
LASER_BEAM_WIDTH = 46        -- Beam width (matches 3 barrels: 14+2+14+2+14)

-- ===================
-- PLASMA MISSILE
-- ===================
PLASMA_CHARGE_TIME = 1.5     -- Windup time (seconds)
PLASMA_COOLDOWN_TIME = 5.0   -- Cooldown after firing (seconds)
PLASMA_DAMAGE = 10           -- Damage per enemy hit (piercing)
PLASMA_MISSILE_SPEED = 500   -- Slower than bullets for dramatic effect
PLASMA_MISSILE_SIZE = 15     -- ~3x normal bullet size (5*3)
PLASMA_COLOR = {0.8, 0.2, 1.0}       -- Purple
PLASMA_CORE_COLOR = {1.0, 0.8, 1.0}  -- White-purple hot core
PLASMA_LIGHT_RADIUS = 120    -- Large glow radius
PLASMA_LIGHT_INTENSITY = 1.0 -- Intense glow
PLASMA_SOUND_VOLUME = 0.3    -- Firing sound volume

-- ===================
-- GOLD
-- ===================
GOLD_PER_KILL = 1

-- ===================
-- POLYGONS CURRENCY
-- ===================
POLYGON_COLOR = {0.7, 0.2, 1.0}       -- Purple
POLYGON_BASE_GLOW = 0.6               -- Default glow intensity
POLYGON_HOVER_GLOW = 1.0              -- Glow when hovered
POLYGON_PULSE_SPEED = 3.0             -- Pulse animation speed
POLYGON_PULSE_AMOUNT = 0.1            -- Pulse size variation (10%)
POLYGON_MAGNET_TIME = 0.7             -- Seconds to attract to turret
POLYGON_LIGHT_RADIUS = 40             -- Glow light radius
POLYGON_LIGHT_INTENSITY = 0.5         -- Glow light intensity
POLYGON_EJECT_SPEED = 150             -- Speed shard ejects from enemy
POLYGON_EJECT_FRICTION = 3.0          -- How quickly ejected shard slows down
POLYGON_FRAGMENT_SIZE_RATIO = 0.5     -- Fragment size relative to parent
POLYGON_FRAGMENT_SPREAD = 0.8         -- Angle spread when shattering (radians)
POLYGON_PICKUP_RADIUS_BASE = 80       -- Base magnetic collection radius
POLYGON_CLUSTER_SHARD_SIZE = 8        -- Size of individual shards in cluster
POLYGON_CLUSTER_SPREAD = 20           -- Spread radius for cluster spawn

-- ===================
-- GAME SPEED
-- ===================
GAME_SPEEDS = {0, 0.1, 0.5, 1, 3, 5}

-- ===================
-- TURRET VISUAL
-- ===================
TURRET_SCALE = 1.0
TURRET_ROTATION_SPEED = 50.0
GUN_KICK_AMOUNT = 4
GUN_KICK_DECAY = 25

-- ===================
-- DRONE SYSTEM
-- ===================
DRONE_BASE_FIRE_RATE = 0.5        -- Seconds between shots
DRONE_PROJECTILE_SPEED = 560      -- 0.8x normal projectile speed
DRONE_ROTATION_SPEED = 15.0       -- Slightly slower than turret

-- Drone light
DRONE_LIGHT_RADIUS = 30
DRONE_LIGHT_INTENSITY = 0.4
DRONE_COLOR = {0.70, 0.20, 1.00}  -- Purple (same as POLYGON_COLOR)

-- ===================
-- SOUND
-- ===================
SOUND_SHOOT_VOLUME = 0.3

-- ===================
-- DAMAGE NUMBERS
-- ===================
DAMAGE_NUMBER_RISE_SPEED = 40
DAMAGE_NUMBER_FADE_TIME = 0.6

-- ===================
-- DUST PARTICLES
-- ===================
DUST_SPAWN_CHANCE = 1.0
DUST_FADE_TIME = 0.6
DUST_SPEED = 40
DUST_COUNT = 3
DUST_SIZE_MIN = 2
DUST_SIZE_MAX = 4

-- ===================
-- CROSSHAIR
-- ===================
CROSSHAIR_GAP = 6        -- Gap from center (pixels)
CROSSHAIR_LENGTH = 12    -- Length of each arm (pixels)
CROSSHAIR_THICKNESS = 3  -- Line thickness (pixels)
CROSSHAIR_COLOR = {0, 1, 0.3, 0.9}  -- Neon green
CROSSHAIR_GLOW_LAYERS = 4   -- Number of bloom layers
CROSSHAIR_GLOW_SPREAD = 3   -- Pixel spread per layer

-- ===================
-- FONT
-- ===================
FONT_PATH = "assets/m5x7.ttf"
FONT_SIZE = 16

-- ===================
-- POST-PROCESSING
-- ===================
-- Chromatic Aberration (applied to gameplay only)
CHROMATIC_ABERRATION_ENABLED = true
CHROMATIC_ABERRATION_AMOUNT = 2.0   -- Pixel offset for RGB split
CHROMATIC_ABERRATION_FALLOFF = 0.5  -- Edge-weighted falloff (0=uniform, 1=edges only)

-- Bloom settings
BLOOM_ENABLED = true
BLOOM_SCALE = 3                     -- Downsample factor (lower = higher quality, more expensive)
BLOOM_INTENSITY = 1.5               -- How much bloom to add (0-2 range typical)
BLOOM_BLUR_PASSES = 4               -- Number of blur iterations (more = softer, wider glow)
BLOOM_THRESHOLD = 0.15              -- Brightness threshold (0=bloom everything, 1=only pure white)
BLOOM_SOFT_THRESHOLD = 0.6          -- Softness of threshold transition (0=hard cutoff, 1=very soft)

-- CRT filter (retro monitor effect)
CRT_ENABLED = true
CRT_SCANLINE_INTENSITY = 0.15       -- Darkness of scanlines (0-1, subtle: 0.1-0.2)
CRT_SCANLINE_COUNT = 240            -- Number of scanlines (lower = thicker lines)
CRT_CURVATURE = 0.03                -- Screen curvature amount (0 = flat, 0.05 = subtle curve)
CRT_VIGNETTE = 0.15                 -- Corner darkening from curvature (0-1)

-- Glitch effect (always-on subtle digital noise)
GLITCH_ENABLED = true
GLITCH_INTENSITY = 0.3              -- Overall glitch amount (0-1)
GLITCH_SCANLINE_JITTER = 8.0        -- Horizontal pixel displacement for jittery lines

-- Heat distortion (always-on heat haze)
HEAT_DISTORTION_ENABLED = true
HEAT_DISTORTION_INTENSITY = 0.15    -- Wave amplitude (keep subtle: 0.1-0.3)
HEAT_DISTORTION_FREQUENCY = 8.0     -- Wave frequency (higher = more ripples)
HEAT_DISTORTION_SPEED = 1.5         -- Animation speed

-- ===================
-- SHIELD
-- ===================
SHIELD_BASE_RADIUS = 80              -- Base radius when unlocked
SHIELD_PULSE_SPEED = 2.0             -- Idle pulse speed
SHIELD_PULSE_AMOUNT = 0.05           -- Pulse size variation (5%)
SHIELD_HIT_FLASH_DURATION = 0.12     -- White flash on kill
SHIELD_HIT_PULSE_AMOUNT = 12         -- Radius expansion on kill
SHIELD_HIT_PULSE_DECAY = 80          -- How fast pulse shrinks back

-- Shield colors (blue-to-green gradient)
SHIELD_COLOR_OUTER = {0.2, 0.5, 1.0}   -- Blue outer glow
SHIELD_COLOR_MID = {0.1, 0.8, 0.9}     -- Cyan transition
SHIELD_COLOR_INNER = {0.2, 1.0, 0.5}   -- Green core
SHIELD_COLOR_FILL = {0.1, 0.6, 0.4}    -- Subtle inner fill

-- ===================
-- MISSILE SILO SYSTEM
-- ===================
-- Silo placement
SILO_ORBIT_RADIUS = 55           -- Distance from turret center (just outside base radius 35)
SILO_SIZE = 16                   -- Silo diameter
SILO_HATCH_GAP = 2               -- Gap when hatch fully opens

-- Silo timing
SILO_BASE_FIRE_RATE = 2.0        -- Seconds between missile launches per silo
SILO_HATCH_OPEN_TIME = 0.15      -- Time to open hatch
SILO_HATCH_CLOSE_TIME = 0.2      -- Time to close hatch after firing
SILO_FIRE_DELAY = 0.05           -- Delay after hatch opens before missile launches

-- Missile properties
MISSILE_SPEED = 250              -- Base missile speed
MISSILE_TURN_RATE = 4.0          -- Radians per second (moderate homing)
MISSILE_DAMAGE = 1               -- Damage on impact
MISSILE_SIZE = 6                 -- Missile body size
MISSILE_TRAIL_LENGTH = 10        -- Trail segments

-- Missile colors (orange theme)
MISSILE_COLOR = {1.0, 0.6, 0.1}         -- Bright orange
MISSILE_CORE_COLOR = {1.0, 0.9, 0.7}    -- White-orange hot core
MISSILE_TRAIL_COLOR = {1.0, 0.5, 0.0}   -- Orange trail

-- Silo colors (orange theme)
SILO_COLOR = {1.0, 0.6, 0.1}            -- Bright orange border
SILO_FILL_COLOR = {0.2, 0.12, 0.02}     -- Dark orange fill
SILO_GLOW_COLOR = {1.0, 0.6, 0.1, 0.3}  -- Orange glow

-- Missile light
MISSILE_LIGHT_RADIUS = 25
MISSILE_LIGHT_INTENSITY = 0.5

-- Missile explosion
MISSILE_EXPLOSION_PARTICLES = 8
MISSILE_EXPLOSION_VELOCITY = 200
