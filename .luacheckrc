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
    "CollectibleShard",
    "FlyingPart",
    "Drone",
    "Sounds",
    "Feedback",
    "DebrisManager",
    "Lighting",
    "DebugConsole",
    "SkillTree",
    "Intro",

    -- Global functions
    "spawnParticle",
    "spawnChunk",
    "spawnDust",
    "spawnShardCluster",
    "spawnDamageNumber",

    -- Game state
    "tower",
    "enemies",
    "projectiles",
    "particles",
    "damageNumbers",
    "chunks",
    "flyingParts",
    "dustParticles",
    "gameTime",
    "currentSpawnRate",
    "totalGold",
    "polygons",
    "collectibleShards",
    "drones",
    "droneProjectiles",
    "totalKills",
    "gameSpeedIndex",
    "startNewRun",

    -- Window constants
    "WINDOW_WIDTH",
    "WINDOW_HEIGHT",
    "CENTER_X",
    "CENTER_Y",

    -- Neon color palette
    "NEON_PRIMARY",
    "NEON_PRIMARY_DIM",
    "NEON_PRIMARY_DARK",
    "NEON_WHITE",
    "NEON_CYAN",
    "NEON_YELLOW",
    "NEON_RED",
    "NEON_BACKGROUND",
    "NEON_GRID",
    "GRID_SIZE",
    "GRID_LINE_WIDTH",

    -- Tower constants
    "TOWER_HP",
    "TOWER_FIRE_RATE",
    "PROJECTILE_SPEED",
    "PROJECTILE_DAMAGE",

    -- Enemy definitions
    "ENEMY_SHAPES",
    "ENEMY_TYPES",

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
    "CORE_LIGHT_RADIUS",
    "CORE_LIGHT_INTENSITY",
    "CORE_LIGHT_COLOR",
    "CORE_LIGHT_FLICKER",
    "CORE_LIGHT_VARIANCE",
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

    -- Knockback (Dynamic)
    "KNOCKBACK_BASE_FORCE",
    "KNOCKBACK_VELOCITY_SCALE",
    "KNOCKBACK_DAMAGE_SCALE",
    "KNOCKBACK_MAX_MULTIPLIER",
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

    -- Active skill (Laser beam)
    "LASER_DEPLOY_TIME",
    "LASER_CHARGE_TIME",
    "LASER_FIRE_TIME",
    "LASER_RETRACT_TIME",
    "LASER_DAMAGE_PER_SEC",
    "LASER_BEAM_LENGTH",
    "LASER_BEAM_WIDTH",

    -- Active skill (Plasma missile)
    "PLASMA_CHARGE_TIME",
    "PLASMA_COOLDOWN_TIME",
    "PLASMA_DAMAGE",
    "PLASMA_MISSILE_SPEED",
    "PLASMA_MISSILE_SIZE",
    "PLASMA_COLOR",
    "PLASMA_CORE_COLOR",
    "PLASMA_LIGHT_RADIUS",
    "PLASMA_LIGHT_INTENSITY",
    "PLASMA_SOUND_VOLUME",

    -- Gold
    "GOLD_PER_KILL",

    -- Polygons currency
    "POLYGON_COLOR",
    "POLYGON_BASE_GLOW",
    "POLYGON_HOVER_GLOW",
    "POLYGON_PULSE_SPEED",
    "POLYGON_PULSE_AMOUNT",
    "POLYGON_MAGNET_TIME",
    "POLYGON_LIGHT_RADIUS",
    "POLYGON_LIGHT_INTENSITY",
    "POLYGON_EJECT_SPEED",
    "POLYGON_EJECT_FRICTION",
    "POLYGON_FRAGMENT_SIZE_RATIO",
    "POLYGON_FRAGMENT_SPREAD",
    "POLYGON_PICKUP_RADIUS_BASE",
    "POLYGON_CLUSTER_SHARD_SIZE",
    "POLYGON_CLUSTER_SPREAD",

    -- Drone system
    "DRONE_BASE_FIRE_RATE",
    "DRONE_PROJECTILE_SPEED",
    "DRONE_ROTATION_SPEED",
    "DRONE_LIGHT_RADIUS",
    "DRONE_LIGHT_INTENSITY",
    "DRONE_COLOR",

    -- Game speed
    "GAME_SPEEDS",

    -- Turret visual
    "TURRET_SCALE",
    "TURRET_ROTATION_SPEED",
    "GUN_KICK_AMOUNT",
    "GUN_KICK_DECAY",

    -- Sound
    "SOUND_SHOOT_VOLUME",

    -- Parts system (breakable sides)
    "PART_FLY_SPEED",
    "PART_FLY_SPEED_INHERIT",
    "PART_SPIN_SPEED_MIN",
    "PART_SPIN_SPEED_MAX",
    "PART_SETTLE_TIME",
    "PART_FADE_DURATION",
    "PART_FRICTION",
    "PART_SETTLE_VELOCITY",
    "GAP_DAMAGE_BONUS",
    "PART_FLASH_DURATION",
    "CORE_FLASH_DURATION",
    "IMPACT_SPIN_INCREASE_MIN",
    "IMPACT_SPIN_INCREASE_MAX",
    "IMPACT_DISPLACEMENT",

    -- Scaling (fullscreen/resolution)
    "SCALE_X",
    "SCALE_Y",
    "SCALE",
    "OFFSET_X",
    "OFFSET_Y",

    -- Impact effects (Dynamic)
    "IMPACT_BASE_INTENSITY",
    "IMPACT_VELOCITY_SCALE",
    "IMPACT_DAMAGE_SCALE",
    "IMPACT_MAX_INTENSITY",

    -- Death explosion (Dynamic)
    "EXPLOSION_BASE_VELOCITY",
    "EXPLOSION_VELOCITY_INHERIT",
    "EXPLOSION_MAX_VELOCITY",

    -- Blood trail settings
    "BLOOD_TRAIL_INTERVAL",
    "BLOOD_TRAIL_INTENSITY",
    "BLOOD_TRAIL_SIZE_MIN",
    "BLOOD_TRAIL_SIZE_MAX",

    -- Chunk settle timing
    "CHUNK_SETTLE_DELAY",
    "CHUNK_SETTLE_VELOCITY",

    -- Crosshair (manual aiming mode)
    "CROSSHAIR_GAP",
    "CROSSHAIR_LENGTH",
    "CROSSHAIR_THICKNESS",
    "CROSSHAIR_COLOR",
    "CROSSHAIR_GLOW_LAYERS",
    "CROSSHAIR_GLOW_SPREAD",

    -- Font
    "FONT_PATH",
    "FONT_SIZE",

    -- Intro sequence
    "INTRO_ENABLED",
    "INTRO_BLACK_DURATION",
    "INTRO_TEXT_HOLD_1",
    "INTRO_TEXT_HOLD_2",
    "INTRO_FADE_DURATION",
    "INTRO_ALERT_DURATION",
    "INTRO_BARREL_SLIDE_DURATION",
    "INTRO_TYPEWRITER_SPEED",
    "INTRO_TEXT_1_LINE1",
    "INTRO_TEXT_1_LINE2",
    "INTRO_LINE_PAUSE",
    "INTRO_TEXT_2",
    "INTRO_ALERT_TEXT",

    -- Post-processing
    "PostFX",
    "CHROMATIC_ABERRATION_ENABLED",
    "CHROMATIC_ABERRATION_AMOUNT",
    "CHROMATIC_ABERRATION_FALLOFF",
    "BLOOM_ENABLED",
    "BLOOM_SCALE",
    "BLOOM_INTENSITY",
    "BLOOM_BLUR_PASSES",
    "BLOOM_THRESHOLD",
    "BLOOM_SOFT_THRESHOLD",
    "CRT_ENABLED",
    "CRT_SCANLINE_INTENSITY",
    "CRT_SCANLINE_COUNT",
    "CRT_CURVATURE",
    "CRT_VIGNETTE",
    "GLITCH_ENABLED",
    "GLITCH_INTENSITY",
    "GLITCH_SCANLINE_JITTER",
    "HEAT_DISTORTION_ENABLED",
    "HEAT_DISTORTION_INTENSITY",
    "HEAT_DISTORTION_FREQUENCY",
    "HEAT_DISTORTION_SPEED",

    -- Shield system
    "Shield",
    "SHIELD_BASE_RADIUS",
    "SHIELD_PULSE_SPEED",
    "SHIELD_PULSE_AMOUNT",
    "SHIELD_HIT_FLASH_DURATION",
    "SHIELD_HIT_PULSE_AMOUNT",
    "SHIELD_HIT_PULSE_DECAY",
    "SHIELD_COLOR_OUTER",
    "SHIELD_COLOR_MID",
    "SHIELD_COLOR_INNER",
    "SHIELD_COLOR_FILL",

    -- Missile silo system
    "Silo",
    "Missile",
    "silos",
    "missiles",
    "SILO_ORBIT_RADIUS",
    "SILO_SIZE",
    "SILO_HATCH_GAP",
    "SILO_BASE_FIRE_RATE",
    "SILO_HATCH_OPEN_TIME",
    "SILO_HATCH_CLOSE_TIME",
    "SILO_FIRE_DELAY",
    "MISSILE_SPEED",
    "MISSILE_TURN_RATE",
    "MISSILE_DAMAGE",
    "MISSILE_SIZE",
    "MISSILE_TRAIL_LENGTH",
    "MISSILE_COLOR",
    "MISSILE_CORE_COLOR",
    "MISSILE_TRAIL_COLOR",
    "SILO_COLOR",
    "SILO_FILL_COLOR",
    "SILO_GLOW_COLOR",
    "MISSILE_LIGHT_RADIUS",
    "MISSILE_LIGHT_INTENSITY",
    "MISSILE_EXPLOSION_PARTICLES",
    "MISSILE_EXPLOSION_VELOCITY",
}

-- Exclude library files from linting
exclude_files = {
    "lib/*",
}
