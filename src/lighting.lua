-- src/lighting.lua
-- Centralized lighting system for the game
-- Handles point lights, vignette, and dynamic shadows

local Lighting = {}

-- Internal state
local lights = {}
local lightIdCounter = 0

-- Stats for debug
local stats = {
    activeLights = 0,
    muzzleFlashes = 0,
    projectileLights = 0,
    eyeLights = 0,
}

local debugMode = false

-- ===================
-- INITIALIZATION
-- ===================

function Lighting:init()
    lights = {}
    lightIdCounter = 0
    stats = {
        activeLights = 0,
        muzzleFlashes = 0,
        projectileLights = 0,
        eyeLights = 0,
    }
end

function Lighting:reset()
    self:init()
end

-- ===================
-- LIGHT MANAGEMENT
-- ===================

-- Add a new light source
-- params: {x, y, radius, intensity, color, falloff, flicker, pulse, pulseAmount, duration, type}
-- Returns light ID for later updates/removal
function Lighting:addLight(params)
    lightIdCounter = lightIdCounter + 1
    local id = lightIdCounter

    local light = {
        id = id,
        x = params.x or 0,
        y = params.y or 0,
        radius = params.radius or 50,
        intensity = params.intensity or 1.0,
        color = params.color or {1, 1, 1},
        falloff = params.falloff or 2.0,
        flicker = params.flicker or 0,
        pulse = params.pulse or 0,
        pulseAmount = params.pulseAmount or 0,
        duration = params.duration,  -- nil = permanent
        timer = 0,
        type = params.type or "generic",
        owner = params.owner,  -- Reference to owning entity
    }

    table.insert(lights, light)
    stats.activeLights = #lights

    return id
end

-- Update an existing light's properties
function Lighting:updateLight(id, params)
    for _, light in ipairs(lights) do
        if light.id == id then
            if params.x then light.x = params.x end
            if params.y then light.y = params.y end
            if params.radius then light.radius = params.radius end
            if params.intensity then light.intensity = params.intensity end
            if params.color then light.color = params.color end
            return true
        end
    end
    return false
end

-- Remove a light by ID
function Lighting:removeLight(id)
    for i = #lights, 1, -1 do
        if lights[i].id == id then
            table.remove(lights, i)
            stats.activeLights = #lights
            return true
        end
    end
    return false
end

-- ===================
-- CONVENIENCE METHODS
-- ===================

-- Add light for a projectile (call once when projectile created)
function Lighting:addProjectileLight(proj)
    local id = self:addLight({
        x = proj.x,
        y = proj.y,
        radius = PROJECTILE_LIGHT_RADIUS,
        intensity = PROJECTILE_LIGHT_INTENSITY,
        color = PROJECTILE_LIGHT_COLOR,
        falloff = 2.0,
        type = "projectile",
        owner = proj,
    })
    stats.projectileLights = stats.projectileLights + 1
    return id
end

-- Add muzzle flash (auto-expires, positioned at barrel tip)
function Lighting:addMuzzleFlash(x, y, angle)
    -- Store angle for directional rendering
    local id = self:addLight({
        x = x,
        y = y,
        radius = MUZZLE_FLASH_RADIUS,
        intensity = MUZZLE_FLASH_INTENSITY,
        color = MUZZLE_FLASH_COLOR,
        falloff = 2.5,  -- Tighter falloff for smaller apparent size
        duration = MUZZLE_FLASH_DURATION,
        type = "muzzle",
    })

    -- Store angle for cone rendering
    for _, light in ipairs(lights) do
        if light.id == id then
            light.angle = angle or 0
            break
        end
    end

    stats.muzzleFlashes = stats.muzzleFlashes + 1
    return id
end

-- Add eye glow for an enemy (with per-enemy variance)
function Lighting:addEyeGlow(enemy, eyeOffsetX, eyeOffsetY)
    -- Add variance per enemy for uniqueness
    local variance = lume.random(-EYE_LIGHT_VARIANCE, EYE_LIGHT_VARIANCE)
    local intensity = EYE_LIGHT_INTENSITY * (1 + variance)

    -- Slight color variance
    local color = {
        EYE_LIGHT_COLOR[1] + lume.random(-0.1, 0.1),
        EYE_LIGHT_COLOR[2] + lume.random(-0.05, 0.05),
        EYE_LIGHT_COLOR[3] + lume.random(-0.05, 0.05),
    }

    local id = self:addLight({
        x = enemy.x,
        y = enemy.y,
        radius = EYE_LIGHT_RADIUS,
        intensity = intensity,
        color = color,
        falloff = 2.5,
        flicker = EYE_LIGHT_FLICKER,
        type = "eye",
        owner = enemy,
    })

    -- Store offset for updating position relative to enemy
    for _, light in ipairs(lights) do
        if light.id == id then
            light.offsetX = eyeOffsetX or 0
            light.offsetY = eyeOffsetY or 0
            break
        end
    end

    stats.eyeLights = stats.eyeLights + 1
    return id
end

-- Add body glow for an enemy (uses enemy's body color)
function Lighting:addEnemyBodyGlow(enemy, glowColor)
    -- Scale radius with enemy scale
    local radius = ENEMY_GLOW_RADIUS * (enemy.scale or 1.0)

    local id = self:addLight({
        x = enemy.x,
        y = enemy.y,
        radius = radius,
        intensity = ENEMY_GLOW_INTENSITY,
        color = glowColor,
        falloff = 2.0,
        flicker = ENEMY_GLOW_FLICKER,
        type = "enemy_glow",
        owner = enemy,
    })

    return id
end

-- Add tower base glow (pulsing)
function Lighting:addTowerGlow(turret)
    return self:addLight({
        x = turret.x,
        y = turret.y,
        radius = TOWER_LIGHT_RADIUS,
        intensity = TOWER_LIGHT_INTENSITY,
        color = TOWER_LIGHT_COLOR,
        falloff = 2.0,
        pulse = TOWER_LIGHT_PULSE_SPEED,
        pulseAmount = TOWER_LIGHT_PULSE_AMOUNT,
        type = "tower",
        owner = turret,
    })
end

-- Add nuke explosion light (call this and update radius over time)
function Lighting:addNukeLight(x, y)
    return self:addLight({
        x = x,
        y = y,
        radius = NUKE_LIGHT_RADIUS,
        intensity = NUKE_LIGHT_INTENSITY,
        color = NUKE_LIGHT_COLOR,
        falloff = 1.0,
        duration = 0.3,
        type = "nuke",
    })
end

-- ===================
-- UPDATE
-- ===================

function Lighting:update(dt)
    -- Update all lights
    for i = #lights, 1, -1 do
        local light = lights[i]
        light.timer = light.timer + dt

        -- Handle duration-based lights (auto-expire)
        if light.duration then
            if light.timer >= light.duration then
                table.remove(lights, i)
            else
                -- Fade out intensity over duration
                local progress = light.timer / light.duration
                light.currentIntensity = light.intensity * (1 - progress)
            end
        else
            light.currentIntensity = light.intensity
        end

        -- Update position for entity-linked lights
        if light.owner then
            if light.owner.dead then
                -- Owner died, remove light
                table.remove(lights, i)
            else
                -- Follow owner position
                light.x = light.owner.x + (light.offsetX or 0)
                light.y = light.owner.y + (light.offsetY or 0)
            end
        end
    end

    stats.activeLights = #lights
end

-- ===================
-- RENDERING
-- ===================

-- Draw a single radial light using concentric circles
local function drawRadialLight(x, y, radius, color, intensity, falloff)
    local steps = LIGHTING_CIRCLE_SEGMENTS
    for i = steps, 1, -1 do
        local t = i / steps
        local r = radius * t
        -- Falloff: outer rings are dimmer
        local alpha = math.pow(1 - t, falloff) * intensity * 0.4

        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.circle("fill", x, y, r)
    end
end

-- Draw a cone-shaped muzzle flash
local function drawMuzzleFlashCone(x, y, radius, color, intensity, angle)
    local coneLength = radius * 1.5
    local coneWidth = radius * 0.6

    -- Direction vector
    local dx = math.cos(angle)
    local dy = math.sin(angle)

    -- Perpendicular vector for cone width
    local px = -dy
    local py = dx

    -- Draw layered cone for glow effect
    for i = 3, 1, -1 do
        local scale = i / 3
        local alpha = intensity * 0.35 * (1 - scale * 0.5)

        local sLength = coneLength * scale
        local sWidth = coneWidth * scale

        local sTipX = x + dx * sLength
        local sTipY = y + dy * sLength
        local sBaseLeftX = x + px * sWidth
        local sBaseLeftY = y + py * sWidth
        local sBaseRightX = x - px * sWidth
        local sBaseRightY = y - py * sWidth

        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.polygon("fill",
            sBaseLeftX, sBaseLeftY,
            sTipX, sTipY,
            sBaseRightX, sBaseRightY
        )
    end

    -- Bright core at muzzle
    love.graphics.setColor(color[1], color[2], color[3], intensity * 0.5)
    love.graphics.circle("fill", x, y, radius * 0.3)
end

-- Draw all lights (call with additive blend mode)
function Lighting:drawLights()
    love.graphics.setBlendMode("add")

    for _, light in ipairs(lights) do
        -- Skip if outside screen (basic culling)
        if light.x > -light.radius and light.x < WINDOW_WIDTH + light.radius and
           light.y > -light.radius and light.y < WINDOW_HEIGHT + light.radius then

            -- Calculate effective intensity
            local intensity = light.currentIntensity or light.intensity

            -- Apply flicker
            if light.flicker > 0 then
                intensity = intensity * (1 - light.flicker * lume.random())
            end

            -- Apply pulse
            if light.pulse > 0 then
                local pulseVal = math.sin(light.timer * light.pulse * math.pi * 2)
                intensity = intensity * (1 + pulseVal * light.pulseAmount)
            end

            -- Skip very dim lights
            if intensity > LIGHTING_MIN_INTENSITY then
                -- Use cone rendering for muzzle flashes
                if light.type == "muzzle" and light.angle then
                    drawMuzzleFlashCone(light.x, light.y, light.radius, light.color, intensity, light.angle)
                else
                    drawRadialLight(light.x, light.y, light.radius, light.color, intensity, light.falloff)
                end
            end
        end
    end

    love.graphics.setBlendMode("alpha")
end

-- Draw vignette (darkening at edges)
function Lighting:drawVignette()
    local cx, cy = CENTER_X, CENTER_Y
    local maxDist = math.sqrt(WINDOW_WIDTH * WINDOW_WIDTH / 4 + WINDOW_HEIGHT * WINDOW_HEIGHT / 4)
    local startDist = maxDist * VIGNETTE_START

    -- Draw dark rings at edges (alpha blend, black with increasing opacity)
    local steps = 20
    local ringWidth = (maxDist - startDist) / steps

    for i = 1, steps do
        local dist = startDist + (i - 0.5) * ringWidth
        local t = i / steps  -- 0 at center edge, 1 at screen edge
        local alpha = math.pow(t, VIGNETTE_FALLOFF) * VIGNETTE_STRENGTH

        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.setLineWidth(ringWidth + 2)
        love.graphics.circle("line", cx, cy, dist)
    end

    -- Fill corners (circles don't reach rectangular corners)
    local cornerAlpha = VIGNETTE_STRENGTH * 0.8
    love.graphics.setColor(0, 0, 0, cornerAlpha)
    love.graphics.rectangle("fill", 0, 0, 50, 50)  -- Top-left
    love.graphics.rectangle("fill", WINDOW_WIDTH - 50, 0, 50, 50)  -- Top-right
    love.graphics.rectangle("fill", 0, WINDOW_HEIGHT - 50, 50, 50)  -- Bottom-left
    love.graphics.rectangle("fill", WINDOW_WIDTH - 50, WINDOW_HEIGHT - 50, 50, 50)  -- Bottom-right

    love.graphics.setLineWidth(1)
end

-- ===================
-- SHADOWS
-- ===================

-- Calculate shadow offset based on nearby lights
function Lighting:getShadowOffset(x, y)
    local shadowDx, shadowDy = 0, 0
    local totalInfluence = 0

    -- Accumulate influence from all lights
    for _, light in ipairs(lights) do
        local dx = x - light.x
        local dy = y - light.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist < light.radius and dist > 0 then
            local intensity = light.currentIntensity or light.intensity
            local influence = (1 - dist / light.radius) * intensity
            shadowDx = shadowDx + (dx / dist) * influence
            shadowDy = shadowDy + (dy / dist) * influence
            totalInfluence = totalInfluence + influence
        end
    end

    -- Normalize and scale
    if totalInfluence > 0.1 then
        local len = math.sqrt(shadowDx * shadowDx + shadowDy * shadowDy)
        if len > 0 then
            shadowDx = (shadowDx / len) * SHADOW_MAX_OFFSET
            shadowDy = (shadowDy / len) * SHADOW_MAX_OFFSET
        end
    else
        -- Use global light direction when no dynamic lights nearby
        shadowDx = math.cos(SHADOW_GLOBAL_ANGLE) * SHADOW_MAX_OFFSET
        shadowDy = math.sin(SHADOW_GLOBAL_ANGLE) * SHADOW_MAX_OFFSET
    end

    -- Calculate alpha (shadows fade when near bright lights)
    local alpha = SHADOW_BASE_ALPHA * math.max(0.2, 1 - totalInfluence * 0.3)

    return shadowDx, shadowDy, alpha
end

-- Draw shadow for an entity
function Lighting:drawEntityShadow(entity, width, height)
    local shadowDx, shadowDy, alpha = self:getShadowOffset(entity.x, entity.y)

    -- Default dimensions based on entity scale
    local w = width or (entity.scale and (5 * BLOB_PIXEL_SIZE * entity.scale) or 30)
    local h = height or (w * 0.5)

    love.graphics.setColor(0, 0, 0, alpha)
    love.graphics.ellipse("fill", entity.x + shadowDx, entity.y + shadowDy, w, h)
end

-- ===================
-- DEBUG
-- ===================

function Lighting:setDebugMode(enabled)
    debugMode = enabled
end

function Lighting:getStats()
    return stats
end

function Lighting:drawDebug()
    if not debugMode then return end

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print("Lights: " .. stats.activeLights, 10, 90)
    love.graphics.print("  Projectile: " .. stats.projectileLights, 10, 105)
    love.graphics.print("  Eye: " .. stats.eyeLights, 10, 120)
    love.graphics.print("  Muzzle: " .. stats.muzzleFlashes, 10, 135)

    -- Draw light positions
    love.graphics.setColor(1, 1, 0, 0.5)
    for _, light in ipairs(lights) do
        love.graphics.circle("line", light.x, light.y, 5)
    end
end

return Lighting
