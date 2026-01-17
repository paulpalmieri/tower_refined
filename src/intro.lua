-- src/intro.lua
-- Intro sequence with typewriter text and turret power-on animation

local Intro = {}

-- Phase constants
local PHASE_BLACK = "black"
local PHASE_TEXT_1 = "text_1"
local PHASE_HOLD_1 = "hold_1"
local PHASE_TEXT_2 = "text_2"
local PHASE_HOLD_2 = "hold_2"
local PHASE_FADE = "fade"
local PHASE_ALERT = "alert"
local PHASE_BARREL = "barrel"
local PHASE_COMPLETE = "complete"

-- State
local phase = PHASE_BLACK
local timer = 0

-- Typewriter state for multi-line support
local typewriter = {
    lines = {},          -- Array of {text, segments}
    currentLine = 1,
    visibleChars = 0,    -- Chars visible on current line
    charTimer = 0,
    linePauseTimer = 0,  -- Timer for pause between lines
    isPaused = false,    -- Whether we're in a pause between lines
}

-- Sound pools
local typeSounds = {}
local alertSound = nil
local TYPE_SOUND_POOL_SIZE = 4

-- Ambient music
local introMusic = nil
local INTRO_MUSIC_PATH = "assets/intro_music_brass.mp3"
local INTRO_MUSIC_VOLUME = 0.5

-- Font
local introFont = nil
local INTRO_FONT_SIZE = 24

-- Text layout
local LINE_SPACING = 1.6

-- Barrel animation
local barrelExtend = 0
local alertSoundPlayed = false

-- Music fade state
local musicFading = false
local musicFadeTimer = 0

-- ===================
-- PROCEDURAL SOUND GENERATION
-- Digital terminal blip - soft, electronic, data-transmission feel
-- ===================

local function generateTypeSound()
    local sampleRate = 44100
    local duration = 0.08
    local samples = math.floor(sampleRate * duration)

    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)

    -- Lower base frequency for softer, more "data" feel
    local baseFreq = 440 + math.random(-40, 80)
    -- Subtle harmonic for richness
    local harmonicFreq = baseFreq * 2.5
    -- Frequency modulation rate for digital warble
    local modRate = 60 + math.random(-10, 10)
    local modDepth = 15 + math.random(0, 10)

    for i = 0, samples - 1 do
        local t = i / sampleRate
        local progress = i / samples

        -- Soft attack, smooth decay (no harsh transient)
        local envelope
        if progress < 0.08 then
            -- Gentle fade in
            envelope = progress / 0.08
            envelope = envelope * envelope  -- Quadratic for softer attack
        elseif progress < 0.25 then
            -- Hold
            envelope = 1
        else
            -- Smooth exponential decay
            envelope = math.exp(-6 * (progress - 0.25))
        end

        -- Frequency modulation for subtle digital warble
        local freqMod = math.sin(2 * math.pi * modRate * t) * modDepth
        local modulatedFreq = baseFreq + freqMod

        -- Primary tone with FM
        local primary = math.sin(2 * math.pi * modulatedFreq * t)

        -- Soft harmonic (triangle-ish wave for warmth)
        local harmonic = math.sin(2 * math.pi * harmonicFreq * t)
        harmonic = harmonic * math.exp(-8 * progress)  -- Faster decay on harmonic

        -- Subtle square wave undertone for "digital" grit
        local squareRaw = math.sin(2 * math.pi * (baseFreq * 0.5) * t) > 0 and 0.1 or -0.1
        local square = squareRaw * math.exp(-12 * progress)  -- Very fast decay

        -- Mix: warm primary with subtle digital texture
        local wave = primary * 0.6 + harmonic * 0.25 + square * 0.15

        soundData:setSample(i, wave * envelope * 0.25)
    end

    return love.audio.newSource(soundData, "static")
end

local function generateAlertSound()
    local sampleRate = 44100
    local duration = 0.5
    local samples = math.floor(sampleRate * duration)

    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)

    for i = 0, samples - 1 do
        local t = i / sampleRate
        -- Two-tone ascending alert
        local freq = t < 0.25 and 800 or 1200

        -- Envelope
        local envelope
        if t < 0.05 then
            envelope = t / 0.05
        elseif t > 0.45 then
            envelope = (0.5 - t) / 0.05
        else
            envelope = 1
        end

        local wave = math.sin(2 * math.pi * freq * t)
        soundData:setSample(i, wave * envelope * 0.35)
    end

    return love.audio.newSource(soundData, "static")
end

-- ===================
-- TEXT PARSING
-- ===================

local function parseText(fullText)
    local segments = {}
    local pos = 1

    local keywords = {
        { pattern = "polygons", style = "polygons" },
        { pattern = "circles", style = "circles" },
    }

    while pos <= #fullText do
        local foundKeyword = nil
        local foundStart = nil

        for _, kw in ipairs(keywords) do
            local s = string.find(fullText:lower(), kw.pattern, pos)
            if s and (not foundStart or s < foundStart) then
                foundStart = s
                foundKeyword = kw
            end
        end

        if foundKeyword and foundStart then
            if foundStart > pos then
                table.insert(segments, {
                    text = fullText:sub(pos, foundStart - 1),
                    startIndex = pos,
                    style = "normal",
                })
            end

            local keywordEnd = foundStart + #foundKeyword.pattern - 1
            table.insert(segments, {
                text = fullText:sub(foundStart, keywordEnd),
                startIndex = foundStart,
                style = foundKeyword.style,
            })

            pos = keywordEnd + 1
        else
            table.insert(segments, {
                text = fullText:sub(pos),
                startIndex = pos,
                style = "normal",
            })
            break
        end
    end

    return segments
end

local function getStyleAtIndex(segments, charIndex)
    for _, seg in ipairs(segments) do
        local segEnd = seg.startIndex + #seg.text - 1
        if charIndex >= seg.startIndex and charIndex <= segEnd then
            return seg.style
        end
    end
    return "normal"
end

-- ===================
-- INITIALIZATION
-- ===================

function Intro:init()
    introFont = love.graphics.newFont(FONT_PATH, INTRO_FONT_SIZE)
    introFont:setFilter("nearest", "nearest")

    for _ = 1, TYPE_SOUND_POOL_SIZE do
        table.insert(typeSounds, generateTypeSound())
    end
    alertSound = generateAlertSound()

    -- Load intro music
    if love.filesystem.getInfo(INTRO_MUSIC_PATH) then
        introMusic = love.audio.newSource(INTRO_MUSIC_PATH, "stream")
        introMusic:setLooping(true)
        introMusic:setVolume(INTRO_MUSIC_VOLUME)
    end
end

function Intro:start()
    phase = PHASE_BLACK
    timer = 0
    typewriter.lines = {}
    typewriter.currentLine = 1
    typewriter.visibleChars = 0
    typewriter.charTimer = 0
    typewriter.linePauseTimer = 0
    typewriter.isPaused = false
    barrelExtend = 0
    alertSoundPlayed = false
    musicFading = false
    musicFadeTimer = 0

    -- Start intro music
    if introMusic then
        introMusic:setVolume(INTRO_MUSIC_VOLUME)
        introMusic:play()
    end
end

function Intro:reset()
    self:start()
end

-- Start from the "SYSTEM ONLINE" animation (skips text phases)
-- Used for game restarts
function Intro:startReboot()
    phase = PHASE_ALERT
    timer = 0
    barrelExtend = 0
    alertSoundPlayed = false
    musicFading = false
    musicFadeTimer = 0
    -- Don't start intro music for reboots
end

-- ===================
-- SOUND PLAYBACK
-- ===================

local typeSoundIndex = 1

local function playTypeSound()
    typeSounds[typeSoundIndex]:stop()
    typeSounds[typeSoundIndex] = generateTypeSound()
    typeSounds[typeSoundIndex]:play()
    typeSoundIndex = (typeSoundIndex % TYPE_SOUND_POOL_SIZE) + 1
end

local function playAlertSound()
    if alertSound then
        alertSound:stop()
        alertSound:play()
    end
end

-- ===================
-- TEXT SETUP
-- ===================

local function setupText1()
    typewriter.lines = {
        { text = INTRO_TEXT_1_LINE1, segments = parseText(INTRO_TEXT_1_LINE1) },
        { text = INTRO_TEXT_1_LINE2, segments = parseText(INTRO_TEXT_1_LINE2) },
    }
    typewriter.currentLine = 1
    typewriter.visibleChars = 0
    typewriter.charTimer = 0
end

local function setupText2()
    typewriter.lines = {
        { text = INTRO_TEXT_2, segments = parseText(INTRO_TEXT_2) },
    }
    typewriter.currentLine = 1
    typewriter.visibleChars = 0
    typewriter.charTimer = 0
end

-- ===================
-- UPDATE
-- ===================

local function updateTypewriter(dt)
    -- Handle inter-line pause
    if typewriter.isPaused then
        typewriter.linePauseTimer = typewriter.linePauseTimer + dt
        if typewriter.linePauseTimer >= INTRO_LINE_PAUSE then
            typewriter.isPaused = false
            typewriter.linePauseTimer = 0
        end
        return false
    end

    local currentLineData = typewriter.lines[typewriter.currentLine]
    if not currentLineData then
        return true  -- All lines complete
    end

    local lineText = currentLineData.text

    -- Check if current line is complete
    if typewriter.visibleChars >= #lineText then
        -- Move to next line
        typewriter.currentLine = typewriter.currentLine + 1
        typewriter.visibleChars = 0
        typewriter.charTimer = 0

        -- Check if all lines are done
        if typewriter.currentLine > #typewriter.lines then
            return true
        end

        -- Start pause before next line
        typewriter.isPaused = true
        typewriter.linePauseTimer = 0
        return false
    end

    -- Type next character
    typewriter.charTimer = typewriter.charTimer + dt
    if typewriter.charTimer >= INTRO_TYPEWRITER_SPEED then
        typewriter.charTimer = 0
        typewriter.visibleChars = typewriter.visibleChars + 1

        local char = lineText:sub(typewriter.visibleChars, typewriter.visibleChars)
        if char ~= " " then
            playTypeSound()
        end
    end

    return false
end

function Intro:update(dt)
    timer = timer + dt

    if phase == PHASE_BLACK then
        if timer >= INTRO_BLACK_DURATION then
            phase = PHASE_TEXT_1
            timer = 0
            setupText1()
        end

    elseif phase == PHASE_TEXT_1 then
        if updateTypewriter(dt) then
            phase = PHASE_HOLD_1
            timer = 0
        end

    elseif phase == PHASE_HOLD_1 then
        if timer >= INTRO_TEXT_HOLD_1 then
            phase = PHASE_TEXT_2
            timer = 0
            setupText2()
        end

    elseif phase == PHASE_TEXT_2 then
        if updateTypewriter(dt) then
            phase = PHASE_HOLD_2
            timer = 0
        end

    elseif phase == PHASE_HOLD_2 then
        if timer >= INTRO_TEXT_HOLD_2 then
            phase = PHASE_FADE
            timer = 0
            -- Start fading music
            musicFading = true
            musicFadeTimer = 0
        end

    elseif phase == PHASE_FADE then
        -- Fade out music during this phase
        if musicFading and introMusic then
            musicFadeTimer = musicFadeTimer + dt
            local fadeProgress = math.min(musicFadeTimer / INTRO_FADE_DURATION, 1)
            introMusic:setVolume(INTRO_MUSIC_VOLUME * (1 - fadeProgress))
            if fadeProgress >= 1 then
                introMusic:stop()
                musicFading = false
            end
        end

        if timer >= INTRO_FADE_DURATION then
            phase = PHASE_ALERT
            timer = 0
            alertSoundPlayed = false
            -- Ensure music is stopped
            if introMusic then
                introMusic:stop()
            end
        end

    elseif phase == PHASE_ALERT then
        if not alertSoundPlayed then
            playAlertSound()
            alertSoundPlayed = true
        end
        if timer >= INTRO_ALERT_DURATION then
            phase = PHASE_BARREL
            timer = 0
        end

    elseif phase == PHASE_BARREL then
        local t = math.min(timer / INTRO_BARREL_SLIDE_DURATION, 1)
        barrelExtend = 1 - math.pow(1 - t, 3)  -- Ease out cubic

        if timer >= INTRO_BARREL_SLIDE_DURATION then
            phase = PHASE_COMPLETE
        end
    end
end

-- ===================
-- SKIP
-- ===================

function Intro:skip()
    phase = PHASE_COMPLETE
    -- Stop music immediately when skipping
    if introMusic then
        introMusic:stop()
    end
end

-- ===================
-- QUERIES
-- ===================

function Intro:isComplete()
    return phase == PHASE_COMPLETE
end

function Intro:getBarrelExtend()
    return barrelExtend
end

function Intro:isInBarrelPhase()
    return phase == PHASE_BARREL
end

function Intro:isInFadeOrLater()
    return phase == PHASE_FADE or phase == PHASE_ALERT or phase == PHASE_BARREL
end

-- ===================
-- DRAWING
-- ===================

local function drawTextLines(lines, currentLine, visibleChars, centerY)
    local font = introFont
    local lineHeight = font:getHeight() * LINE_SPACING

    -- Calculate total height
    local totalHeight = #lines * lineHeight
    local startY = centerY - totalHeight / 2

    love.graphics.setFont(font)

    for lineIdx, lineData in ipairs(lines) do
        local lineY = startY + (lineIdx - 1) * lineHeight
        local lineWidth = font:getWidth(lineData.text)
        local x = CENTER_X - lineWidth / 2

        -- Determine how many chars to show on this line
        local charsToShow
        if lineIdx < currentLine then
            charsToShow = #lineData.text  -- Full line
        elseif lineIdx == currentLine then
            charsToShow = visibleChars
        else
            charsToShow = 0  -- Not started yet
        end

        for i = 1, charsToShow do
            local char = lineData.text:sub(i, i)
            local charWidth = font:getWidth(char)
            local style = getStyleAtIndex(lineData.segments, i)

            -- Glitch effect
            local glitchX, glitchY = 0, 0
            if (style == "polygons" or style == "circles") and math.random() > 0.90 then
                glitchX = math.random(-3, 3)
                glitchY = math.random(-2, 2)
            end

            if style == "polygons" then
                local colors = {
                    {1.0, 0.2, 0.2},
                    {0.2, 1.0, 1.0},
                    {1.0, 1.0, 0.2},
                }
                local colorIndex = ((i - 1 + math.floor(love.timer.getTime() * 5)) % #colors) + 1
                local color = colors[colorIndex]

                love.graphics.setColor(color[1], color[2], color[3], 0.4)
                love.graphics.print(char, x + glitchX - 1, lineY + glitchY)
                love.graphics.print(char, x + glitchX + 1, lineY + glitchY)
                love.graphics.setColor(color[1], color[2], color[3], 1)
                love.graphics.print(char, x + glitchX, lineY + glitchY)

            elseif style == "circles" then
                local c = NEON_PRIMARY
                love.graphics.setColor(c[1], c[2], c[3], 0.5)
                love.graphics.print(char, x + glitchX - 1, lineY + glitchY)
                love.graphics.print(char, x + glitchX + 1, lineY + glitchY)
                love.graphics.setColor(c[1], c[2], c[3], 1)
                love.graphics.print(char, x + glitchX, lineY + glitchY)

            else
                love.graphics.setColor(0.75, 0.75, 0.75, 1)
                love.graphics.print(char, x, lineY)
            end

            x = x + charWidth
        end
    end
end

function Intro:draw()
    -- Background
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    if phase == PHASE_BLACK then
        return
    end

    -- Text phases
    if phase == PHASE_TEXT_1 or phase == PHASE_HOLD_1 or
       phase == PHASE_TEXT_2 or phase == PHASE_HOLD_2 then
        drawTextLines(typewriter.lines, typewriter.currentLine, typewriter.visibleChars, CENTER_Y)
    end
end

function Intro:drawGameElements()
    if phase == PHASE_FADE then
        local fadeAlpha = 1 - (timer / INTRO_FADE_DURATION)
        love.graphics.setColor(0, 0, 0, fadeAlpha)
        love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    elseif phase == PHASE_ALERT then
        -- Flashing alert text
        local flash = math.sin(timer * 8 * math.pi) * 0.5 + 0.5

        love.graphics.setFont(introFont)

        -- Glow
        love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], flash * 0.4)
        local text = INTRO_ALERT_TEXT
        local textW = introFont:getWidth(text)
        love.graphics.print(text, CENTER_X - textW / 2 - 2, CENTER_Y - 100)
        love.graphics.print(text, CENTER_X - textW / 2 + 2, CENTER_Y - 100)

        -- Main
        love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], flash)
        love.graphics.print(text, CENTER_X - textW / 2, CENTER_Y - 100)
    end
    -- PHASE_BARREL: turret animation handled by getBarrelExtend()
end

return Intro
