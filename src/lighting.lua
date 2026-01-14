-- src/lighting.lua
-- Simple glow lighting for neon aesthetic
-- Tower, projectiles, and muzzle flash only

local Lighting = {}

local lights = {}
local lightIdCounter = 0

function Lighting:init()
    lights = {}
    lightIdCounter = 0
end

function Lighting:reset()
    self:init()
end

-- Add a light source
-- params: {x, y, radius, intensity, color, pulse, pulseAmount, duration, type, owner}
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
        pulse = params.pulse or 0,
        pulseAmount = params.pulseAmount or 0,
        duration = params.duration,
        timer = 0,
        type = params.type or "generic",
        owner = params.owner,
        angle = params.angle,
    }

    table.insert(lights, light)
    return id
end

-- Remove a light by ID
function Lighting:removeLight(id)
    for i = #lights, 1, -1 do
        if lights[i].id == id then
            table.remove(lights, i)
            return true
        end
    end
    return false
end

-- Add light for a projectile
function Lighting:addProjectileLight(proj)
    return self:addLight({
        x = proj.x,
        y = proj.y,
        radius = PROJECTILE_LIGHT_RADIUS,
        intensity = PROJECTILE_LIGHT_INTENSITY,
        color = PROJECTILE_LIGHT_COLOR,
        type = "projectile",
        owner = proj,
    })
end

-- Add muzzle flash (auto-expires)
function Lighting:addMuzzleFlash(x, y, angle)
    return self:addLight({
        x = x,
        y = y,
        radius = MUZZLE_FLASH_RADIUS,
        intensity = MUZZLE_FLASH_INTENSITY,
        color = MUZZLE_FLASH_COLOR,
        duration = MUZZLE_FLASH_DURATION,
        type = "muzzle",
        angle = angle,
    })
end

-- Add tower glow (pulsing)
function Lighting:addTowerGlow(turret)
    return self:addLight({
        x = turret.x,
        y = turret.y,
        radius = TOWER_LIGHT_RADIUS,
        intensity = TOWER_LIGHT_INTENSITY,
        color = TOWER_LIGHT_COLOR,
        pulse = TOWER_LIGHT_PULSE_SPEED,
        pulseAmount = TOWER_LIGHT_PULSE_AMOUNT,
        type = "tower",
        owner = turret,
    })
end

function Lighting:update(dt)
    for i = #lights, 1, -1 do
        local light = lights[i]
        light.timer = light.timer + dt

        -- Handle duration-based lights (auto-expire)
        if light.duration then
            if light.timer >= light.duration then
                table.remove(lights, i)
            else
                local progress = light.timer / light.duration
                light.currentIntensity = light.intensity * (1 - progress)
            end
        else
            light.currentIntensity = light.intensity
        end

        -- Update position for entity-linked lights
        if light.owner then
            if light.owner.dead then
                table.remove(lights, i)
            else
                light.x = light.owner.x
                light.y = light.owner.y
            end
        end
    end
end

-- Draw a radial glow
local function drawRadialLight(x, y, radius, color, intensity)
    local steps = 6
    for i = steps, 1, -1 do
        local t = i / steps
        local r = radius * t
        local alpha = (1 - t) * intensity * 0.3

        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.circle("fill", x, y, r)
    end
end

-- Draw muzzle flash cone
local function drawMuzzleFlashCone(x, y, radius, color, intensity, angle)
    local coneLength = radius * 1.2
    local coneWidth = radius * 0.5
    local dx = math.cos(angle)
    local dy = math.sin(angle)
    local px = -dy
    local py = dx

    -- Cone layers
    for i = 2, 1, -1 do
        local scale = i / 2
        local alpha = intensity * 0.4 * scale

        local tipX = x + dx * coneLength * scale
        local tipY = y + dy * coneLength * scale
        local leftX = x + px * coneWidth * scale
        local leftY = y + py * coneWidth * scale
        local rightX = x - px * coneWidth * scale
        local rightY = y - py * coneWidth * scale

        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.polygon("fill", leftX, leftY, tipX, tipY, rightX, rightY)
    end

    -- Bright core
    love.graphics.setColor(color[1], color[2], color[3], intensity * 0.6)
    love.graphics.circle("fill", x, y, radius * 0.2)
end

function Lighting:drawLights()
    love.graphics.setBlendMode("add")

    for _, light in ipairs(lights) do
        local intensity = light.currentIntensity or light.intensity

        -- Apply pulse
        if light.pulse > 0 then
            local pulseVal = math.sin(light.timer * light.pulse * math.pi * 2)
            intensity = intensity * (1 + pulseVal * light.pulseAmount)
        end

        if intensity > 0.05 then
            if light.type == "muzzle" and light.angle then
                drawMuzzleFlashCone(light.x, light.y, light.radius, light.color, intensity, light.angle)
            else
                drawRadialLight(light.x, light.y, light.radius, light.color, intensity)
            end
        end
    end

    love.graphics.setBlendMode("alpha")
end

function Lighting:getLightCount()
    return #lights
end

return Lighting
