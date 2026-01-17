-- src/roguelite/levelup_ui.lua
-- Level-up selection UI - displays 5 upgrade cards

local LevelUpUI = {
    -- Animation state
    fadeIn = 0,
    cardAnimations = {},  -- Per-card animation offsets
}

-- Card layout constants
local CARD_WIDTH = 140
local CARD_HEIGHT = 180
local CARD_SPACING = 20
local CARD_Y_OFFSET = 100  -- Distance from center

function LevelUpUI:init()
    self.fadeIn = 0
    self.cardAnimations = {}
    for i = 1, 5 do
        self.cardAnimations[i] = {
            offset = 50,      -- Starts offset down
            scale = 0.9,      -- Starts slightly smaller
        }
    end
end

function LevelUpUI:show()
    self.fadeIn = 0
    for i = 1, 5 do
        self.cardAnimations[i] = {
            offset = 50 + (i - 3) * 20,  -- Staggered offset
            scale = 0.9,
        }
    end
end

function LevelUpUI:update(dt, roguelite)
    if not roguelite.levelUpPending then return end

    -- Animate fade in
    self.fadeIn = math.min(1, self.fadeIn + dt * 4)

    -- Animate cards sliding in
    for i, anim in ipairs(self.cardAnimations) do
        local targetOffset = 0
        local targetScale = 1.0

        -- Selected card is slightly larger
        if i == roguelite.selectedIndex then
            targetScale = 1.05
        end

        anim.offset = anim.offset + (targetOffset - anim.offset) * dt * 8
        anim.scale = anim.scale + (targetScale - anim.scale) * dt * 10
    end
end

function LevelUpUI:draw(roguelite)
    if not roguelite.levelUpPending then return end

    -- Dim background overlay
    love.graphics.setColor(0, 0, 0, 0.7 * self.fadeIn)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    -- Title
    love.graphics.setColor(1, 1, 1, self.fadeIn)
    local titleText = "LEVEL UP!"
    local font = love.graphics.getFont()
    local titleW = font:getWidth(titleText)
    love.graphics.print(titleText, (WINDOW_WIDTH - titleW) / 2, 80 * self.fadeIn)

    -- Level indicator
    love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], self.fadeIn)
    local levelText = "Level " .. roguelite.level
    local levelW = font:getWidth(levelText)
    love.graphics.print(levelText, (WINDOW_WIDTH - levelW) / 2, 110 * self.fadeIn)

    -- Draw cards
    local totalWidth = #roguelite.pendingChoices * CARD_WIDTH + (#roguelite.pendingChoices - 1) * CARD_SPACING
    local startX = (WINDOW_WIDTH - totalWidth) / 2

    for i, choice in ipairs(roguelite.pendingChoices) do
        local cardX = startX + (i - 1) * (CARD_WIDTH + CARD_SPACING)
        local cardY = CENTER_Y - CARD_HEIGHT / 2 + CARD_Y_OFFSET + self.cardAnimations[i].offset
        local isSelected = (i == roguelite.selectedIndex)

        self:drawCard(cardX, cardY, choice, isSelected, i, self.cardAnimations[i].scale)
    end

    -- Controls hint
    love.graphics.setColor(NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.6 * self.fadeIn)
    local hintText = "[1-5] or [Left/Right + Enter] to select"
    local hintW = font:getWidth(hintText)
    love.graphics.print(hintText, (WINDOW_WIDTH - hintW) / 2, WINDOW_HEIGHT - 60)
end

function LevelUpUI:drawCard(x, y, choice, isSelected, index, scale)
    -- Apply scale from center of card
    local centerX = x + CARD_WIDTH / 2
    local centerY = y + CARD_HEIGHT / 2

    love.graphics.push()
    love.graphics.translate(centerX, centerY)
    love.graphics.scale(scale, scale)
    love.graphics.translate(-CARD_WIDTH / 2, -CARD_HEIGHT / 2)

    local alpha = self.fadeIn

    -- Card background
    if isSelected then
        -- Glow effect for selected card
        love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.15 * alpha)
        love.graphics.rectangle("fill", -8, -8, CARD_WIDTH + 16, CARD_HEIGHT + 16)
    end

    -- Main card background
    local bgColor = choice.isMajor and {0.08, 0.02, 0.08} or {0.03, 0.03, 0.05}
    love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], 0.95 * alpha)
    love.graphics.rectangle("fill", 0, 0, CARD_WIDTH, CARD_HEIGHT)

    -- Border
    local borderColor
    if isSelected then
        borderColor = {1, 1, 1, alpha}
    elseif choice.isMajor then
        borderColor = {POLYGON_COLOR[1], POLYGON_COLOR[2], POLYGON_COLOR[3], 0.7 * alpha}
    else
        borderColor = {NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.5 * alpha}
    end
    love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    love.graphics.setLineWidth(isSelected and 3 or 2)
    love.graphics.rectangle("line", 0, 0, CARD_WIDTH, CARD_HEIGHT)
    love.graphics.setLineWidth(1)

    -- Number indicator
    love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.6 * alpha)
    love.graphics.print("[" .. index .. "]", 8, 8)

    -- Icon
    local iconColor = self:getIconColor(choice)
    self:drawIcon(choice.icon, CARD_WIDTH / 2, 55, iconColor, alpha)

    -- Major/Minor badge
    if choice.isMajor then
        love.graphics.setColor(POLYGON_COLOR[1], POLYGON_COLOR[2], POLYGON_COLOR[3], alpha)
        love.graphics.print("MAJOR", 8, CARD_HEIGHT - 25)
    end

    -- Name
    love.graphics.setColor(1, 1, 1, alpha)
    local font = love.graphics.getFont()
    local nameW = font:getWidth(choice.name)
    local nameX = (CARD_WIDTH - nameW) / 2
    love.graphics.print(choice.name, nameX, 90)

    -- Description (wrapped)
    love.graphics.setColor(0.7, 0.7, 0.7, alpha * 0.9)
    self:drawWrappedText(choice.description, 8, 115, CARD_WIDTH - 16)

    -- Stack count for minors
    if choice.currentStacks and choice.currentStacks > 0 then
        love.graphics.setColor(NEON_YELLOW[1], NEON_YELLOW[2], NEON_YELLOW[3], alpha * 0.8)
        local stackText = "x" .. (choice.currentStacks + 1)
        local stackW = font:getWidth(stackText)
        love.graphics.print(stackText, CARD_WIDTH - stackW - 8, CARD_HEIGHT - 25)
    end

    love.graphics.pop()
end

function LevelUpUI:getIconColor(choice)
    if choice.id == "shield" or choice.id == "shield_charge" then
        return NEON_CYAN
    elseif choice.id == "missile_silo" or choice.id == "missile_count" then
        return MISSILE_COLOR
    elseif choice.id == "xp_drone" or choice.id == "drone_count" then
        return DRONE_COLOR
    elseif choice.id == "damage_aura" or choice.id == "aura_damage" or choice.id == "aura_radius" then
        return NEON_RED
    elseif choice.id == "damage_up" then
        return NEON_RED
    elseif choice.id == "fire_rate_up" then
        return NEON_YELLOW
    elseif choice.id == "projectile_speed_up" then
        return NEON_PRIMARY
    elseif choice.id == "pickup_radius_up" then
        return POLYGON_COLOR
    else
        return NEON_PRIMARY
    end
end

function LevelUpUI:drawIcon(iconType, cx, cy, color, alpha)
    love.graphics.setColor(color[1], color[2], color[3], alpha)

    -- Scale up icons for better visibility in cards
    local scale = 1.8

    if iconType == "shield" then
        -- Shield: hexagonal barrier
        love.graphics.polygon("line",
            cx, cy - 10 * scale,
            cx + 8 * scale, cy - 5 * scale,
            cx + 8 * scale, cy + 5 * scale,
            cx, cy + 10 * scale,
            cx - 8 * scale, cy + 5 * scale,
            cx - 8 * scale, cy - 5 * scale
        )
        -- Inner glow
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.3)
        love.graphics.polygon("fill",
            cx, cy - 7 * scale,
            cx + 5 * scale, cy - 3.5 * scale,
            cx + 5 * scale, cy + 3.5 * scale,
            cx, cy + 7 * scale,
            cx - 5 * scale, cy + 3.5 * scale,
            cx - 5 * scale, cy - 3.5 * scale
        )

    elseif iconType == "silo" then
        -- Silo/missile: rocket shape
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.polygon("fill",
            cx, cy - 10 * scale,
            cx - 5 * scale, cy + 4 * scale,
            cx - 3 * scale, cy + 8 * scale,
            cx + 3 * scale, cy + 8 * scale,
            cx + 5 * scale, cy + 4 * scale
        )
        -- Exhaust
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.6)
        love.graphics.polygon("fill",
            cx - 2 * scale, cy + 8 * scale,
            cx, cy + 13 * scale,
            cx + 2 * scale, cy + 8 * scale
        )

    elseif iconType == "drone" then
        -- Drone: circle with barrel
        love.graphics.circle("fill", cx, cy, 6 * scale)
        love.graphics.rectangle("fill", cx, cy - 2 * scale, 8 * scale, 4 * scale)
        -- Orbit arc
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.4)
        love.graphics.arc("line", "open", cx - 3 * scale, cy, 10 * scale, -math.pi * 0.7, math.pi * 0.7)

    elseif iconType == "aura" then
        -- Aura: concentric rings
        love.graphics.circle("line", cx, cy, 4 * scale)
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.6)
        love.graphics.circle("line", cx, cy, 7 * scale)
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.3)
        love.graphics.circle("line", cx, cy, 10 * scale)

    elseif iconType == "fire_rate" then
        -- Fire rate: bullets
        love.graphics.rectangle("fill", cx - 8 * scale, cy - 2 * scale, 5 * scale, 4 * scale)
        love.graphics.rectangle("fill", cx - 1.5 * scale, cy - 2 * scale, 5 * scale, 4 * scale)
        love.graphics.rectangle("fill", cx + 5 * scale, cy - 2 * scale, 5 * scale, 4 * scale)

    elseif iconType == "damage" then
        -- Damage: explosion star
        love.graphics.polygon("fill",
            cx, cy - 8 * scale,
            cx + 3 * scale, cy - 3 * scale,
            cx + 8 * scale, cy - 3 * scale,
            cx + 4 * scale, cy + 1 * scale,
            cx + 6 * scale, cy + 7 * scale,
            cx, cy + 3 * scale,
            cx - 6 * scale, cy + 7 * scale,
            cx - 4 * scale, cy + 1 * scale,
            cx - 8 * scale, cy - 3 * scale,
            cx - 3 * scale, cy - 3 * scale
        )

    elseif iconType == "projectile_speed" then
        -- Speed: arrow with motion lines
        love.graphics.polygon("fill", cx + 8 * scale, cy, cx + 2 * scale, cy - 5 * scale, cx + 2 * scale, cy + 5 * scale)
        love.graphics.rectangle("fill", cx - 6 * scale, cy - 2 * scale, 10 * scale, 4 * scale)
        -- Speed lines
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.4)
        love.graphics.line(cx - 10 * scale, cy - 5 * scale, cx - 6 * scale, cy - 5 * scale)
        love.graphics.line(cx - 12 * scale, cy, cx - 8 * scale, cy)
        love.graphics.line(cx - 10 * scale, cy + 5 * scale, cx - 6 * scale, cy + 5 * scale)

    elseif iconType == "pickup_radius" then
        -- Pickup: expanding circles
        love.graphics.circle("line", cx, cy, 4 * scale)
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.6)
        love.graphics.circle("line", cx, cy, 7 * scale)
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.3)
        love.graphics.circle("line", cx, cy, 10 * scale)

    elseif iconType == "skip" then
        -- Skip: X mark
        love.graphics.setLineWidth(3)
        love.graphics.line(cx - 6 * scale, cy - 6 * scale, cx + 6 * scale, cy + 6 * scale)
        love.graphics.line(cx + 6 * scale, cy - 6 * scale, cx - 6 * scale, cy + 6 * scale)
        love.graphics.setLineWidth(1)

    else
        -- Default: simple square
        love.graphics.rectangle("fill", cx - 6 * scale, cy - 6 * scale, 12 * scale, 12 * scale)
    end
end

function LevelUpUI:drawWrappedText(text, x, y, maxWidth)
    local font = love.graphics.getFont()
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end

    local lines = {}
    local currentLine = ""

    for _, word in ipairs(words) do
        local testLine = currentLine == "" and word or (currentLine .. " " .. word)
        if font:getWidth(testLine) <= maxWidth then
            currentLine = testLine
        else
            if currentLine ~= "" then
                table.insert(lines, currentLine)
            end
            currentLine = word
        end
    end
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end

    local lineHeight = font:getHeight() + 2
    for i, line in ipairs(lines) do
        love.graphics.print(line, x, y + (i - 1) * lineHeight)
    end
end

-- Handle keyboard input
function LevelUpUI:keypressed(key, roguelite)
    if not roguelite.levelUpPending then return false end

    -- Number keys 1-5
    local num = tonumber(key)
    if num and num >= 1 and num <= #roguelite.pendingChoices then
        roguelite:selectUpgrade(num)
        Sounds.playPurchase()
        return true
    end

    -- Arrow keys
    if key == "left" then
        roguelite:moveSelection(-1)
        return true
    elseif key == "right" then
        roguelite:moveSelection(1)
        return true
    end

    -- Confirm
    if key == "return" or key == "space" then
        roguelite:confirmSelection()
        Sounds.playPurchase()
        return true
    end

    return false
end

-- Handle mouse input
function LevelUpUI:mousepressed(x, y, button, roguelite)
    if not roguelite.levelUpPending then return false end
    if button ~= 1 then return false end

    -- Check which card was clicked
    local totalWidth = #roguelite.pendingChoices * CARD_WIDTH + (#roguelite.pendingChoices - 1) * CARD_SPACING
    local startX = (WINDOW_WIDTH - totalWidth) / 2

    for i = 1, #roguelite.pendingChoices do
        local cardX = startX + (i - 1) * (CARD_WIDTH + CARD_SPACING)
        local cardY = CENTER_Y - CARD_HEIGHT / 2 + CARD_Y_OFFSET

        if x >= cardX and x <= cardX + CARD_WIDTH and
           y >= cardY and y <= cardY + CARD_HEIGHT then
            roguelite:selectUpgrade(i)
            Sounds.playPurchase()
            return true
        end
    end

    return false
end

-- Handle mouse movement for hover
function LevelUpUI:mousemoved(x, y, roguelite)
    if not roguelite.levelUpPending then return end

    local totalWidth = #roguelite.pendingChoices * CARD_WIDTH + (#roguelite.pendingChoices - 1) * CARD_SPACING
    local startX = (WINDOW_WIDTH - totalWidth) / 2

    for i = 1, #roguelite.pendingChoices do
        local cardX = startX + (i - 1) * (CARD_WIDTH + CARD_SPACING)
        local cardY = CENTER_Y - CARD_HEIGHT / 2 + CARD_Y_OFFSET

        if x >= cardX and x <= cardX + CARD_WIDTH and
           y >= cardY and y <= cardY + CARD_HEIGHT then
            roguelite.selectedIndex = i
            return
        end
    end
end

return LevelUpUI
