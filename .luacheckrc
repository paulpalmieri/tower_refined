-- .luacheckrc
-- Luacheck configuration for Tower Idle Roguelite (Love2D)

-- Use Love2D standard library definitions
std = "lua51+love"

-- Maximum line length (0 = unlimited)
max_line_length = false

-- Ignore certain warnings globally
ignore = {
    "212",  -- Unused argument (common in Love2D callbacks)
    "213",  -- Unused loop variable
    "611",  -- Line contains only whitespace
    "612",  -- Line contains trailing whitespace
    "613",  -- Trailing whitespace in string
    "631",  -- Line too long
}

-- Project globals (read-write)
globals = {
    -- OOP from classic.lua
    "Object",

    -- Utility libraries
    "lume",

    -- Game classes (defined globally)
    "Enemy",
    "Turret",
    "Projectile",
    "Particle",
    "DamageNumber",
    "Chunk",
    "Sounds",
    "Feedback",
    "DebrisManager",
    "Lighting",
    "DebugConsole",

    -- Global functions
    "spawnParticle",
    "spawnChunk",
    "spawnDust",

    -- Game state
    "tower",
    "enemies",
    "projectiles",
    "particles",
    "damageNumbers",
    "chunks",
    "dustParticles",
    "gameTime",
    "currentSpawnRate",
    "totalGold",
    "totalKills",
    "gameSpeedIndex",
    "startNewRun",
    "activateNuke",

    -- Window constants
    "WINDOW_WIDTH",
    "WINDOW_HEIGHT",
    "CENTER_X",
    "CENTER_Y",

    -- Tower constants
    "TOWER_HP",
    "TOWER_FIRE_RATE",
    "PROJECTILE_SPEED",
    "PROJECTILE_DAMAGE",

    -- Enemy constants
    "BASIC_HP",
    "BASIC_SPEED",
    "FAST_HP",
    "FAST_SPEED",
    "TANK_HP",
    "TANK_SPEED",

    -- Visual grounding
    "SHADOW_OFFSET_X",
    "SHADOW_OFFSET_Y",
    "SHADOW_ALPHA",
    "BOB_AMPLITUDE",
    "SWAY_AMPLITUDE",
    "SPAWN_LAND_DURATION",
    "SPAWN_LAND_SCALE",
    "SPAWN_LAND_ALPHA",

    -- Spawning distance
    "SPAWN_DISTANCE",

    -- Lighting system
    "VIGNETTE_STRENGTH",
    "VIGNETTE_START",
    "VIGNETTE_FALLOFF",
    "PROJECTILE_LIGHT_RADIUS",
    "PROJECTILE_LIGHT_INTENSITY",
    "PROJECTILE_LIGHT_COLOR",
    "MUZZLE_FLASH_RADIUS",
    "MUZZLE_FLASH_INTENSITY",
    "MUZZLE_FLASH_DURATION",
    "MUZZLE_FLASH_COLOR",
    "EYE_LIGHT_RADIUS",
    "EYE_LIGHT_INTENSITY",
    "EYE_LIGHT_COLOR",
    "EYE_LIGHT_FLICKER",
    "EYE_LIGHT_VARIANCE",
    "ENEMY_GLOW_RADIUS",
    "ENEMY_GLOW_INTENSITY",
    "ENEMY_GLOW_FLICKER",
    "ENEMY_SHADE_CONTRAST",
    "ENEMY_SHADE_HIGHLIGHT",
    "TOWER_LIGHT_RADIUS",
    "TOWER_LIGHT_INTENSITY",
    "TOWER_LIGHT_COLOR",
    "TOWER_LIGHT_PULSE_SPEED",
    "TOWER_LIGHT_PULSE_AMOUNT",
    "NUKE_LIGHT_RADIUS",
    "NUKE_LIGHT_INTENSITY",
    "NUKE_LIGHT_COLOR",
    "SHADOW_MAX_OFFSET",
    "SHADOW_BASE_ALPHA",
    "SHADOW_GLOBAL_ANGLE",
    "LIGHTING_CIRCLE_SEGMENTS",
    "LIGHTING_MIN_INTENSITY",

    -- Chaos
    "SPEED_VARIATION",

    -- Animation
    "ANIM_SPEED_SCALE",

    -- Dust particles
    "DUST_SPAWN_CHANCE",
    "DUST_FADE_TIME",
    "DUST_SPEED",
    "DUST_COUNT",
    "DUST_SIZE_MIN",
    "DUST_SIZE_MAX",

    -- Knockback
    "KNOCKBACK_FORCE",
    "KNOCKBACK_DURATION",

    -- Spawning
    "SPAWN_RATE",
    "MAX_ENEMIES",
    "SPAWN_RATE_INCREASE",

    -- Blob appearance
    "BLOB_PIXEL_SIZE",

    -- Hit feedback
    "BLOB_FLASH_DURATION",

    -- Particle physics
    "LIMB_VELOCITY_RATIO",
    "DEATH_BURST_RATIO",
    "PIXEL_FADE_TIME",
    "CHUNK_FRICTION",

    -- Screen shake
    "SCREEN_SHAKE_INTENSITY",
    "SCREEN_SHAKE_ON_HIT",
    "SCREEN_SHAKE_DURATION",

    -- Damage numbers
    "DAMAGE_NUMBER_RISE_SPEED",
    "DAMAGE_NUMBER_FADE_TIME",

    -- Dead limb colors
    "CORPSE_DESATURATION",
    "CORPSE_DARKENING",
    "CORPSE_BLUE_TINT",

    -- Limb chunks
    "MIN_CHUNK_PIXELS",
    "CHUNK_SHAPE_IRREGULARITY",
    "CHUNK_NEIGHBOR_WEIGHT",

    -- Collision
    "ENEMY_CONTACT_DAMAGE",
    "TOWER_PAD_SIZE",

    -- Active skill
    "NUKE_DAMAGE",
    "NUKE_RADIUS",
    "NUKE_COOLDOWN",

    -- Gold
    "GOLD_PER_KILL",

    -- Game speed
    "GAME_SPEEDS",

    -- Turret visual
    "TURRET_SCALE",
    "TURRET_ROTATION_SPEED",
    "GUN_KICK_AMOUNT",
    "GUN_KICK_DECAY",

    -- Sound
    "SOUND_SHOOT_VOLUME",

    -- Dismemberment thresholds
    "DISMEMBER_THRESHOLDS",
    "MINOR_SPATTER_THRESHOLD",

    -- Blood trail settings
    "BLOOD_TRAIL_INTERVAL",
    "BLOOD_TRAIL_INTENSITY",
    "BLOOD_TRAIL_SIZE_MIN",
    "BLOOD_TRAIL_SIZE_MAX",

    -- Chunk settle timing
    "CHUNK_SETTLE_DELAY",
    "CHUNK_SETTLE_VELOCITY",

    -- Scope cursor (manual aiming mode)
    "SCOPE_INNER_RADIUS",
    "SCOPE_OUTER_RADIUS",
    "SCOPE_GAP",
    "SCOPE_LINE_LENGTH",
    "SCOPE_COLOR",
}

-- Exclude library files from linting
exclude_files = {
    "lib/*",
}
