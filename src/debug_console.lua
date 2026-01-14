-- src/debug_console.lua
-- Debug console with sliders for live variable tuning
-- Toggle: ` (backtick) | Scroll: Mouse wheel | Drag sliders to adjust

local DebugConsole = {}

-- ===================
-- STATE
-- ===================
local consoleVisible = false
local scrollOffset = 0
local maxScroll = 0

-- Input state
local inputBuffer = ""
local errorMessage = ""
local errorTimer = 0

-- Button/input interaction
local hoveredElement = nil    -- {varName=string, type="minus"|"reset"|"plus"|"input"}
local activeButton = nil      -- Same format, tracks pressed button
local focusedInput = nil      -- Variable name of focused text input
local inputEditBuffer = ""    -- Text being edited in focused input
local inputCursorPos = 0      -- Cursor position
local inputCursorBlink = 0    -- For blinking cursor animation

-- Autocomplete state
local autocompleteMatches = {}
local autocompleteIndex = 0

-- Variable registry
local variables = {}       -- { name = {name, category, categoryIndex, varType, flashTimer, cachedValue, min, max} }
local sortedVariables = {} -- Sorted list for rendering
local categories = {}      -- { {name, color, index} }

-- ===================
-- CONSTANTS
-- ===================
local FLASH_DURATION = 0.4
local ERROR_DISPLAY_TIME = 2.0

-- Layout
local ROW_HEIGHT = 22
local PADDING = 12
local NAME_WIDTH = 200
local VALUE_WIDTH = 80
local BUTTON_WIDTH = 32
local BUTTON_HEIGHT = 18
local BUTTON_SPACING = 4
local INPUT_FIELD_WIDTH = 80
local INPUT_HEIGHT = 28
local HEADER_HEIGHT = 24

-- Read-only variables (computed from others)
local READ_ONLY = {
    CENTER_X = true,
    CENTER_Y = true,
}

-- ===================
-- COLOR SCHEME
-- ===================
local CATEGORY_COLORS = {
    ["WINDOW"] = {0.5, 0.6, 0.7},
    ["TOWER"] = {0.3, 0.9, 0.5},
    ["TURRET VISUAL"] = {0.3, 0.8, 0.5},
    ["ENEMIES"] = {1.0, 0.4, 0.4},
    ["COLLISION"] = {1.0, 0.5, 0.4},
    ["KNOCKBACK"] = {1.0, 0.6, 0.2},
    ["HIT FEEDBACK"] = {1.0, 0.65, 0.25},
    ["SCREEN SHAKE"] = {1.0, 0.7, 0.3},
    ["DAMAGE NUMBERS"] = {1.0, 0.75, 0.35},
    ["VISUAL GROUNDING"] = {0.7, 0.5, 0.9},
    ["BLOB APPEARANCE"] = {0.75, 0.55, 0.85},
    ["ANIMATION"] = {0.65, 0.5, 0.85},
    ["DUST PARTICLES"] = {0.9, 0.75, 0.6},
    ["PARTICLE PHYSICS"] = {0.95, 0.5, 0.6},
    ["DEAD LIMB COLORS"] = {0.85, 0.45, 0.55},
    ["LIMB CHUNK SETTINGS"] = {0.9, 0.5, 0.65},
    ["BLOOD TRAIL SETTINGS"] = {0.8, 0.4, 0.5},
    ["CHUNK SETTLE TIMING"] = {0.85, 0.55, 0.6},
    ["DISMEMBERMENT THRESHOLDS"] = {0.9, 0.45, 0.55},
    ["LIGHTING SYSTEM"] = {1.0, 0.95, 0.4},
    ["SPAWNING DISTANCE"] = {0.4, 0.9, 0.9},
    ["SPAWNING (continuous)"] = {0.4, 0.85, 0.85},
    ["CHAOS"] = {0.5, 0.85, 0.9},
    ["ACTIVE SKILL (Nuke)"] = {0.9, 0.9, 0.9},
    ["GOLD"] = {1.0, 0.85, 0.2},
    ["GAME SPEED"] = {0.85, 0.85, 0.85},
    ["SOUND"] = {0.8, 0.8, 0.8},
    ["SCOPE CURSOR"] = {0.6, 0.7, 0.8},
}

local DEFAULT_COLOR = {0.7, 0.7, 0.7}

-- ===================
-- UTILITY FUNCTIONS
-- ===================

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = deepCopy(v)
    end
    return copy
end

local function valuesEqual(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) == "table" then
        if #a ~= #b then return false end
        for i = 1, #a do
            if a[i] ~= b[i] then return false end
        end
        return true
    end
    return a == b
end

local function detectType(value)
    if type(value) == "table" then
        if #value == 3 and type(value[1]) == "number" then
            local isColor = value[1] >= 0 and value[1] <= 1.5 and
                           value[2] >= 0 and value[2] <= 1.5 and
                           value[3] >= 0 and value[3] <= 1.5
            if isColor then return "color" end
        end
        return "array"
    elseif type(value) == "number" then
        return "number"
    else
        return "string"
    end
end

local function getCategoryColor(categoryName)
    return CATEGORY_COLORS[categoryName] or DEFAULT_COLOR
end

-- Calculate reasonable min/max for a variable based on its current value
local function calculateBounds(value, varType)
    if varType == "color" then
        return 0, 1
    elseif varType == "array" then
        return 0, 100 -- Generic bounds for arrays
    elseif varType == "string" then
        return 0, 0 -- Strings don't have numeric bounds
    else
        -- Number
        if value == 0 then
            return -100, 100
        elseif value > 0 then
            return 0, value * 4
        else
            return value * 4, 0
        end
    end
end

-- ===================
-- VARIABLE DISCOVERY
-- ===================

local function parseConfigFile()
    local content = love.filesystem.read("src/config.lua")
    if not content then
        errorMessage = "Could not read src/config.lua"
        errorTimer = ERROR_DISPLAY_TIME
        return
    end

    local currentCategory = "UNKNOWN"
    local categoryIndex = 0
    local prevLineWasSeparator = false

    for line in content:gmatch("[^\r\n]+") do
        -- Check for section separator
        if line:match("^%-%-%s*=+%s*$") then
            prevLineWasSeparator = true
        elseif prevLineWasSeparator then
            -- Line after separator - check if it's a section name
            local sectionMatch = line:match("^%-%-%s*(.+)%s*$")
            if sectionMatch and sectionMatch ~= "" then
                currentCategory = sectionMatch:match("^%s*(.-)%s*$")
                categoryIndex = categoryIndex + 1
                table.insert(categories, {
                    name = currentCategory,
                    color = getCategoryColor(currentCategory),
                    index = categoryIndex
                })
            else
                -- Not a section name - might be a variable (e.g., right after closing separator)
                local varName = line:match("^([A-Z][A-Z0-9_]*)%s*=")
                if varName and _G[varName] ~= nil then
                    local globalVal = _G[varName]
                    local varType = detectType(globalVal)
                    local minVal, maxVal = calculateBounds(
                        varType == "number" and globalVal or (varType == "color" and globalVal[1] or 0),
                        varType
                    )

                    variables[varName] = {
                        name = varName,
                        category = currentCategory,
                        categoryIndex = categoryIndex,
                        varType = varType,
                        flashTimer = 0,
                        cachedValue = deepCopy(globalVal),
                        defaultValue = deepCopy(globalVal),
                        readOnly = READ_ONLY[varName] or false,
                        min = minVal,
                        max = maxVal,
                    }
                end
            end
            prevLineWasSeparator = false
        else
            -- Normal line - check for variable
            local varName = line:match("^([A-Z][A-Z0-9_]*)%s*=")
            if varName and _G[varName] ~= nil then
                local globalVal = _G[varName]
                local varType = detectType(globalVal)
                local minVal, maxVal = calculateBounds(
                    varType == "number" and globalVal or (varType == "color" and globalVal[1] or 0),
                    varType
                )

                variables[varName] = {
                    name = varName,
                    category = currentCategory,
                    categoryIndex = categoryIndex,
                    varType = varType,
                    flashTimer = 0,
                    cachedValue = deepCopy(globalVal),
                    defaultValue = deepCopy(globalVal),
                    readOnly = READ_ONLY[varName] or false,
                    min = minVal,
                    max = maxVal,
                }
            end
        end
    end

    -- Build sorted list
    sortedVariables = {}
    for _, var in pairs(variables) do
        table.insert(sortedVariables, var)
    end
    table.sort(sortedVariables, function(a, b)
        if a.categoryIndex ~= b.categoryIndex then
            return a.categoryIndex < b.categoryIndex
        end
        return a.name < b.name
    end)

    -- Calculate max scroll
    local contentHeight = #sortedVariables * ROW_HEIGHT + HEADER_HEIGHT
    local visibleHeight = WINDOW_HEIGHT - INPUT_HEIGHT - PADDING * 2 - HEADER_HEIGHT
    maxScroll = math.max(0, contentHeight - visibleHeight)
end

-- ===================
-- VALUE FORMATTING
-- ===================

local function formatValue(var)
    local val = _G[var.name]
    if val == nil then return "nil" end

    if var.varType == "color" then
        return string.format("%.2f, %.2f, %.2f", val[1], val[2], val[3])
    elseif var.varType == "array" then
        local parts = {}
        for _, v in ipairs(val) do
            if type(v) == "number" then
                if v == math.floor(v) then
                    table.insert(parts, tostring(v))
                else
                    table.insert(parts, string.format("%.2f", v))
                end
            else
                table.insert(parts, tostring(v))
            end
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    else
        if type(val) == "number" then
            if val == math.floor(val) then
                return tostring(val)
            else
                return string.format("%.3f", val)
            end
        else
            return tostring(val)
        end
    end
end

-- ===================
-- VALUE PARSING
-- ===================

local function parseValue(str, varType)
    str = str:match("^%s*(.-)%s*$")

    if varType == "number" then
        local num = tonumber(str)
        if num then return true, num end
        return false, nil
    elseif varType == "array" or varType == "color" then
        str = str:gsub("[{}]", "")
        local values = {}
        for numStr in str:gmatch("[%d%.%-]+") do
            local num = tonumber(numStr)
            if num then
                table.insert(values, num)
            end
        end
        if #values > 0 then
            return true, values
        end
        return false, nil
    end

    return false, nil
end

-- ===================
-- BUTTON/INPUT LOGIC
-- ===================

-- Get button/input positions for a row
local function getControlPositions(rowIndex)
    local y = HEADER_HEIGHT + PADDING + (rowIndex - 1) * ROW_HEIGHT - scrollOffset
    local baseX = PADDING + NAME_WIDTH + VALUE_WIDTH + 10
    return {
        minus = {x = baseX, y = y + 2, w = BUTTON_WIDTH, h = BUTTON_HEIGHT},
        reset = {x = baseX + BUTTON_WIDTH + BUTTON_SPACING, y = y + 2, w = BUTTON_WIDTH + 8, h = BUTTON_HEIGHT},
        plus = {x = baseX + BUTTON_WIDTH * 2 + BUTTON_SPACING * 2 + 8, y = y + 2, w = BUTTON_WIDTH, h = BUTTON_HEIGHT},
        input = {x = baseX + BUTTON_WIDTH * 3 + BUTTON_SPACING * 3 + 16, y = y + 2, w = INPUT_FIELD_WIDTH, h = BUTTON_HEIGHT},
    }
end

local function applyPercentChange(var, percent)
    if var.readOnly then return end
    local multiplier = 1 + (percent / 100)

    if var.varType == "number" then
        local newVal = _G[var.name] * multiplier
        -- Clamp to bounds
        newVal = math.max(var.min, math.min(var.max, newVal))
        -- Snap to integer if default was integer
        if var.defaultValue == math.floor(var.defaultValue) then
            newVal = math.floor(newVal + 0.5)
        end
        _G[var.name] = newVal
    elseif var.varType == "color" then
        local current = _G[var.name]
        _G[var.name] = {
            math.max(0, math.min(1, current[1] * multiplier)),
            math.max(0, math.min(1, current[2] * multiplier)),
            math.max(0, math.min(1, current[3] * multiplier)),
        }
    end
    var.flashTimer = FLASH_DURATION
    var.cachedValue = deepCopy(_G[var.name])
end

local function resetToDefault(var)
    if var.readOnly then return end
    _G[var.name] = deepCopy(var.defaultValue)
    var.flashTimer = FLASH_DURATION
    var.cachedValue = deepCopy(_G[var.name])
end

local function startInputEdit(var)
    focusedInput = var.name
    inputEditBuffer = formatValue(var)
    inputCursorPos = #inputEditBuffer
end

local function commitInputEdit()
    if not focusedInput then return end

    local var = variables[focusedInput]
    if var then
        local success, parsed = parseValue(inputEditBuffer, var.varType)
        if success then
            _G[focusedInput] = parsed
            var.flashTimer = FLASH_DURATION
            var.cachedValue = deepCopy(parsed)
        else
            errorMessage = "Invalid value"
            errorTimer = ERROR_DISPLAY_TIME
        end
    end
    focusedInput = nil
    inputEditBuffer = ""
    inputCursorPos = 0
end

local function cancelInputEdit()
    focusedInput = nil
    inputEditBuffer = ""
    inputCursorPos = 0
end

-- ===================
-- DRAWING HELPERS
-- ===================

local function drawButton(x, y, w, h, label, hovered, active, accentColor)
    -- Background
    if active then
        love.graphics.setColor(0.08, 0.08, 0.08, 1)
    elseif hovered then
        love.graphics.setColor(0.25, 0.28, 0.3, 1)
    else
        love.graphics.setColor(0.15, 0.15, 0.18, 1)
    end
    love.graphics.rectangle("fill", x, y, w, h, 3, 3)

    -- Border
    love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], hovered and 0.8 or 0.4)
    love.graphics.rectangle("line", x, y, w, h, 3, 3)

    -- Label (centered)
    love.graphics.setColor(1, 1, 1, 0.9)
    local font = love.graphics.getFont()
    local textW = font:getWidth(label)
    love.graphics.print(label, x + (w - textW) / 2, y + 2)
end

local function drawInputField(x, y, w, h, var, focused, hovered, accentColor)
    -- Background
    if focused then
        love.graphics.setColor(0.12, 0.12, 0.15, 1)
    else
        love.graphics.setColor(0.08, 0.08, 0.1, 1)
    end
    love.graphics.rectangle("fill", x, y, w, h, 3, 3)

    -- Border
    if focused then
        love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.9)
    elseif hovered then
        love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 0.5)
    else
        love.graphics.setColor(0.3, 0.3, 0.35, 0.6)
    end
    love.graphics.rectangle("line", x, y, w, h, 3, 3)

    -- Text content
    love.graphics.setColor(1, 1, 1, 0.9)
    local displayText = focused and inputEditBuffer or formatValue(var)
    -- Truncate if too long
    local font = love.graphics.getFont()
    while font:getWidth(displayText) > w - 8 and #displayText > 1 do
        displayText = displayText:sub(1, -2)
    end
    love.graphics.print(displayText, x + 4, y + 2)

    -- Cursor (when focused)
    if focused and math.floor(inputCursorBlink * 2) % 2 == 0 then
        local cursorX = x + 4 + font:getWidth(inputEditBuffer:sub(1, inputCursorPos))
        love.graphics.setColor(accentColor[1], accentColor[2], accentColor[3], 1)
        love.graphics.rectangle("fill", cursorX, y + 3, 1, h - 6)
    end
end

-- ===================
-- COMMAND PARSING
-- ===================

local function processCommand(cmd)
    local varName, value = cmd:match("^set%s+([A-Z_][A-Z0-9_]*)%s+(.+)$")
    if not varName then
        varName, value = cmd:match("^([A-Z_][A-Z0-9_]*)%s*=%s*(.+)$")
    end
    if not varName then
        varName, value = cmd:match("^([A-Z_][A-Z0-9_]*)%s+(.+)$")
    end

    if cmd:lower() == "help" then
        errorMessage = "Syntax: set VAR_NAME value"
        errorTimer = ERROR_DISPLAY_TIME * 1.5
        return true
    end

    if not varName or not value then
        errorMessage = "Syntax: set VAR_NAME value"
        errorTimer = ERROR_DISPLAY_TIME
        return false
    end

    local var = variables[varName]
    if not var then
        errorMessage = "Unknown variable: " .. varName
        errorTimer = ERROR_DISPLAY_TIME
        return false
    end

    if var.readOnly then
        errorMessage = varName .. " is read-only"
        errorTimer = ERROR_DISPLAY_TIME
        return false
    end

    local success, parsed = parseValue(value, var.varType)
    if not success then
        errorMessage = "Invalid value for " .. varName
        errorTimer = ERROR_DISPLAY_TIME
        return false
    end

    _G[varName] = parsed
    var.flashTimer = FLASH_DURATION
    var.cachedValue = deepCopy(parsed)
    -- Update bounds based on new value
    var.min, var.max = calculateBounds(
        var.varType == "number" and parsed or (var.varType == "color" and parsed[1] or 0),
        var.varType
    )

    return true
end

-- ===================
-- PUBLIC API
-- ===================

function DebugConsole:init()
    parseConfigFile()
end

function DebugConsole:update(dt)
    -- Update flash timers
    for _, var in pairs(variables) do
        if var.flashTimer > 0 then
            var.flashTimer = var.flashTimer - dt
            if var.flashTimer < 0 then
                var.flashTimer = 0
            end
        end
    end

    -- Update error timer
    if errorTimer > 0 then
        errorTimer = errorTimer - dt
        if errorTimer < 0 then
            errorTimer = 0
            errorMessage = ""
        end
    end

    -- Detect external changes
    for name, var in pairs(variables) do
        local currentVal = _G[name]
        if not valuesEqual(var.cachedValue, currentVal) then
            var.cachedValue = deepCopy(currentVal)
            var.flashTimer = FLASH_DURATION
        end
    end

    -- Update cursor blink timer
    inputCursorBlink = inputCursorBlink + dt
end

function DebugConsole:draw()
    if not consoleVisible then return end

    -- Background (fully transparent)
    -- love.graphics.setColor(0, 0, 0, 0.94)
    -- love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    -- Header (no background)
    love.graphics.setColor(0.6, 0.8, 1.0, 0.9)
    love.graphics.print("DEBUG CONSOLE  [` close | Scroll: wheel | Type: set VAR value]",
                        PADDING, 5)

    -- Clip drawing to content area
    local contentY = HEADER_HEIGHT
    local contentHeight = WINDOW_HEIGHT - HEADER_HEIGHT - INPUT_HEIGHT - PADDING

    love.graphics.setScissor(0, contentY, WINDOW_WIDTH, contentHeight)

    -- Draw variables
    local currentCategory = nil
    for i, var in ipairs(sortedVariables) do
        local y = HEADER_HEIGHT + PADDING + (i - 1) * ROW_HEIGHT - scrollOffset

        -- Skip if off-screen
        if y + ROW_HEIGHT >= contentY and y < contentY + contentHeight then
            local catColor = getCategoryColor(var.category)

            -- Category separator (subtle line when category changes)
            if var.category ~= currentCategory then
                currentCategory = var.category
                if i > 1 then
                    love.graphics.setColor(catColor[1], catColor[2], catColor[3], 0.3)
                    love.graphics.line(PADDING, y - 2, WINDOW_WIDTH - PADDING, y - 2)
                end
            end

            -- Flash animation
            local displayColor = {catColor[1], catColor[2], catColor[3]}
            if var.flashTimer > 0 then
                local t = var.flashTimer / FLASH_DURATION
                displayColor[1] = catColor[1] + (1 - catColor[1]) * t
                displayColor[2] = catColor[2] + (1 - catColor[2]) * t
                displayColor[3] = catColor[3] + (1 - catColor[3]) * t
            end

            -- Dim read-only variables
            local alpha = var.readOnly and 0.4 or 0.95

            -- Variable name
            love.graphics.setColor(displayColor[1], displayColor[2], displayColor[3], alpha)
            local displayName = var.name
            if #displayName > 28 then
                displayName = displayName:sub(1, 26) .. ".."
            end
            love.graphics.print(displayName, PADDING, y + 2)

            -- Value
            local valueStr = formatValue(var)
            if #valueStr > 16 then
                valueStr = valueStr:sub(1, 14) .. ".."
            end
            love.graphics.setColor(1, 1, 1, alpha * 0.8)
            love.graphics.print(valueStr, PADDING + NAME_WIDTH, y + 2)

            -- Controls (buttons + input) for editable variables
            if not var.readOnly and (var.varType == "number" or var.varType == "color") then
                local pos = getControlPositions(i)

                -- Draw minus button [-]
                local minusHovered = hoveredElement and hoveredElement.varName == var.name and hoveredElement.type == "minus"
                local minusActive = activeButton and activeButton.varName == var.name and activeButton.type == "minus"
                drawButton(pos.minus.x, pos.minus.y, pos.minus.w, pos.minus.h, "-", minusHovered, minusActive, displayColor)

                -- Draw reset button [Reset]
                local resetHovered = hoveredElement and hoveredElement.varName == var.name and hoveredElement.type == "reset"
                local resetActive = activeButton and activeButton.varName == var.name and activeButton.type == "reset"
                drawButton(pos.reset.x, pos.reset.y, pos.reset.w, pos.reset.h, "Reset", resetHovered, resetActive, displayColor)

                -- Draw plus button [+]
                local plusHovered = hoveredElement and hoveredElement.varName == var.name and hoveredElement.type == "plus"
                local plusActive = activeButton and activeButton.varName == var.name and activeButton.type == "plus"
                drawButton(pos.plus.x, pos.plus.y, pos.plus.w, pos.plus.h, "+", plusHovered, plusActive, displayColor)

                -- Draw input field
                local inputFocused = focusedInput == var.name
                local inputHovered = hoveredElement and hoveredElement.varName == var.name and hoveredElement.type == "input"
                drawInputField(pos.input.x, pos.input.y, pos.input.w, pos.input.h, var, inputFocused, inputHovered, displayColor)
            elseif var.varType == "array" then
                -- Show array indicator
                love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
                love.graphics.print("(use command)", PADDING + NAME_WIDTH + VALUE_WIDTH + 10, y + 2)
            end
        end
    end

    love.graphics.setScissor()

    -- Scroll indicator
    if maxScroll > 0 then
        local scrollbarHeight = contentHeight * (contentHeight / (contentHeight + maxScroll))
        local scrollbarY = contentY + (scrollOffset / maxScroll) * (contentHeight - scrollbarHeight)
        love.graphics.setColor(0.4, 0.5, 0.6, 0.5)
        love.graphics.rectangle("fill", WINDOW_WIDTH - 8, scrollbarY, 4, scrollbarHeight, 2, 2)
    end

    -- Input line
    local inputY = WINDOW_HEIGHT - INPUT_HEIGHT - PADDING / 2

    -- Prompt
    love.graphics.setColor(0.5, 0.8, 1.0, 1.0)
    love.graphics.print("> ", PADDING, inputY + 2)

    -- Input text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(inputBuffer, PADDING + 14, inputY + 2)

    -- Autocomplete hint
    if #autocompleteMatches > 0 and autocompleteIndex > 0 then
        local hint = autocompleteMatches[autocompleteIndex]
        local font = love.graphics.getFont()
        local inputWidth = font:getWidth(inputBuffer)
        love.graphics.setColor(0.5, 0.7, 0.9, 0.6)
        local prefix = inputBuffer:match("^set%s+(.*)$") or inputBuffer:match("^([A-Z_]*)$") or ""
        if hint:sub(1, #prefix):upper() == prefix:upper() then
            love.graphics.print(hint:sub(#prefix + 1), PADDING + 14 + inputWidth, inputY + 2)
        end
    end

    -- Cursor
    if math.floor(love.timer.getTime() * 2.5) % 2 == 0 then
        local font = love.graphics.getFont()
        local cursorX = PADDING + 14 + font:getWidth(inputBuffer)
        love.graphics.rectangle("fill", cursorX, inputY + 2, 2, font:getHeight())
    end

    -- Error or autocomplete hint
    if errorTimer > 0 and errorMessage ~= "" then
        local alpha = math.min(1, errorTimer / 0.3)
        love.graphics.setColor(1, 0.4, 0.4, alpha)
        love.graphics.print(errorMessage, PADDING + 300, inputY + 2)
    elseif #autocompleteMatches > 1 then
        love.graphics.setColor(0.5, 0.6, 0.7, 0.8)
        love.graphics.print(string.format("[%d/%d] Tab", autocompleteIndex, #autocompleteMatches), PADDING + 300, inputY + 2)
    end
end

-- Mouse handling
function DebugConsole:mousepressed(x, y, button)
    if not consoleVisible then return false end
    if button ~= 1 then return false end

    -- If we have a focused input, clicking outside commits it
    if focusedInput then
        local var = variables[focusedInput]
        if var then
            for i, v in ipairs(sortedVariables) do
                if v.name == var.name then
                    local pos = getControlPositions(i)
                    local ip = pos.input
                    if not (x >= ip.x and x <= ip.x + ip.w and y >= ip.y and y <= ip.y + ip.h) then
                        commitInputEdit()
                    end
                    break
                end
            end
        end
    end

    -- Check controls for each variable
    local contentY = HEADER_HEIGHT
    local contentHeight = WINDOW_HEIGHT - HEADER_HEIGHT - INPUT_HEIGHT - PADDING

    for i, var in ipairs(sortedVariables) do
        if not var.readOnly and (var.varType == "number" or var.varType == "color") then
            local pos = getControlPositions(i)
            local rowY = pos.minus.y

            if rowY >= contentY - ROW_HEIGHT and rowY < contentY + contentHeight then
                -- Check minus button
                if x >= pos.minus.x and x <= pos.minus.x + pos.minus.w and
                   y >= pos.minus.y and y <= pos.minus.y + pos.minus.h then
                    activeButton = {varName = var.name, type = "minus"}
                    return true
                end
                -- Check reset button
                if x >= pos.reset.x and x <= pos.reset.x + pos.reset.w and
                   y >= pos.reset.y and y <= pos.reset.y + pos.reset.h then
                    activeButton = {varName = var.name, type = "reset"}
                    return true
                end
                -- Check plus button
                if x >= pos.plus.x and x <= pos.plus.x + pos.plus.w and
                   y >= pos.plus.y and y <= pos.plus.y + pos.plus.h then
                    activeButton = {varName = var.name, type = "plus"}
                    return true
                end
                -- Check input field
                if x >= pos.input.x and x <= pos.input.x + pos.input.w and
                   y >= pos.input.y and y <= pos.input.y + pos.input.h then
                    startInputEdit(var)
                    return true
                end
            end
        end
    end

    return true -- Consume click when console is visible
end

function DebugConsole:mousereleased(x, y, button)
    if not consoleVisible then return false end

    if activeButton then
        local var = variables[activeButton.varName]
        if var then
            -- Check if still hovering over same button
            for i, v in ipairs(sortedVariables) do
                if v.name == var.name then
                    local pos = getControlPositions(i)
                    local btn = pos[activeButton.type]
                    if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                        -- Execute button action
                        if activeButton.type == "minus" then
                            applyPercentChange(var, -10)
                        elseif activeButton.type == "reset" then
                            resetToDefault(var)
                        elseif activeButton.type == "plus" then
                            applyPercentChange(var, 10)
                        end
                    end
                    break
                end
            end
        end
        activeButton = nil
        return true
    end
    return consoleVisible
end

function DebugConsole:mousemoved(x, y)
    if not consoleVisible then return end

    hoveredElement = nil
    local contentY = HEADER_HEIGHT
    local contentHeight = WINDOW_HEIGHT - HEADER_HEIGHT - INPUT_HEIGHT - PADDING

    for i, var in ipairs(sortedVariables) do
        if not var.readOnly and (var.varType == "number" or var.varType == "color") then
            local pos = getControlPositions(i)
            local rowY = pos.minus.y

            if rowY >= contentY - ROW_HEIGHT and rowY < contentY + contentHeight then
                for _, btnType in ipairs({"minus", "reset", "plus", "input"}) do
                    local btn = pos[btnType]
                    if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                        hoveredElement = {varName = var.name, type = btnType}
                        return
                    end
                end
            end
        end
    end
end

function DebugConsole:wheelmoved(x, y)
    if not consoleVisible then return false end

    scrollOffset = scrollOffset - y * 40
    scrollOffset = math.max(0, math.min(maxScroll, scrollOffset))
    return true
end

-- Toggle console
function DebugConsole:toggle()
    consoleVisible = not consoleVisible
    if not consoleVisible then
        inputBuffer = ""
        autocompleteMatches = {}
        autocompleteIndex = 0
        hoveredElement = nil
        activeButton = nil
        focusedInput = nil
        inputEditBuffer = ""
        inputCursorPos = 0
    end
end

function DebugConsole:close()
    consoleVisible = false
    inputBuffer = ""
    autocompleteMatches = {}
    autocompleteIndex = 0
    hoveredElement = nil
    activeButton = nil
    focusedInput = nil
    inputEditBuffer = ""
    inputCursorPos = 0
end

function DebugConsole:isVisible()
    return consoleVisible
end

function DebugConsole:appendText(text)
    inputBuffer = inputBuffer .. text
    autocompleteMatches = {}
    autocompleteIndex = 0
end

function DebugConsole:backspace()
    if #inputBuffer > 0 then
        inputBuffer = inputBuffer:sub(1, -2)
        autocompleteMatches = {}
        autocompleteIndex = 0
    end
end

function DebugConsole:executeInput()
    if #autocompleteMatches > 0 and autocompleteIndex > 0 then
        local match = autocompleteMatches[autocompleteIndex]
        local prefix = inputBuffer:match("^(set%s+)") or ""
        inputBuffer = prefix .. match .. " "
        autocompleteMatches = {}
        autocompleteIndex = 0
        return
    end

    if inputBuffer ~= "" then
        processCommand(inputBuffer)
        inputBuffer = ""
        autocompleteMatches = {}
        autocompleteIndex = 0
    end
end

function DebugConsole:autocomplete()
    local prefix = inputBuffer:match("^set%s+([A-Z_]*)$") or inputBuffer:match("^([A-Z_]+)$")

    if not prefix or prefix == "" then
        if inputBuffer == "" or inputBuffer == "set " then
            errorMessage = "Type variable name to autocomplete"
            errorTimer = ERROR_DISPLAY_TIME
        end
        return
    end

    prefix = prefix:upper()

    if #autocompleteMatches > 0 then
        autocompleteIndex = (autocompleteIndex % #autocompleteMatches) + 1
        return
    end

    autocompleteMatches = {}
    for name, _ in pairs(variables) do
        if name:sub(1, #prefix) == prefix then
            table.insert(autocompleteMatches, name)
        end
    end

    table.sort(autocompleteMatches)

    if #autocompleteMatches == 0 then
        errorMessage = "No matches for: " .. prefix
        errorTimer = ERROR_DISPLAY_TIME
    elseif #autocompleteMatches == 1 then
        local match = autocompleteMatches[1]
        local setPrefix = inputBuffer:match("^(set%s+)") or ""
        inputBuffer = setPrefix .. match .. " "
        autocompleteMatches = {}
        autocompleteIndex = 0
    else
        autocompleteIndex = 1
    end
end

-- Handle keypress when text input is focused
function DebugConsole:handleKeypress(key)
    if focusedInput then
        if key == "return" or key == "kpenter" then
            commitInputEdit()
            return true
        elseif key == "escape" then
            cancelInputEdit()
            return true
        elseif key == "backspace" then
            if inputCursorPos > 0 then
                inputEditBuffer = inputEditBuffer:sub(1, inputCursorPos - 1) .. inputEditBuffer:sub(inputCursorPos + 1)
                inputCursorPos = inputCursorPos - 1
            end
            return true
        elseif key == "delete" then
            if inputCursorPos < #inputEditBuffer then
                inputEditBuffer = inputEditBuffer:sub(1, inputCursorPos) .. inputEditBuffer:sub(inputCursorPos + 2)
            end
            return true
        elseif key == "left" then
            inputCursorPos = math.max(0, inputCursorPos - 1)
            return true
        elseif key == "right" then
            inputCursorPos = math.min(#inputEditBuffer, inputCursorPos + 1)
            return true
        elseif key == "home" then
            inputCursorPos = 0
            return true
        elseif key == "end" then
            inputCursorPos = #inputEditBuffer
            return true
        end
    end
    return false  -- Not handled, pass to command input
end

-- Handle text input when text input is focused
function DebugConsole:handleTextInput(text)
    if focusedInput then
        inputEditBuffer = inputEditBuffer:sub(1, inputCursorPos) .. text .. inputEditBuffer:sub(inputCursorPos + 1)
        inputCursorPos = inputCursorPos + #text
        return true
    end
    return false  -- Not handled, pass to command input
end

function DebugConsole:setValue(name, value)
    local var = variables[name]
    if var and not var.readOnly then
        _G[name] = value
        var.flashTimer = FLASH_DURATION
        var.cachedValue = deepCopy(value)
        return true
    end
    return false
end

function DebugConsole:getVariableInfo(name)
    return variables[name]
end

function DebugConsole:getCategories()
    return categories
end

return DebugConsole
