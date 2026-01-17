-- gameover_system.lua
-- Manages the game over animation state machine

local GameOverSystem = {
    phase = "none",           -- "none", "fade_in", "title_hold", "reveal", "complete"
    timer = 0,
    titleAlpha = 0,
    titleY = 0,
    statRevealProgress = 0,
    overlayAlpha = 0,
}

-- Ease-out cubic function for smooth deceleration
local function easeOutCubic(t)
    return 1 - math.pow(1 - t, 3)
end

-- Initialize the system
function GameOverSystem:init()
    self:reset()
end

-- Reset state (call between runs)
function GameOverSystem:reset()
    self.phase = "none"
    self.timer = 0
    self.titleAlpha = 0
    self.titleY = CENTER_Y
    self.statRevealProgress = 0
    self.overlayAlpha = 0
end

-- Start the game over animation
function GameOverSystem:start()
    self.phase = "fade_in"
    self.timer = 0
    self.titleAlpha = 0
    self.titleY = CENTER_Y * 0.3  -- 30% from top
    self.statRevealProgress = 0
    self.overlayAlpha = 0
end

-- Update the game over animation state machine
function GameOverSystem:update(dt)
    if self.phase == "none" then return end

    self.timer = self.timer + dt

    if self.phase == "fade_in" then
        local t = math.min(self.timer / GAMEOVER_FADE_DURATION, 1)
        self.overlayAlpha = easeOutCubic(t) * 0.85
        if t >= 1 then
            self.phase = "title_hold"
            self.timer = 0
        end

    elseif self.phase == "title_hold" then
        -- Fade in title
        local fadeT = math.min(self.timer / GAMEOVER_TITLE_FADE_DURATION, 1)
        self.titleAlpha = easeOutCubic(fadeT)

        -- Auto-advance to reveal after timeout
        if self.timer >= GAMEOVER_TITLE_HOLD_TIMEOUT then
            self.phase = "reveal"
            self.timer = 0
        end

    elseif self.phase == "reveal" then
        local t = math.min(self.timer / GAMEOVER_REVEAL_DURATION, 1)
        self.statRevealProgress = easeOutCubic(t)

        if t >= 1 then
            self.phase = "complete"
            self.timer = 0
        end

    -- "complete" phase: nothing to update, just wait for input
    end
end

-- Trigger reveal phase (called on keypress during title_hold)
function GameOverSystem:triggerReveal()
    if self.phase == "title_hold" then
        self.phase = "reveal"
        self.timer = 0
    end
end

-- Draw the game over screen
function GameOverSystem:draw(gameTime, totalKills, gold, totalGold, polygonsCount)
    -- Don't draw if animation hasn't started
    if self.phase == "none" then return end

    local font = love.graphics.getFont()
    local title = "SYSTEM FAILURE"
    local titleWidth = font:getWidth(title)

    -- Layout constants
    local titleYBase = CENTER_Y * 0.3      -- ~30% from top when revealed
    local titleYStart = CENTER_Y - 80      -- Initial centered position
    local statsStartY = CENTER_Y * 0.45    -- Stats start at ~45% from top
    local statLineHeight = 20
    local buttonsY = CENTER_Y * 0.7        -- Buttons at ~70% from top

    -- Dark overlay
    love.graphics.setColor(0.01, 0.03, 0.01, self.overlayAlpha)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    -- During fade_in, just draw overlay
    if self.phase == "fade_in" then return end

    -- Calculate title position (slides up during reveal)
    local titleY
    if self.phase == "title_hold" then
        titleY = titleYStart
    else
        -- Interpolate from center to top position during reveal
        titleY = lume.lerp(titleYStart, titleYBase, self.statRevealProgress)
    end
    local titleX = CENTER_X - titleWidth / 2

    -- Title with red neon glow
    local titleAlpha = self.titleAlpha
    love.graphics.setColor(NEON_RED[1], NEON_RED[2], NEON_RED[3], 0.3 * titleAlpha)
    love.graphics.print(title, titleX - 1, titleY - 1)
    love.graphics.print(title, titleX + 1, titleY + 1)
    love.graphics.setColor(NEON_RED[1], NEON_RED[2], NEON_RED[3], titleAlpha)
    love.graphics.print(title, titleX, titleY)

    -- Don't draw stats during title_hold phase
    if self.phase == "title_hold" then return end

    -- Stats with staggered reveal
    local statsX = CENTER_X - 70
    local revealProgress = self.statRevealProgress

    -- Helper to get alpha for a specific stat index (0-based)
    local function getStatAlpha(index)
        local statStart = index * GAMEOVER_STAT_STAGGER
        local statProgress = (revealProgress - statStart) / (1 - statStart)
        return math.max(0, math.min(1, statProgress)) * 0.9
    end

    -- Time Survived (green)
    local minutes = math.floor(gameTime / 60)
    local seconds = math.floor(gameTime % 60)
    love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], getStatAlpha(0))
    love.graphics.print(string.format("Time Survived: %d:%02d", minutes, seconds), statsX, statsStartY)

    -- Enemies Destroyed (green)
    love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], getStatAlpha(1))
    love.graphics.print("Enemies Destroyed: " .. totalKills, statsX, statsStartY + statLineHeight)

    -- Credits Earned (yellow)
    love.graphics.setColor(NEON_YELLOW[1], NEON_YELLOW[2], NEON_YELLOW[3], getStatAlpha(2))
    love.graphics.print("Credits Earned: +" .. gold, statsX, statsStartY + statLineHeight * 2)

    -- Total Credits (yellow)
    love.graphics.setColor(NEON_YELLOW[1], NEON_YELLOW[2], NEON_YELLOW[3], getStatAlpha(3))
    love.graphics.print("Total Credits: " .. totalGold, statsX, statsStartY + statLineHeight * 3)

    -- Polygons (purple)
    love.graphics.setColor(POLYGON_COLOR[1], POLYGON_COLOR[2], POLYGON_COLOR[3], getStatAlpha(4))
    love.graphics.print("Polygons: P" .. polygonsCount, statsX, statsStartY + statLineHeight * 4)

    -- Only show buttons when animation is complete
    if self.phase == "complete" then
        -- [R] REBOOT
        love.graphics.setColor(NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.7)
        love.graphics.print("[R] REBOOT", CENTER_X - 100, buttonsY)

        -- [S] SKILL TREE
        love.graphics.setColor(NEON_CYAN[1], NEON_CYAN[2], NEON_CYAN[3], 0.8)
        love.graphics.print("[S] SKILL TREE", CENTER_X + 20, buttonsY)
    end
end

-- Check if animation is active
function GameOverSystem:isActive()
    return self.phase ~= "none"
end

-- Check if animation is complete
function GameOverSystem:isComplete()
    return self.phase == "complete"
end

-- Get current phase for input handling
function GameOverSystem:getPhase()
    return self.phase
end

return GameOverSystem
