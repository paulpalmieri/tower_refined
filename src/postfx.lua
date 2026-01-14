-- src/postfx.lua
-- Post-processing effects: Bloom, Chromatic Aberration, Glitch, Heat Distortion, CRT
-- CRT effects apply to everything (including UI), other effects are gameplay-only

local PostFX = {}

-- Canvases
local sceneCanvas       -- Captures game world for game effects
local bloomCanvas1      -- Downsampled bright areas
local bloomCanvas2      -- Ping-pong blur buffer
local crtCanvas         -- Captures full screen for CRT effect

-- Shaders
local gameShader        -- Chromatic aberration + glitch + heat (gameplay only)
local crtShader         -- CRT scanlines + curvature (applied to everything)
local blurShader
local thresholdShader

-- Time tracking for animated effects
local effectTime = 0

-- Brightness threshold extraction shader
local thresholdShaderCode = [[
extern float threshold;
extern float softThreshold;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec4 pixel = Texel(tex, tc);
    float brightness = dot(pixel.rgb, vec3(0.2126, 0.7152, 0.0722));
    float knee = threshold * softThreshold;
    float soft = brightness - threshold + knee;
    soft = clamp(soft, 0.0, 2.0 * knee);
    soft = soft * soft / (4.0 * knee + 0.00001);
    float contribution = max(soft, brightness - threshold) / max(brightness, 0.00001);
    contribution = clamp(contribution, 0.0, 1.0);
    return vec4(pixel.rgb * contribution, 1.0);
}
]]

-- Game effects shader (chromatic aberration + glitch + heat distortion)
-- Applied only to gameplay, not UI
local gameShaderCode = [[
extern float time;
extern vec2 resolution;

// Chromatic aberration
extern float chromaticAmount;
extern float chromaticFalloff;

// Glitch effect
extern float glitchIntensity;
extern float scanlineJitter;

// Heat distortion
extern float heatIntensity;
extern float heatFrequency;
extern float heatSpeed;

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec2 uv = tc;

    // === HEAT DISTORTION ===
    if (heatIntensity > 0.0) {
        float heatWaveX = sin(uv.y * heatFrequency + time * heatSpeed);
        float heatWaveY = cos(uv.x * heatFrequency * 0.7 + time * heatSpeed * 0.8);
        float ripple = sin(length(uv - 0.5) * 15.0 - time * 2.0) * 0.3;
        uv.x += (heatWaveX + ripple) * heatIntensity / resolution.x * 4.0;
        uv.y += heatWaveY * heatIntensity * 0.5 / resolution.y * 4.0;
    }

    // === GLITCH SCANLINE JITTER ===
    if (glitchIntensity > 0.0) {
        float lineIndex = floor(sc.y / 2.0);
        float lineRandom = hash(lineIndex + floor(time * 8.0));

        if (lineRandom > 0.97) {
            float displacement = (hash(lineIndex + time) - 0.5) * scanlineJitter * glitchIntensity;
            uv.x += displacement / resolution.x;
        }

        float sliceTime = floor(time * 2.5);
        float sliceRandom = hash(sliceTime);
        if (sliceRandom > 0.9) {
            float sliceY = hash(sliceTime + 1.0);
            float sliceHeight = 0.015 + hash(sliceTime + 2.0) * 0.04;
            if (abs(tc.y - sliceY) < sliceHeight) {
                uv.x += (hash(sliceTime + 3.0) - 0.5) * glitchIntensity * 0.015;
            }
        }
    }

    // === CHROMATIC ABERRATION ===
    vec2 dir = uv - vec2(0.5);
    float dist = length(dir);
    float offsetScale = mix(1.0, dist * 2.0, chromaticFalloff);
    vec2 offset = (dir / max(dist, 0.001)) * (chromaticAmount / resolution.x) * offsetScale;
    float rgbWander = sin(time * 0.7) * glitchIntensity * 0.5 / resolution.x;

    float r = Texel(tex, uv + offset + vec2(rgbWander, 0.0)).r;
    float g = Texel(tex, uv).g;
    float b = Texel(tex, uv - offset - vec2(rgbWander, 0.0)).b;
    float a = Texel(tex, uv).a;

    return vec4(r, g, b, a) * color;
}
]]

-- CRT shader (scanlines + curvature + vignette)
-- Applied to everything including UI
local crtShaderCode = [[
extern float crtScanlineIntensity;
extern float crtScanlineCount;
extern float crtCurvature;
extern float crtVignette;

vec2 crtCurve(vec2 uv, float amount) {
    uv = uv * 2.0 - 1.0;
    vec2 offset = abs(uv.yx) * amount;
    uv = uv + uv * offset * offset;
    uv = uv * 0.5 + 0.5;
    return uv;
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec2 uv = tc;

    // === CRT CURVATURE ===
    if (crtCurvature > 0.0) {
        uv = crtCurve(uv, crtCurvature);
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
            return vec4(0.0, 0.0, 0.0, 1.0);
        }
    }

    vec4 pixel = Texel(tex, uv);
    vec3 col = pixel.rgb;

    // === CRT SCANLINES ===
    if (crtScanlineIntensity > 0.0) {
        float scanline = sin(uv.y * crtScanlineCount * 3.14159) * 0.5 + 0.5;
        scanline = pow(scanline, 1.5);
        col *= 1.0 - (crtScanlineIntensity * (1.0 - scanline));
    }

    // === CRT VIGNETTE ===
    if (crtVignette > 0.0) {
        vec2 vignetteUV = uv * 2.0 - 1.0;
        float vignette = 1.0 - dot(vignetteUV, vignetteUV) * crtVignette;
        vignette = clamp(vignette, 0.0, 1.0);
        col *= vignette;
    }

    return vec4(col, pixel.a) * color;
}
]]

-- Gaussian blur shader (9-tap)
local blurShaderCode = [[
extern vec2 direction;
extern vec2 resolution;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec2 off = direction / resolution;
    vec4 sum = vec4(0.0);
    sum += Texel(tex, tc - off * 4.0) * 0.0162;
    sum += Texel(tex, tc - off * 3.0) * 0.0540;
    sum += Texel(tex, tc - off * 2.0) * 0.1216;
    sum += Texel(tex, tc - off * 1.0) * 0.1945;
    sum += Texel(tex, tc) * 0.2270;
    sum += Texel(tex, tc + off * 1.0) * 0.1945;
    sum += Texel(tex, tc + off * 2.0) * 0.1216;
    sum += Texel(tex, tc + off * 3.0) * 0.0540;
    sum += Texel(tex, tc + off * 4.0) * 0.0162;
    return sum * color;
}
]]

function PostFX:init()
    local w, h = love.graphics.getDimensions()
    self:createCanvases(w, h)
    self:createShaders()
end

function PostFX:createCanvases(w, h)
    sceneCanvas = love.graphics.newCanvas(w, h)
    crtCanvas = love.graphics.newCanvas(w, h)
    local bw, bh = math.floor(w / BLOOM_SCALE), math.floor(h / BLOOM_SCALE)
    bloomCanvas1 = love.graphics.newCanvas(bw, bh)
    bloomCanvas2 = love.graphics.newCanvas(bw, bh)
end

function PostFX:createShaders()
    gameShader = love.graphics.newShader(gameShaderCode)
    crtShader = love.graphics.newShader(crtShaderCode)
    blurShader = love.graphics.newShader(blurShaderCode)
    thresholdShader = love.graphics.newShader(thresholdShaderCode)
end

function PostFX:update(dt)
    effectTime = effectTime + dt
end

function PostFX:resize(w, h)
    self:createCanvases(w, h)
end

-- Start capturing game world (for game effects)
function PostFX:beginCapture()
    love.graphics.setCanvas(sceneCanvas)
    love.graphics.clear(0, 0, 0, 1)
end

-- End game world capture
function PostFX:endCapture()
    love.graphics.setCanvas()
end

-- Start capturing everything for CRT effect
function PostFX:beginCRT()
    if CRT_ENABLED then
        love.graphics.setCanvas(crtCanvas)
        love.graphics.clear(0, 0, 0, 1)
    end
end

-- End CRT capture and apply CRT shader to everything
function PostFX:endCRT()
    if CRT_ENABLED then
        love.graphics.setCanvas()

        love.graphics.setShader(crtShader)
        crtShader:send("crtScanlineIntensity", CRT_SCANLINE_INTENSITY or 0.15)
        crtShader:send("crtScanlineCount", CRT_SCANLINE_COUNT or 240)
        crtShader:send("crtCurvature", CRT_CURVATURE or 0.03)
        crtShader:send("crtVignette", CRT_VIGNETTE or 0.15)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(crtCanvas, 0, 0)
        love.graphics.setShader()
    end
end

-- Draw game scene with game effects (glitch, heat, chromatic) + bloom
-- Called after endCapture(), before UI drawing
function PostFX:drawScene()
    local w, h = love.graphics.getDimensions()

    -- === BLOOM PASS ===
    if BLOOM_ENABLED then
        local bw, bh = bloomCanvas1:getDimensions()

        love.graphics.setCanvas(bloomCanvas1)
        love.graphics.clear(0, 0, 0, 1)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setShader(thresholdShader)
        thresholdShader:send("threshold", BLOOM_THRESHOLD)
        thresholdShader:send("softThreshold", BLOOM_SOFT_THRESHOLD)
        love.graphics.draw(sceneCanvas, 0, 0, 0, 1/BLOOM_SCALE, 1/BLOOM_SCALE)
        love.graphics.setShader()

        for _ = 1, BLOOM_BLUR_PASSES do
            love.graphics.setCanvas(bloomCanvas2)
            love.graphics.setShader(blurShader)
            blurShader:send("direction", {1.0, 0.0})
            blurShader:send("resolution", {bw, bh})
            love.graphics.draw(bloomCanvas1, 0, 0)

            love.graphics.setCanvas(bloomCanvas1)
            blurShader:send("direction", {0.0, 1.0})
            love.graphics.draw(bloomCanvas2, 0, 0)
        end
        love.graphics.setShader()
        love.graphics.setCanvas()
    end

    -- Restore CRT canvas if CRT is enabled (we're drawing into it)
    if CRT_ENABLED then
        love.graphics.setCanvas(crtCanvas)
    end

    -- === GAME EFFECTS ===
    local useGameEffects = CHROMATIC_ABERRATION_ENABLED or GLITCH_ENABLED or HEAT_DISTORTION_ENABLED
    if useGameEffects then
        love.graphics.setShader(gameShader)
        gameShader:send("time", effectTime)
        gameShader:send("resolution", {w, h})
        gameShader:send("chromaticAmount", CHROMATIC_ABERRATION_ENABLED and CHROMATIC_ABERRATION_AMOUNT or 0)
        gameShader:send("chromaticFalloff", CHROMATIC_ABERRATION_FALLOFF or 0.5)
        gameShader:send("glitchIntensity", GLITCH_ENABLED and GLITCH_INTENSITY or 0)
        gameShader:send("scanlineJitter", GLITCH_SCANLINE_JITTER or 8.0)
        gameShader:send("heatIntensity", HEAT_DISTORTION_ENABLED and HEAT_DISTORTION_INTENSITY or 0)
        gameShader:send("heatFrequency", HEAT_DISTORTION_FREQUENCY or 8.0)
        gameShader:send("heatSpeed", HEAT_DISTORTION_SPEED or 1.5)
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(sceneCanvas, 0, 0)
    love.graphics.setShader()

    -- Add bloom on top
    if BLOOM_ENABLED then
        love.graphics.setBlendMode("add")
        love.graphics.setColor(1, 1, 1, BLOOM_INTENSITY)
        love.graphics.draw(bloomCanvas1, 0, 0, 0, BLOOM_SCALE, BLOOM_SCALE)
        love.graphics.setBlendMode("alpha")
    end
end

-- Legacy function for backwards compatibility (calls drawScene)
function PostFX:draw()
    self:drawScene()
end

return PostFX
