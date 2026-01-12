-- Debug Overlay Module
-- Press D to toggle, game pauses when open
-- S cycles game speed (works anytime)

Debug = {
    active = false,
    scroll = 0,
    maxScroll = 0,
    dragging = nil,
    hoveredControl = nil,

    -- Layout constants
    PANEL_X = 20,
    PANEL_Y = 20,
    PANEL_WIDTH = 360,
    PANEL_HEIGHT = 420,
    ROW_HEIGHT = 22,
    SLIDER_WIDTH = 150,
    LABEL_WIDTH = 140,
    PADDING = 10,
    HEADER_HEIGHT = 30,
}

-- Store default values for reset
local defaults = {}

-- Category definitions with their parameters
-- Each parameter: {name, varName, min, max, step, format}
Debug.categories = {
    {
        name = "Tower",
        expanded = true,
        params = {
            {"HP", "TOWER_HP", 10, 500, 10, "%d"},
            {"Fire Rate", "TOWER_FIRE_RATE", 0.05, 2.0, 0.05, "%.2f"},
            {"Proj Speed", "PROJECTILE_SPEED", 100, 1500, 50, "%d"},
            {"Proj Damage", "PROJECTILE_DAMAGE", 1, 100, 1, "%d"},
        }
    },
    {
        name = "Enemies",
        expanded = true,
        params = {
            {"Basic HP", "BASIC_HP", 1, 100, 1, "%d"},
            {"Basic Speed", "BASIC_SPEED", 5, 200, 5, "%d"},
            {"Fast HP", "FAST_HP", 1, 50, 1, "%d"},
            {"Fast Speed", "FAST_SPEED", 20, 300, 5, "%d"},
            {"Tank HP", "TANK_HP", 5, 200, 5, "%d"},
            {"Tank Speed", "TANK_SPEED", 5, 100, 5, "%d"},
        }
    },
    {
        name = "Knockback",
        expanded = false,
        params = {
            {"Force", "KNOCKBACK_FORCE", 0, 500, 20, "%d"},
            {"Duration", "KNOCKBACK_DURATION", 0, 0.5, 0.02, "%.2f"},
        }
    },
    {
        name = "Feedback",
        expanded = false,
        params = {
            {"Shake Intensity", "SCREEN_SHAKE_INTENSITY", 0, 20, 1, "%d"},
            {"Shake On Hit", "SCREEN_SHAKE_ON_HIT", 0, 10, 0.5, "%.1f"},
            {"Shake Duration", "SCREEN_SHAKE_DURATION", 0.01, 0.5, 0.02, "%.2f"},
            {"Scatter Velocity", "PIXEL_SCATTER_VELOCITY", 50, 800, 25, "%d"},
            {"Death Burst", "DEATH_BURST_VELOCITY", 100, 1000, 50, "%d"},
        }
    },
    {
        name = "Spawning",
        expanded = false,
        params = {
            {"Spawn Rate", "SPAWN_RATE", 0.1, 10, 0.1, "%.1f"},
            {"Max Enemies", "MAX_ENEMIES", 5, 200, 5, "%d"},
        }
    },
}

-- Action buttons
Debug.actions = {
    {name = "Restart Run", action = function() startNewRun() end},
    {name = "Activate Nuke", action = function() activateNuke() end},
    {name = "Toggle Ricochet", action = function() powers.ricochet = not powers.ricochet end},
    {name = "Toggle Multishot", action = function() powers.multishot = not powers.multishot end},
    {name = "Toggle Pierce", action = function() powers.pierce = not powers.pierce end},
    {name = "Kill All Enemies", action = function()
        for i = #enemies, 1, -1 do
            enemies[i].hp = 0
            enemies[i].dead = true
        end
    end},
    {name = "Reset to Defaults", action = function() Debug:resetDefaults() end},
}

function Debug:init()
    -- Store default values
    for _, cat in ipairs(self.categories) do
        for _, param in ipairs(cat.params) do
            local varName = param[2]
            if _G[varName] then
                defaults[varName] = _G[varName]
            end
        end
    end
end

function Debug:resetDefaults()
    for varName, value in pairs(defaults) do
        _G[varName] = value
    end
end

function Debug:update(dt)
    -- Update hover state
    local mx, my = love.mouse.getPosition()
    self.hoveredControl = nil

    -- Check for hover over controls
    local y = self.PANEL_Y + self.HEADER_HEIGHT - self.scroll

    for _, cat in ipairs(self.categories) do
        -- Category header
        local headerY = y
        if my >= headerY and my < headerY + self.ROW_HEIGHT and
           mx >= self.PANEL_X and mx < self.PANEL_X + self.PANEL_WIDTH then
            self.hoveredControl = {type = "header", category = cat}
        end
        y = y + self.ROW_HEIGHT

        if cat.expanded then
            for _, param in ipairs(cat.params) do
                if y > self.PANEL_Y + self.HEADER_HEIGHT and y < self.PANEL_Y + self.PANEL_HEIGHT - 50 then
                    local sliderX = self.PANEL_X + self.LABEL_WIDTH + self.PADDING
                    local sliderY = y
                    if my >= sliderY and my < sliderY + self.ROW_HEIGHT and
                       mx >= sliderX and mx < sliderX + self.SLIDER_WIDTH then
                        self.hoveredControl = {type = "slider", param = param}
                    end
                end
                y = y + self.ROW_HEIGHT
            end
        end
    end

    -- Actions section
    y = y + 10
    for i, action in ipairs(self.actions) do
        if y > self.PANEL_Y + self.HEADER_HEIGHT and y < self.PANEL_Y + self.PANEL_HEIGHT - 10 then
            if my >= y and my < y + self.ROW_HEIGHT and
               mx >= self.PANEL_X + self.PADDING and mx < self.PANEL_X + self.PANEL_WIDTH - self.PADDING then
                self.hoveredControl = {type = "action", index = i, action = action}
            end
        end
        y = y + self.ROW_HEIGHT
    end

    -- Update max scroll
    self.maxScroll = math.max(0, y + self.scroll - self.PANEL_Y - self.PANEL_HEIGHT + 20)

    -- Handle dragging
    if self.dragging then
        local param = self.dragging.param
        local varName = param[2]
        local min, max = param[3], param[4]
        local sliderX = self.PANEL_X + self.LABEL_WIDTH + self.PADDING

        local t = (mx - sliderX) / self.SLIDER_WIDTH
        t = math.max(0, math.min(1, t))

        local step = param[5]
        local rawValue = min + t * (max - min)
        local value = math.floor(rawValue / step + 0.5) * step
        value = math.max(min, math.min(max, value))

        _G[varName] = value

        -- Sync tower properties when relevant globals change
        if syncTowerFromGlobals then
            syncTowerFromGlobals()
        end
    end
end

function Debug:draw()
    -- Semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", self.PANEL_X - 5, self.PANEL_Y - 5,
                           self.PANEL_WIDTH + 10, self.PANEL_HEIGHT + 10, 8)

    -- Panel border
    love.graphics.setColor(0.3, 0.5, 0.7, 1)
    love.graphics.rectangle("line", self.PANEL_X - 5, self.PANEL_Y - 5,
                           self.PANEL_WIDTH + 10, self.PANEL_HEIGHT + 10, 8)

    -- Title
    love.graphics.setColor(1, 1, 1, 1)
    local speedText = (GAME_SPEEDS and gameSpeedIndex) and (GAME_SPEEDS[gameSpeedIndex] .. "x") or "?"
    love.graphics.print("DEBUG (D close, S speed: " .. speedText .. ")",
                       self.PANEL_X + self.PADDING, self.PANEL_Y + 5)

    -- Scissor for scrolling content
    love.graphics.setScissor(self.PANEL_X, self.PANEL_Y + self.HEADER_HEIGHT,
                            self.PANEL_WIDTH, self.PANEL_HEIGHT - self.HEADER_HEIGHT - 10)

    local y = self.PANEL_Y + self.HEADER_HEIGHT - self.scroll

    for _, cat in ipairs(self.categories) do
        -- Category header
        local isHovered = self.hoveredControl and
                         self.hoveredControl.type == "header" and
                         self.hoveredControl.category == cat

        if isHovered then
            love.graphics.setColor(0.3, 0.4, 0.5, 1)
            love.graphics.rectangle("fill", self.PANEL_X, y, self.PANEL_WIDTH, self.ROW_HEIGHT)
        end

        love.graphics.setColor(0.6, 0.8, 1, 1)
        local arrow = cat.expanded and "v " or "> "
        love.graphics.print(arrow .. cat.name, self.PANEL_X + self.PADDING, y + 3)
        y = y + self.ROW_HEIGHT

        if cat.expanded then
            for _, param in ipairs(cat.params) do
                local name, varName, min, max, _, fmt = unpack(param)
                local value = _G[varName] or 0

                -- Label
                love.graphics.setColor(0.8, 0.8, 0.8, 1)
                love.graphics.print(name, self.PANEL_X + self.PADDING + 10, y + 3)

                -- Slider background
                local sliderX = self.PANEL_X + self.LABEL_WIDTH + self.PADDING
                local sliderY = y + 6
                local sliderH = 10

                local isSliderHovered = self.hoveredControl and
                                       self.hoveredControl.type == "slider" and
                                       self.hoveredControl.param == param

                love.graphics.setColor(0.2, 0.2, 0.3, 1)
                love.graphics.rectangle("fill", sliderX, sliderY, self.SLIDER_WIDTH, sliderH, 3)

                -- Slider fill
                local t = (value - min) / (max - min)
                local fillColor = isSliderHovered and {0.4, 0.7, 1, 1} or {0.3, 0.5, 0.8, 1}
                love.graphics.setColor(unpack(fillColor))
                love.graphics.rectangle("fill", sliderX, sliderY, self.SLIDER_WIDTH * t, sliderH, 3)

                -- Slider handle
                local handleX = sliderX + self.SLIDER_WIDTH * t
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.circle("fill", handleX, sliderY + sliderH/2, 6)

                -- Value text
                love.graphics.setColor(1, 1, 0.7, 1)
                love.graphics.print(string.format(fmt, value), sliderX + self.SLIDER_WIDTH + 10, y + 3)

                y = y + self.ROW_HEIGHT
            end
        end
    end

    -- Separator
    y = y + 5
    love.graphics.setColor(0.4, 0.4, 0.5, 1)
    love.graphics.line(self.PANEL_X + self.PADDING, y,
                      self.PANEL_X + self.PANEL_WIDTH - self.PADDING, y)
    y = y + 10

    -- Action buttons
    love.graphics.setColor(0.6, 0.8, 1, 1)
    love.graphics.print("Actions:", self.PANEL_X + self.PADDING, y)
    y = y + self.ROW_HEIGHT

    for i, action in ipairs(self.actions) do
        local isHovered = self.hoveredControl and
                         self.hoveredControl.type == "action" and
                         self.hoveredControl.index == i

        if isHovered then
            love.graphics.setColor(0.3, 0.5, 0.3, 1)
        else
            love.graphics.setColor(0.2, 0.3, 0.2, 1)
        end
        love.graphics.rectangle("fill", self.PANEL_X + self.PADDING, y,
                               self.PANEL_WIDTH - self.PADDING * 2, self.ROW_HEIGHT - 2, 4)

        love.graphics.setColor(0.3, 0.6, 0.3, 1)
        love.graphics.rectangle("line", self.PANEL_X + self.PADDING, y,
                               self.PANEL_WIDTH - self.PADDING * 2, self.ROW_HEIGHT - 2, 4)

        love.graphics.setColor(0.8, 1, 0.8, 1)
        love.graphics.print(action.name, self.PANEL_X + self.PADDING + 10, y + 3)

        y = y + self.ROW_HEIGHT
    end

    love.graphics.setScissor()

    -- Scroll indicator
    if self.maxScroll > 0 then
        local scrollbarHeight = self.PANEL_HEIGHT - self.HEADER_HEIGHT - 20
        local thumbHeight = scrollbarHeight * (scrollbarHeight / (scrollbarHeight + self.maxScroll))
        local thumbY = self.PANEL_Y + self.HEADER_HEIGHT + 5 +
                      (self.scroll / self.maxScroll) * (scrollbarHeight - thumbHeight)

        love.graphics.setColor(0.3, 0.3, 0.4, 1)
        love.graphics.rectangle("fill", self.PANEL_X + self.PANEL_WIDTH - 8,
                               self.PANEL_Y + self.HEADER_HEIGHT + 5, 5, scrollbarHeight, 2)

        love.graphics.setColor(0.5, 0.6, 0.7, 1)
        love.graphics.rectangle("fill", self.PANEL_X + self.PANEL_WIDTH - 8,
                               thumbY, 5, thumbHeight, 2)
    end

    -- Stats panel on right side
    self:drawStats()
end

function Debug:drawStats()
    local x = self.PANEL_X + self.PANEL_WIDTH + 20
    local y = self.PANEL_Y
    local w = 180

    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", x - 5, y - 5, w + 10, 280, 8)

    love.graphics.setColor(0.3, 0.5, 0.7, 1)
    love.graphics.rectangle("line", x - 5, y - 5, w + 10, 280, 8)

    love.graphics.setColor(0.6, 0.8, 1, 1)
    love.graphics.print("Live Stats", x + 5, y + 5)
    y = y + 25

    love.graphics.setColor(0.8, 0.8, 0.8, 1)

    local stats = {
        {"Enemies", enemies and #enemies or 0},
        {"Projectiles", projectiles and #projectiles or 0},
        {"Particles", particles and #particles or 0},
        {"Chunks", chunks and #chunks or 0},
        {"Dust", dustParticles and #dustParticles or 0},
        {"Dmg Numbers", damageNumbers and #damageNumbers or 0},
        {"", ""},
        {"Game Time", string.format("%.1fs", gameTime or 0)},
        {"Spawn Rate", string.format("%.2f/s", currentSpawnRate or SPAWN_RATE or 0)},
        {"", ""},
        {"Tower HP", tower and tower.hp or 0},
        {"Level", level or 1},
        {"XP", (xp or 0) .. "/" .. (xpToNextLevel or 0)},
        {"Gold", totalGold or 0},
        {"Kills", totalKills or 0},
    }

    for _, stat in ipairs(stats) do
        if stat[1] ~= "" then
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
            love.graphics.print(stat[1] .. ":", x + 5, y)
            love.graphics.setColor(1, 1, 0.7, 1)
            love.graphics.print(tostring(stat[2]), x + 100, y)
        end
        y = y + 16
    end

    -- Powers status
    y = y + 5
    love.graphics.setColor(0.6, 0.8, 1, 1)
    love.graphics.print("Powers", x + 5, y)
    y = y + 18

    local powerList = {
        {"Ricochet", powers and powers.ricochet},
        {"Multishot", powers and powers.multishot},
        {"Pierce", powers and powers.pierce},
    }

    for _, p in ipairs(powerList) do
        if p[2] then
            love.graphics.setColor(0.3, 0.8, 0.3, 1)
            love.graphics.print("[ON]  " .. p[1], x + 5, y)
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
            love.graphics.print("[OFF] " .. p[1], x + 5, y)
        end
        y = y + 16
    end
end

function Debug:mousepressed(x, y, button)
    if button ~= 1 then return end

    if self.hoveredControl then
        if self.hoveredControl.type == "header" then
            self.hoveredControl.category.expanded = not self.hoveredControl.category.expanded
        elseif self.hoveredControl.type == "slider" then
            self.dragging = {param = self.hoveredControl.param}
        elseif self.hoveredControl.type == "action" then
            self.hoveredControl.action.action()
        end
    end
end

function Debug:mousereleased(x, y, button)
    if button == 1 then
        self.dragging = nil
    end
end

function Debug:wheelmoved(x, y)
    self.scroll = self.scroll - y * 30
    self.scroll = math.max(0, math.min(self.maxScroll, self.scroll))
end

-- Initialize on load
Debug:init()

return Debug
