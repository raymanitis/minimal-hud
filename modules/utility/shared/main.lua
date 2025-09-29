local utility = {}
local logger = require("modules.utility.shared.logger")
local config = require("config.shared")

---@param value number
---@return number
utility.convertRpmToPercentage = function(value)
    local percentage = math.ceil(value * 10000 - 2001) / 80
    return math.max(0, math.min(percentage, 100))
end

---@param num number
---@param numDecimalPlaces number?
---@return integer
utility.round = function(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num + 0.5 * mult)
end

utility.convertEngineHealthToPercentage = function(value)
    -- Engine health ranges from 1000 (perfect) to 0 (about to catch fire)
    -- Values below 0 are just shown as 0% since they're critically damaged
    local clampedValue = math.max(0, math.min(value, 1000))

    local percentage = (clampedValue / 1000) * 100

    percentage = math.floor(percentage + 0.5)

    return percentage
end

---@return {width: number, height: number, left: number, top: number}
utility.calculateMinimapSizeAndPosition = function()
    SetBigmapActive(false, false)
    local minimap = {}
    local resX, resY = GetActiveScreenResolution()

    local aspectRatio = GetAspectRatio(false)
    local minimapRawX, minimapRawY

    SetScriptGfxAlign(string.byte("L"), string.byte("B"))

    if IsBigmapActive() then
        minimapRawX, minimapRawY = GetScriptGfxPosition(-0.00, 0.022 + -0.435416666)
        minimap.width = resX / (2.52 * aspectRatio)
        minimap.height = resY / 2.4374
        goto continue
    end

    minimapRawX, minimapRawY = GetScriptGfxPosition(0.000, 0.002 + -0.229888)
    minimap.width = resX / (3.48 * aspectRatio)
    minimap.height = resY / 5.55

    ::continue::

    ResetScriptGfxAlign()

    minimap.leftX = minimapRawX
    minimap.rightX = minimapRawX + minimap.width
    minimap.topY = minimapRawY
    minimap.bottomY = minimapRawY + minimap.height
    minimap.X = minimapRawX + (minimap.width / 2)
    minimap.Y = minimapRawY + (minimap.height / 2)

    -- Enhanced sizing and positioning for ultrawide and 4K displays
    local isUltraWide = aspectRatio > 2.0  -- 21:9 or wider
    local is4K = resX >= 3840 or resY >= 2160
    local isUltraWide34 = resX == 3840 and resY == 1440  -- Specific 34" ultrawide resolution
    local isUltraWide3440 = resX == 3440 and resY == 1440  -- Specific 3440x1440 ultrawide resolution
    
    local minWidth, minHeight, leftOffset, topOffset
    if isUltraWide3440 then
        -- Specific optimization for 3440x1440 ultrawide
        minWidth = math.max(200, resX * 0.13)
        minHeight = math.max(160, resY * 0.15)
        leftOffset = -0.120  -- EXTREME NEGATIVE adjustment to force to LEFT edge
        topOffset = 0.020   -- Move closer to bottom edge
    elseif isUltraWide34 then
        -- Specific optimization for 3840x1440 ultrawide
        minWidth = math.max(200, resX * 0.13)
        minHeight = math.max(160, resY * 0.15)
        leftOffset = 0.040  -- Move much closer to left edge - aggressive adjustment
        topOffset = 0.008   -- Move closer to bottom edge
    elseif isUltraWide then
        -- General ultrawide optimization (21:9, 32:9, etc.)
        minWidth = math.max(180, resX * 0.12)
        minHeight = math.max(140, resY * 0.12)
        leftOffset = 0.045  -- Move much closer to left edge - aggressive adjustment
        topOffset = 0.010   -- Move closer to bottom edge
    elseif is4K then
        -- 4K displays
        minWidth = math.max(220, resX * 0.15)
        minHeight = math.max(160, resY * 0.15)
        leftOffset = 0.001
        topOffset = 0.001
    else
        -- Standard displays (1920x1080, etc.)
        minWidth = math.max(200, resX * 0.15)
        minHeight = math.max(150, resY * 0.15)
        leftOffset = 0.001
        topOffset = 0.001
    end
    
    -- Apply positioning adjustments for better corner anchoring
    minimap.webLeft = (minimapRawX - leftOffset) * resX
    minimap.webTop = (minimapRawY - topOffset) * resY
    minimap.webWidth = math.max(minWidth, (minimap.width / resX) * resX)
    minimap.webHeight = math.max(minHeight, (minimap.height / resY) * resY)

    -- Ensure the minimap doesn't go outside screen bounds
    minimap.webLeft = math.max(0, minimap.webLeft)
    minimap.webTop = math.max(0, minimap.webTop)

    return {
        top = minimap.webTop,
        left = minimap.webLeft,
        height = minimap.webHeight,
        width = minimap.webWidth,
    }
end

--- Checks whether the specified framework is valid.
---@return boolean
utility.isFrameworkValid = function()
    local framework = config.framework and config.framework:lower() or nil

    if not framework then
        logger.info("(utility:isFrameworkValid) No framework specified, defaulting to 'none'.")
        return false
    end

    local validFrameworks = {
        esx = true,
        qb = true,
        ox = true,
        custom = true,
    }

    logger.verbose("(utility:isFrameworkValid) Checking if framework is valid: ", validFrameworks[framework] ~= nil)
    return validFrameworks[framework] ~= nil
end

-- Prevents the bigmap from staying active after the minimap is closed, since sometimes the bigmap is still active and stuck on the screen
utility.preventBigmapFromStayingActive = function()
    local timeout = 0
    while true do
        logger.debug("(utility:preventBigmapFromStayingActive) Running, timeout: ", timeout)

        SetBigmapActive(false, false)
        SetRadarZoom(1100)

        if timeout >= 10000 then
            return
        end

        timeout = timeout + 1000
        Wait(1000)
    end
end

utility.setupMinimap = function()
    logger.info("(utility:setupMinimap) Setting up minimap.")
    
    local resX, resY = GetActiveScreenResolution()
    local aspectRatio = GetAspectRatio(false)
    local isUltraWide = aspectRatio > 2.0
    local isUltraWide34 = resX == 3840 and resY == 1440
    local isUltraWide3440 = resX == 3440 and resY == 1440
    local is2560x1080 = resX == 2560 and resY == 1080
    
    -- Adjust minimap positioning based on display type
    local minimapX, minimapY, minimapW, minimapH
    local maskX, maskY, maskW, maskH
    local blurX, blurY, blurW, blurH
    
    if isUltraWide3440 then
        -- Specific positioning for 3440x1440 ultrawide - moved 2px left
        minimapX, minimapY, minimapW, minimapH = -0.165, -0.080, 0.140, 0.175
        maskX, maskY, maskW, maskH = -0.098, -0.050, 0.105, 0.150
        blurX, blurY, blurW, blurH = -0.188, -0.060, 0.250, 0.220
    elseif is2560x1080 then
        -- Specific positioning for 2560x1080 ultrawide - moved 300px more to the left
        minimapX, minimapY, minimapW, minimapH = -0.700, -0.120, 0.140, 0.175
        maskX, maskY, maskW, maskH = -0.633, -0.090, 0.105, 0.150
        blurX, blurY, blurW, blurH = -0.723, -0.100, 0.250, 0.220
    elseif isUltraWide34 then
        -- Specific positioning for 3840x1440 ultrawide - moved much closer to left edge
        minimapX, minimapY, minimapW, minimapH = 0.030, -0.035, 0.140, 0.175
        maskX, maskY, maskW, maskH = 0.047, -0.005, 0.105, 0.150
        blurX, blurY, blurW, blurH = 0.007, -0.015, 0.250, 0.220
    elseif isUltraWide then
        -- General ultrawide positioning - moved much closer to left edge
        minimapX, minimapY, minimapW, minimapH = 0.028, -0.036, 0.135, 0.170
        maskX, maskY, maskW, maskH = 0.050, -0.006, 0.100, 0.145
        blurX, blurY, blurW, blurH = 0.005, -0.016, 0.245, 0.215
    else
        -- Standard positioning
        minimapX, minimapY, minimapW, minimapH = -0.0045, -0.038, 0.150, 0.188888
        maskX, maskY, maskW, maskH = 0.020, -0.008, 0.111, 0.159
        blurX, blurY, blurW, blurH = -0.03, -0.018, 0.266, 0.237
    end
    
    SetMinimapComponentPosition('minimap', 'L', 'B', minimapX, minimapY, minimapW, minimapH)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', maskX, maskY, maskW, maskH)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', blurX, blurY, blurW, blurH)

    SetBlipAlpha(GetNorthRadarBlip(), 0)
    SetBigmapActive(true, false)
    SetMinimapClipType(0)
    CreateThread(utility.preventBigmapFromStayingActive)

    if not _G.minimapVisible then
        DisplayRadar(false)
    end
end

--- Loads streamed minimap textures from the `stream/` folder and applies layout.
---@param shape? "square"|"circle"
utility.applyMinimapTextures = function(shape)
    -- Default to square if not specified
    local targetShape = shape == "circle" and "circle" or "square"
    
    local resX, resY = GetActiveScreenResolution()
    local aspectRatio = GetAspectRatio(false)
    local isUltraWide = aspectRatio > 2.0
    local isUltraWide34 = resX == 3840 and resY == 1440
    local isUltraWide3440 = resX == 3440 and resY == 1440

    if targetShape == "square" then
        -- Use squaremap.ytd for square minimap
        local dict = "squaremap"
        RequestStreamedTextureDict(dict, false)
        
        local waited = 0
        while not HasStreamedTextureDictLoaded(dict) and waited < 2000 do
            Wait(50)
            waited = waited + 50
        end
        
        SetMinimapClipType(0)
        AddReplaceTexture("platform:/textures/graphics", "radarmasksm", dict, "radarmasksm")
        AddReplaceTexture("platform:/textures/graphics", "radarmask1g", dict, "radarmasksm")
        
        -- Square minimap positioning with ultrawide support
        local minimapX, minimapY, minimapW, minimapH
        local maskX, maskY, maskW, maskH
        local blurX, blurY, blurW, blurH
        
        if isUltraWide3440 then
            -- Specific positioning for 3440x1440 ultrawide - moved 2px left
            minimapX, minimapY, minimapW, minimapH = -0.170, -0.089, 0.155, 0.170
            maskX, maskY, maskW, maskH = 0.0, 0.0, 0.120, 0.185
            
            blurX, blurY, blurW, blurH = -0.179, -0.025, 0.255, 0.285
        elseif is2560x1080 then
            -- Specific positioning for 2560x1080 ultrawide - moved 300px more to the left
            minimapX, minimapY, minimapW, minimapH = -0.705, -0.129, 0.155, 0.170
            maskX, maskY, maskW, maskH = 0.0, 0.0, 0.120, 0.185
            blurX, blurY, blurW, blurH = -0.714, -0.065, 0.255, 0.285
        elseif isUltraWide34 then
            -- Specific positioning for 3840x1440 ultrawide - moved much closer to left edge
            minimapX, minimapY, minimapW, minimapH = 0.035, -0.044, 0.155, 0.170
            maskX, maskY, maskW, maskH = 0.0, 0.0, 0.120, 0.185
            blurX, blurY, blurW, blurH = 0.026, 0.020, 0.255, 0.285
        elseif isUltraWide then
            -- General ultrawide positioning - moved much closer to left edge
            minimapX, minimapY, minimapW, minimapH = 0.033, -0.045, 0.150, 0.165
            maskX, maskY, maskW, maskH = 0.0, 0.0, 0.115, 0.180
            blurX, blurY, blurW, blurH = 0.025, 0.018, 0.250, 0.280
        else
            -- Standard positioning
            minimapX, minimapY, minimapW, minimapH = 0.0, -0.047, 0.1638, 0.183
            maskX, maskY, maskW, maskH = 0.0, 0.0, 0.128, 0.20
            blurX, blurY, blurW, blurH = -0.01, 0.025, 0.262, 0.300
        end
        
        SetMinimapComponentPosition("minimap", "L", "B", minimapX, minimapY, minimapW, minimapH)
        SetMinimapComponentPosition("minimap_mask", "L", "B", maskX, maskY, maskW, maskH)
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', blurX, blurY, blurW, blurH)
    else
        -- Use minimap.ytd for circle minimap
        local dict = "minimap"
        RequestStreamedTextureDict(dict, false)
        
        local waited = 0
        while not HasStreamedTextureDictLoaded(dict) and waited < 2000 do
            Wait(50)
            waited = waited + 50
        end
        
        SetMinimapClipType(1)
        AddReplaceTexture("platform:/textures/graphics", "radarmasksm", dict, "radarmasksm")
        AddReplaceTexture("platform:/textures/graphics", "radarmask1g", dict, "radarmasksm")
        
        -- Circle minimap positioning with ultrawide support
        local minimapX, minimapY, minimapW, minimapH
        local maskX, maskY, maskW, maskH
        local blurX, blurY, blurW, blurH
        
        if isUltraWide3440 then
            -- Specific positioning for 3440x1440 ultrawide - moved 2px left
            minimapX, minimapY, minimapW, minimapH = -0.165, -0.072, 0.170, 0.245
            maskX, maskY, maskW, maskH = 0.023, 0.0, 0.060, 0.185
            blurX, blurY, blurW, blurH = -0.159, -0.033, 0.245, 0.325
        elseif is2560x1080 then
            -- Specific positioning for 2560x1080 ultrawide - moved 300px more to the left
            minimapX, minimapY, minimapW, minimapH = -0.700, -0.112, 0.170, 0.245
            maskX, maskY, maskW, maskH = 0.023, 0.0, 0.060, 0.185
            blurX, blurY, blurW, blurH = -0.694, -0.073, 0.245, 0.325
        elseif isUltraWide34 then
            -- Specific positioning for 3840x1440 ultrawide - moved much closer to left edge
            minimapX, minimapY, minimapW, minimapH = 0.030, -0.027, 0.170, 0.245
            maskX, maskY, maskW, maskH = 0.233, 0.0, 0.060, 0.185
            blurX, blurY, blurW, blurH = 0.036, 0.012, 0.245, 0.325
        elseif isUltraWide then
            -- General ultrawide positioning - moved much closer to left edge
            minimapX, minimapY, minimapW, minimapH = 0.028, -0.028, 0.165, 0.240
            maskX, maskY, maskW, maskH = 0.228, 0.0, 0.058, 0.180
            blurX, blurY, blurW, blurH = 0.035, 0.010, 0.240, 0.320
        else
            -- Standard positioning
            minimapX, minimapY, minimapW, minimapH = -0.0100, -0.030, 0.180, 0.258
            maskX, maskY, maskW, maskH = 0.200, 0.0, 0.065, 0.20
            blurX, blurY, blurW, blurH = -0.00, 0.015, 0.252, 0.338
        end
        
        SetMinimapComponentPosition("minimap", "L", "B", minimapX, minimapY, minimapW, minimapH)
        SetMinimapComponentPosition("minimap_mask", "L", "B", maskX, maskY, maskW, maskH)
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', blurX, blurY, blurW, blurH)
    end

    SetBlipAlpha(GetNorthRadarBlip(), 0)
    SetRadarBigmapEnabled(true, false)
    Wait(50)
    SetRadarBigmapEnabled(false, false)
end

---@param coords vector3
---@return boolean
---@return table
utility.get2DCoordFrom3DCoord = function(coords)
    if not coords then
        return false, {}
    end
    local onScreen, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    return onScreen, { left = tostring(x * 100) .. "%", top = tostring(y * 100) .. "%" }
end

return utility
