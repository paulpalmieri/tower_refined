-- src/feedback.lua
-- Centralized Feedback System for all sensory output
-- Single entry point: Feedback:trigger(preset_name, context)

local Feedback = {}

-- ===================
-- INTERNAL STATE
-- ===================

-- Screen shake state
local shake = {
    intensity = 0,
    duration = 0,
    timer = 0,
    offsetX = 0,
    offsetY = 0
}

-- Hit-stop (time dilation) state
local hitStop = {
    active = false,
    timer = 0,
    duration = 0
}

-- Active tweens for squash/stretch effects
local tweens = {}

-- Debug mode flag
local debugMode = false

-- ===================
-- EFFECT PRESETS
-- ===================
-- Each preset can combine multiple feedback channels

Feedback.presets = {
    -- Combat hits (projectile impacts)
    small_hit = {
        shake = { intensity = 1.5, duration = 0.06 },
        hitStop = { duration = 0.05 },  -- 50ms freeze on every hit
    },
    medium_hit = {
        shake = { intensity = 3, duration = 0.1 },
        hitStop = { duration = 0.02 },  -- 20ms freeze
    },
    big_hit = {
        shake = { intensity = 5, duration = 0.12 },
        hitStop = { duration = 0.04 },  -- 40ms freeze
    },

    -- Debris events (damage-scaled effects)
    minor_spatter = {
        shake = { intensity = 1, duration = 0.04 },
        -- No hit-stop for minor damage
    },
    limb_break = {
        shake = { intensity = 4, duration = 0.1 },
        hitStop = { duration = 0.06 },  -- 60ms freeze for limb loss
    },
    total_collapse = {
        shake = { intensity = 6, duration = 0.15 },
        hitStop = { duration = 0.08 },  -- 80ms freeze for death
    },

    -- Enemy deaths
    enemy_death = {
        shake = { intensity = 5, duration = 0.12 },
        hitStop = { duration = 0.03 },  -- 30ms freeze
    },

    -- Tower feedback
    tower_damage = {
        shake = { intensity = 7.5, duration = 0.12 },
        hitStop = { duration = 0.05 },  -- 50ms freeze
    },
    tower_fire = {
        -- Reserved for future turret firing feedback
        -- Currently turret handles its own muzzle flash
    },

    -- Abilities
    nuke_explosion = {
        shake = { intensity = 10, duration = 0.3 },
        hitStop = { duration = 0.08 },  -- 80ms freeze
    },
}

-- ===================
-- TWEEN EASING FUNCTIONS
-- ===================

local function easeOutQuad(t)
    return 1 - (1 - t) * (1 - t)
end

local function easeOutBack(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)
end

local function easeOutElastic(t)
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    local c4 = (2 * math.pi) / 3
    return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
end

-- ===================
-- INTERNAL FUNCTIONS
-- ===================

local function triggerShake(intensity, duration)
    -- Only override if new shake is stronger or current has faded
    if intensity > shake.intensity or shake.timer <= 0 then
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
    -- Start hit-stop (or extend if already active)
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

local function updateTweens(dt)
    for i = #tweens, 1, -1 do
        local tween = tweens[i]
        tween.elapsed = tween.elapsed + dt

        if tween.elapsed >= tween.duration then
            -- Complete tween
            if tween.onComplete then
                tween.onComplete(tween.target)
            end
            table.remove(tweens, i)
        else
            -- Apply easing
            local t = tween.elapsed / tween.duration
            local easedT = tween.easing(t)

            for key, values in pairs(tween.properties) do
                tween.target[key] = values.from + (values.to - values.from) * easedT
            end

            if tween.onUpdate then
                tween.onUpdate(tween.target, easedT)
            end
        end
    end
end

-- ===================
-- PUBLIC API
-- ===================

--- Trigger a feedback preset
--- @param presetName string The name of the preset to trigger
--- @param context table|nil Optional context for damage-aware effects:
---   damage_dealt: number - Amount of damage dealt
---   current_hp: number - Enemy HP after damage
---   max_hp: number - Enemy max HP
---   impact_angle: number - Bullet angle in radians
---   impact_x, impact_y: number - Impact position
---   enemy: table - Reference to enemy (for part access)
function Feedback:trigger(presetName, context)
    local preset = self.presets[presetName]
    if not preset then
        print("[Feedback] Warning: Unknown preset '" .. tostring(presetName) .. "'")
        return
    end

    -- Scale intensity based on damage context if provided
    local intensityMult = 1.0
    if context and context.damage_dealt and context.max_hp then
        local damagePercent = context.damage_dealt / context.max_hp
        -- Scale between 0.5x and 1.5x based on damage percentage
        intensityMult = 0.5 + math.min(1.0, damagePercent) * 1.0
    end

    -- Apply each feedback channel defined in the preset
    if preset.shake then
        local intensity = preset.shake.intensity * intensityMult
        triggerShake(intensity, preset.shake.duration)
    end

    if preset.hitStop then
        triggerHitStop(preset.hitStop.duration)
    end
end

--- Check if a health threshold was crossed
--- @param oldHpPercent number Previous HP percentage (0-1)
--- @param newHpPercent number New HP percentage (0-1)
--- @return number|nil The threshold crossed (0.75, 0.50, 0.25) or nil
function Feedback:checkThresholdCrossed(oldHpPercent, newHpPercent)
    for _, threshold in ipairs(DISMEMBER_THRESHOLDS) do
        if oldHpPercent > threshold and newHpPercent <= threshold then
            return threshold
        end
    end
    return nil
end

--- Determine appropriate preset based on damage context
--- @param context table Damage context with damage_dealt, current_hp, max_hp
--- @return string Preset name to use
function Feedback:getPresetForDamage(context)
    if not context then return "small_hit" end

    local damagePercent = (context.damage_dealt or 0) / (context.max_hp or 1)

    -- Death = total collapse
    if context.current_hp and context.current_hp <= 0 then
        return "total_collapse"
    end

    -- Big damage (>25% in one hit) = big hit
    if damagePercent >= 0.25 then
        return "big_hit"
    end

    -- Medium damage (10-25%) = medium hit
    if damagePercent >= MINOR_SPATTER_THRESHOLD then
        return "medium_hit"
    end

    -- Small damage (<10%) = minor spatter
    return "minor_spatter"
end

--- Update the feedback system
--- @param dt number Delta time from love.update
--- @return number Adjusted dt for gameplay (0 during hit-stop)
function Feedback:update(dt)
    -- Update internal timers using raw dt (never frozen)
    updateShake(dt)
    updateHitStop(dt)
    updateTweens(dt)

    -- Return adjusted dt for gameplay
    if hitStop.active then
        return 0  -- Freeze gameplay during hit-stop
    end
    return dt
end

--- Get the current screen shake offset
--- @return number, number offsetX, offsetY
function Feedback:getShakeOffset()
    return shake.offsetX, shake.offsetY
end

--- Get the current shake intensity (for debug display)
--- @return number Current intensity
function Feedback:getShakeIntensity()
    return shake.intensity
end

--- Check if hit-stop is currently active
--- @return boolean
function Feedback:isHitStopped()
    return hitStop.active
end

--- Get remaining hit-stop time
--- @return number Remaining time in seconds
function Feedback:getHitStopRemaining()
    return hitStop.timer
end

-- ===================
-- TWEEN API
-- ===================

--- Create a tween for squash/stretch or other property animations
--- @param target table The object to animate
--- @param properties table Property definitions {key = {from=, to=}}
--- @param duration number Duration in seconds
--- @param easing string|function Easing function name or custom function
--- @param onComplete function|nil Callback when tween completes
--- @return table The tween object
function Feedback:tween(target, properties, duration, easing, onComplete)
    local easingFn
    if type(easing) == "function" then
        easingFn = easing
    elseif easing == "easeOutQuad" then
        easingFn = easeOutQuad
    elseif easing == "easeOutBack" then
        easingFn = easeOutBack
    elseif easing == "easeOutElastic" then
        easingFn = easeOutElastic
    else
        easingFn = easeOutQuad  -- default
    end

    local tween = {
        target = target,
        properties = properties,
        duration = duration,
        elapsed = 0,
        easing = easingFn,
        onComplete = onComplete,
        onUpdate = nil,
    }

    table.insert(tweens, tween)
    return tween
end

--- Cancel all tweens for a specific target
--- @param target table The target to cancel tweens for
function Feedback:cancelTweens(target)
    for i = #tweens, 1, -1 do
        if tweens[i].target == target then
            table.remove(tweens, i)
        end
    end
end

-- ===================
-- DEBUG
-- ===================

--- Enable/disable debug mode
--- @param enabled boolean
function Feedback:setDebugMode(enabled)
    debugMode = enabled
end

--- Draw debug overlay (call from love.draw)
--- @param debrisStats table|nil Optional debris stats from DebrisManager
--- @param chunkCount number|nil Number of active chunks
--- @param settledCount number|nil Number of settled chunks
function Feedback:drawDebug(debrisStats, chunkCount, settledCount)
    if not debugMode then return end

    love.graphics.setColor(1, 1, 1, 0.9)
    local y = 90

    love.graphics.print("=== FEEDBACK DEBUG ===", 10, y)
    y = y + 15

    love.graphics.print(string.format("Shake: %.2f (%.2fms left)",
        shake.intensity, shake.timer * 1000), 10, y)
    y = y + 15

    local hitStopStr = hitStop.active and
        string.format("YES (%.0fms left)", hitStop.timer * 1000) or "no"
    love.graphics.print("HitStop: " .. hitStopStr, 10, y)
    y = y + 15

    love.graphics.print("Active Tweens: " .. #tweens, 10, y)
    y = y + 20

    -- Debris stats section
    love.graphics.print("=== DEBRIS DEBUG ===", 10, y)
    y = y + 15

    if chunkCount then
        local settledStr = settledCount and string.format(" (%d settled)", settledCount) or ""
        love.graphics.print(string.format("Active Chunks: %d%s", chunkCount, settledStr), 10, y)
        y = y + 15
    end

    if debrisStats then
        love.graphics.print(string.format("Total Spawned: %d chunks, %d particles",
            debrisStats.totalChunksSpawned or 0,
            debrisStats.totalParticlesSpawned or 0), 10, y)
        y = y + 15
    end

    love.graphics.setColor(0.8, 1, 0.8, 0.9)
    love.graphics.print("[D] Force Dismember nearest enemy", 10, y)
end

--- Reset all feedback state (useful for new runs)
function Feedback:reset()
    shake.intensity = 0
    shake.duration = 0
    shake.timer = 0
    shake.offsetX = 0
    shake.offsetY = 0

    hitStop.active = false
    hitStop.timer = 0
    hitStop.duration = 0

    tweens = {}
end

return Feedback
