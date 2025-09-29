---@diagnostic disable: cast-local-type
local logger = require("modules.utility.shared.logger")
local interface = require("modules.interface.client")
local utility = require("modules.utility.shared.main")

local PlayerStatusThread = {}
PlayerStatusThread.__index = PlayerStatusThread

---@return table
function PlayerStatusThread.new()
    local self = setmetatable({
        isVehicleThreadRunning = false,
        source = {
            server_id = GetPlayerServerId(PlayerId()),
        },
    }, PlayerStatusThread)

    return self
end

function PlayerStatusThread:getIsVehicleThreadRunning()
    return self.isVehicleThreadRunning
end

---@param value boolean
function PlayerStatusThread:setIsVehicleThreadRunning(value)
    logger.verbose("(PlayerStatusThread:setIsVehicleThreadRunning) Setting: ", value)
    self.isVehicleThreadRunning = value
end

local function GetCompassDirection(heading)
    local directions = {
        [1] = 'N', -- 0-22.5
        [2] = 'NE', -- 22.5-67.5
        [3] = 'E', -- 67.5-112.5
        [4] = 'SE', -- 112.5-157.5
        [5] = 'S', -- 157.5-202.5
        [6] = 'SW', -- 202.5-247.5
        [7] = 'W', -- 247.5-292.5
        [8] = 'NW'   -- 292.5-337.5
    }

    -- Normalize heading to 0-360
    heading = heading % 360
    if heading < 0 then heading = heading + 360 end

    -- Determine direction based on heading
    if heading >= 337.5 or heading < 22.5 then
        return directions[1]
    elseif heading >= 22.5 and heading < 67.5 then
        return directions[2]
    elseif heading >= 67.5 and heading < 112.5 then
        return directions[3]
    elseif heading >= 112.5 and heading < 157.5 then
        return directions[4]
    elseif heading >= 157.5 and heading < 202.5 then
        return directions[5]
    elseif heading >= 202.5 and heading < 247.5 then
        return directions[6]
    elseif heading >= 247.5 and heading < 292.5 then
        return directions[7]
    else
        return directions[8]
    end
end
local function getStreetName(coords)
    local x, y, z = table.unpack(coords)
    local streetName, crossing = GetStreetNameAtCoord(x, y, z)
    return { main = GetStreetNameFromHashKey(streetName), cross = GetStreetNameFromHashKey(crossing) }
end
local GetNameOfZone, GetLabelText = GetNameOfZone, GetLabelText
local GetPlayerUnderwaterTimeRemaining, GetPlayerSprintStaminaRemaining = GetPlayerUnderwaterTimeRemaining, GetPlayerSprintStaminaRemaining
local GetPedArmour, GetEntityHealth, GetEntityMaxHealth, GetEntityCoords, GetEntityHeading, DoesEntityExist, DisplayRadar, IsPedSwimmingUnderWater, NetworkIsPlayerTalking, IsRadarHidden = GetPedArmour, GetEntityHealth, GetEntityMaxHealth, GetEntityCoords, GetEntityHeading, DoesEntityExist, DisplayRadar, IsPedSwimmingUnderWater, NetworkIsPlayerTalking, IsRadarHidden

function PlayerStatusThread:start(vehicleStatusThread, framework)
    CreateThread(function()
        while true do
            local ped = cache.ped
            local playerId = cache.playerId
            local talking = NetworkIsPlayerTalking(playerId)
            local veh = cache.vehicle
            local voice = 0

            local newLocationData = {
                compass = nil,
                street = nil,
                zone = nil
            }

            local voiceModes = {
                Whisper = 20,
                Normal = 50,
                Shouting = 100,
            }

            if LocalPlayer.state["proximity"] then
                voice = voiceModes[LocalPlayer.state["proximity"].mode] or 0
            else
                voice = 0
            end

            -- Get health and armor values with error handling
            local pedArmour = GetPedArmour(ped)
            local pedCurrentHealth = GetEntityHealth(ped)
            local pedMaxHealth = GetEntityMaxHealth(ped)
            local healthPercent = math.max(0, math.min(100, math.floor(((pedCurrentHealth - 100) / (pedMaxHealth - 100)) * 100)))

            local hunger = LocalPlayer.state.hunger or 0
            local thirst = LocalPlayer.state.thirst or 0
            local stress = LocalPlayer.state.stress or 0

            -- Get oxygen and stamina
            local oxygen = 100
            local stamina = 100
            if IsPedSwimmingUnderWater(ped) then
                oxygen = math.floor(GetPlayerUnderwaterTimeRemaining(playerId) * 10)
            else
                stamina = math.floor(100 - GetPlayerSprintStaminaRemaining(playerId))
            end

            if veh and DoesEntityExist(veh) then
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                local compass = GetCompassDirection(heading)
                local streetData = getStreetName(coords)
                local streetName = streetData.main or 'Unknown'
                local crossStreet = streetData.cross or ''

                local fullStreetName = streetName
                if crossStreet and crossStreet ~= '' and crossStreet ~= streetName then
                    fullStreetName = streetName .. ' & ' .. crossStreet
                end
                local zoneName = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))

                newLocationData = {
                    compass = compass,
                    street = fullStreetName,
                    zone = zoneName
                }
            else
                -- When not in vehicle, only update location data every 2 seconds to reduce resource usage
                if not _G.lastLocationUpdate or GetGameTimer() - _G.lastLocationUpdate > 2000 then
                    local coords = GetEntityCoords(ped)
                    local heading = GetEntityHeading(ped)
                    local compass = GetCompassDirection(heading)
                    local streetData = getStreetName(coords)
                    local streetName = streetData.main or 'Unknown'
                    local crossStreet = streetData.cross or ''

                    local fullStreetName = streetName
                    if crossStreet and crossStreet ~= '' and crossStreet ~= streetName then
                        fullStreetName = streetName .. ' & ' .. crossStreet
                    end
                    local zoneName = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))

                    newLocationData = {
                        compass = compass,
                        street = fullStreetName,
                        zone = zoneName
                    }
                    _G.cachedLocationData = newLocationData
                    _G.lastLocationUpdate = GetGameTimer()
                else
                    -- Use cached location data when not updating
                    newLocationData = _G.cachedLocationData or {
                        compass = nil,
                        street = nil,
                        zone = nil
                    }
                end
            end

            if veh and DoesEntityExist(veh) then
                if not self:getIsVehicleThreadRunning() and vehicleStatusThread then
                    vehicleStatusThread:start()
                    DisplayRadar(true)
                    logger.verbose("(playerStatus) (vehicleStatusThread) Vehicle status thread started.")
                else
                    DisplayRadar(true)
                end
            else
                if self:getIsVehicleThreadRunning() and vehicleStatusThread then
                    vehicleStatusThread:stop()
                end
                DisplayRadar(_G.minimapVisible)
            end

            if IsRadarHidden() then
                if exports.ox_inventory:Search("count", "gps_device") > 0 then
                    DisplayRadar(true)
                end
            else
                if not veh then
                    if exports.ox_inventory:Search("count", "gps_device") < 0 then
                        DisplayRadar(false)
                    end
                end
            end

            local player_data = {
                health = healthPercent,
                armor = pedArmour,
                hunger = hunger,
                thirst = thirst,
                stress = stress,
                oxygen = oxygen,
                stamina = stamina,
                streetLabel = newLocationData.street,
                areaLabel = newLocationData.zone,
                heading = newLocationData.compass,
                voice = voice,
                mic = talking,
                isSeatbeltOn = LocalPlayer.state.seatbelt,
                isInVehicle = veh ~= false,
                playerId = cache.serverId,
            }

            -- Cache minimap calculations to reduce expensive operations
            -- Only recalculate if not cached or if resolution changed
            local currentResX, currentResY = GetActiveScreenResolution()
            if not _G.cachedMinimapData or _G.lastResolutionX ~= currentResX or _G.lastResolutionY ~= currentResY then
                _G.cachedMinimapData = utility.calculateMinimapSizeAndPosition()
                _G.lastResolutionX = currentResX
                _G.lastResolutionY = currentResY
            end
            local minimapData = _G.cachedMinimapData

            interface:message("state::global::set", {
                minimap = minimapData,
                player = player_data,
            })

            -- Optimize wait time based on vehicle status
            -- When in vehicle: 150ms (same as vehicle thread for smooth updates)
            -- When not in vehicle: 500ms (reduces resource usage significantly)
            local waitTime = veh and DoesEntityExist(veh) and 150 or 500
            Wait(waitTime)
        end
    end)
end

return PlayerStatusThread
