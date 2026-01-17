-- composite_templates.lua
-- Hand-designed composite enemy templates
--
-- RULES:
-- 1. Max 2 layers (core shape + attached shapes only)
-- 2. Core shapes: square, pentagon, hexagon (no heptagon)
-- 3. Children must be exactly ONE order lower than core:
--    - Square (4) → triangles (3)
--    - Pentagon (5) → squares (4)
--    - Hexagon (6) → pentagons (5)
-- 4. Coverage: ALL sides covered, OR alternating sides (even-sided cores only)
--
-- Colors: triangle=Red, square=Cyan, pentagon=Yellow, hexagon=Orange

COMPOSITE_TEMPLATES = {
    -- ===================
    -- SQUARE CORE (4 sides, even) + TRIANGULAR children
    -- ===================

    -- Square + 2 triangles (alternating: sides 1,3)
    half_shielded_square = {
        core = "square",
        baseSize = 12,
        scale = 1.0,
        speed = 50,
        children = {
            {shape = "triangle", side = 1},
            {shape = "triangle", side = 3},
        }
    },

    -- Square + 4 triangles (all sides)
    shielded_square = {
        core = "square",
        baseSize = 14,
        scale = 1.0,
        speed = 40,
        children = {
            {shape = "triangle", side = 1},
            {shape = "triangle", side = 2},
            {shape = "triangle", side = 3},
            {shape = "triangle", side = 4},
        }
    },

    -- ===================
    -- PENTAGON CORE (5 sides, odd - must cover all) + SQUARE children
    -- ===================

    -- Pentagon + 5 squares (all sides)
    shielded_pentagon = {
        core = "pentagon",
        baseSize = 16,
        scale = 1.0,
        speed = 28,
        children = {
            {shape = "square", side = 1},
            {shape = "square", side = 2},
            {shape = "square", side = 3},
            {shape = "square", side = 4},
            {shape = "square", side = 5},
        }
    },

    -- ===================
    -- HEXAGON CORE (6 sides, even) + PENTAGON children
    -- ===================

    -- Hexagon + 3 pentagons (alternating: sides 1,3,5)
    half_shielded_hexagon = {
        core = "hexagon",
        baseSize = 18,
        scale = 1.0,
        speed = 22,
        children = {
            {shape = "pentagon", side = 1},
            {shape = "pentagon", side = 3},
            {shape = "pentagon", side = 5},
        }
    },

    -- Hexagon + 6 pentagons (all sides)
    shielded_hexagon = {
        core = "hexagon",
        baseSize = 19,
        scale = 1.0,
        speed = 18,
        children = {
            {shape = "pentagon", side = 1},
            {shape = "pentagon", side = 2},
            {shape = "pentagon", side = 3},
            {shape = "pentagon", side = 4},
            {shape = "pentagon", side = 5},
            {shape = "pentagon", side = 6},
        }
    },
}

return COMPOSITE_TEMPLATES
