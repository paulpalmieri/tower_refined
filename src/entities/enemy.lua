-- enemy.lua
-- Top-down pixel devil enemy with animated legs

local Enemy = Object:extend()

-- Color palettes for each enemy type
local DEVIL_COLORS_BASIC = {
    horn = {0.55, 0.15, 0.15},
    hornLight = {0.7, 0.25, 0.2},
    body = {0.85, 0.28, 0.32},
    bodyLight = {0.95, 0.4, 0.42},
    bodyDark = {0.65, 0.18, 0.22},
    bodyInner = {0.75, 0.22, 0.26},
    core = {0.4, 0.08, 0.12},
    eyeWhite = {1.0, 0.95, 0.7},
    eyePupil = {0.15, 0.08, 0.08},
    leg = {0.6, 0.2, 0.22},
    legDark = {0.45, 0.15, 0.18},
    tail = {0.7, 0.2, 0.22},
    tailTip = {0.5, 0.12, 0.15},
}

local DEVIL_COLORS_FAST = {
    horn = {0.15, 0.45, 0.15},
    hornLight = {0.2, 0.6, 0.25},
    body = {0.28, 0.75, 0.32},
    bodyLight = {0.4, 0.88, 0.45},
    bodyDark = {0.18, 0.55, 0.22},
    bodyInner = {0.22, 0.65, 0.26},
    core = {0.08, 0.35, 0.12},
    eyeWhite = {1.0, 0.95, 0.7},
    eyePupil = {0.08, 0.15, 0.08},
    leg = {0.2, 0.5, 0.22},
    legDark = {0.15, 0.38, 0.18},
    tail = {0.2, 0.6, 0.22},
    tailTip = {0.12, 0.42, 0.15},
}

local DEVIL_COLORS_TANK = {
    horn = {0.15, 0.15, 0.55},
    hornLight = {0.2, 0.25, 0.7},
    body = {0.28, 0.32, 0.85},
    bodyLight = {0.4, 0.45, 0.95},
    bodyDark = {0.18, 0.22, 0.65},
    bodyInner = {0.22, 0.26, 0.75},
    core = {0.08, 0.12, 0.4},
    eyeWhite = {1.0, 0.95, 0.7},
    eyePupil = {0.08, 0.08, 0.15},
    leg = {0.2, 0.22, 0.6},
    legDark = {0.15, 0.18, 0.45},
    tail = {0.2, 0.22, 0.7},
    tailTip = {0.12, 0.15, 0.5},
}

-- Layer destruction order (first = destroyed first)
local LAYER_ORDER = {
    horn = 1,
    leg = 2,
    outer = 3,
    inner = 4,
    eye = 5,
    core = 6,
}

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
local ANIM_FRAME_DURATION = 0.1  -- ~10 FPS walk cycle

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
    self.animSpeed = 1.0
    if enemyType == "fast" then
        self.speed = FAST_SPEED
        self.scale = 0.7
        self.maxHp = FAST_HP
        self.colors = DEVIL_COLORS_FAST
        self.animSpeed = 1.5  -- Faster leg scurry
    elseif enemyType == "tank" then
        self.speed = TANK_SPEED
        self.scale = 1.4
        self.maxHp = TANK_HP
        self.colors = DEVIL_COLORS_TANK
        self.animSpeed = 0.7  -- Slower lumber
    end
    self.hp = self.maxHp

    -- Speed variation (chaos)
    local speedMult = 1.0 + lume.random(-SPEED_VARIATION, SPEED_VARIATION)
    self.speed = self.speed * speedMult

    -- Visual grounding state
    self.bobOffset = 0
    self.spawnTimer = SPAWN_LAND_DURATION
    self.isSpawning = true

    -- Pending limb pixels (for accumulating damage before spawning chunks)
    self.pendingLimbPixels = {}

    -- Generate pixels for current frame
    self.pixels = {}
    self.basePixels = {}  -- Store original pixel definitions
    self.totalPixelCount = 0
    self:generatePixels()
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
        local bobPhase = (self.animTimer / ANIM_FRAME_DURATION) + (self.animFrame - 1)
        self.bobOffset = math.sin(bobPhase * math.pi) * BOB_AMPLITUDE

        -- Direct movement at constant speed
        self.x = self.x + self.vx * self.speed * dt
        self.y = self.y + self.vy * self.speed * dt
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

    -- Calculate spawn animation effects
    local spawnScale = 1.0
    local spawnAlpha = 1.0
    if self.isSpawning then
        local spawnProgress = 1 - (self.spawnTimer / SPAWN_LAND_DURATION)
        -- Ease out: starts big, shrinks to normal
        spawnScale = SPAWN_LAND_SCALE - (SPAWN_LAND_SCALE - 1) * spawnProgress * spawnProgress
        -- Alpha: fades in
        spawnAlpha = SPAWN_LAND_ALPHA + (1 - SPAWN_LAND_ALPHA) * spawnProgress
    end

    local finalScale = spawnScale

    -- Draw shadow first (before body, at ground level)
    -- Shadow scales/fades based on height (negative bobOffset = higher)
    local heightFactor = 1.0 + self.bobOffset / 10  -- Higher = smaller shadow
    heightFactor = math.max(0.5, math.min(1.0, heightFactor))  -- Clamp
    local shadowWidth = 5 * ps * 0.85 * heightFactor
    local shadowHeight = 3 * ps * 0.85 * heightFactor
    local shadowAlpha = SHADOW_ALPHA * spawnAlpha * heightFactor
    love.graphics.setColor(0, 0, 0, shadowAlpha)
    love.graphics.ellipse("fill",
        self.x + SHADOW_OFFSET_X,
        self.y + SHADOW_OFFSET_Y,
        shadowWidth, shadowHeight)

    -- Draw body with bobbing offset and spawn effects
    love.graphics.push()
    love.graphics.translate(self.x, self.y + self.bobOffset)
    love.graphics.rotate(self.angle)
    love.graphics.scale(finalScale, finalScale)

    for _, pixel in ipairs(self.pixels) do
        if pixel.alive then
            local drawColor = pixel.color

            if self.flashTimer > 0 then
                drawColor = {1, 1, 1}
            end

            love.graphics.setColor(drawColor[1], drawColor[2], drawColor[3], spawnAlpha)
            love.graphics.rectangle("fill",
                pixel.ox - ps / 2,
                pixel.oy - ps / 2,
                ps,
                ps)
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
    local speed = lume.random(PIXEL_SCATTER_VELOCITY * 0.8, PIXEL_SCATTER_VELOCITY * 1.2)

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

function Enemy:takeDamage(hitX, hitY, amount, bulletAngle)
    self.flashTimer = BLOB_FLASH_DURATION

    -- Apply knockback in bullet direction
    if bulletAngle then
        self:applyKnockback(bulletAngle, KNOCKBACK_FORCE)
    end

    triggerScreenShake(SCREEN_SHAKE_ON_HIT, SCREEN_SHAKE_DURATION * 0.5)

    -- Reduce HP
    self.hp = self.hp - amount

    -- Death check BEFORE pixel destruction
    if self.hp <= 0 then
        -- Flush any pending limb pixels before death
        self:flushPendingLimb(bulletAngle)
        self:die(bulletAngle or 0)
        return amount, true
    end

    -- Calculate how many pixels should remain based on HP percentage
    local hpPercent = math.max(0, self.hp / self.maxHp)
    local targetPixels = math.ceil(self.totalPixelCount * hpPercent)
    local currentPixels = self:getAliveCount()
    local pixelsToDestroy = currentPixels - targetPixels

    local ps = BLOB_PIXEL_SIZE * self.scale
    local frameData = DEVIL_FRAMES[self.animFrame]
    local cosA = math.cos(self.angle)
    local sinA = math.sin(self.angle)

    -- Spawn blood spray particles (fast, tight spread)
    local baseAngle = bulletAngle or 0
    for i = 1, 6 do
        local angle = baseAngle + lume.random(-0.25, 0.25)
        local speed = lume.random(300, 450)
        spawnParticle({
            x = hitX,
            y = hitY,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            color = {0.6, 0.08, 0.08},  -- dark red blood
            size = lume.random(1, 3),
            lifetime = lume.random(0.15, 0.3)
        })
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

    local ps = BLOB_PIXEL_SIZE * self.scale

    triggerScreenShake(SCREEN_SHAKE_INTENSITY, SCREEN_SHAKE_DURATION)

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
                    local speed = lume.random(DEATH_BURST_VELOCITY * 0.6, DEATH_BURST_VELOCITY * 1.0)

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
