-- src/hud.lua
-- HUD rendering extracted from main.lua

local HUD = {}

-- Draw all UI elements
-- ctx should contain:
--   tower, gameTime, enemyCount, gameSpeed, godMode, autoFire,
--   laserSystem, plasmaSystem, roguelite, stats, totalGold
function HUD:draw(ctx)
    -- ===================
    -- NEON UI STYLING
    -- ===================

    -- Time and enemy count (neon green)
    love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.9)
    local minutes = math.floor(ctx.gameTime / 60)
    local seconds = math.floor(ctx.gameTime % 60)
    love.graphics.print(string.format("Time: %d:%02d", minutes, seconds), 10, 10)
    love.graphics.print("Enemies: " .. ctx.enemyCount, 10, 30)

    -- Game speed indicator
    local speedText
    if ctx.gameSpeed == 0 then
        love.graphics.setColor(NEON_RED[1], NEON_RED[2], NEON_RED[3], 0.9)
        speedText = "PAUSED [Z]"
    elseif ctx.gameSpeed < 1 then
        love.graphics.setColor(NEON_CYAN[1], NEON_CYAN[2], NEON_CYAN[3], 0.9)
        speedText = "Speed: " .. ctx.gameSpeed .. "x [Z]"
    elseif ctx.gameSpeed > 1 then
        love.graphics.setColor(NEON_YELLOW[1], NEON_YELLOW[2], NEON_YELLOW[3], 0.9)
        speedText = "Speed: " .. ctx.gameSpeed .. "x [Z]"
    else
        love.graphics.setColor(NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.7)
        speedText = "Speed: " .. ctx.gameSpeed .. "x [Z]"
    end
    love.graphics.print(speedText, 10, 50)

    -- God mode indicator
    if ctx.godMode then
        love.graphics.setColor(NEON_CYAN[1], NEON_CYAN[2], NEON_CYAN[3], 0.9)
        love.graphics.print("GOD MODE [G]", 10, 70)
    end

    -- Auto-fire mode indicator
    local autoFireY = ctx.godMode and 90 or 70
    if ctx.autoFire then
        love.graphics.setColor(NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.7)
        love.graphics.print("Auto-Fire: ON [X]", 10, autoFireY)
    else
        love.graphics.setColor(NEON_RED[1], NEON_RED[2], NEON_RED[3], 0.9)
        love.graphics.print("Manual Aim [X]", 10, autoFireY)
    end

    -- Tower HP bar with neon styling
    love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.9)
    love.graphics.print("CORE HP", WINDOW_WIDTH - 110, 10)

    local hpBarWidth = 100
    local hpBarHeight = 14
    local hpPercent = ctx.tower:getHpPercent()

    -- Dark fill background
    love.graphics.setColor(0.02, 0.05, 0.02, 0.9)
    love.graphics.rectangle("fill", WINDOW_WIDTH - 110, 30, hpBarWidth, hpBarHeight)

    -- HP bar color based on health
    local hpColor = {NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3]}
    if hpPercent < 0.3 then
        hpColor = {NEON_RED[1], NEON_RED[2], NEON_RED[3]}
    elseif hpPercent < 0.6 then
        hpColor = {NEON_YELLOW[1], NEON_YELLOW[2], NEON_YELLOW[3]}
    end

    -- HP fill with glow
    love.graphics.setColor(hpColor[1], hpColor[2], hpColor[3], 0.3)
    love.graphics.rectangle("fill", WINDOW_WIDTH - 110, 30, hpBarWidth * hpPercent, hpBarHeight)
    love.graphics.setColor(hpColor[1], hpColor[2], hpColor[3], 0.8)
    love.graphics.rectangle("fill", WINDOW_WIDTH - 110, 32, hpBarWidth * hpPercent, hpBarHeight - 4)

    -- Neon border
    love.graphics.setColor(hpColor[1], hpColor[2], hpColor[3], 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", WINDOW_WIDTH - 110, 30, hpBarWidth, hpBarHeight)
    love.graphics.setLineWidth(1)

    -- HP text inside bar
    local hpText = math.floor(ctx.tower.hp) .. "/" .. math.floor(ctx.tower.maxHp)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(hpText)
    local textHeight = font:getHeight()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(hpText, WINDOW_WIDTH - 110 + (hpBarWidth - textWidth) / 2, 30 + (hpBarHeight - textHeight) / 2)

    -- Gold (current run) - yellow neon
    love.graphics.setColor(NEON_YELLOW[1], NEON_YELLOW[2], NEON_YELLOW[3], 0.9)
    love.graphics.print("Gold: " .. ctx.totalGold, WINDOW_WIDTH - 110, 50)

    -- XP Bar and Level - purple neon
    local xpBarX = WINDOW_WIDTH - 160
    local xpBarY = 70
    local xpBarWidth = 150
    local xpBarHeight = 14

    -- Level text
    love.graphics.setColor(POLYGON_COLOR[1], POLYGON_COLOR[2], POLYGON_COLOR[3], 0.9)
    love.graphics.print("LVL " .. ctx.roguelite.level, xpBarX, xpBarY - 16)

    -- XP bar background
    love.graphics.setColor(0.02, 0.02, 0.05, 0.9)
    love.graphics.rectangle("fill", xpBarX, xpBarY, xpBarWidth, xpBarHeight)

    -- XP bar fill
    local xpProgress = ctx.roguelite:getXPProgress()
    love.graphics.setColor(POLYGON_COLOR[1], POLYGON_COLOR[2], POLYGON_COLOR[3], 0.4)
    love.graphics.rectangle("fill", xpBarX, xpBarY, xpBarWidth * xpProgress, xpBarHeight)
    love.graphics.setColor(POLYGON_COLOR[1], POLYGON_COLOR[2], POLYGON_COLOR[3], 0.8)
    love.graphics.rectangle("fill", xpBarX, xpBarY + 2, xpBarWidth * xpProgress, xpBarHeight - 4)

    -- XP bar border
    love.graphics.setColor(POLYGON_COLOR[1], POLYGON_COLOR[2], POLYGON_COLOR[3], 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", xpBarX, xpBarY, xpBarWidth, xpBarHeight)
    love.graphics.setLineWidth(1)

    -- XP text inside bar
    local xpText = math.floor(ctx.roguelite.currentXP) .. "/" .. math.floor(ctx.roguelite.xpToNextLevel)
    local xpTextW = font:getWidth(xpText)
    local xpTextH = font:getHeight()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(xpText, xpBarX + (xpBarWidth - xpTextW) / 2, xpBarY + (xpBarHeight - xpTextH) / 2)

    -- Laser button with neon styling
    local laserY = WINDOW_HEIGHT - 60
    local laserWidth = 90
    local laserHeight = 30

    -- Dark background
    love.graphics.setColor(0.02, 0.05, 0.02, 0.9)
    love.graphics.rectangle("fill", 10, laserY, laserWidth, laserHeight)

    local laserState = ctx.laserSystem:getState()
    if laserState == "ready" then
        -- Ready glow
        love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.4)
        love.graphics.rectangle("fill", 10, laserY, laserWidth, laserHeight)
        love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.8)
        love.graphics.rectangle("fill", 12, laserY + 2, laserWidth - 4, laserHeight - 4)

        -- Border glow
        love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 10, laserY, laserWidth, laserHeight)
        love.graphics.setLineWidth(1)

        -- Text
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("[1] LASER", 18, laserY + 8)
    elseif laserState == "deploying" or laserState == "charging" then
        -- Charging progress fill (green to white based on charge)
        local chargePercent
        if laserState == "deploying" then
            chargePercent = (ctx.laserSystem.timer / LASER_DEPLOY_TIME) * 0.1
        else
            chargePercent = 0.1 + (ctx.laserSystem.timer / LASER_CHARGE_TIME) * 0.9
        end

        -- Interpolate from green to white based on charge
        local whiteBlend = ctx.laserSystem.chargeGlow
        local r = NEON_PRIMARY[1] + (1 - NEON_PRIMARY[1]) * whiteBlend
        local g = NEON_PRIMARY[2]
        local b = NEON_PRIMARY[3] + (1 - NEON_PRIMARY[3]) * whiteBlend

        love.graphics.setColor(r, g, b, 0.5)
        love.graphics.rectangle("fill", 10, laserY, laserWidth * chargePercent, laserHeight)

        -- Border
        love.graphics.setColor(r, g, b, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 10, laserY, laserWidth, laserHeight)
        love.graphics.setLineWidth(1)

        -- Text
        love.graphics.setColor(r, g, b, 1)
        love.graphics.print("CHARGING", 22, laserY + 8)
    elseif laserState == "firing" then
        -- Firing glow (pulsing)
        local pulse = 0.6 + math.sin(love.timer.getTime() * 15) * 0.4
        love.graphics.setColor(1, 1, 1, pulse * 0.6)
        love.graphics.rectangle("fill", 10, laserY, laserWidth, laserHeight)

        -- Border
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 10, laserY, laserWidth, laserHeight)
        love.graphics.setLineWidth(1)

        -- Text
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print("FIRING!", 26, laserY + 8)
    else
        -- Retracting (dim)
        love.graphics.setColor(NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.3)
        love.graphics.rectangle("fill", 10, laserY, laserWidth * ctx.laserSystem.cannonExtend, laserHeight)

        -- Border
        love.graphics.setColor(NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", 10, laserY, laserWidth, laserHeight)

        -- Text
        love.graphics.setColor(NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.7)
        love.graphics.print("[1] LASER", 18, laserY + 8)
    end

    -- Plasma button with purple neon styling
    local plasmaX = 110
    local plasmaY = WINDOW_HEIGHT - 60
    local plasmaWidth = 90
    local plasmaHeight = 30

    -- Dark background
    love.graphics.setColor(0.03, 0.01, 0.05, 0.9)
    love.graphics.rectangle("fill", plasmaX, plasmaY, plasmaWidth, plasmaHeight)

    local plasmaState = ctx.plasmaSystem:getState()
    if plasmaState == "ready" then
        -- Ready glow (purple)
        love.graphics.setColor(PLASMA_COLOR[1], PLASMA_COLOR[2], PLASMA_COLOR[3], 0.4)
        love.graphics.rectangle("fill", plasmaX, plasmaY, plasmaWidth, plasmaHeight)
        love.graphics.setColor(PLASMA_COLOR[1], PLASMA_COLOR[2], PLASMA_COLOR[3], 0.8)
        love.graphics.rectangle("fill", plasmaX + 2, plasmaY + 2, plasmaWidth - 4, plasmaHeight - 4)

        -- Border glow
        love.graphics.setColor(PLASMA_COLOR[1], PLASMA_COLOR[2], PLASMA_COLOR[3], 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", plasmaX, plasmaY, plasmaWidth, plasmaHeight)
        love.graphics.setLineWidth(1)

        -- Text
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("[2] PLASMA", plasmaX + 6, plasmaY + 8)
    elseif plasmaState == "charging" then
        -- Charging progress fill (purple to white based on charge)
        local chargePercent = ctx.plasmaSystem:getChargeProgress()

        -- Interpolate from purple to white based on charge
        local whiteBlend = chargePercent
        local r = PLASMA_COLOR[1] + (1 - PLASMA_COLOR[1]) * whiteBlend
        local g = PLASMA_COLOR[2] + (1 - PLASMA_COLOR[2]) * whiteBlend
        local b = PLASMA_COLOR[3]

        love.graphics.setColor(r, g, b, 0.5)
        love.graphics.rectangle("fill", plasmaX, plasmaY, plasmaWidth * chargePercent, plasmaHeight)

        -- Border
        love.graphics.setColor(r, g, b, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", plasmaX, plasmaY, plasmaWidth, plasmaHeight)
        love.graphics.setLineWidth(1)

        -- Text
        love.graphics.setColor(r, g, b, 1)
        love.graphics.print("CHARGING", plasmaX + 10, plasmaY + 8)
    else
        -- Cooldown (dim purple with progress)
        local cooldownTime = PLASMA_COOLDOWN_TIME * ctx.stats.plasmaCooldown
        local cooldownPercent = ctx.plasmaSystem.timer / cooldownTime
        love.graphics.setColor(PLASMA_COLOR[1] * 0.4, PLASMA_COLOR[2] * 0.4, PLASMA_COLOR[3] * 0.4, 0.3)
        love.graphics.rectangle("fill", plasmaX, plasmaY, plasmaWidth * cooldownPercent, plasmaHeight)

        -- Border
        love.graphics.setColor(PLASMA_COLOR[1] * 0.5, PLASMA_COLOR[2] * 0.5, PLASMA_COLOR[3] * 0.5, 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", plasmaX, plasmaY, plasmaWidth, plasmaHeight)

        -- Text
        love.graphics.setColor(PLASMA_COLOR[1] * 0.5, PLASMA_COLOR[2] * 0.5, PLASMA_COLOR[3] * 0.5, 0.7)
        love.graphics.print("[2] PLASMA", plasmaX + 6, plasmaY + 8)
    end

    -- Shield charges indicator (below ability buttons)
    if ctx.tower.shield and ctx.tower.shield.maxCharges > 0 then
        local shieldX = 10
        local shieldY = WINDOW_HEIGHT - 25
        local shieldWidth = 90
        local shieldHeight = 16

        -- Background
        love.graphics.setColor(0.02, 0.03, 0.05, 0.9)
        love.graphics.rectangle("fill", shieldX, shieldY, shieldWidth, shieldHeight)

        -- Charge fill
        local chargeRatio = ctx.tower.shield:getChargeRatio()
        if chargeRatio > 0 then
            love.graphics.setColor(NEON_CYAN[1], NEON_CYAN[2], NEON_CYAN[3], 0.6)
            love.graphics.rectangle("fill", shieldX, shieldY, shieldWidth * chargeRatio, shieldHeight)
        end

        -- Border
        local borderAlpha = chargeRatio > 0 and 0.8 or 0.3
        love.graphics.setColor(NEON_CYAN[1], NEON_CYAN[2], NEON_CYAN[3], borderAlpha)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", shieldX, shieldY, shieldWidth, shieldHeight)

        -- Text
        local textAlpha = chargeRatio > 0 and 1 or 0.5
        love.graphics.setColor(1, 1, 1, textAlpha)
        love.graphics.print("Shield: " .. ctx.tower.shield.charges, shieldX + 5, shieldY + 2)
    end
end

return HUD
