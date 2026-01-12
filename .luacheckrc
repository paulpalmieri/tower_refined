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

    -- Global functions
    "spawnParticle",
    "spawnChunk",
    "spawnDust",
    "triggerScreenShake",

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
    "SPAWN_LAND_DURATION",
    "SPAWN_LAND_SCALE",
    "SPAWN_LAND_ALPHA",

    -- Chaos
    "SPEED_VARIATION",

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
    "PIXEL_SCATTER_VELOCITY",
    "DEATH_BURST_VELOCITY",
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
    "ENEMY_CONTACT_RADIUS",

    -- Active skill
    "NUKE_DAMAGE",
    "NUKE_RADIUS",
    "NUKE_COOLDOWN",

    -- Game speed
    "GAME_SPEEDS",

    -- Turret visual
    "TURRET_SCALE",
    "GUN_KICK_AMOUNT",
    "GUN_KICK_DECAY",

    -- Sound
    "SOUND_SHOOT_VOLUME",
}

-- Exclude library files from linting
exclude_files = {
    "lib/*",
}
