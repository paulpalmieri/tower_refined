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
    "Blob",
    "Turret",
    "Projectile",
    "Particle",
    "DamageNumber",
    "Chunk",
    "Debug",
    "Sounds",

    -- Global functions
    "spawnParticle",
    "spawnChunk",
    "spawnDust",
    "triggerScreenShake",
    "addXP",
    "syncTowerFromGlobals",

    -- Game state accessed by debug overlay
    "tower",
    "enemies",
    "projectiles",
    "particles",
    "damageNumbers",
    "chunks",
    "dustParticles",
    "gameTime",
    "currentSpawnRate",
    "level",
    "xp",
    "xpToNextLevel",
    "totalGold",
    "totalKills",
    "powers",
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

    -- Collision
    "SEPARATION_FORCE",
    "SEPARATION_RADIUS",

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

    -- Damage
    "CLICK_DAMAGE",
    "DAMAGE_PER_PIXEL",

    -- Hit feedback
    "BLOB_FLASH_DURATION",

    -- Particle physics
    "PIXEL_SCATTER_VELOCITY",
    "DEATH_BURST_VELOCITY",
    "PIXEL_FADE_TIME",
    "CHUNK_GRAVITY",
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

    -- Waves
    "WAVE_BASE_ENEMIES",
    "WAVE_ENEMY_INCREASE",
    "SPAWN_DELAY",

    -- Progression
    "XP_PER_ENEMY",
    "XP_TO_LEVEL_BASE",
    "XP_LEVEL_SCALE",
    "GOLD_PER_WAVE",

    -- Collision
    "ENEMY_CONTACT_DAMAGE",
    "ENEMY_CONTACT_RADIUS",

    -- Active skill
    "NUKE_DAMAGE",
    "NUKE_RADIUS",
    "NUKE_COOLDOWN",

    -- Fire/Burn effect
    "BURN_DAMAGE",
    "BURN_TICK_RATE",
    "BURN_DURATION",
    "BURN_STACK_MAX",

    -- Game speed
    "GAME_SPEEDS",

    -- Movement feel
    "MOVEMENT_JITTER_STRENGTH",
    "MOVEMENT_JITTER_FREQUENCY",
    "BOB_SQUASH_AMOUNT",

    -- Chaos behavior
    "BURST_CHANCE",
    "BURST_SPEED_MULT",
    "BURST_DURATION",

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
