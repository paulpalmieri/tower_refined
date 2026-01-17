-- src/skilltree/init.lua
-- Main skill tree module

local NodeData = require "src.skilltree.node_data"
local SkillNode = require "src.skilltree.node"
local Canvas = require "src.skilltree.canvas"
local Transition = require "src.skilltree.transition"

local SkillTree = {}

-- State
local nodes = {}           -- Map of id -> SkillNode
local nodeList = {}        -- Ordered list for rendering
local canvas = nil
local transition = nil
local hoveredNode = nil

-- Play transition state (simple glitch/fade)
local playTransition = {
    active = false,
    timer = 0,
    onComplete = nil,
}

-- Play button state
local playButton = {
    x = 0,
    y = 0,
    width = 100,
    height = 36,
    hovered = false,
}

-- ===================
-- INITIALIZATION
-- ===================

function SkillTree:init()
    -- Create canvas
    canvas = Canvas(NodeData.GRID_SIZE, NodeData.CELL_SIZE)
    transition = Transition()

    -- Create nodes from definitions
    nodes = {}
    nodeList = {}

    for id, def in pairs(NodeData.NODE_DEFS) do
        local node = SkillNode(def)
        nodes[id] = node
        table.insert(nodeList, node)
    end

    -- Mark turret as purchased (starting node)
    if nodes.turret then
        nodes.turret.currentLevel = 1
    end

    -- Update play button position
    playButton.x = WINDOW_WIDTH - playButton.width - 20
    playButton.y = WINDOW_HEIGHT - playButton.height - 20
end

function SkillTree:reset()
    -- Reset all node levels except turret
    for id, node in pairs(nodes) do
        if id == "turret" then
            node.currentLevel = 1
        else
            node.currentLevel = 0
        end
    end

    transition:reset()
    hoveredNode = nil

    -- Reset canvas to center
    canvas:reset(NodeData.GRID_SIZE, NodeData.CELL_SIZE)
end

-- ===================
-- TRANSITION
-- ===================

function SkillTree:startTransition()
    transition:start()
end

function SkillTree:isTransitionComplete()
    return transition:isComplete() or transition.phase == "none"
end

-- ===================
-- PLAY TRANSITION (Glitch/Fade)
-- ===================

function SkillTree:startPlayTransition(onComplete)
    playTransition.active = true
    playTransition.timer = 0
    playTransition.onComplete = onComplete
end

function SkillTree:updatePlayTransition(dt)
    if not playTransition.active then return false end

    playTransition.timer = playTransition.timer + dt

    if playTransition.timer >= PLAY_TRANSITION_DURATION then
        playTransition.active = false
        if playTransition.onComplete then
            playTransition.onComplete()
        end
        return true  -- Transition complete
    end

    return false
end

function SkillTree:isPlayTransitionActive()
    return playTransition.active
end

function SkillTree:drawPlayTransitionOverlay()
    if not playTransition.active then return end

    local progress = playTransition.timer / PLAY_TRANSITION_DURATION

    -- Fade to black
    local fadeAlpha = progress * progress  -- Ease-in
    love.graphics.setColor(0, 0, 0, fadeAlpha)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
end

-- ===================
-- UPDATE
-- ===================

function SkillTree:update(dt)
    transition:update(dt)

    if transition:isComplete() or transition.phase == "none" then
        canvas:update(dt)
    end
end

-- ===================
-- DRAWING
-- ===================

function SkillTree:draw()
    -- During transition, draw with animated zoom/fade
    if transition:isActive() then
        self:drawTransition()
        return
    end

    -- Normal skill tree rendering
    self:drawSkillTree()
end

function SkillTree:drawTransition()
    -- Draw skill tree fading in
    local fadeAlpha = transition:getFadeAlpha()

    -- First draw the skill tree (it will fade in)
    love.graphics.setColor(1, 1, 1, fadeAlpha)
    self:drawSkillTree()
end

function SkillTree:drawSkillTree()
    -- Background
    love.graphics.setColor(NEON_BACKGROUND[1], NEON_BACKGROUND[2], NEON_BACKGROUND[3], 0.98)
    love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

    -- Apply canvas transform
    canvas:applyTransform()

    -- Draw grid (subtle)
    self:drawGrid()

    -- Draw connections first (behind nodes)
    self:drawConnections()

    -- Draw nodes
    for _, node in ipairs(nodeList) do
        self:drawNode(node)
    end

    canvas:resetTransform()

    -- Draw UI overlay (not affected by canvas transform)
    self:drawUI()
end

function SkillTree:drawGrid()
    love.graphics.setColor(NEON_GRID[1], NEON_GRID[2], NEON_GRID[3], 0.15)
    love.graphics.setLineWidth(1)

    local size = NodeData.GRID_SIZE * NodeData.CELL_SIZE
    for i = 0, NodeData.GRID_SIZE do
        local pos = i * NodeData.CELL_SIZE
        love.graphics.line(pos, 0, pos, size)
        love.graphics.line(0, pos, size, pos)
    end
end

function SkillTree:drawConnections()
    love.graphics.setLineWidth(2)

    -- Track drawn connections to avoid duplicates
    local drawn = {}

    for _, node in ipairs(nodeList) do
        local x1, y1 = node:getWorldPosition(NodeData.CELL_SIZE)
        x1 = x1 + NodeData.CELL_SIZE / 2
        y1 = y1 + NodeData.CELL_SIZE / 2

        for _, connId in ipairs(node.connections) do
            -- Create unique key for this connection
            local key = node.id < connId and (node.id .. "-" .. connId) or (connId .. "-" .. node.id)

            if not drawn[key] then
                drawn[key] = true

                local connNode = nodes[connId]
                if connNode then
                    local x2, y2 = connNode:getWorldPosition(NodeData.CELL_SIZE)
                    x2 = x2 + NodeData.CELL_SIZE / 2
                    y2 = y2 + NodeData.CELL_SIZE / 2

                    -- Connection color based on purchase state
                    if node.currentLevel > 0 and connNode.currentLevel > 0 then
                        -- Both purchased - bright green
                        love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.7)
                    elseif node.currentLevel > 0 or connNode.currentLevel > 0 then
                        -- One purchased - dim green
                        love.graphics.setColor(NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.5)
                    else
                        -- Neither purchased - grey
                        love.graphics.setColor(0.25, 0.25, 0.25, 0.4)
                    end

                    love.graphics.line(x1, y1, x2, y2)
                end
            end
        end
    end

    love.graphics.setLineWidth(1)
end

function SkillTree:drawNode(node)
    local wx, wy = node:getWorldPosition(NodeData.CELL_SIZE)
    local cx = wx + NodeData.CELL_SIZE / 2
    local cy = wy + NodeData.CELL_SIZE / 2
    local halfSize = NodeData.NODE_SIZE / 2

    -- Get border color
    local borderColor = node:getBorderColor(totalGold, nodes)

    -- Draw node background (dark fill)
    love.graphics.setColor(0.03, 0.03, 0.05, 0.95)
    love.graphics.rectangle("fill", cx - halfSize, cy - halfSize, NodeData.NODE_SIZE, NodeData.NODE_SIZE)

    -- Draw icon
    local iconColor = self:getBranchColor(node.branch)
    local iconAlpha = node.placeholder and 0.2 or 0.7
    if node.currentLevel > 0 then
        iconAlpha = 1.0
    end
    self:drawIcon(node.icon, cx, cy, iconColor, iconAlpha)

    -- Draw border
    love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", cx - halfSize, cy - halfSize, NodeData.NODE_SIZE, NodeData.NODE_SIZE)

    -- Draw level indicator if has levels
    if node.maxLevel > 0 and not node.placeholder then
        local levelText = node.currentLevel .. "/" .. node.maxLevel
        love.graphics.setColor(0.8, 0.8, 0.8, 0.9)
        local font = love.graphics.getFont()
        local textW = font:getWidth(levelText)
        love.graphics.print(levelText, cx - textW / 2, cy + halfSize + 2)
    end

    -- Hover highlight
    if node == hoveredNode then
        love.graphics.setColor(1, 1, 1, 0.2)
        love.graphics.rectangle("fill", cx - halfSize - 2, cy - halfSize - 2, NodeData.NODE_SIZE + 4, NodeData.NODE_SIZE + 4)
    end

    love.graphics.setLineWidth(1)
end

function SkillTree:drawIcon(iconType, cx, cy, color, alpha)
    love.graphics.setColor(color[1], color[2], color[3], alpha)

    if iconType == "turret" then
        -- Turret: circle base + barrel
        love.graphics.circle("fill", cx, cy + 1, 4)
        love.graphics.rectangle("fill", cx - 1, cy - 5, 2, 6)

    elseif iconType == "fire_rate" then
        -- Fire rate: three bullets stacked (rapid fire)
        love.graphics.rectangle("fill", cx - 4, cy - 2, 3, 2)
        love.graphics.rectangle("fill", cx - 1, cy - 2, 3, 2)
        love.graphics.rectangle("fill", cx + 2, cy - 2, 3, 2)
        -- Muzzle flash lines
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.5)
        love.graphics.line(cx - 5, cy + 2, cx + 5, cy + 2)
        love.graphics.line(cx - 4, cy + 4, cx + 4, cy + 4)

    elseif iconType == "velocity" then
        -- Velocity: arrow pointing right with speed lines
        -- Arrow head
        love.graphics.polygon("fill", cx + 4, cy, cx, cy - 3, cx, cy + 3)
        -- Arrow body
        love.graphics.rectangle("fill", cx - 4, cy - 1, 6, 2)
        -- Speed lines
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.4)
        love.graphics.line(cx - 6, cy - 3, cx - 3, cy - 3)
        love.graphics.line(cx - 7, cy, cx - 5, cy)
        love.graphics.line(cx - 6, cy + 3, cx - 3, cy + 3)

    elseif iconType == "health" then
        -- Health: heart shape
        -- Using two circles and a triangle for heart
        love.graphics.circle("fill", cx - 2, cy - 1, 3)
        love.graphics.circle("fill", cx + 2, cy - 1, 3)
        love.graphics.polygon("fill", cx - 5, cy, cx + 5, cy, cx, cy + 5)

    elseif iconType == "gold" then
        -- Gold: coin with $ symbol
        love.graphics.circle("fill", cx, cy, 5)
        love.graphics.setColor(0.03, 0.03, 0.05, 1)
        -- S shape for dollar
        love.graphics.rectangle("fill", cx - 2, cy - 3, 4, 2)
        love.graphics.rectangle("fill", cx - 2, cy - 1, 2, 2)
        love.graphics.rectangle("fill", cx - 2, cy + 1, 4, 2)
        love.graphics.rectangle("fill", cx, cy + 1, 2, -2)

    elseif iconType == "armor" then
        -- Armor: shield shape
        love.graphics.polygon("fill",
            cx, cy - 5,
            cx + 5, cy - 2,
            cx + 4, cy + 3,
            cx, cy + 5,
            cx - 4, cy + 3,
            cx - 5, cy - 2
        )

    elseif iconType == "luck" then
        -- Luck: four-leaf clover / star
        for i = 0, 3 do
            local angle = (i * math.pi / 2) - math.pi / 4
            local lx = cx + math.cos(angle) * 3
            local ly = cy + math.sin(angle) * 3
            love.graphics.circle("fill", lx, ly, 2.5)
        end
        love.graphics.circle("fill", cx, cy, 2)

    elseif iconType == "locked" then
        -- Locked: question mark
        love.graphics.arc("fill", cx, cy - 2, 4, math.pi, 0)
        love.graphics.rectangle("fill", cx + 1, cy - 2, 3, 3)
        love.graphics.rectangle("fill", cx - 1, cy + 1, 2, 2)
        love.graphics.rectangle("fill", cx - 1, cy + 4, 2, 2)

    -- Laser icons
    elseif iconType == "laser" then
        -- Laser beam: three horizontal lines converging
        love.graphics.setLineWidth(2)
        love.graphics.line(cx - 5, cy - 3, cx + 5, cy)
        love.graphics.line(cx - 5, cy, cx + 5, cy)
        love.graphics.line(cx - 5, cy + 3, cx + 5, cy)
        love.graphics.setLineWidth(1)

    elseif iconType == "laser_duration" then
        -- Duration: beam with clock-like arc
        love.graphics.setLineWidth(2)
        love.graphics.line(cx - 5, cy, cx + 2, cy)
        love.graphics.setLineWidth(1)
        love.graphics.arc("line", "open", cx + 2, cy, 4, -math.pi/2, math.pi)

    elseif iconType == "laser_charge" then
        -- Charge speed: lightning bolt
        love.graphics.polygon("fill",
            cx - 2, cy - 5,
            cx + 2, cy - 1,
            cx, cy - 1,
            cx + 2, cy + 5,
            cx - 2, cy + 1,
            cx, cy + 1
        )

    elseif iconType == "laser_width" then
        -- Width: expanding beam
        love.graphics.polygon("fill",
            cx - 5, cy - 1,
            cx - 5, cy + 1,
            cx + 5, cy + 4,
            cx + 5, cy - 4
        )

    -- Plasma icons
    elseif iconType == "plasma" then
        -- Plasma orb: circle with glow rings
        love.graphics.circle("fill", cx, cy, 4)
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.5)
        love.graphics.circle("line", cx, cy, 6)

    elseif iconType == "plasma_speed" then
        -- Speed: orb with motion lines
        love.graphics.circle("fill", cx + 2, cy, 3)
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.4)
        love.graphics.line(cx - 5, cy - 2, cx - 2, cy - 2)
        love.graphics.line(cx - 6, cy, cx - 2, cy)
        love.graphics.line(cx - 5, cy + 2, cx - 2, cy + 2)

    elseif iconType == "plasma_cooldown" then
        -- Cooldown: circular arrow
        love.graphics.arc("line", "open", cx, cy, 4, 0, math.pi * 1.5)
        love.graphics.polygon("fill", cx + 4, cy - 2, cx + 4, cy + 2, cx + 6, cy)

    elseif iconType == "plasma_size" then
        -- Size: large orb
        love.graphics.circle("fill", cx, cy, 5)
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.3)
        love.graphics.circle("fill", cx, cy, 7)

    -- Collection icons
    elseif iconType == "magnet" then
        -- Magnet: horseshoe with attraction lines
        love.graphics.setLineWidth(2)
        love.graphics.arc("line", "open", cx, cy, 5, math.pi, 0)
        love.graphics.line(cx - 5, cy, cx - 5, cy + 4)
        love.graphics.line(cx + 5, cy, cx + 5, cy + 4)
        -- Attraction lines
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.4)
        love.graphics.line(cx - 2, cy + 6, cx - 2, cy + 3)
        love.graphics.line(cx + 2, cy + 6, cx + 2, cy + 3)
        love.graphics.setLineWidth(1)

    elseif iconType == "pickup_radius" then
        -- Pickup radius: expanding circles
        love.graphics.circle("line", cx, cy, 3)
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.6)
        love.graphics.circle("line", cx, cy, 5)
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.3)
        love.graphics.circle("line", cx, cy, 7)

    -- Drone icons
    elseif iconType == "drone" then
        -- Drone: small circle with barrel
        love.graphics.circle("fill", cx, cy, 4)
        love.graphics.rectangle("fill", cx, cy - 1, 5, 2)
        -- Orbit indicator
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.4)
        love.graphics.arc("line", "open", cx - 2, cy, 6, -math.pi * 0.7, math.pi * 0.7)

    elseif iconType == "drone_fire_rate" then
        -- Drone with speed lines
        love.graphics.circle("fill", cx + 1, cy, 3)
        love.graphics.rectangle("fill", cx + 1, cy - 1, 4, 2)
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.5)
        love.graphics.line(cx - 5, cy - 2, cx - 2, cy - 2)
        love.graphics.line(cx - 6, cy, cx - 2, cy)
        love.graphics.line(cx - 5, cy + 2, cx - 2, cy + 2)

    -- Shield icons
    elseif iconType == "shield" then
        -- Shield icon: hexagonal barrier shape
        love.graphics.polygon("line",
            cx, cy - 6,
            cx + 5, cy - 3,
            cx + 5, cy + 3,
            cx, cy + 6,
            cx - 5, cy + 3,
            cx - 5, cy - 3
        )

    elseif iconType == "shield_radius" then
        -- Expanding circles
        love.graphics.circle("line", cx, cy, 3)
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.5)
        love.graphics.circle("line", cx, cy, 5)
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.25)
        love.graphics.circle("line", cx, cy, 7)

    elseif iconType == "shield_charges" then
        -- Battery/capacitor icon
        love.graphics.rectangle("line", cx - 4, cy - 3, 8, 6)
        love.graphics.rectangle("fill", cx + 4, cy - 1, 2, 2)
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.7)
        love.graphics.rectangle("fill", cx - 3, cy - 2, 4, 4)

    -- Missile silo icons
    elseif iconType == "missile" then
        -- Missile: rocket shape pointing up
        love.graphics.polygon("fill",
            cx, cy - 5,
            cx - 3, cy + 2,
            cx - 2, cy + 5,
            cx + 2, cy + 5,
            cx + 3, cy + 2
        )
        -- Exhaust flame
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.6)
        love.graphics.polygon("fill",
            cx - 1, cy + 5,
            cx, cy + 8,
            cx + 1, cy + 5
        )

    elseif iconType == "silo_count" then
        -- Multiple small squares (silos)
        love.graphics.rectangle("fill", cx - 5, cy - 2, 4, 4)
        love.graphics.rectangle("fill", cx + 1, cy - 2, 4, 4)
        love.graphics.rectangle("fill", cx - 2, cy + 2, 4, 4)

    elseif iconType == "silo_double" then
        -- Two missiles side by side
        love.graphics.polygon("fill", cx - 3, cy - 4, cx - 5, cy + 2, cx - 1, cy + 2)
        love.graphics.polygon("fill", cx + 3, cy - 4, cx + 1, cy + 2, cx + 5, cy + 2)

    elseif iconType == "silo_fire_rate" then
        -- Missile with speed lines
        love.graphics.polygon("fill", cx + 1, cy - 4, cx - 1, cy + 3, cx + 3, cy + 3)
        love.graphics.setColor(color[1], color[2], color[3], alpha * 0.5)
        love.graphics.line(cx - 4, cy - 2, cx - 2, cy - 2)
        love.graphics.line(cx - 5, cy + 1, cx - 2, cy + 1)

    else
        -- Default: simple square
        love.graphics.rectangle("fill", cx - 4, cy - 4, 8, 8)
    end
end

function SkillTree:getBranchColor(branch)
    if branch == "damage" then return NEON_RED end
    if branch == "health" then return NEON_PRIMARY end
    if branch == "resource" then return NEON_YELLOW end
    if branch == "collection" then return POLYGON_COLOR end
    if branch == "drone" then return DRONE_COLOR end
    if branch == "defense" then return NEON_CYAN end
    if branch == "offense" then return MISSILE_COLOR end  -- Orange for missile silos
    if branch == "bottom" then return {0.4, 0.4, 0.4} end
    return NEON_CYAN -- center
end

function SkillTree:drawUI()
    -- Title
    love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.9)
    love.graphics.print("SKILL TREE", 20, 20)

    -- Gold display
    love.graphics.setColor(NEON_YELLOW[1], NEON_YELLOW[2], NEON_YELLOW[3], 0.9)
    love.graphics.print("Credits: " .. totalGold, 20, 42)

    -- Polygons display
    love.graphics.setColor(POLYGON_COLOR[1], POLYGON_COLOR[2], POLYGON_COLOR[3], 0.9)
    love.graphics.print("Polygons: P" .. polygons, 20, 62)

    -- Hovered node info
    if hoveredNode then
        self:drawNodeTooltip(hoveredNode)
    end

    -- Play button
    self:drawPlayButton()

    -- Controls hint
    love.graphics.setColor(NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.5)
    love.graphics.print("Drag to pan | Scroll to zoom | Click to purchase | [R] Play", 20, WINDOW_HEIGHT - 30)
end

function SkillTree:drawNodeTooltip(node)
    local tipX = 20
    local tipY = WINDOW_HEIGHT - 180
    local tipW = 220
    local tipH = 130

    -- Background
    love.graphics.setColor(0.02, 0.02, 0.05, 0.95)
    love.graphics.rectangle("fill", tipX, tipY, tipW, tipH)
    love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", tipX, tipY, tipW, tipH)
    love.graphics.setLineWidth(1)

    -- Name
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(node.name, tipX + 10, tipY + 10)

    -- Level
    if node.maxLevel > 0 then
        love.graphics.setColor(NEON_PRIMARY_DIM[1], NEON_PRIMARY_DIM[2], NEON_PRIMARY_DIM[3], 0.8)
        love.graphics.print("Level: " .. node.currentLevel .. "/" .. node.maxLevel, tipX + 10, tipY + 32)
    end

    -- Effect description
    if node.effects and node.effects.type and not node.placeholder then
        local effectText = self:getEffectDescription(node)
        love.graphics.setColor(0.7, 0.7, 0.7, 0.9)
        love.graphics.print(effectText, tipX + 10, tipY + 54)
    end

    -- Cost or maxed status
    local cost = node:getNextCost()
    if cost then
        local canAfford = totalGold >= cost
        local costColor = canAfford and NEON_YELLOW or NEON_RED
        love.graphics.setColor(costColor[1], costColor[2], costColor[3], 0.9)
        love.graphics.print("Cost: " .. cost, tipX + 10, tipY + 76)

        if not node:isReachable(nodes) then
            love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
            love.graphics.print("(Requires adjacent node)", tipX + 10, tipY + 98)
        elseif not canAfford then
            love.graphics.setColor(NEON_RED[1], NEON_RED[2], NEON_RED[3], 0.7)
            love.graphics.print("(Not enough credits)", tipX + 10, tipY + 98)
        else
            love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.7)
            love.graphics.print("(Click to purchase)", tipX + 10, tipY + 98)
        end
    else
        love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.7)
        love.graphics.print("MAXED", tipX + 10, tipY + 76)
    end
end

function SkillTree:getEffectDescription(node)
    local effectType = node.effects.type
    local nextVal = node:getNextEffect()
    local currVal = node:getCurrentEffect()

    if effectType == "fireRate" then
        if nextVal then
            return "Fire rate: x" .. string.format("%.2f", nextVal)
        elseif currVal then
            return "Fire rate: x" .. string.format("%.2f", currVal)
        end
    elseif effectType == "projectileSpeed" then
        if nextVal then
            return "Bullet speed: x" .. string.format("%.2f", nextVal)
        elseif currVal then
            return "Bullet speed: x" .. string.format("%.2f", currVal)
        end
    elseif effectType == "maxHp" then
        if nextVal then
            return "Max HP: +" .. nextVal
        elseif currVal then
            return "Max HP: +" .. currVal
        end
    elseif effectType == "goldMultiplier" then
        if nextVal then
            return "Gold: x" .. string.format("%.2f", nextVal)
        elseif currVal then
            return "Gold: x" .. string.format("%.2f", currVal)
        end
    -- Laser effects
    elseif effectType == "laserDamage" then
        local val = nextVal or currVal
        if val then return "Laser damage: x" .. string.format("%.2f", val) end
    elseif effectType == "laserDuration" then
        local val = nextVal or currVal
        if val then return "Laser duration: x" .. string.format("%.2f", val) end
    elseif effectType == "laserChargeSpeed" then
        local val = nextVal or currVal
        if val then return "Deploy speed: x" .. string.format("%.2f", val) end
    elseif effectType == "laserWidth" then
        local val = nextVal or currVal
        if val then return "Beam width: x" .. string.format("%.2f", val) end
    -- Plasma effects
    elseif effectType == "plasmaDamage" then
        local val = nextVal or currVal
        if val then return "Plasma damage: x" .. string.format("%.2f", val) end
    elseif effectType == "plasmaSpeed" then
        local val = nextVal or currVal
        if val then return "Missile speed: x" .. string.format("%.2f", val) end
    elseif effectType == "plasmaCooldown" then
        local val = nextVal or currVal
        if val then return "Cooldown: x" .. string.format("%.2f", val) end
    elseif effectType == "plasmaSize" then
        local val = nextVal or currVal
        if val then return "Missile size: x" .. string.format("%.2f", val) end
    -- Collection effects
    elseif effectType == "magnetEnabled" then
        return "Auto-collect nearby shards"
    elseif effectType == "pickupRadius" then
        local val = nextVal or currVal
        if val then return "Pickup radius: x" .. string.format("%.2f", val) end
    -- Drone effects
    elseif effectType == "droneCount" then
        local val = nextVal or currVal
        if val then return "Active drones: " .. val end
    elseif effectType == "droneFireRate" then
        local val = nextVal or currVal
        if val then return "Drone fire rate: x" .. string.format("%.2f", val) end
    -- Shield effects
    elseif effectType == "shieldUnlock" then
        return "Unlocks energy shield (1 charge)"
    elseif effectType == "shieldRadius" then
        local val = nextVal or currVal
        if val then return "Shield radius: x" .. string.format("%.2f", val) end
    elseif effectType == "shieldCharges" then
        local val = nextVal or currVal
        if val then return "Shield charges: " .. val end
    -- Missile silo effects
    elseif effectType == "siloCount" then
        local val = nextVal or currVal
        if val then return "Active silos: " .. val end
    elseif effectType == "siloFireRate" then
        local val = nextVal or currVal
        if val then return "Silo fire rate: x" .. string.format("%.2f", val) end
    elseif effectType == "siloDoubleShot" then
        return "Silos fire 2 missiles (+1 silo)"
    end

    return ""
end

function SkillTree:drawPlayButton()
    local btn = playButton

    -- Glow effect when hovered
    if btn.hovered then
        love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.2)
        love.graphics.rectangle("fill", btn.x - 3, btn.y - 3, btn.width + 6, btn.height + 6)
    end

    -- Background
    if btn.hovered then
        love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], 0.25)
    else
        love.graphics.setColor(0.02, 0.05, 0.02, 0.9)
    end
    love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height)

    -- Border
    love.graphics.setColor(NEON_PRIMARY[1], NEON_PRIMARY[2], NEON_PRIMARY[3], btn.hovered and 1 or 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", btn.x, btn.y, btn.width, btn.height)
    love.graphics.setLineWidth(1)

    -- Text
    love.graphics.setColor(1, 1, 1, 1)
    local font = love.graphics.getFont()
    local text = "PLAY"
    local textW = font:getWidth(text)
    local textH = font:getHeight()
    love.graphics.print(text, btn.x + (btn.width - textW) / 2, btn.y + (btn.height - textH) / 2)
end

-- ===================
-- INPUT HANDLING
-- ===================

function SkillTree:mousepressed(x, y, button)
    if button == 1 then
        -- Check play button
        local btn = playButton
        if x >= btn.x and x <= btn.x + btn.width and
           y >= btn.y and y <= btn.y + btn.height then
            return "play"
        end

        -- Check node click
        if hoveredNode then
            if hoveredNode:canPurchase(totalGold, nodes) then
                local cost = hoveredNode:purchase()
                totalGold = totalGold - cost
                Sounds.playPurchase()
                return "purchase"
            end
        end

        -- Start drag
        canvas:startDrag(x, y)
    end

    return nil
end

function SkillTree:mousereleased(x, y, button)
    if button == 1 then
        canvas:endDrag()
    end
end

function SkillTree:mousemoved(x, y)
    -- Update drag
    canvas:drag(x, y)

    -- Update play button hover
    local btn = playButton
    btn.hovered = x >= btn.x and x <= btn.x + btn.width and
                  y >= btn.y and y <= btn.y + btn.height

    -- Update node hover (only when not dragging)
    hoveredNode = nil
    if not canvas.dragging then
        local wx, wy = canvas:screenToWorld(x, y)

        for _, node in ipairs(nodeList) do
            local nx, ny = node:getWorldPosition(NodeData.CELL_SIZE)
            local cx = nx + NodeData.CELL_SIZE / 2
            local cy = ny + NodeData.CELL_SIZE / 2
            local halfSize = NodeData.NODE_SIZE / 2

            if wx >= cx - halfSize and wx <= cx + halfSize and
               wy >= cy - halfSize and wy <= cy + halfSize then
                hoveredNode = node
                break
            end
        end
    end
end

function SkillTree:wheelmoved(x, y)
    canvas:adjustZoom(y)
end

function SkillTree:keypressed(key)
    if key == "r" or key == "return" or key == "space" then
        return "play"
    elseif key == "escape" then
        return "back"
    end
    return nil
end

-- ===================
-- UPGRADE APPLICATION
-- ===================

function SkillTree:applyUpgrades(stats)
    -- Reset stats to base values
    stats.fireRate = 1.0
    stats.projectileSpeed = 1.0
    stats.maxHp = 0
    stats.goldMultiplier = 1.0
    stats.damage = 1.0

    -- Reset laser stats
    stats.laserDamage = 1.0
    stats.laserDuration = 1.0
    stats.laserChargeSpeed = 1.0
    stats.laserWidth = 1.0

    -- Reset plasma stats
    stats.plasmaDamage = 1.0
    stats.plasmaSpeed = 1.0
    stats.plasmaCooldown = 1.0
    stats.plasmaSize = 1.0

    -- Reset collection stats
    stats.magnetEnabled = false
    stats.pickupRadius = 1.0

    -- Reset drone stats
    stats.droneCount = 0
    stats.droneFireRate = 1.0

    -- Reset shield stats
    stats.shieldUnlocked = false
    stats.shieldCharges = 0
    stats.shieldRadius = 1.0

    -- Reset silo stats
    stats.siloCount = 0
    stats.siloFireRate = 1.0
    stats.siloDoubleShot = false

    -- Apply all purchased node effects
    for _, node in pairs(nodes) do
        if node.currentLevel > 0 and node.effects and node.effects.type then
            local effectType = node.effects.type
            local value = node.effects.values[node.currentLevel]

            if value then
                if effectType == "fireRate" then
                    stats.fireRate = stats.fireRate * value
                elseif effectType == "projectileSpeed" then
                    stats.projectileSpeed = stats.projectileSpeed * value
                elseif effectType == "maxHp" then
                    stats.maxHp = stats.maxHp + value
                elseif effectType == "goldMultiplier" then
                    stats.goldMultiplier = stats.goldMultiplier * value
                elseif effectType == "damage" then
                    stats.damage = stats.damage * value
                -- Laser effects
                elseif effectType == "laserDamage" then
                    stats.laserDamage = stats.laserDamage * value
                elseif effectType == "laserDuration" then
                    stats.laserDuration = stats.laserDuration * value
                elseif effectType == "laserChargeSpeed" then
                    stats.laserChargeSpeed = stats.laserChargeSpeed * value
                elseif effectType == "laserWidth" then
                    stats.laserWidth = stats.laserWidth * value
                -- Plasma effects
                elseif effectType == "plasmaDamage" then
                    stats.plasmaDamage = stats.plasmaDamage * value
                elseif effectType == "plasmaSpeed" then
                    stats.plasmaSpeed = stats.plasmaSpeed * value
                elseif effectType == "plasmaCooldown" then
                    stats.plasmaCooldown = stats.plasmaCooldown * value
                elseif effectType == "plasmaSize" then
                    stats.plasmaSize = stats.plasmaSize * value
                -- Collection effects
                elseif effectType == "magnetEnabled" then
                    stats.magnetEnabled = value > 0
                elseif effectType == "pickupRadius" then
                    stats.pickupRadius = stats.pickupRadius * value
                -- Drone effects
                elseif effectType == "droneCount" then
                    stats.droneCount = value  -- Takes highest value (not cumulative)
                elseif effectType == "droneFireRate" then
                    stats.droneFireRate = stats.droneFireRate * value
                -- Shield effects
                elseif effectType == "shieldUnlock" then
                    stats.shieldUnlocked = true
                    stats.shieldCharges = math.max(stats.shieldCharges, 1)
                elseif effectType == "shieldRadius" then
                    stats.shieldRadius = stats.shieldRadius * value
                elseif effectType == "shieldCharges" then
                    stats.shieldCharges = math.max(stats.shieldCharges, value)
                -- Silo effects
                elseif effectType == "siloCount" then
                    stats.siloCount = math.max(stats.siloCount, value)
                elseif effectType == "siloFireRate" then
                    stats.siloFireRate = stats.siloFireRate * value
                elseif effectType == "siloDoubleShot" then
                    stats.siloDoubleShot = true
                    stats.siloCount = stats.siloCount + 1  -- Bonus silo
                end
            end
        end
    end
end

return SkillTree
