-- enemy.lua
-- Top-down pixel devil enemy with animated legs

local Enemy = Object:extend()
local MonsterSpec = require "src.monster_spec"

-- Get color palettes from MonsterSpec
local DEVIL_COLORS_BASIC = MonsterSpec.palettes.basic
local DEVIL_COLORS_FAST = MonsterSpec.palettes.fast
local DEVIL_COLORS_TANK = MonsterSpec.palettes.tank

-- Get layer order from MonsterSpec
local LAYER_ORDER = MonsterSpec.LAYER_ORDER

-- Animation frames for walking (4 frames)
-- Top-down view: horns point up (forward), tail points down (back)
-- Legs move FORWARD/BACKWARD (Y axis) for realistic running gait
local DEVIL_FRAMES = {
    -- Frame 1: Diagonal stride A (Left-front + Right-back reaching forward)
    {
        -- Horns (pointing forward/up)
        {-1, -5, "horn", "horn"},
        {0, -6, "horn", "hornLight"},
        {1, -5, "horn", "horn"},

        -- Head top
        {-2, -4, "outer", "body"},
        {-1, -4, "outer", "bodyLight"},
        {0, -4, "outer", "bodyLight"},
        {1, -4, "outer", "bodyLight"},
        {2, -4, "outer", "body"},

        -- Head with eyes
        {-2, -3, "outer", "body"},
        {-1, -3, "eye", "eyeWhite"},
        {0, -3, "inner", "bodyInner"},
        {1, -3, "eye", "eyeWhite"},
        {2, -3, "outer", "body"},

        -- Front legs (LEFT reaching forward, RIGHT pushing back)
        {-3, -4, "leg", "leg"},      -- Left front FORWARD (y=-4, reaching ahead)
        {-4, -3, "leg", "legDark"},
        {3, -1, "leg", "legDark"},   -- Right front BACK (y=-1, pushing behind)
        {4, 0, "leg", "leg"},

        -- Upper body
        {-2, -2, "outer", "body"},
        {-1, -2, "inner", "bodyInner"},
        {0, -2, "core", "core"},
        {1, -2, "inner", "bodyInner"},
        {2, -2, "outer", "body"},

        -- Mid body
        {-2, -1, "outer", "body"},
        {-1, -1, "inner", "bodyInner"},
        {0, -1, "core", "core"},
        {1, -1, "inner", "bodyInner"},
        {2, -1, "outer", "body"},

        -- Lower body
        {-2, 0, "outer", "bodyDark"},
        {-1, 0, "inner", "body"},
        {0, 0, "inner", "bodyInner"},
        {1, 0, "inner", "body"},
        {2, 0, "outer", "bodyDark"},

        -- Back legs (RIGHT reaching forward, LEFT pushing back)
        {3, 0, "leg", "legDark"},    -- Right back FORWARD (y=0, reaching)
        {4, -1, "leg", "leg"},
        {-3, 2, "leg", "legDark"},   -- Left back BACK (y=2, pushing)
        {-4, 3, "leg", "leg"},

        -- Rump
        {-1, 1, "outer", "bodyDark"},
        {0, 1, "outer", "body"},
        {1, 1, "outer", "bodyDark"},

        -- Tail
        {0, 2, "outer", "tail"},
        {0, 3, "outer", "tail"},
        {-1, 4, "outer", "tailTip"},
    },

    -- Frame 2: Passing position (legs underneath body)
    {
        -- Horns
        {-1, -5, "horn", "horn"},
        {0, -6, "horn", "hornLight"},
        {1, -5, "horn", "horn"},

        -- Head top
        {-2, -4, "outer", "body"},
        {-1, -4, "outer", "bodyLight"},
        {0, -4, "outer", "bodyLight"},
        {1, -4, "outer", "bodyLight"},
        {2, -4, "outer", "body"},

        -- Head with eyes
        {-2, -3, "outer", "body"},
        {-1, -3, "eye", "eyeWhite"},
        {0, -3, "inner", "bodyInner"},
        {1, -3, "eye", "eyeWhite"},
        {2, -3, "outer", "body"},

        -- Front legs (neutral, tucked under)
        {-3, -2, "leg", "leg"},
        {-4, -2, "leg", "legDark"},
        {3, -2, "leg", "leg"},
        {4, -2, "leg", "legDark"},

        -- Upper body
        {-2, -2, "outer", "body"},
        {-1, -2, "inner", "bodyInner"},
        {0, -2, "core", "core"},
        {1, -2, "inner", "bodyInner"},
        {2, -2, "outer", "body"},

        -- Mid body
        {-2, -1, "outer", "body"},
        {-1, -1, "inner", "bodyInner"},
        {0, -1, "core", "core"},
        {1, -1, "inner", "bodyInner"},
        {2, -1, "outer", "body"},

        -- Lower body
        {-2, 0, "outer", "bodyDark"},
        {-1, 0, "inner", "body"},
        {0, 0, "inner", "bodyInner"},
        {1, 0, "inner", "body"},
        {2, 0, "outer", "bodyDark"},

        -- Back legs (neutral, tucked under)
        {-3, 1, "leg", "leg"},
        {-4, 1, "leg", "legDark"},
        {3, 1, "leg", "leg"},
        {4, 1, "leg", "legDark"},

        -- Rump
        {-1, 1, "outer", "bodyDark"},
        {0, 1, "outer", "body"},
        {1, 1, "outer", "bodyDark"},

        -- Tail
        {0, 2, "outer", "tail"},
        {0, 3, "outer", "tail"},
        {1, 4, "outer", "tailTip"},
    },

    -- Frame 3: Diagonal stride B (Right-front + Left-back reaching forward)
    {
        -- Horns
        {-1, -5, "horn", "horn"},
        {0, -6, "horn", "hornLight"},
        {1, -5, "horn", "horn"},

        -- Head top
        {-2, -4, "outer", "body"},
        {-1, -4, "outer", "bodyLight"},
        {0, -4, "outer", "bodyLight"},
        {1, -4, "outer", "bodyLight"},
        {2, -4, "outer", "body"},

        -- Head with eyes
        {-2, -3, "outer", "body"},
        {-1, -3, "eye", "eyeWhite"},
        {0, -3, "inner", "bodyInner"},
        {1, -3, "eye", "eyeWhite"},
        {2, -3, "outer", "body"},

        -- Front legs (RIGHT reaching forward, LEFT pushing back)
        {-3, -1, "leg", "legDark"},  -- Left front BACK (y=-1, pushing)
        {-4, 0, "leg", "leg"},
        {3, -4, "leg", "legDark"},   -- Right front FORWARD (y=-4, reaching)
        {4, -3, "leg", "leg"},

        -- Upper body
        {-2, -2, "outer", "body"},
        {-1, -2, "inner", "bodyInner"},
        {0, -2, "core", "core"},
        {1, -2, "inner", "bodyInner"},
        {2, -2, "outer", "body"},

        -- Mid body
        {-2, -1, "outer", "body"},
        {-1, -1, "inner", "bodyInner"},
        {0, -1, "core", "core"},
        {1, -1, "inner", "bodyInner"},
        {2, -1, "outer", "body"},

        -- Lower body
        {-2, 0, "outer", "bodyDark"},
        {-1, 0, "inner", "body"},
        {0, 0, "inner", "bodyInner"},
        {1, 0, "inner", "body"},
        {2, 0, "outer", "bodyDark"},

        -- Back legs (LEFT reaching forward, RIGHT pushing back)
        {-3, 0, "leg", "legDark"},   -- Left back FORWARD (y=0, reaching)
        {-4, -1, "leg", "leg"},
        {3, 2, "leg", "legDark"},    -- Right back BACK (y=2, pushing)
        {4, 3, "leg", "leg"},

        -- Rump
        {-1, 1, "outer", "bodyDark"},
        {0, 1, "outer", "body"},
        {1, 1, "outer", "bodyDark"},

        -- Tail
        {0, 2, "outer", "tail"},
        {0, 3, "outer", "tail"},
        {-1, 4, "outer", "tailTip"},
    },

    -- Frame 4: Passing position (legs underneath body)
    {
        -- Horns
        {-1, -5, "horn", "horn"},
        {0, -6, "horn", "hornLight"},
        {1, -5, "horn", "horn"},

        -- Head top
        {-2, -4, "outer", "body"},
        {-1, -4, "outer", "bodyLight"},
        {0, -4, "outer", "bodyLight"},
        {1, -4, "outer", "bodyLight"},
        {2, -4, "outer", "body"},

        -- Head with eyes
        {-2, -3, "outer", "body"},
        {-1, -3, "eye", "eyeWhite"},
        {0, -3, "inner", "bodyInner"},
        {1, -3, "eye", "eyeWhite"},
        {2, -3, "outer", "body"},

        -- Front legs (neutral, tucked under)
        {-3, -2, "leg", "legDark"},
        {-4, -2, "leg", "leg"},
        {3, -2, "leg", "legDark"},
        {4, -2, "leg", "leg"},

        -- Upper body
        {-2, -2, "outer", "body"},
        {-1, -2, "inner", "bodyInner"},
        {0, -2, "core", "core"},
        {1, -2, "inner", "bodyInner"},
        {2, -2, "outer", "body"},

        -- Mid body
        {-2, -1, "outer", "body"},
        {-1, -1, "inner", "bodyInner"},
        {0, -1, "core", "core"},
        {1, -1, "inner", "bodyInner"},
        {2, -1, "outer", "body"},

        -- Lower body
        {-2, 0, "outer", "bodyDark"},
        {-1, 0, "inner", "body"},
        {0, 0, "inner", "bodyInner"},
        {1, 0, "inner", "body"},
        {2, 0, "outer", "bodyDark"},

        -- Back legs (neutral, tucked under)
        {-3, 1, "leg", "legDark"},
        {-4, 1, "leg", "leg"},
        {3, 1, "leg", "legDark"},
        {4, 1, "leg", "leg"},

        -- Rump
        {-1, 1, "outer", "bodyDark"},
        {0, 1, "outer", "body"},
        {1, 1, "outer", "bodyDark"},

        -- Tail
        {0, 2, "outer", "tail"},
        {0, 3, "outer", "tail"},
        {1, 4, "outer", "tailTip"},
    },
}

-- Animation constants
local ANIM_FRAME_DURATION = 0.017  -- ~10 FPS walk cycle (slower, more deliberate)

function Enemy:new(x, y, scale, enemyType)
    self.x = x
    self.y = y
    self.scale = scale or 1.0
    self.enemyType = enemyType or "basic"
    self.dead = false
    self.flashTimer = 0

    -- Movement
    self.vx = 0
    self.vy = 0
    self.speed = BASIC_SPEED
    self.angle = 0

    -- Knockback
    self.knockbackVx = 0
    self.knockbackVy = 0
    self.knockbackTimer = 0

    -- Animation
    self.animFrame = 1
    self.animTimer = 0

    -- HP system and color palette based on enemy type
    self.maxHp = BASIC_HP
    self.colors = DEVIL_COLORS_BASIC
    if enemyType == "fast" then
        self.speed = FAST_SPEED
        self.scale = 0.7
        self.maxHp = FAST_HP
        self.colors = DEVIL_COLORS_FAST
    elseif enemyType == "tank" then
        self.speed = TANK_SPEED
        self.scale = 1.4
        self.maxHp = TANK_HP
        self.colors = DEVIL_COLORS_TANK
    end
    self.hp = self.maxHp

    -- Speed variation (chaos)
    local speedMult = 1.0 + lume.random(-SPEED_VARIATION, SPEED_VARIATION)
    self.speed = self.speed * speedMult

    -- Animation speed scales with movement speed so legs match travel
    self.animSpeed = self.speed * ANIM_SPEED_SCALE

    -- Visual grounding state
    self.bobOffset = 0
    self.swayOffset = 0
    self.spawnTimer = SPAWN_LAND_DURATION
    self.isSpawning = true

    -- Pending limb pixels (for accumulating damage before spawning chunks)
    self.pendingLimbPixels = {}

    -- Health threshold tracking for dismemberment
    self.lastHpPercent = 1.0          -- Previous HP percentage
    self.brokenParts = {}             -- Track which thresholds have triggered

    -- Generate pixels for current frame
    self.pixels = {}
    self.basePixels = {}  -- Store original pixel definitions
    self.totalPixelCount = 0
    self:generatePixels()

    -- Register eye lights with Lighting system
    self.eyeLightIds = {}
    self:registerEyeLights()

    -- Register body glow with Lighting system (uses body color)
    self.bodyGlowId = nil
    self:registerBodyGlow()
end

-- Register eye lights with the Lighting system
function Enemy:registerEyeLights()
    for _, bp in ipairs(self.basePixels) do
        if bp.layer == "eye" then
            local lightId = Lighting:addEyeGlow(self, 0, 0)
            table.insert(self.eyeLightIds, lightId)
        end
    end
end

-- Remove eye lights from the Lighting system
function Enemy:removeEyeLights()
    for _, lightId in ipairs(self.eyeLightIds) do
        Lighting:removeLight(lightId)
    end
    self.eyeLightIds = {}
end

-- Register body glow with the Lighting system
function Enemy:registerBodyGlow()
    -- Use the body color from the enemy's palette for the glow
    local glowColor = self.colors.body
    self.bodyGlowId = Lighting:addEnemyBodyGlow(self, glowColor)
end

-- Remove body glow from the Lighting system
function Enemy:removeBodyGlow()
    if self.bodyGlowId then
        Lighting:removeLight(self.bodyGlowId)
        self.bodyGlowId = nil
    end
end

function Enemy:generatePixels()
    local ps = BLOB_PIXEL_SIZE * self.scale
    local frameData = DEVIL_FRAMES[self.animFrame]

    -- Store base definitions for damage tracking (only once)
    if #self.basePixels == 0 then
        for i, def in ipairs(frameData) do
            local ox, oy, layer, colorKey = def[1], def[2], def[3], def[4]
            local baseColor = self.colors[colorKey]

            local variation = lume.random(-0.03, 0.03)
            local color = {
                lume.clamp(baseColor[1] + variation, 0, 1),
                lume.clamp(baseColor[2] + variation, 0, 1),
                lume.clamp(baseColor[3] + variation, 0, 1)
            }

            self.basePixels[i] = {
                baseOx = ox,
                baseOy = oy,
                layer = layer,
                layerOrder = LAYER_ORDER[layer] or 3,
                color = color,
                alive = true
            }
        end
        self.totalPixelCount = #self.basePixels
    end

    -- Update pixel positions from current frame
    self.pixels = {}
    for i, def in ipairs(frameData) do
        local ox, oy = def[1], def[2]

        if self.basePixels[i] and self.basePixels[i].alive then
            table.insert(self.pixels, {
                ox = ox * ps,
                oy = oy * ps,
                layer = self.basePixels[i].layer,
                layerOrder = self.basePixels[i].layerOrder,
                color = self.basePixels[i].color,
                alive = true,
                baseIndex = i
            })
        end
    end
end

function Enemy:update(dt)
    -- Spawn landing animation
    if self.isSpawning then
        self.spawnTimer = self.spawnTimer - dt
        if self.spawnTimer <= 0 then
            self.isSpawning = false
        end
    end

    -- Flash timer
    if self.flashTimer > 0 then
        self.flashTimer = self.flashTimer - dt
    end

    -- Knockback physics (the juicy part)
    if self.knockbackTimer > 0 then
        self.knockbackTimer = self.knockbackTimer - dt
        self.x = self.x + self.knockbackVx * dt
        self.y = self.y + self.knockbackVy * dt
        self.knockbackVx = self.knockbackVx * 0.85
        self.knockbackVy = self.knockbackVy * 0.85
    end

    -- Movement toward target
    if self.vx ~= 0 or self.vy ~= 0 then
        -- Instant facing (no smooth turning)
        self.angle = math.atan2(self.vy, self.vx) + math.pi / 2

        -- Walk animation (purely visual)
        self.animTimer = self.animTimer + dt * self.animSpeed
        if self.animTimer >= ANIM_FRAME_DURATION then
            self.animTimer = 0
            self.animFrame = (self.animFrame % 4) + 1
            self:generatePixels()

            -- Dust on push frames
            if self.animFrame == 1 or self.animFrame == 3 then
                spawnDust(self.x, self.y, self.angle - math.pi / 2)
            end
        end

        -- Simple sine bob (critter feel)
        -- bobPhase goes 0→4 over one full walk cycle (4 frames)
        local bobPhase = (self.animTimer / ANIM_FRAME_DURATION) + (self.animFrame - 1)

        -- Bob happens twice per cycle (up on each push frame)
        self.bobOffset = math.sin(bobPhase * math.pi) * BOB_AMPLITUDE

        -- Sway happens once per cycle (body shifts opposite to pushing legs)
        -- Use half frequency so one full left-right-left cycle per 4 frames
        self.swayOffset = math.sin(bobPhase * math.pi * 0.5) * SWAY_AMPLITUDE

        -- Direct movement at constant speed
        local newX = self.x + self.vx * self.speed * dt
        local newY = self.y + self.vy * self.speed * dt

        -- Clamp to tower pad boundary (don't enter the pad)
        local padHalfSize = TOWER_PAD_SIZE * BLOB_PIXEL_SIZE * TURRET_SCALE
        local towerX, towerY = CENTER_X, CENTER_Y

        -- Check if new position would be inside pad
        local dxNew = newX - towerX
        local dyNew = newY - towerY
        if math.abs(dxNew) < padHalfSize and math.abs(dyNew) < padHalfSize then
            -- Clamp to nearest edge
            if math.abs(dxNew) > math.abs(dyNew) then
                -- Closer to left/right edge
                newX = towerX + (dxNew > 0 and padHalfSize or -padHalfSize)
            else
                -- Closer to top/bottom edge
                newY = towerY + (dyNew > 0 and padHalfSize or -padHalfSize)
            end
        end

        self.x = newX
        self.y = newY
    end
end

function Enemy:moveToward(targetX, targetY)
    local dx = targetX - self.x
    local dy = targetY - self.y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 0 then
        -- Normalized direction vector
        self.vx = dx / dist
        self.vy = dy / dist
    end
end

function Enemy:applyKnockback(angle, force)
    self.knockbackVx = math.cos(angle) * force
    self.knockbackVy = math.sin(angle) * force
    self.knockbackTimer = KNOCKBACK_DURATION
end

function Enemy:draw()
    local ps = BLOB_PIXEL_SIZE * self.scale

    -- Calculate distance from center for fog visibility
    local distFromCenter = math.sqrt((self.x - CENTER_X)^2 + (self.y - CENTER_Y)^2)

    -- Fog visibility based on vignette area
    local maxDist = math.sqrt(WINDOW_WIDTH * WINDOW_WIDTH / 4 + WINDOW_HEIGHT * WINDOW_HEIGHT / 4)
    local visibleDist = maxDist * VIGNETTE_START
    local fogDist = maxDist * 0.85

    local bodyAlpha = 1.0
    if distFromCenter > visibleDist then
        bodyAlpha = 1.0 - math.min(1.0, (distFromCenter - visibleDist) / (fogDist - visibleDist))
    end

    -- Fog glow factor (1 = fully in fog, 0 = fully visible)
    local fogGlow = 1.0 - bodyAlpha

    -- Draw body with bobbing offset
    -- Sway is applied perpendicular to facing direction (local X after rotation)
    love.graphics.push()
    love.graphics.translate(self.x, self.y + self.bobOffset)
    love.graphics.rotate(self.angle)
    love.graphics.translate(self.swayOffset, 0)  -- Local X = perpendicular to facing

    -- Draw edge glow when in fog (outline effect)
    if fogGlow > 0.1 then
        local glowColor = EYE_LIGHT_COLOR
        local glowAlpha = fogGlow * 0.3
        local glowOffset = ps * 0.4

        -- Draw glow behind each pixel (offset in multiple directions for outline effect)
        for _, pixel in ipairs(self.pixels) do
            if pixel.alive then
                love.graphics.setColor(glowColor[1], glowColor[2], glowColor[3], glowAlpha)
                -- Draw slightly larger rectangles offset in each direction
                for _, dir in ipairs({{1,0}, {-1,0}, {0,1}, {0,-1}}) do
                    love.graphics.rectangle("fill",
                        pixel.ox - ps / 2 + dir[1] * glowOffset,
                        pixel.oy - ps / 2 + dir[2] * glowOffset,
                        ps, ps)
                end
            end
        end
    end

    -- Draw all body pixels (non-eyes) with tight directional shading
    for _, pixel in ipairs(self.pixels) do
        if pixel.alive and pixel.layer ~= "eye" then
            local drawColor

            if self.flashTimer > 0 then
                drawColor = {1, 1, 1}
            else
                -- Tight directional shading: light from above-left
                -- normY: -1 at top (horns), +1 at bottom (tail)
                -- normX: -1 at left, +1 at right
                local normY = pixel.oy / (ps * 5)
                local normX = pixel.ox / (ps * 4)

                -- Base shading: darker at bottom, brighter at top
                local shade = -normY * ENEMY_SHADE_CONTRAST

                -- Add slight X-axis shading (light from left)
                shade = shade - normX * (ENEMY_SHADE_CONTRAST * 0.3)

                -- Top highlight boost
                if normY < -0.3 then
                    shade = shade + ENEMY_SHADE_HIGHLIGHT * (1 + normY / 0.3)
                end

                -- Edge darkening for outer pixels (more defined silhouette)
                if pixel.layer == "outer" then
                    shade = shade - 0.08
                end

                -- Apply shading
                local lightFactor = 1.0 + shade
                lightFactor = lume.clamp(lightFactor, 0.5, 1.3)

                drawColor = {
                    lume.clamp(pixel.color[1] * lightFactor, 0, 1),
                    lume.clamp(pixel.color[2] * lightFactor, 0, 1),
                    lume.clamp(pixel.color[3] * lightFactor, 0, 1)
                }
            end

            love.graphics.setColor(drawColor[1], drawColor[2], drawColor[3], bodyAlpha)
            love.graphics.rectangle("fill",
                pixel.ox - ps / 2,
                pixel.oy - ps / 2,
                ps, ps)
        end
    end

    -- Draw eyes (brighter, with glow when in fog)
    for _, pixel in ipairs(self.pixels) do
        if pixel.alive and pixel.layer == "eye" then
            -- Eye glow halo when in fog
            if fogGlow > 0.2 then
                local glowAlpha = fogGlow * 0.5
                love.graphics.setColor(EYE_LIGHT_COLOR[1], EYE_LIGHT_COLOR[2], EYE_LIGHT_COLOR[3], glowAlpha)
                love.graphics.rectangle("fill",
                    pixel.ox - ps,
                    pixel.oy - ps,
                    ps * 2, ps * 2)
            end

            -- Eye pixel (stays visible even in fog)
            local eyeAlpha = math.max(bodyAlpha, 0.6 + fogGlow * 0.4)
            local drawColor = pixel.color

            if self.flashTimer > 0 then
                drawColor = {1, 1, 1}
            elseif fogGlow > 0.1 then
                -- Brighten eyes in fog
                drawColor = {
                    math.min(1, pixel.color[1] + fogGlow * 0.3),
                    math.min(1, pixel.color[2] + fogGlow * 0.1),
                    math.min(1, pixel.color[3] + fogGlow * 0.1),
                }
            end

            love.graphics.setColor(drawColor[1], drawColor[2], drawColor[3], eyeAlpha)
            love.graphics.rectangle("fill",
                pixel.ox - ps / 2,
                pixel.oy - ps / 2,
                ps, ps)
        end
    end

    love.graphics.pop()
end

function Enemy:containsPoint(px, py)
    local ps = BLOB_PIXEL_SIZE * self.scale
    local bounds = 6 * ps

    if math.abs(px - self.x) > bounds or math.abs(py - self.y) > bounds then
        return false
    end

    for _, pixel in ipairs(self.pixels) do
        if pixel.alive then
            -- Transform point to local space
            local dx = px - self.x
            local dy = py - self.y
            local cosA = math.cos(-self.angle)
            local sinA = math.sin(-self.angle)
            local localX = dx * cosA - dy * sinA
            local localY = dx * sinA + dy * cosA

            local dist = math.sqrt((localX - pixel.ox) ^ 2 + (localY - pixel.oy) ^ 2)
            if dist < ps * 1.5 then
                return true
            end
        end
    end
    return false
end

function Enemy:getAliveCount()
    local count = 0
    for _, bp in ipairs(self.basePixels) do
        if bp.alive then
            count = count + 1
        end
    end
    return count
end

-- Get indices of pixels adjacent to the given pixel (8-way adjacency)
function Enemy:getAdjacentPixels(pixelIndex)
    local target = self.basePixels[pixelIndex]
    if not target then return {} end

    local adjacent = {}
    for i, bp in ipairs(self.basePixels) do
        if i ~= pixelIndex and bp.alive then
            local dx = math.abs(bp.baseOx - target.baseOx)
            local dy = math.abs(bp.baseOy - target.baseOy)
            if dx <= 1 and dy <= 1 then
                table.insert(adjacent, i)
            end
        end
    end
    return adjacent
end

-- Select an organic-shaped group of pixels using region growing
function Enemy:selectOrganicPixelGroup(seedIndex, targetCount)
    local selected = {}
    local selectedCount = 1
    local candidates = {}

    -- Start with seed
    selected[seedIndex] = true

    -- Add seed's neighbors as initial candidates
    for _, adjIdx in ipairs(self:getAdjacentPixels(seedIndex)) do
        if not selected[adjIdx] then
            -- Score: layer priority + adjacency bonus + randomness
            local bp = self.basePixels[adjIdx]
            local score = (7 - bp.layerOrder) * 10  -- Outer layers first
            score = score + CHUNK_NEIGHBOR_WEIGHT * 20  -- Adjacent to selected
            score = score + lume.random(0, 30 * CHUNK_SHAPE_IRREGULARITY)
            candidates[adjIdx] = score
        end
    end

    -- Grow region until we reach target count
    while selectedCount < targetCount do
        -- Find best candidate
        local bestIdx, bestScore = nil, -1
        for idx, score in pairs(candidates) do
            if score > bestScore then
                bestIdx = idx
                bestScore = score
            end
        end

        if not bestIdx then break end  -- No more candidates

        -- Add best to selected
        selected[bestIdx] = true
        selectedCount = selectedCount + 1
        candidates[bestIdx] = nil

        -- Add new adjacent candidates
        for _, adjIdx in ipairs(self:getAdjacentPixels(bestIdx)) do
            if not selected[adjIdx] and not candidates[adjIdx] then
                local bp = self.basePixels[adjIdx]
                -- Count how many selected neighbors
                local adjCount = 0
                for _, checkAdj in ipairs(self:getAdjacentPixels(adjIdx)) do
                    if selected[checkAdj] then adjCount = adjCount + 1 end
                end

                local score = (7 - bp.layerOrder) * 10
                score = score + adjCount * CHUNK_NEIGHBOR_WEIGHT * 20
                score = score + lume.random(0, 30 * CHUNK_SHAPE_IRREGULARITY)
                candidates[adjIdx] = score
            end
        end
    end

    return selected
end

-- Spawn a chunk from pending limb pixels
function Enemy:spawnLimbFromPending(bulletAngle)
    if #self.pendingLimbPixels < 1 then return end

    local ps = BLOB_PIXEL_SIZE * self.scale
    local baseAngle = bulletAngle or 0

    -- Calculate center of pending pixels
    local centerX, centerY = 0, 0
    for _, p in ipairs(self.pendingLimbPixels) do
        centerX = centerX + p.worldX
        centerY = centerY + p.worldY
    end
    centerX = centerX / #self.pendingLimbPixels
    centerY = centerY / #self.pendingLimbPixels

    -- Convert to offsets from center
    local pixels = {}
    for _, p in ipairs(self.pendingLimbPixels) do
        table.insert(pixels, {
            ox = p.worldX - centerX,
            oy = p.worldY - centerY,
            color = p.color
        })
    end

    -- Spawn chunk flying in bullet direction
    local angle = baseAngle + lume.random(-0.3, 0.3)
    local speed = lume.random(PROJECTILE_SPEED * LIMB_VELOCITY_RATIO * 0.8, PROJECTILE_SPEED * LIMB_VELOCITY_RATIO * 1.2)

    spawnChunk({
        x = centerX,
        y = centerY,
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        pixels = pixels,
        size = ps
    })

    -- Clear pending
    self.pendingLimbPixels = {}
end

-- Force spawn any pending pixels (called before death)
function Enemy:flushPendingLimb(bulletAngle)
    if #self.pendingLimbPixels > 0 then
        self:spawnLimbFromPending(bulletAngle)
    end
end

-- Eject pixels belonging to layers associated with a health threshold
-- Called when HP crosses a threshold (e.g., 75%, 50%, 25%)
function Enemy:ejectLimbAtThreshold(threshold, bulletAngle)
    local layers = MonsterSpec.getLayersForThreshold(threshold)
    if not layers or #layers == 0 then return end

    local ps = BLOB_PIXEL_SIZE * self.scale
    local frameData = DEVIL_FRAMES[self.animFrame]
    local cosA = math.cos(self.angle)
    local sinA = math.sin(self.angle)

    -- Collect pixels belonging to the threshold's layers
    local limbPixels = {}
    local centerX, centerY = 0, 0
    local pixelCount = 0

    for i, bp in ipairs(self.basePixels) do
        if bp.alive and frameData[i] then
            -- Check if this pixel's layer matches any in the threshold
            for _, layer in ipairs(layers) do
                if bp.layer == layer then
                    bp.alive = false  -- Mark as destroyed

                    local ox = frameData[i][1] * ps
                    local oy = frameData[i][2] * ps
                    local worldX = self.x + ox * cosA - oy * sinA
                    local worldY = self.y + ox * sinA + oy * cosA

                    table.insert(limbPixels, {
                        worldX = worldX,
                        worldY = worldY,
                        color = {bp.color[1], bp.color[2], bp.color[3]}
                    })
                    centerX = centerX + worldX
                    centerY = centerY + worldY
                    pixelCount = pixelCount + 1
                    break
                end
            end
        end
    end

    -- Spawn the limb chunk if we have enough pixels
    if pixelCount > 0 then
        centerX = centerX / pixelCount
        centerY = centerY / pixelCount

        -- Convert to offsets from center
        local pixels = {}
        for _, lp in ipairs(limbPixels) do
            table.insert(pixels, {
                ox = lp.worldX - centerX,
                oy = lp.worldY - centerY,
                color = lp.color
            })
        end

        -- Use DebrisManager if available
        if DebrisManager and DebrisManager.spawnLimb then
            DebrisManager:spawnLimb(centerX, centerY, bulletAngle, pixels, PROJECTILE_SPEED * LIMB_VELOCITY_RATIO)
        else
            -- Fallback: spawn directly
            local angle = bulletAngle + lume.random(-0.3, 0.3)
            local speed = lume.random(PROJECTILE_SPEED * LIMB_VELOCITY_RATIO * 0.8, PROJECTILE_SPEED * LIMB_VELOCITY_RATIO * 1.2)
            spawnChunk({
                x = centerX,
                y = centerY,
                vx = math.cos(angle) * speed,
                vy = math.sin(angle) * speed,
                pixels = pixels,
                size = ps
            })
        end

        -- Regenerate pixels after limb ejection
        self:generatePixels()
    end
end

-- Force dismemberment for debugging - ejects limb at next threshold
function Enemy:forceDismember()
    -- Find the next threshold that hasn't been triggered
    for _, threshold in ipairs(DISMEMBER_THRESHOLDS) do
        if not self.brokenParts[threshold] then
            self.brokenParts[threshold] = true
            -- Use a random angle for the ejection
            local randomAngle = lume.random(0, math.pi * 2)
            self:ejectLimbAtThreshold(threshold, randomAngle)
            Feedback:trigger("limb_break")
            return true
        end
    end
    return false  -- All thresholds already triggered
end

function Enemy:takeDamage(hitX, hitY, amount, bulletAngle)
    self.flashTimer = BLOB_FLASH_DURATION

    -- Apply knockback in bullet direction
    if bulletAngle then
        self:applyKnockback(bulletAngle, KNOCKBACK_FORCE)
    end

    -- Track HP percentage before damage
    local oldHpPercent = self.lastHpPercent

    -- Reduce HP
    self.hp = self.hp - amount
    local newHpPercent = math.max(0, self.hp / self.maxHp)
    self.lastHpPercent = newHpPercent

    -- Build damage context for feedback
    local damageContext = {
        damage_dealt = amount,
        current_hp = self.hp,
        max_hp = self.maxHp,
        impact_angle = bulletAngle or 0,
        impact_x = hitX,
        impact_y = hitY,
        enemy = self
    }

    -- Death check BEFORE pixel destruction
    if self.hp <= 0 then
        -- Flush any pending limb pixels before death
        self:flushPendingLimb(bulletAngle)
        self:die(bulletAngle or 0)
        return amount, true
    end

    -- Check for health threshold crossings (limb breaks)
    local thresholdCrossed = Feedback:checkThresholdCrossed(oldHpPercent, newHpPercent)
    if thresholdCrossed and not self.brokenParts[thresholdCrossed] then
        self.brokenParts[thresholdCrossed] = true
        self:ejectLimbAtThreshold(thresholdCrossed, bulletAngle or 0)
        Feedback:trigger("limb_break", damageContext)
    else
        -- Use damage-aware preset selection
        local preset = Feedback:getPresetForDamage(damageContext)
        Feedback:trigger(preset, damageContext)
    end

    -- Calculate how many pixels should remain based on HP percentage
    local hpPercent = newHpPercent
    local targetPixels = math.ceil(self.totalPixelCount * hpPercent)
    local currentPixels = self:getAliveCount()
    local pixelsToDestroy = currentPixels - targetPixels

    local ps = BLOB_PIXEL_SIZE * self.scale
    local frameData = DEVIL_FRAMES[self.animFrame]
    local cosA = math.cos(self.angle)
    local sinA = math.sin(self.angle)

    -- Spawn blood spray via DebrisManager if available, else fallback
    local baseAngle = bulletAngle or 0
    if DebrisManager and DebrisManager.spawnImpactEffects then
        DebrisManager:spawnImpactEffects(damageContext)
    else
        -- Fallback: spawn blood spray particles directly
        for _ = 1, 6 do
            local angle = baseAngle + lume.random(-0.25, 0.25)
            local speed = lume.random(300, 450)
            spawnParticle({
                x = hitX,
                y = hitY,
                vx = math.cos(angle) * speed,
                vy = math.sin(angle) * speed,
                color = {0.6, 0.08, 0.08},
                size = lume.random(1, 3),
                lifetime = lume.random(0.15, 0.3)
            })
        end
    end

    -- Only destroy if we need to remove pixels
    if pixelsToDestroy > 0 then
        -- Find seed pixel (closest to hit point, preferring outer layers)
        local seedCandidates = {}
        for i, bp in ipairs(self.basePixels) do
            if bp.alive and bp.layerOrder <= 4 then  -- Outer/inner layers
                if frameData[i] then
                    local ox = frameData[i][1] * ps
                    local oy = frameData[i][2] * ps
                    local worldX = self.x + ox * cosA - oy * sinA
                    local worldY = self.y + ox * sinA + oy * cosA
                    local dist = math.sqrt((worldX - hitX)^2 + (worldY - hitY)^2)
                    table.insert(seedCandidates, {index = i, dist = dist})
                end
            end
        end

        -- Pick closest pixel as seed
        table.sort(seedCandidates, function(a, b) return a.dist < b.dist end)
        local seedIndex = seedCandidates[1] and seedCandidates[1].index

        if seedIndex then
            -- Select organic group of pixels to destroy
            local selected = self:selectOrganicPixelGroup(seedIndex, pixelsToDestroy)

            -- Destroy selected pixels and add to pending limb
            for idx, _ in pairs(selected) do
                local bp = self.basePixels[idx]
                bp.alive = false

                if frameData[idx] then
                    local ox = frameData[idx][1] * ps
                    local oy = frameData[idx][2] * ps
                    local worldX = self.x + ox * cosA - oy * sinA
                    local worldY = self.y + ox * sinA + oy * cosA

                    table.insert(self.pendingLimbPixels, {
                        worldX = worldX,
                        worldY = worldY,
                        color = {bp.color[1], bp.color[2], bp.color[3]}
                    })
                end
            end

            -- Check if we have enough for a minimum-sized chunk
            if #self.pendingLimbPixels >= MIN_CHUNK_PIXELS then
                self:spawnLimbFromPending(bulletAngle)
            end

            -- Regenerate pixels after damage
            self:generatePixels()
        end
    end

    return amount, false
end

function Enemy:die(bulletAngle)
    self.dead = true

    -- Remove lights from Lighting system
    self:removeEyeLights()
    self:removeBodyGlow()

    local ps = BLOB_PIXEL_SIZE * self.scale

    -- Build context for total collapse feedback
    local deathContext = {
        damage_dealt = self.maxHp,  -- Assume lethal damage
        current_hp = 0,
        max_hp = self.maxHp,
        impact_angle = bulletAngle,
        impact_x = self.x,
        impact_y = self.y,
        enemy = self
    }

    -- Screen shake + hit-stop via Feedback system (total_collapse for death)
    Feedback:trigger("total_collapse", deathContext)

    local frameData = DEVIL_FRAMES[self.animFrame]
    local cosA = math.cos(self.angle)
    local sinA = math.sin(self.angle)

    -- Spawn blood spray (bigger burst on death)
    for i = 1, 10 do
        local angle = bulletAngle + lume.random(-0.4, 0.4)
        local speed = lume.random(350, 550)
        spawnParticle({
            x = self.x,
            y = self.y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            color = {0.6, 0.08, 0.08},
            size = lume.random(2, 4),
            lifetime = lume.random(0.2, 0.35)
        })
    end

    -- Collect all alive pixels with world positions
    local allPixels = {}
    for i, bp in ipairs(self.basePixels) do
        if bp.alive and frameData[i] then
            local ox = frameData[i][1] * ps
            local oy = frameData[i][2] * ps
            local worldX = self.x + ox * cosA - oy * sinA
            local worldY = self.y + ox * sinA + oy * cosA

            table.insert(allPixels, {
                worldX = worldX,
                worldY = worldY,
                localY = frameData[i][2],  -- for splitting into limbs
                color = {bp.color[1], bp.color[2], bp.color[3]}
            })
        end
    end

    -- Split pixels into organic limb groups (respecting minimum size)
    if #allPixels > 0 then
        -- Pre-compute random offsets for consistent sorting
        for i, p in ipairs(allPixels) do
            p.sortY = p.localY + lume.random(-0.5, 0.5) * CHUNK_SHAPE_IRREGULARITY
        end
        -- Sort by local Y with some randomness for organic cuts
        table.sort(allPixels, function(a, b)
            return a.sortY < b.sortY
        end)

        -- Determine number of limb chunks based on MIN_CHUNK_PIXELS
        local numLimbs = math.floor(#allPixels / MIN_CHUNK_PIXELS)
        numLimbs = math.max(1, math.min(4, numLimbs))  -- 1-4 chunks
        local pixelsPerLimb = math.ceil(#allPixels / numLimbs)

        for limbIndex = 1, numLimbs do
            local startIdx = (limbIndex - 1) * pixelsPerLimb + 1
            local endIdx = math.min(limbIndex * pixelsPerLimb, #allPixels)

            -- Add randomness to group boundaries for organic shapes
            if limbIndex < numLimbs and endIdx < #allPixels then
                local shift = math.floor(lume.random(-2, 2) * CHUNK_SHAPE_IRREGULARITY)
                endIdx = lume.clamp(endIdx + shift, startIdx + MIN_CHUNK_PIXELS - 1, #allPixels)
            end

            if startIdx <= #allPixels then
                -- Collect pixels for this limb
                local limbPixels = {}
                local centerX, centerY = 0, 0

                for i = startIdx, endIdx do
                    local p = allPixels[i]
                    if p then
                        table.insert(limbPixels, p)
                        centerX = centerX + p.worldX
                        centerY = centerY + p.worldY
                    end
                end

                if #limbPixels > 0 then
                    centerX = centerX / #limbPixels
                    centerY = centerY / #limbPixels

                    -- Convert to offset from center
                    local pixels = {}
                    for _, lp in ipairs(limbPixels) do
                        table.insert(pixels, {
                            ox = lp.worldX - centerX,
                            oy = lp.worldY - centerY,
                            color = lp.color
                        })
                    end

                    -- Spawn limb with spread in bullet direction
                    local angle = bulletAngle + lume.random(-0.8, 0.8)
                    local speed = lume.random(PROJECTILE_SPEED * DEATH_BURST_RATIO * 0.6, PROJECTILE_SPEED * DEATH_BURST_RATIO * 1.0)

                    spawnChunk({
                        x = centerX,
                        y = centerY,
                        vx = math.cos(angle) * speed,
                        vy = math.sin(angle) * speed,
                        pixels = pixels,
                        size = ps
                    })
                end
            end
        end
    end
end

function Enemy:getBounds()
    local ps = BLOB_PIXEL_SIZE * self.scale
    local halfWidth = 5 * ps
    local halfHeight = 6 * ps
    return self.x - halfWidth, self.y - halfHeight, halfWidth * 2, halfHeight * 2
end

function Enemy:distanceTo(x, y)
    return math.sqrt((self.x - x) ^ 2 + (self.y - y) ^ 2)
end

return Enemy
