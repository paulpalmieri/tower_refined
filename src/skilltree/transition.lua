-- src/skilltree/transition.lua
-- Death screen to skill tree animation

local Object = require "lib.classic"
local lume = require "lib.lume"

local Transition = Object:extend()

-- Transition phases
local PHASE_NONE = "none"
local PHASE_ZOOM_OUT = "zoom_out"
local PHASE_FADE = "fade"
local PHASE_COMPLETE = "complete"

-- Timing
local ZOOM_DURATION = 0.6
local FADE_DURATION = 0.3

function Transition:new()
    self.phase = PHASE_NONE
    self.timer = 0
    self.progress = 0

    -- Zoom parameters
    self.startZoom = 1.0
    self.endZoom = 0.8
    self.currentZoom = 1.0

    -- Fade parameters
    self.fadeAlpha = 0
end

function Transition:start()
    self.phase = PHASE_ZOOM_OUT
    self.timer = 0
    self.progress = 0
    self.fadeAlpha = 0
    self.currentZoom = self.startZoom
end

function Transition:update(dt)
    if self.phase == PHASE_NONE or self.phase == PHASE_COMPLETE then
        return
    end

    self.timer = self.timer + dt

    if self.phase == PHASE_ZOOM_OUT then
        self.progress = math.min(1, self.timer / ZOOM_DURATION)
        -- Ease out cubic
        local t = 1 - math.pow(1 - self.progress, 3)
        self.currentZoom = lume.lerp(self.startZoom, self.endZoom, t)

        if self.progress >= 1 then
            self.phase = PHASE_FADE
            self.timer = 0
        end
    elseif self.phase == PHASE_FADE then
        self.progress = math.min(1, self.timer / FADE_DURATION)
        -- Ease in-out
        local t = self.progress < 0.5
            and 2 * self.progress * self.progress
            or 1 - math.pow(-2 * self.progress + 2, 2) / 2
        self.fadeAlpha = t

        if self.progress >= 1 then
            self.phase = PHASE_COMPLETE
        end
    end
end

function Transition:isActive()
    return self.phase ~= PHASE_NONE and self.phase ~= PHASE_COMPLETE
end

function Transition:isComplete()
    return self.phase == PHASE_COMPLETE
end

function Transition:getZoom()
    return self.currentZoom
end

function Transition:getFadeAlpha()
    return self.fadeAlpha
end

function Transition:getDeathScreenAlpha()
    -- Death screen fades out as skill tree fades in
    return 1 - self.fadeAlpha
end

function Transition:reset()
    self.phase = PHASE_NONE
    self.timer = 0
    self.progress = 0
    self.fadeAlpha = 0
    self.currentZoom = self.startZoom
end

return Transition
