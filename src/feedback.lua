-- src/feedback.lua
-- Simple feedback system: screen shake and hit-stop
-- Entry point: Feedback:trigger(preset_name, context)

local Feedback = {}

-- Screen shake state
local shake = {
    intensity = 0,
    duration = 0,
    timer = 0,
    offsetX = 0,
    offsetY = 0
}

-- Hit-stop state
local hitStop = {
    active = false,
    timer = 0,
    duration = 0
}

-- Presets
Feedback.presets = {
    small_hit = {
        shake = { intensity = 1.5, duration = 0.06 },
        hitStop = { duration = 0.03 },
    },
    enemy_death = {
        shake = { intensity = 5, duration = 0.12 },
        hitStop = { duration = 0.03 },
    },
    tower_damage = {
        shake = { intensity = 7.5, duration = 0.12 },
        hitStop = { duration = 0.05 },
    },
    laser_charge = {
        shake = { intensity = 0.3, duration = 0.1 },
    },
    laser_fire = {
        shake = { intensity = 4, duration = 0.15 },
        hitStop = { duration = 0.04 },
    },
    laser_continuous = {
        shake = { intensity = 4, duration = 0.1 },
    },
    plasma_charge = {
        shake = { intensity = 2.5, duration = 0.1 },
    },
    plasma_fire = {
        shake = { intensity = 10, duration = 0.2 },
        hitStop = { duration = 0.08 },
    },
    shield_kill = {
        shake = { intensity = 4, duration = 0.1 },
        hitStop = { duration = 0.03 },
    },
    missile_launch = {
        shake = { intensity = 1.5, duration = 0.08 },
    },
    missile_impact = {
        shake = { intensity = 3, duration = 0.1 },
        hitStop = { duration = 0.02 },
    },
    -- Enemy attack feedback
    enemy_projectile_hit = {
        shake = { intensity = 3, duration = 0.08 },
    },
    kamikaze_explosion = {
        shake = { intensity = 6, duration = 0.15 },
        hitStop = { duration = 0.04 },
    },
    aoe_trigger = {
        shake = { intensity = 4, duration = 0.1 },
    },
    -- Dash feedback
    dash_launch = {
        shake = { intensity = 4, duration = 0.08 },
        hitStop = { duration = 0.02 },
    },
    dash_land = {
        shake = { intensity = 3, duration = 0.06 },
    },
}

local function triggerShake(intensity, duration)
    -- Always refresh if same or higher intensity (supports continuous shaking)
    if intensity >= shake.intensity or shake.timer <= 0 then
        shake.intensity = intensity
        shake.duration = duration
        shake.timer = duration
    end
end

local function updateShake(dt)
    if shake.timer > 0 then
        shake.timer = shake.timer - dt
        local t = shake.timer / shake.duration
        local currentIntensity = shake.intensity * t
        shake.offsetX = (math.random() * 2 - 1) * currentIntensity
        shake.offsetY = (math.random() * 2 - 1) * currentIntensity
    else
        shake.offsetX = 0
        shake.offsetY = 0
        shake.intensity = 0
    end
end

local function triggerHitStop(duration)
    hitStop.active = true
    hitStop.duration = duration
    hitStop.timer = duration
end

local function updateHitStop(dt)
    if hitStop.active then
        hitStop.timer = hitStop.timer - dt
        if hitStop.timer <= 0 then
            hitStop.active = false
            hitStop.timer = 0
        end
    end
end

--- Trigger a feedback preset
function Feedback:trigger(presetName, context)
    local preset = self.presets[presetName]
    if not preset then
        return
    end

    -- Scale intensity based on damage context
    local intensityMult = 1.0
    if context and context.damage_dealt and context.max_hp then
        local damagePercent = context.damage_dealt / context.max_hp
        intensityMult = 0.5 + math.min(1.0, damagePercent) * 1.0
    end

    if preset.shake then
        local intensity = preset.shake.intensity * intensityMult
        triggerShake(intensity, preset.shake.duration)
    end

    if preset.hitStop then
        triggerHitStop(preset.hitStop.duration)
    end
end

--- Update feedback system
function Feedback:update(dt)
    updateShake(dt)
    updateHitStop(dt)

    if hitStop.active then
        return 0  -- Freeze gameplay
    end
    return dt
end

function Feedback:getShakeOffset()
    return shake.offsetX, shake.offsetY
end

function Feedback:isHitStopped()
    return hitStop.active
end

function Feedback:reset()
    shake.intensity = 0
    shake.duration = 0
    shake.timer = 0
    shake.offsetX = 0
    shake.offsetY = 0
    hitStop.active = false
    hitStop.timer = 0
    hitStop.duration = 0
end

return Feedback
