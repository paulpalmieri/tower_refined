-- src/skilltree/node_data.lua
-- Skill tree node definitions

local NODE_DEFS = {
    -- ===================
    -- CENTER NODE (always unlocked)
    -- ===================
    turret = {
        id = "turret",
        gridX = 12,
        gridY = 12,
        name = "Turret Core",
        icon = "turret",
        maxLevel = 0,
        costs = {},
        effects = {},
        connections = {"fire_rate_1", "health_1", "gold_1", "magnet_1"},
        branch = "center",
    },

    -- ===================
    -- TOP BRANCH: DAMAGE (gridY decreasing)
    -- ===================
    fire_rate_1 = {
        id = "fire_rate_1",
        gridX = 12,
        gridY = 10,
        name = "Rapid Fire",
        icon = "fire_rate",
        maxLevel = 5,
        costs = {40, 60, 90, 135, 200},
        effects = {
            type = "fireRate",
            values = {1.15, 1.30, 1.50, 1.75, 2.00},
        },
        connections = {"turret", "fire_rate_2", "bullet_velocity_1", "laser_power_1"},
        branch = "damage",
    },
    fire_rate_2 = {
        id = "fire_rate_2",
        gridX = 12,
        gridY = 8,
        name = "Rapid Fire II",
        icon = "fire_rate",
        maxLevel = 5,
        costs = {80, 120, 180, 270, 400},
        effects = {
            type = "fireRate",
            values = {1.10, 1.20, 1.35, 1.50, 1.75},
        },
        connections = {"fire_rate_1", "fire_rate_3"},
        branch = "damage",
    },
    fire_rate_3 = {
        id = "fire_rate_3",
        gridX = 12,
        gridY = 6,
        name = "Machine Gun",
        icon = "fire_rate",
        maxLevel = 3,
        costs = {200, 400, 800},
        effects = {
            type = "fireRate",
            values = {1.25, 1.50, 2.00},
        },
        connections = {"fire_rate_2"},
        branch = "damage",
    },
    bullet_velocity_1 = {
        id = "bullet_velocity_1",
        gridX = 10,
        gridY = 10,
        name = "Velocity Rounds",
        icon = "velocity",
        maxLevel = 5,
        costs = {50, 75, 110, 165, 245},
        effects = {
            type = "projectileSpeed",
            values = {1.15, 1.30, 1.50, 1.75, 2.00},
        },
        connections = {"fire_rate_1", "bullet_velocity_2", "plasma_power_1"},
        branch = "damage",
    },
    bullet_velocity_2 = {
        id = "bullet_velocity_2",
        gridX = 10,
        gridY = 8,
        name = "Accelerated Munitions",
        icon = "velocity",
        maxLevel = 5,
        costs = {100, 150, 225, 340, 500},
        effects = {
            type = "projectileSpeed",
            values = {1.10, 1.20, 1.35, 1.50, 1.75},
        },
        connections = {"bullet_velocity_1", "bullet_velocity_3"},
        branch = "damage",
    },
    bullet_velocity_3 = {
        id = "bullet_velocity_3",
        gridX = 10,
        gridY = 6,
        name = "Hypersonic",
        icon = "velocity",
        maxLevel = 3,
        costs = {250, 500, 1000},
        effects = {
            type = "projectileSpeed",
            values = {1.25, 1.50, 2.00},
        },
        connections = {"bullet_velocity_2"},
        branch = "damage",
    },
    -- ===================
    -- LASER BRANCH (extends right from fire_rate_1)
    -- ===================
    laser_power_1 = {
        id = "laser_power_1",
        gridX = 14,
        gridY = 10,
        name = "Focused Beam",
        icon = "laser",
        maxLevel = 5,
        costs = {60, 100, 150, 225, 340},
        effects = {
            type = "laserDamage",
            values = {1.20, 1.40, 1.60, 1.90, 2.25},
        },
        connections = {"fire_rate_1", "laser_power_2", "laser_duration_1"},
        branch = "damage",
    },
    laser_power_2 = {
        id = "laser_power_2",
        gridX = 14,
        gridY = 8,
        name = "Overcharged Beam",
        icon = "laser",
        maxLevel = 4,
        costs = {150, 250, 400, 650},
        effects = {
            type = "laserDamage",
            values = {1.25, 1.50, 1.80, 2.20},
        },
        connections = {"laser_power_1", "laser_width_1"},
        branch = "damage",
    },
    laser_duration_1 = {
        id = "laser_duration_1",
        gridX = 16,
        gridY = 10,
        name = "Sustained Fire",
        icon = "laser_duration",
        maxLevel = 5,
        costs = {80, 130, 200, 310, 470},
        effects = {
            type = "laserDuration",
            values = {1.20, 1.40, 1.60, 1.85, 2.15},
        },
        connections = {"laser_power_1", "laser_charge_1"},
        branch = "damage",
    },
    laser_charge_1 = {
        id = "laser_charge_1",
        gridX = 18,
        gridY = 10,
        name = "Quick Deploy",
        icon = "laser_charge",
        maxLevel = 4,
        costs = {100, 180, 300, 500},
        effects = {
            type = "laserChargeSpeed",
            values = {1.25, 1.50, 1.80, 2.20},
        },
        connections = {"laser_duration_1"},
        branch = "damage",
    },
    laser_width_1 = {
        id = "laser_width_1",
        gridX = 14,
        gridY = 6,
        name = "Wide Beam",
        icon = "laser_width",
        maxLevel = 3,
        costs = {200, 400, 800},
        effects = {
            type = "laserWidth",
            values = {1.30, 1.60, 2.00},
        },
        connections = {"laser_power_2"},
        branch = "damage",
    },

    -- ===================
    -- PLASMA BRANCH (extends left from bullet_velocity_1)
    -- ===================
    plasma_power_1 = {
        id = "plasma_power_1",
        gridX = 8,
        gridY = 10,
        name = "Charged Plasma",
        icon = "plasma",
        maxLevel = 5,
        costs = {60, 100, 150, 225, 340},
        effects = {
            type = "plasmaDamage",
            values = {1.25, 1.50, 1.80, 2.15, 2.60},
        },
        connections = {"bullet_velocity_1", "plasma_power_2", "plasma_speed_1"},
        branch = "damage",
    },
    plasma_power_2 = {
        id = "plasma_power_2",
        gridX = 8,
        gridY = 8,
        name = "Supercharged Plasma",
        icon = "plasma",
        maxLevel = 4,
        costs = {150, 250, 400, 650},
        effects = {
            type = "plasmaDamage",
            values = {1.30, 1.60, 2.00, 2.50},
        },
        connections = {"plasma_power_1", "plasma_size_1"},
        branch = "damage",
    },
    plasma_speed_1 = {
        id = "plasma_speed_1",
        gridX = 6,
        gridY = 10,
        name = "Accelerated Plasma",
        icon = "plasma_speed",
        maxLevel = 5,
        costs = {70, 120, 190, 290, 440},
        effects = {
            type = "plasmaSpeed",
            values = {1.20, 1.40, 1.65, 1.90, 2.20},
        },
        connections = {"plasma_power_1", "plasma_cooldown_1"},
        branch = "damage",
    },
    plasma_cooldown_1 = {
        id = "plasma_cooldown_1",
        gridX = 4,
        gridY = 10,
        name = "Rapid Recharge",
        icon = "plasma_cooldown",
        maxLevel = 4,
        costs = {100, 180, 300, 500},
        effects = {
            type = "plasmaCooldown",
            values = {0.85, 0.70, 0.55, 0.40},
        },
        connections = {"plasma_speed_1"},
        branch = "damage",
    },
    plasma_size_1 = {
        id = "plasma_size_1",
        gridX = 8,
        gridY = 6,
        name = "Massive Payload",
        icon = "plasma_size",
        maxLevel = 3,
        costs = {200, 400, 800},
        effects = {
            type = "plasmaSize",
            values = {1.30, 1.60, 2.00},
        },
        connections = {"plasma_power_2"},
        branch = "damage",
    },

    -- ===================
    -- LEFT BRANCH: HEALTH (gridX decreasing)
    -- ===================
    health_1 = {
        id = "health_1",
        gridX = 10,
        gridY = 12,
        name = "Reinforced Core",
        icon = "health",
        maxLevel = 5,
        costs = {30, 45, 70, 105, 155},
        effects = {
            type = "maxHp",
            values = {25, 50, 75, 100, 150},
        },
        connections = {"turret", "health_2", "drone_unlock", "shield_unlock"},
        branch = "health",
    },
    health_2 = {
        id = "health_2",
        gridX = 8,
        gridY = 12,
        name = "Reinforced Core II",
        icon = "health",
        maxLevel = 5,
        costs = {60, 90, 140, 210, 310},
        effects = {
            type = "maxHp",
            values = {25, 50, 75, 100, 150},
        },
        connections = {"health_1", "health_3"},
        branch = "health",
    },
    health_3 = {
        id = "health_3",
        gridX = 6,
        gridY = 12,
        name = "Fortress",
        icon = "health",
        maxLevel = 3,
        costs = {150, 300, 600},
        effects = {
            type = "maxHp",
            values = {100, 200, 400},
        },
        connections = {"health_2"},
        branch = "health",
    },
    -- ===================
    -- DRONE BRANCH (extends down from health_1)
    -- ===================
    drone_unlock = {
        id = "drone_unlock",
        gridX = 10,
        gridY = 14,
        name = "Drone Protocol",
        icon = "drone",
        maxLevel = 1,
        costs = {100},
        effects = {
            type = "droneCount",
            values = {1},
        },
        connections = {"health_1", "drone_fire_rate"},
        branch = "drone",
    },
    drone_fire_rate = {
        id = "drone_fire_rate",
        gridX = 10,
        gridY = 16,
        name = "Rapid Acquisition",
        icon = "drone_fire_rate",
        maxLevel = 5,
        costs = {60, 100, 150, 225, 340},
        effects = {
            type = "droneFireRate",
            values = {1.20, 1.40, 1.65, 1.90, 2.20},
        },
        connections = {"drone_unlock", "drone_extra_2"},
        branch = "drone",
    },
    drone_extra_2 = {
        id = "drone_extra_2",
        gridX = 10,
        gridY = 18,
        name = "Drone Mk II",
        icon = "drone",
        maxLevel = 1,
        costs = {200},
        effects = {
            type = "droneCount",
            values = {2},
        },
        connections = {"drone_fire_rate", "drone_extra_3"},
        branch = "drone",
    },
    drone_extra_3 = {
        id = "drone_extra_3",
        gridX = 10,
        gridY = 20,
        name = "Drone Mk III",
        icon = "drone",
        maxLevel = 1,
        costs = {400},
        effects = {
            type = "droneCount",
            values = {3},
        },
        connections = {"drone_extra_2"},
        branch = "drone",
    },

    -- ===================
    -- RIGHT BRANCH: RESOURCE (gridX increasing)
    -- ===================
    gold_1 = {
        id = "gold_1",
        gridX = 14,
        gridY = 12,
        name = "Gold Magnet",
        icon = "gold",
        maxLevel = 5,
        costs = {35, 55, 85, 125, 185},
        effects = {
            type = "goldMultiplier",
            values = {1.25, 1.50, 1.75, 2.00, 2.50},
        },
        connections = {"turret", "gold_2", "luck_1"},
        branch = "resource",
    },
    gold_2 = {
        id = "gold_2",
        gridX = 16,
        gridY = 12,
        name = "Gold Magnet II",
        icon = "gold",
        maxLevel = 5,
        costs = {70, 110, 170, 250, 370},
        effects = {
            type = "goldMultiplier",
            values = {1.20, 1.40, 1.60, 1.80, 2.00},
        },
        connections = {"gold_1", "gold_3"},
        branch = "resource",
    },
    gold_3 = {
        id = "gold_3",
        gridX = 18,
        gridY = 12,
        name = "Midas Touch",
        icon = "gold",
        maxLevel = 3,
        costs = {200, 400, 800},
        effects = {
            type = "goldMultiplier",
            values = {1.50, 2.00, 3.00},
        },
        connections = {"gold_2"},
        branch = "resource",
    },
    luck_1 = {
        id = "luck_1",
        gridX = 14,
        gridY = 14,
        name = "Lucky Drops",
        icon = "luck",
        maxLevel = 1,
        costs = {999999},
        effects = {},
        connections = {"gold_1"},
        branch = "resource",
        placeholder = true,
    },

    -- ===================
    -- BOTTOM BRANCH: XP/COLLECTION (gridY increasing)
    -- ===================
    magnet_1 = {
        id = "magnet_1",
        gridX = 12,
        gridY = 14,
        name = "Shard Magnet",
        icon = "magnet",
        maxLevel = 1,
        costs = {150},
        effects = {
            type = "magnetEnabled",
            values = {1},
        },
        connections = {"turret", "pickup_radius_1"},
        branch = "collection",
    },
    pickup_radius_1 = {
        id = "pickup_radius_1",
        gridX = 12,
        gridY = 16,
        name = "Collection Range",
        icon = "pickup_radius",
        maxLevel = 5,
        costs = {80, 120, 180, 270, 400},
        effects = {
            type = "pickupRadius",
            values = {1.25, 1.50, 1.75, 2.00, 2.50},
        },
        connections = {"magnet_1"},
        branch = "collection",
    },

    -- ===================
    -- DEFENSE BRANCH: SHIELD (extends down-left from health_1)
    -- ===================
    shield_unlock = {
        id = "shield_unlock",
        gridX = 8,
        gridY = 14,
        name = "Energy Shield",
        icon = "shield",
        maxLevel = 1,
        costs = {150},
        effects = {
            type = "shieldUnlock",
            values = {1},  -- Unlocks with 1 charge
        },
        connections = {"health_1", "shield_radius_1", "shield_charges_1"},
        branch = "defense",
    },
    shield_radius_1 = {
        id = "shield_radius_1",
        gridX = 6,
        gridY = 14,
        name = "Extended Barrier",
        icon = "shield_radius",
        maxLevel = 3,
        costs = {100, 200, 400},
        effects = {
            type = "shieldRadius",
            values = {1.25, 1.50, 2.00},  -- Radius multipliers
        },
        connections = {"shield_unlock"},
        branch = "defense",
    },
    shield_charges_1 = {
        id = "shield_charges_1",
        gridX = 8,
        gridY = 16,
        name = "Capacitor Banks",
        icon = "shield_charges",
        maxLevel = 4,
        costs = {120, 240, 480, 960},
        effects = {
            type = "shieldCharges",
            values = {2, 3, 5, 8},  -- Total charges at each level
        },
        connections = {"shield_unlock", "shield_charges_2", "homing_missiles_1"},
        branch = "defense",
    },
    shield_charges_2 = {
        id = "shield_charges_2",
        gridX = 8,
        gridY = 18,
        name = "Overcharged Banks",
        icon = "shield_charges",
        maxLevel = 3,
        costs = {500, 1000, 2000},
        effects = {
            type = "shieldCharges",
            values = {12, 18, 25},
        },
        connections = {"shield_charges_1"},
        branch = "defense",
    },

    -- ===================
    -- MISSILE SILO BRANCH (extends from shield_charges_1)
    -- ===================
    homing_missiles_1 = {
        id = "homing_missiles_1",
        gridX = 6,
        gridY = 16,
        name = "Missile Silos",
        icon = "missile",
        maxLevel = 1,
        costs = {150},
        effects = {
            type = "siloCount",
            values = {1},  -- Unlocks with 1 silo
        },
        connections = {"shield_charges_1", "silo_count_1", "silo_fire_rate_1"},
        branch = "offense",
    },
    silo_count_1 = {
        id = "silo_count_1",
        gridX = 4,
        gridY = 16,
        name = "Additional Silos",
        icon = "silo_count",
        maxLevel = 10,
        costs = {80, 100, 130, 170, 220, 290, 380, 500, 650, 850},
        effects = {
            type = "siloCount",
            values = {2, 3, 4, 5, 6, 7, 8, 9, 10, 11},  -- Cumulative silo count
        },
        connections = {"homing_missiles_1", "silo_double_fire"},
        branch = "offense",
    },
    silo_double_fire = {
        id = "silo_double_fire",
        gridX = 4,
        gridY = 18,
        name = "Twin Warheads",
        icon = "silo_double",
        maxLevel = 1,
        costs = {400},
        effects = {
            type = "siloDoubleShot",
            values = {1},  -- Enables double shot + 1 bonus silo
        },
        connections = {"silo_count_1"},
        branch = "offense",
    },
    silo_fire_rate_1 = {
        id = "silo_fire_rate_1",
        gridX = 6,
        gridY = 18,
        name = "Rapid Launch",
        icon = "silo_fire_rate",
        maxLevel = 5,
        costs = {100, 160, 250, 400, 640},
        effects = {
            type = "siloFireRate",
            values = {1.25, 1.50, 1.80, 2.20, 2.75},  -- Fire rate multiplier
        },
        connections = {"homing_missiles_1"},
        branch = "offense",
    },
}

-- Grid and node size constants
local GRID_SIZE = 25
local CELL_SIZE = 32
local NODE_SIZE = 16

return {
    NODE_DEFS = NODE_DEFS,
    GRID_SIZE = GRID_SIZE,
    CELL_SIZE = CELL_SIZE,
    NODE_SIZE = NODE_SIZE,
}
