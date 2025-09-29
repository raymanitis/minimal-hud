if not IsDuplicityVersion() then
    local config = require("config.shared")
    local playerStatusClass = require("modules.threads.client.player_status")
    local vehicleStatusClass = require("modules.threads.client.vehicle_status")
    local utility = require("modules.utility.shared.main")
    local logger = require("modules.utility.shared.logger")
    local interface = require("modules.interface.client")

    local playerStatusThread = playerStatusClass.new()
    local vehicleStatusThread = vehicleStatusClass.new(playerStatusThread)
    local framework = utility.isFrameworkValid() and require("modules.frameworks." .. config.framework:lower()).new() or
            false

    playerStatusThread:start(vehicleStatusThread, framework)

    _G.minimapVisible = config.minimapAlways

    -- Send player ID to UI only once after loading
    local function sendPlayerId()
        local playerId = cache.serverId
        interface:message("state::player::id", playerId)
        logger.info("(sendPlayerId) Sent player ID to UI: ", playerId)
    end

    exports("toggleHud", function(state)
        interface:toggle(state or nil)
        DisplayRadar(state)
        logger.info("(exports:toggleHud) Toggled HUD to state: ", state)
    end)

    local function toggleMap(state)
        _G.minimapVisible = state
        DisplayRadar(state)
        logger.info("(toggleMap) Toggled map to state: ", state)
    end

    exports("toggleMap", toggleMap)

    RegisterCommand("togglehud", function()
        interface:toggle()
    end, false)

    -- Toggle HUD when pause menu is active
    local isPauseMenuOpen = false
    CreateThread(function()
        while true do
            local currentPauseMenuState = IsPauseMenuActive()

            if currentPauseMenuState ~= isPauseMenuOpen then
                isPauseMenuOpen = currentPauseMenuState

                if isPauseMenuOpen then
                    interface:toggle(false)
                else
                    interface:toggle(true)
                end
            end
            Wait(isPauseMenuOpen and 250 or 500)
        end
    end)

    interface:on("APP_LOADED", function(_, cb)
        local resX, resY = GetActiveScreenResolution()
        local aspectRatio = GetAspectRatio(false)
        
        -- Debug 4K resolution info
        logger.info("(APP_LOADED) Resolution: " .. resX .. "x" .. resY .. ", Aspect Ratio: " .. aspectRatio)
        
        local data = {
            config = config,
            minimap = utility.calculateMinimapSizeAndPosition(),
        }

        cb(data)

        CreateThread(utility.setupMinimap)
        -- Apply streamed minimap textures on initial load (square by default)
        CreateThread(function()
            Wait(200)
            utility.applyMinimapTextures("square")
        end)
        toggleMap(config.minimapAlways)
        -- Send player ID when the app is loaded
        sendPlayerId()
    end)

    -- Public event to reload/apply minimap with streamed textures
    RegisterNetEvent("hud:client:LoadMap", function(shape)
        Wait(50)
        utility.applyMinimapTextures(shape)
    end)

    -- NUI callbacks via interface system
    interface:on("ToggleMapShape", function(data, cb)
        _G.minimapShape = (data and data.shape) or "square"
        Wait(50)
        utility.applyMinimapTextures(_G.minimapShape)
        cb(true)
    end)

    interface:on("ToggleMapBorders", function(data, cb)
        _G.minimapBorders = data and data.checked == true
        cb(true)
    end)

    -- Hunger/Thirst notifications (per 1% drop under 20)
    local lastHungerStep = nil
    local lastThirstStep = nil

    AddStateBagChangeHandler('hunger', ('player:%s'):format(cache.serverId), function(_, _, value)
        local current = math.floor(tonumber(value) or 0)
        if current < 20 then
            local last = lastHungerStep
            if last == nil then
                last = current + 1
            end
            if current < last then
                lib.notify({
                    description = "You are feeling hungry!",
                    icon = 'fa-burger',
                    iconColor = '#dcae11',
                    duration = 3500
                })
            end
            lastHungerStep = current
        else
            lastHungerStep = nil
        end
    end)

    AddStateBagChangeHandler('thirst', ('player:%s'):format(cache.serverId), function(_, _, value)
        local current = math.floor(tonumber(value) or 0)
        if current < 20 then
            local last = lastThirstStep
            if last == nil then
                last = current + 1
            end
            if current < last then
                lib.notify({
                    description = "You are feeling thirsty!",
                    icon = 'fa-droplet',
                    iconColor = '#51aeff',
                    duration = 3500
                })
            end
            lastThirstStep = current
        else
            lastThirstStep = nil
        end
    end)

    -- Hide default HUD elements
    CreateThread(function()
        local minimap = RequestScaleformMovie("minimap")

        SetRadarBigmapEnabled(true, false)
        Wait(500)
        SetRadarBigmapEnabled(false, false)

        HideHudComponents = { 1, 2, 3, 4, 6, 7, 9, 13, 17, 19, 20, 21, 22 }
        for _, v in pairs(HideHudComponents) do
            SetHudComponentPosition(v, 99999999.9, 99999999.9)
        end

        while true do
            Wait(10000)
            BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
            ScaleformMovieMethodAddParamInt(3)
            EndScaleformMovieMethod()
        end
    end)

    CreateThread(function()
        -- Wait a bit to allow framework or core to initialize
        Wait(500)

        local isLoaded = false

        if framework and framework.name == "qbcore" then
            -- Method 1: Try QBCore.PlayerData
            local QBCore = exports['qb-core']:GetCoreObject()
            local player = QBCore.Functions.GetPlayerData()
            isLoaded = player and player.citizenid ~= nil
        elseif LocalPlayer and LocalPlayer.state and LocalPlayer.state.isLoggedIn then
            -- Method 2: Check LocalPlayer state (backup)
            isLoaded = true
        end

        if isLoaded then
            interface:toggle(true)
            DisplayRadar(config.minimapAlways)
            _G.minimapVisible = config.minimapAlways
            -- Send player ID when determining player is already loaded
            sendPlayerId()

            logger.info("[ScriptStart] HUD and minimap initialized because player was already loaded.")
        else
            logger.info("[ScriptStart] Player not yet loaded; waiting for QBCore:Client:OnPlayerLoaded event.")
        end
    end)

    return
end