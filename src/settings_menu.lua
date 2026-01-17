-- src/settings_menu.lua
-- Simple settings menu with toggles for fullscreen and CRT effect

local SettingsMenu = {}

-- State
local selectedIndex = 1
local options = {}

-- ===================
-- INITIALIZATION
-- ===================

function SettingsMenu:init()
    -- Define menu options
    options = {
        {
            label = "Fullscreen",
            getValue = function() return isFullscreen end,
            toggle = function() toggleFullscreen() end,
        },
        {
            label = "CRT Effect",
            getValue = function() return CRT_ENABLED end,
            toggle = function() CRT_ENABLED = not CRT_ENABLED end,
        },
        {
            label = "Chromatic Aberration",
            getValue = function() return CHROMATIC_ABERRATION_ENABLED end,
            toggle = function() CHROMATIC_ABERRATION_ENABLED = not CHROMATIC_ABERRATION_ENABLED end,
        },
        {
            label = "Bloom",
            getValue = function() return BLOOM_ENABLED end,
            toggle = function() BLOOM_ENABLED = not BLOOM_ENABLED end,
        },
        {
            label = "Glitch",
            getValue = function() return GLITCH_ENABLED end,
            toggle = function() GLITCH_ENABLED = not GLITCH_ENABLED end,
        },
        {
            label = "Heat Distortion",
            getValue = function() return HEAT_DISTORTION_ENABLED end,
            toggle = function() HEAT_DISTORTION_ENABLED = not HEAT_DISTORTION_ENABLED end,
        },
    }
    selectedIndex = 1
end

-- ===================
-- UPDATE
-- ===================

function SettingsMenu:update(dt)
    -- No animation needed for this simple menu
end

-- ===================
-- DRAWING
-- ===================

function SettingsMenu:draw()
    -- Dark semi-transparent overlay
    love.graphics.setColor(0.02, 0.04, 0.02, 0.92)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    -- Menu box dimensions
    local boxWidth = 280
    local boxHeight = 320
    local boxX = (WINDOW_WIDTH - boxWidth) / 2
    local boxY = (WINDOW_HEIGHT - boxHeight) / 2

    -- Draw box background
    love.graphics.setColor(0.03, 0.06, 0.03, 0.95)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight)

    -- Draw box border
    love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight)
    love.graphics.setLineWidth(1)

    -- Title
    local title = "SETTINGS"
    local font = love.graphics.getFont()
    local titleWidth = font:getWidth(title)
    love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 1)
    love.graphics.print(title, boxX + (boxWidth - titleWidth) / 2, boxY + 20)

    -- Draw options
    local optionY = boxY + 55
    local optionSpacing = 35

    for i, option in ipairs(options) do
        local isSelected = (i == selectedIndex)
        local isEnabled = option.getValue()

        -- Selection highlight
        if isSelected then
            love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.15)
            love.graphics.rectangle("fill", boxX + 15, optionY - 5, boxWidth - 30, 28)
        end

        -- Checkbox
        local checkboxX = boxX + 30
        local checkboxY = optionY + 2
        local checkboxSize = 16

        -- Checkbox border
        local alpha = isSelected and 1 or 0.6
        love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], alpha)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", checkboxX, checkboxY, checkboxSize, checkboxSize)
        love.graphics.setLineWidth(1)

        -- Checkbox fill if enabled
        if isEnabled then
            love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.8)
            love.graphics.rectangle("fill", checkboxX + 3, checkboxY + 3, checkboxSize - 6, checkboxSize - 6)
        end

        -- Label
        local labelX = checkboxX + checkboxSize + 12
        if isSelected then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.7)
        end
        love.graphics.print(option.label, labelX, optionY)

        optionY = optionY + optionSpacing
    end

    -- Hint at bottom
    love.graphics.setColor(NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.6)
    local hint = "ESC to close"
    local hintWidth = font:getWidth(hint)
    love.graphics.print(hint, boxX + (boxWidth - hintWidth) / 2, boxY + boxHeight - 30)
end

-- ===================
-- INPUT HANDLING
-- ===================

function SettingsMenu:keypressed(key)
    if key == "escape" then
        return "close"
    elseif key == "up" then
        selectedIndex = selectedIndex - 1
        if selectedIndex < 1 then
            selectedIndex = #options
        end
    elseif key == "down" then
        selectedIndex = selectedIndex + 1
        if selectedIndex > #options then
            selectedIndex = 1
        end
    elseif key == "return" or key == "space" then
        -- Toggle selected option
        local option = options[selectedIndex]
        if option and option.toggle then
            option.toggle()
        end
    end

    return nil
end

return SettingsMenu
