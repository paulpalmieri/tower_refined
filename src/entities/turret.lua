-- turret.lua
-- Flak Cannon turret - heavy single barrel

local Turret = Object:extend()

-- ===================
-- FLAK CANNON COLORS (Olive-Steel with Weathering)
-- ===================
local TURRET_COLORS = {
    -- Base armor plates (olive-grey)
    baseDark = {0.28, 0.29, 0.26},
    baseMid = {0.36, 0.37, 0.33},
    baseLight = {0.44, 0.45, 0.40},
    -- Platform metal
    platformDark = {0.26, 0.27, 0.24},
    platform = {0.33, 0.34, 0.30},
    platformLight = {0.40, 0.41, 0.37},
    -- Foundation/treads
    foundationDark = {0.22, 0.23, 0.20},
    foundation = {0.30, 0.31, 0.28},
    -- Barrel (dark steel)
    barrelDark = {0.22, 0.24, 0.26},
    barrelMid = {0.30, 0.32, 0.34},
    barrelLight = {0.38, 0.40, 0.42},
    barrelHighlight = {0.48, 0.50, 0.52},
    -- Breech/housing
    breechDark = {0.24, 0.26, 0.28},
    breech = {0.32, 0.34, 0.36},
    breechLight = {0.40, 0.42, 0.44},
    -- Muzzle/bore
    muzzle = {0.10, 0.10, 0.12},
    muzzleRim = {0.35, 0.37, 0.39},
    -- Weathering (rust/wear)
    rust = {0.45, 0.28, 0.18},
    rustDark = {0.32, 0.20, 0.14},
    wear = {0.48, 0.46, 0.42},
    wearLight = {0.55, 0.53, 0.48},
    scorch = {0.14, 0.13, 0.12},
    scorchMid = {0.20, 0.19, 0.18},
    -- Rivets/bolts
    rivet = {0.22, 0.23, 0.25},
    rivetLight = {0.42, 0.43, 0.45},
    -- Sandbags (fortification)
    sandbagDark = {0.35, 0.30, 0.22},
    sandbag = {0.45, 0.38, 0.28},
    sandbagLight = {0.52, 0.45, 0.35},
    -- Ammo crate
    crateDark = {0.28, 0.22, 0.15},
    crate = {0.38, 0.30, 0.20},
    crateLight = {0.45, 0.38, 0.28},
    -- Targeting optics
    opticGlass = {0.15, 0.20, 0.25},
    opticRim = {0.30, 0.32, 0.34},
    -- Ground support (concrete pad - visible but grounded)
    groundDark = {0.15, 0.14, 0.12},
    ground = {0.20, 0.19, 0.16},
    groundMid = {0.25, 0.23, 0.20},
    groundLight = {0.30, 0.28, 0.24},
    rubble = {0.18, 0.16, 0.13},
    rubbleLight = {0.23, 0.21, 0.17},
}

-- ===================
-- GROUND SUPPORT SPRITE (drawn first, blends into dark floor)
-- Large square concrete pad - anchors turret to environment
-- Uses TOWER_PAD_SIZE from config for collision sync
-- ===================
local SUPPORT_SPRITE = {}

-- Generate a big square pad programmatically (uses global TOWER_PAD_SIZE)
-- Note: This runs at load time, so TOWER_PAD_SIZE must be defined in config.lua
local PAD_SIZE = TOWER_PAD_SIZE or 16  -- Half-size, so full pad is 32x32 pixels
for py = -PAD_SIZE, PAD_SIZE do
    for px = -PAD_SIZE, PAD_SIZE do
        -- Distance from edge for shading
        local edgeDistX = PAD_SIZE - math.abs(px)
        local edgeDistY = PAD_SIZE - math.abs(py)
        local edgeDist = math.min(edgeDistX, edgeDistY)

        local colorKey
        if edgeDist <= 1 then
            colorKey = "groundDark"
        elseif edgeDist <= 3 then
            colorKey = "ground"
        elseif edgeDist <= 5 then
            colorKey = "groundMid"
        else
            -- Add some variation in the middle
            local noise = (px * 7 + py * 13) % 5
            if noise == 0 then
                colorKey = "rubble"
            elseif noise == 1 then
                colorKey = "ground"
            else
                colorKey = "groundLight"
            end
        end

        table.insert(SUPPORT_SPRITE, {px, py, colorKey})
    end
end

-- ===================
-- BASE SPRITE (static, doesn't rotate)
-- Fortified emplacement with sandbags, armor plates, and military detail
-- ===================
local BASE_SPRITE = {
    -- === TOP SANDBAG ROW (y=-5) - irregular edge ===
    {-4, -5, "sandbagDark"}, {-3, -5, "sandbag"}, {-2, -5, "sandbagLight"}, {-1, -5, "sandbag"},
    {0, -5, "sandbagLight"}, {1, -5, "sandbag"}, {2, -5, "sandbagLight"}, {3, -5, "sandbagDark"},

    -- === UPPER SANDBAGS + PLATFORM EDGE (y=-4) ===
    {-6, -4, "sandbagDark"}, {-5, -4, "sandbag"}, {-4, -4, "sandbagLight"}, {-3, -4, "sandbag"},
    {-2, -4, "platformDark"}, {-1, -4, "platform"}, {0, -4, "platformLight"}, {1, -4, "platform"},
    {2, -4, "sandbag"}, {3, -4, "sandbagLight"}, {4, -4, "sandbag"}, {5, -4, "sandbagDark"},

    -- === ROTATION TRACK AREA (y=-3 to y=+3) ===
    -- Row -3: Platform top with rivets
    {-7, -3, "sandbagDark"}, {-6, -3, "sandbag"},
    {-5, -3, "rivet"}, {-4, -3, "platformLight"}, {-3, -3, "platform"}, {-2, -3, "platformLight"}, {-1, -3, "platform"}, {0, -3, "platformLight"}, {1, -3, "platform"}, {2, -3, "platformLight"}, {3, -3, "rivet"},
    {4, -3, "sandbag"}, {5, -3, "sandbagLight"}, {6, -3, "sandbagDark"},

    -- Row -2: Platform sides
    {-8, -2, "sandbagDark"}, {-7, -2, "sandbag"}, {-6, -2, "platformDark"},
    {-5, -2, "platform"}, {-4, -2, "platformLight"}, {-3, -2, "platform"}, {2, -2, "platform"}, {3, -2, "platformLight"}, {4, -2, "platform"},
    {5, -2, "platformDark"}, {6, -2, "sandbag"}, {7, -2, "sandbagDark"},

    -- Row -1: Platform sides with wear marks
    {-8, -1, "sandbag"}, {-7, -1, "sandbagLight"}, {-6, -1, "platformDark"},
    {-5, -1, "wear"}, {-4, -1, "platform"}, {3, -1, "platform"}, {4, -1, "wear"},
    {5, -1, "platformDark"}, {6, -1, "sandbagLight"}, {7, -1, "sandbag"},

    -- Row 0: Platform middle
    {-8, 0, "sandbagLight"}, {-7, 0, "sandbag"}, {-6, 0, "platformDark"},
    {-5, 0, "platform"}, {-4, 0, "platformLight"}, {3, 0, "platformLight"}, {4, 0, "platform"},
    {5, 0, "platformDark"}, {6, 0, "sandbag"}, {7, 0, "sandbagLight"},

    -- Row 1: Platform sides
    {-8, 1, "sandbag"}, {-7, 1, "sandbagDark"}, {-6, 1, "platformDark"},
    {-5, 1, "platform"}, {-4, 1, "platform"}, {3, 1, "platform"}, {4, 1, "platform"},
    {5, 1, "platformDark"}, {6, 1, "sandbagDark"}, {7, 1, "sandbag"},

    -- Row 2: Platform sides with rust
    {-8, 2, "sandbagDark"}, {-7, 2, "sandbag"}, {-6, 2, "platformDark"},
    {-5, 2, "rustDark"}, {-4, 2, "platform"}, {3, 2, "platform"}, {4, 2, "rust"},
    {5, 2, "platformDark"}, {6, 2, "sandbag"}, {7, 2, "sandbagDark"},

    -- Row 3: Platform bottom with rivets
    {-7, 3, "sandbagDark"}, {-6, 3, "sandbag"},
    {-5, 3, "rivet"}, {-4, 3, "platform"}, {-3, 3, "platformLight"}, {-2, 3, "platform"}, {-1, 3, "platformLight"}, {0, 3, "platform"}, {1, 3, "platformLight"}, {2, 3, "platform"}, {3, 3, "rivet"},
    {4, 3, "sandbag"}, {5, 3, "sandbagLight"}, {6, 3, "sandbagDark"},

    -- === LOWER PLATFORM + AMMO STORAGE (y=4 to y=9) ===
    -- Row 4: Transition with panel seam
    {-8, 4, "sandbagDark"}, {-7, 4, "sandbag"}, {-6, 4, "sandbagLight"},
    {-5, 4, "foundationDark"}, {-4, 4, "foundation"}, {-3, 4, "foundationDark"}, {-2, 4, "foundation"}, {-1, 4, "foundationDark"}, {0, 4, "foundation"}, {1, 4, "foundationDark"}, {2, 4, "foundation"}, {3, 4, "foundationDark"}, {4, 4, "foundation"},
    {5, 4, "sandbagLight"}, {6, 4, "sandbag"}, {7, 4, "sandbagDark"},

    -- Row 5: Main platform body with ammo crate on left
    {-9, 5, "sandbagDark"}, {-8, 5, "sandbag"},
    {-7, 5, "crateDark"}, {-6, 5, "crate"}, {-5, 5, "crateLight"}, {-4, 5, "crate"},  -- Ammo crate
    {-3, 5, "foundationDark"}, {-2, 5, "foundation"}, {-1, 5, "foundationDark"}, {0, 5, "foundation"}, {1, 5, "foundationDark"}, {2, 5, "foundation"}, {3, 5, "foundationDark"}, {4, 5, "foundation"}, {5, 5, "foundationDark"},
    {6, 5, "sandbag"}, {7, 5, "sandbagLight"}, {8, 5, "sandbagDark"},

    -- Row 6: Platform body with crate + rust patches
    {-9, 6, "sandbag"}, {-8, 6, "sandbagLight"},
    {-7, 6, "crateDark"}, {-6, 6, "crateLight"}, {-5, 6, "crate"}, {-4, 6, "crateDark"},  -- Ammo crate
    {-3, 6, "foundation"}, {-2, 6, "rust"}, {-1, 6, "foundation"}, {0, 6, "foundationDark"}, {1, 6, "foundation"}, {2, 6, "rustDark"}, {3, 6, "foundation"}, {4, 6, "foundationDark"}, {5, 6, "foundation"},
    {6, 6, "sandbagLight"}, {7, 6, "sandbag"}, {8, 6, "sandbagDark"},

    -- Row 7: Platform with rivets
    {-9, 7, "sandbagLight"}, {-8, 7, "sandbag"},
    {-7, 7, "rivet"}, {-6, 7, "foundationDark"}, {-5, 7, "foundation"}, {-4, 7, "foundationDark"}, {-3, 7, "rivet"}, {-2, 7, "foundation"}, {-1, 7, "foundationDark"}, {0, 7, "rivet"}, {1, 7, "foundationDark"}, {2, 7, "foundation"}, {3, 7, "rivet"}, {4, 7, "foundationDark"}, {5, 7, "foundation"}, {6, 7, "rivet"},
    {7, 7, "sandbag"}, {8, 7, "sandbagLight"},

    -- Row 8: Lower edge with wear
    {-8, 8, "sandbagDark"}, {-7, 8, "sandbag"},
    {-6, 8, "foundationDark"}, {-5, 8, "wear"}, {-4, 8, "foundation"}, {-3, 8, "foundationDark"}, {-2, 8, "foundation"}, {-1, 8, "wear"}, {0, 8, "foundation"}, {1, 8, "foundationDark"}, {2, 8, "foundation"}, {3, 8, "wear"}, {4, 8, "foundation"}, {5, 8, "foundationDark"},
    {6, 8, "sandbag"}, {7, 8, "sandbagDark"},

    -- Row 9: Bottom edge (darker, in shadow)
    {-7, 9, "sandbagDark"}, {-6, 9, "sandbagDark"},
    {-5, 9, "foundationDark"}, {-4, 9, "foundationDark"}, {-3, 9, "foundationDark"}, {-2, 9, "foundationDark"}, {-1, 9, "foundationDark"}, {0, 9, "foundationDark"}, {1, 9, "foundationDark"}, {2, 9, "foundationDark"}, {3, 9, "foundationDark"}, {4, 9, "foundationDark"},
    {5, 9, "sandbagDark"}, {6, 9, "sandbagDark"},

    -- Row 10: Shadow/ground contact
    {-4, 10, "foundationDark"}, {-3, 10, "foundationDark"}, {-2, 10, "foundationDark"}, {-1, 10, "foundationDark"}, {0, 10, "foundationDark"}, {1, 10, "foundationDark"}, {2, 10, "foundationDark"}, {3, 10, "foundationDark"},
}

-- ===================
-- BARREL SPRITE (rotates) - Battle-worn AA gun design
-- Muzzle brake, cooling jacket, reinforcement bands, targeting optics
-- ===================
local BARREL_LENGTH = 22

local BARREL_SPRITE = {
    -- === MUZZLE BRAKE (7px wide with fins/slots) === rows -22 to -18
    -- Muzzle brake tip with flash hider slots
    {-3, -22, "scorch"}, {-2, -22, "muzzle"}, {-1, -22, "muzzle"}, {0, -22, "muzzle"}, {1, -22, "muzzle"}, {2, -22, "scorch"},
    -- Muzzle brake body with vent slots
    {-3, -21, "scorchMid"}, {-2, -21, "barrelMid"}, {-1, -21, "muzzle"}, {0, -21, "barrelLight"}, {1, -21, "muzzle"}, {2, -21, "barrelMid"}, {3, -21, "scorchMid"},
    {-3, -20, "barrelDark"}, {-2, -20, "barrelLight"}, {-1, -20, "muzzle"}, {0, -20, "barrelHighlight"}, {1, -20, "muzzle"}, {2, -20, "barrelLight"}, {3, -20, "barrelDark"},
    -- Muzzle brake fins
    {-4, -19, "barrelDark"}, {-3, -19, "barrelMid"}, {-2, -19, "barrelLight"}, {-1, -19, "barrelMid"}, {0, -19, "barrelLight"}, {1, -19, "barrelMid"}, {2, -19, "barrelLight"}, {3, -19, "barrelMid"}, {4, -19, "barrelDark"},
    -- Muzzle brake base
    {-3, -18, "barrelDark"}, {-2, -18, "barrelMid"}, {-1, -18, "barrelLight"}, {0, -18, "barrelHighlight"}, {1, -18, "barrelLight"}, {2, -18, "barrelMid"}, {3, -18, "barrelDark"},

    -- === BARREL TAPER FROM MUZZLE === row -17
    {-2, -17, "barrelDark"}, {-1, -17, "barrelMid"}, {0, -17, "barrelLight"}, {1, -17, "barrelMid"}, {2, -17, "barrelDark"},

    -- === MAIN BARREL SHAFT (3px wide) with scorch marks === rows -16 to -12
    {-1, -16, "scorchMid"}, {0, -16, "barrelMid"}, {1, -16, "scorch"},  -- Scorch near muzzle
    {-1, -15, "barrelDark"}, {0, -15, "barrelLight"}, {1, -15, "barrelDark"},
    {-1, -14, "barrelDark"}, {0, -14, "barrelMid"}, {1, -14, "scorchMid"},  -- More scorch
    {-1, -13, "barrelDark"}, {0, -13, "barrelLight"}, {1, -13, "barrelDark"},
    {-1, -12, "barrelDark"}, {0, -12, "barrelMid"}, {1, -12, "barrelDark"},

    -- === REINFORCEMENT BAND 1 (with rivets) === row -11
    {-2, -11, "rivet"}, {-1, -11, "barrelHighlight"}, {0, -11, "barrelHighlight"}, {1, -11, "barrelHighlight"}, {2, -11, "rivet"},

    -- === COOLING JACKET SECTION (perforated) === rows -10 to -8
    {-1, -10, "barrelDark"}, {0, -10, "muzzle"}, {1, -10, "barrelDark"},  -- Cooling hole
    {-1, -9, "barrelDark"}, {0, -9, "barrelLight"}, {1, -9, "barrelDark"},
    {-1, -8, "barrelDark"}, {0, -8, "muzzle"}, {1, -8, "barrelDark"},  -- Cooling hole

    -- === REINFORCEMENT BAND 2 (with rivets) === row -7
    {-2, -7, "rivet"}, {-1, -7, "barrelHighlight"}, {0, -7, "wear"}, {1, -7, "barrelHighlight"}, {2, -7, "rivet"},

    -- === BARREL TAPER TO BREECH === row -6
    {-2, -6, "barrelDark"}, {-1, -6, "barrelMid"}, {0, -6, "barrelLight"}, {1, -6, "barrelMid"}, {2, -6, "barrelDark"},

    -- === BREECH ASSEMBLY (chunky, detailed) === rows -5 to -2
    {-3, -5, "breechDark"}, {-2, -5, "breech"}, {-1, -5, "breechLight"}, {0, -5, "breechLight"}, {1, -5, "breech"}, {2, -5, "breechDark"},
    {-3, -4, "breechDark"}, {-2, -4, "rivet"}, {-1, -4, "breechLight"}, {0, -4, "breechLight"}, {1, -4, "rivet"}, {2, -4, "breechDark"},
    {-3, -3, "breechDark"}, {-2, -3, "breech"}, {-1, -3, "rust"}, {0, -3, "breechLight"}, {1, -3, "breech"}, {2, -3, "breechDark"},  -- Rust spot
    {-3, -2, "breechDark"}, {-2, -2, "breech"}, {-1, -2, "breech"}, {0, -2, "breech"}, {1, -2, "breech"}, {2, -2, "breechDark"},

    -- === TURRET HOUSING (rotates with barrel) === rows -1 to 3
    -- Top rim with armor detail
    {-5, -1, "baseDark"}, {-4, -1, "rivet"}, {-3, -1, "baseMid"}, {-2, -1, "baseLight"}, {-1, -1, "baseLight"}, {0, -1, "baseLight"}, {1, -1, "baseLight"}, {2, -1, "baseMid"}, {3, -1, "rivet"}, {4, -1, "baseDark"},
    -- Housing body with panel seams
    {-5, 0, "baseDark"}, {-4, 0, "baseMid"}, {-3, 0, "baseLight"}, {-2, 0, "baseMid"}, {-1, 0, "baseLight"}, {0, 0, "baseLight"}, {1, 0, "baseMid"}, {2, 0, "baseLight"}, {3, 0, "baseMid"}, {4, 0, "baseDark"},
    -- Targeting optics on left side
    {-5, 1, "baseDark"}, {-4, 1, "opticRim"}, {-3, 1, "opticGlass"}, {-2, 1, "baseMid"}, {-1, 1, "baseLight"}, {0, 1, "baseLight"}, {1, 1, "baseMid"}, {2, 1, "baseMid"}, {3, 1, "baseMid"}, {4, 1, "baseDark"},
    -- Housing lower with wear
    {-5, 2, "baseDark"}, {-4, 2, "baseMid"}, {-3, 2, "wear"}, {-2, 2, "baseMid"}, {-1, 2, "baseMid"}, {0, 2, "baseMid"}, {1, 2, "baseMid"}, {2, 2, "wear"}, {3, 2, "baseMid"}, {4, 2, "baseDark"},
    -- Bottom rim with rivets
    {-4, 3, "rivet"}, {-3, 3, "baseDark"}, {-2, 3, "baseDark"}, {-1, 3, "baseDark"}, {0, 3, "baseDark"}, {1, 3, "baseDark"}, {2, 3, "baseDark"}, {3, 3, "rivet"},
}

-- ===================
-- PER-PIXEL COLOR NOISE (baked at load time for performance)
-- ===================
local NOISE_AMOUNT = 0.03
local bakedSupportSprite = nil
local bakedBaseSprite = nil
local bakedBarrelSprite = nil

local function bakeSprite(spriteData)
    local baked = {}
    for i, def in ipairs(spriteData) do
        local ox, oy, colorKey = def[1], def[2], def[3]
        local baseColor = TURRET_COLORS[colorKey]
        if baseColor then
            -- Use deterministic noise based on position for consistency
            local seed = ox * 1000 + oy * 10 + i
            math.randomseed(seed)
            local r = baseColor[1] + (math.random() - 0.5) * NOISE_AMOUNT * 2
            local g = baseColor[2] + (math.random() - 0.5) * NOISE_AMOUNT * 2
            local b = baseColor[3] + (math.random() - 0.5) * NOISE_AMOUNT * 2
            -- Clamp values
            r = math.max(0, math.min(1, r))
            g = math.max(0, math.min(1, g))
            b = math.max(0, math.min(1, b))
            table.insert(baked, {ox, oy, {r, g, b}})
        end
    end
    -- Restore random seed
    math.randomseed(os.time())
    return baked
end

-- ===================
-- TURRET CLASS
-- ===================

function Turret:new(x, y)
    self.x = x
    self.y = y
    self.angle = -math.pi / 2  -- Point upward by default
    self.targetAngle = self.angle  -- For smooth rotation
    self.fireTimer = 0
    self.hp = TOWER_HP
    self.maxHp = TOWER_HP

    -- Stats (can be modified by upgrades)
    self.fireRate = TOWER_FIRE_RATE
    self.damage = PROJECTILE_DAMAGE
    self.projectileSpeed = PROJECTILE_SPEED

    -- Visual effects
    self.muzzleFlash = 0
    self.glowPulse = 0
    self.gunKick = 0

    -- Enhanced visual effects
    self.damageFlinch = 0
    self.statusBlink = 0

    -- Bake sprites with per-pixel noise (only once, shared across instances)
    if not bakedSupportSprite then
        bakedSupportSprite = bakeSprite(SUPPORT_SPRITE)
    end
    if not bakedBaseSprite then
        bakedBaseSprite = bakeSprite(BASE_SPRITE)
    end
    if not bakedBarrelSprite then
        bakedBarrelSprite = bakeSprite(BARREL_SPRITE)
    end
end

function Turret:update(dt, targetX, targetY)
    -- Calculate target angle
    if targetX and targetY then
        self.targetAngle = math.atan2(targetY - self.y, targetX - self.x)
    end

    -- Smooth rotation toward target (shortest path)
    local angleDiff = self.targetAngle - self.angle
    -- Normalize to [-pi, pi] for shortest rotation
    while angleDiff > math.pi do angleDiff = angleDiff - 2 * math.pi end
    while angleDiff < -math.pi do angleDiff = angleDiff + 2 * math.pi end

    -- Rotate at fixed speed, or snap if very close
    local rotateAmount = TURRET_ROTATION_SPEED * dt
    if math.abs(angleDiff) < rotateAmount then
        self.angle = self.targetAngle
    elseif angleDiff > 0 then
        self.angle = self.angle + rotateAmount
    else
        self.angle = self.angle - rotateAmount
    end

    -- Keep angle normalized
    while self.angle > math.pi do self.angle = self.angle - 2 * math.pi end
    while self.angle < -math.pi do self.angle = self.angle + 2 * math.pi end

    -- Fire timer
    if self.fireTimer > 0 then
        self.fireTimer = self.fireTimer - dt
    end

    -- Muzzle flash decay
    if self.muzzleFlash > 0 then
        self.muzzleFlash = self.muzzleFlash - dt
    end

    -- Gun kick decay
    if self.gunKick > 0 then
        self.gunKick = self.gunKick - dt * GUN_KICK_DECAY
        if self.gunKick < 0 then self.gunKick = 0 end
    end

    -- Glow pulse animation
    self.glowPulse = self.glowPulse + dt * 2

    -- Status blink
    self.statusBlink = (self.statusBlink + dt) % 1.0

    -- Damage flinch decay
    if self.damageFlinch > 0 then
        self.damageFlinch = self.damageFlinch - dt * 15
        if self.damageFlinch < 0 then self.damageFlinch = 0 end
    end
end

function Turret:canFire()
    return self.fireTimer <= 0
end

function Turret:fire()
    if not self:canFire() then return nil end

    self.fireTimer = self.fireRate
    self.muzzleFlash = 0.1
    self.gunKick = GUN_KICK_AMOUNT

    -- Play shooting sound
    Sounds.playShoot()

    -- Calculate muzzle position
    local gunLength = BARREL_LENGTH * BLOB_PIXEL_SIZE * TURRET_SCALE
    local muzzleX = self.x + math.cos(self.angle) * gunLength
    local muzzleY = self.y + math.sin(self.angle) * gunLength

    -- Create projectile
    local projectile = Projectile(
        muzzleX,
        muzzleY,
        self.angle,
        self.projectileSpeed,
        self.damage
    )

    return projectile
end

function Turret:draw()
    local ps = BLOB_PIXEL_SIZE * TURRET_SCALE
    local hpPercent = self:getHpPercent()

    -- Calculate damage flinch offset
    local flinchX = self.damageFlinch * math.cos(self.angle + math.pi) * 2
    local flinchY = self.damageFlinch * math.sin(self.angle + math.pi) * 2

    -- Draw ground support first (behind everything, blends into floor)
    for _, def in ipairs(bakedSupportSprite) do
        local ox, oy, color = def[1], def[2], def[3]
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.rectangle("fill",
            self.x + ox * ps - ps / 2 + flinchX,
            self.y + oy * ps - ps / 2 + flinchY,
            ps, ps)
    end

    -- Draw base (static, doesn't rotate) using baked sprite with noise
    for _, def in ipairs(bakedBaseSprite) do
        local ox, oy, color = def[1], def[2], def[3]
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.rectangle("fill",
            self.x + ox * ps - ps / 2 + flinchX,
            self.y + oy * ps - ps / 2 + flinchY,
            ps, ps)
    end

    -- Draw status lights (HP indicator)
    local statusColor
    if hpPercent > 0.5 then
        statusColor = {0.2, 0.8, 0.3}  -- Green
    elseif hpPercent > 0.25 then
        statusColor = {0.9, 0.8, 0.2}  -- Yellow
    else
        statusColor = {0.9, 0.25, 0.2}  -- Red
    end

    local statusAlpha = 1.0
    if hpPercent <= 0.25 then
        statusAlpha = self.statusBlink < 0.5 and 1.0 or 0.3
    elseif hpPercent <= 0.5 then
        statusAlpha = 0.7 + math.sin(self.statusBlink * math.pi * 2) * 0.3
    end

    -- Status lights on platform edges (flanking the central area)
    love.graphics.setColor(statusColor[1], statusColor[2], statusColor[3], statusAlpha)
    love.graphics.rectangle("fill", self.x + 5 * ps - ps / 2 + flinchX, self.y + 5 * ps - ps / 2 + flinchY, ps, ps)
    love.graphics.rectangle("fill", self.x - 3 * ps - ps / 2 + flinchX, self.y + 5 * ps - ps / 2 + flinchY, ps, ps)

    -- Draw rotating parts (barrel) using baked sprite with noise
    love.graphics.push()
    love.graphics.translate(self.x + flinchX, self.y + flinchY)
    love.graphics.rotate(self.angle + math.pi / 2)  -- Adjust for sprite pointing up

    -- Calculate gun kick offset (kicks backward = +y in local space)
    local kickOffset = self.gunKick * ps

    -- Draw barrel with kick offset
    for _, def in ipairs(bakedBarrelSprite) do
        local ox, oy, color = def[1], def[2], def[3]
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.rectangle("fill",
            ox * ps - ps / 2,
            oy * ps - ps / 2 + kickOffset,
            ps, ps)
    end

    -- Muzzle flash handled by Lighting system

    love.graphics.pop()

    -- Tower glow handled by Lighting system
end

function Turret:takeDamage(amount)
    self.hp = self.hp - amount
    self.damageFlinch = 1.0

    -- Screen shake + hit-stop via Feedback system
    Feedback:trigger("tower_damage")

    if self.hp <= 0 then
        self.hp = 0
        return true
    end
    return false
end

function Turret:getHpPercent()
    return self.hp / self.maxHp
end

return Turret
