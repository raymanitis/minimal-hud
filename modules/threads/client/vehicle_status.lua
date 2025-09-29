local interface = require("modules.interface.client")
local utility = require("modules.utility.shared.main")
local logger = require("modules.utility.shared.logger")
local config = require("config.shared")

local VehicleStatusThread = {}
VehicleStatusThread.__index = VehicleStatusThread

function VehicleStatusThread.new(playerStatus)
    local self = setmetatable({}, VehicleStatusThread)
    self.playerStatus = playerStatus
    self.isRunning = false
    self.vehicle = nil
    self.vehType = nil
    self.lastSentState = {}
    self.updateTimer = 0
    self.lastUpdate = 0

    SetHudComponentPosition(6, 999999.0, 999999.0) -- VEHICLE NAME
    SetHudComponentPosition(7, 999999.0, 999999.0) -- AREA NAME
    SetHudComponentPosition(8, 999999.0, 999999.0) -- VEHICLE CLASS
    SetHudComponentPosition(9, 999999.0, 999999.0) -- STREET NAME

    return self
end

function VehicleStatusThread:start()
    if self.isRunning then return end
    
    self.isRunning = true
    self.vehicle = cache.vehicle
    self.playerStatus:setIsVehicleThreadRunning(true)
    
    -- Set up statebag listeners for efficient updates
    self:setupStateListeners()
    
    -- Start the main update loop with much reduced frequency
    self:startUpdateLoop()
end

function VehicleStatusThread:stop()
    if not self.isRunning then return end
    
    self.isRunning = false
    self.vehicle = nil
    self.vehType = nil
    self.playerStatus:setIsVehicleThreadRunning(false)
    
    -- Clean up statebag listeners
    self:cleanupStateListeners()
    
    logger.verbose("(vehicleStatusThread) Vehicle status thread ended.")
end

function VehicleStatusThread:setupStateListeners()
    -- Use ox_lib state management for better performance
    if lib then
        -- Listen for vehicle changes using ox_lib state
        lib.onCache('vehicle', function(value)
            if value and value ~= self.vehicle then
                self.vehicle = value
                self.vehType = nil -- Reset vehicle type
                self:updateVehicleData()
            end
        end)
    else
        -- Fallback to statebag if ox_lib not available
        AddStateBagChangeHandler('vehicle', 'player:' .. cache.serverId, function(bagName, key, value, reserved, replicated)
            if value and value ~= self.vehicle then
                self.vehicle = value
                self.vehType = nil -- Reset vehicle type
                self:updateVehicleData()
            end
        end)
    end
    
    -- Listen for fuel changes if available
    if GetResourceState('cdn-fuel') == 'started' then
        AddStateBagChangeHandler('fuel', 'player:' .. cache.serverId, function(bagName, key, value, reserved, replicated)
            if value and self.isRunning then
                self:updateVehicleData()
            end
        end)
    end
end

function VehicleStatusThread:cleanupStateListeners()
    -- Statebag handlers are automatically cleaned up when the resource stops
    -- or when the player disconnects, so no manual cleanup needed
end

function VehicleStatusThread:startUpdateLoop()
    CreateThread(function()
        local convertRpmToPercentage = utility.convertRpmToPercentage
        local convertEngineHealthToPercentage = utility.convertEngineHealthToPercentage
        
        while self.isRunning and cache.vehicle do
            local currentTime = GetGameTimer()
            
            -- Only update if enough time has passed or if we're moving
            local shouldUpdate = false
            local waitTime = 500 -- Default idle
            
            if self.vehicle and DoesEntityExist(self.vehicle) then
                local speed = GetEntitySpeed(self.vehicle) * 3.6
                
                if speed > 5 then
                    -- Moving: update frequently (~15Hz)
                    shouldUpdate = currentTime - self.lastUpdate > 66
                    waitTime = 66
                elseif speed > 0 then
                    -- Slow movement: moderate updates (~10Hz)
                    shouldUpdate = currentTime - self.lastUpdate > 100
                    waitTime = 100
                else
                    -- Stationary: reduced updates
                    shouldUpdate = currentTime - self.lastUpdate > 500
                    waitTime = 500
                end
            end
            
            if shouldUpdate then
                self:updateVehicleData()
                self.lastUpdate = currentTime
            end
            
            Wait(waitTime)
        end
        
        self:stop()
    end)
end

function VehicleStatusThread:updateVehicleData()
    if not self.vehicle or not DoesEntityExist(self.vehicle) then
        self:stop()
        return
    end
    
    local vehicle = self.vehicle
    local convertRpmToPercentage = utility.convertRpmToPercentage
    local convertEngineHealthToPercentage = utility.convertEngineHealthToPercentage
    
    -- Get vehicle type once
    if not self.vehType then
        self.vehType = GetVehicleTypeRaw(vehicle)
        logger.verbose("(vehicleStatusThread) set vehType to " .. self.vehType)
    end
    
    -- Get current values
    local engineState = GetIsVehicleEngineRunning(vehicle)
    local currentGear = GetVehicleDashboardCurrentGear()
    local highGear = GetVehicleHighGear(vehicle)
    local vehSpeed = GetEntitySpeed(vehicle)
    local speed = math.floor(vehSpeed * 3.6)
    
    -- Calculate gear string
    local gearString = "N"
    local newGears = highGear
    if highGear ~= 1 then 
        if not engineState then
            gearString = ""
        elseif currentGear == 0 and vehSpeed > 0 then
            gearString = "R"
        elseif currentGear == 1 and vehSpeed < 0.1 and engineState then
            gearString = "N"
        elseif currentGear == 1 then
            gearString = "1"
        elseif currentGear > 1 then
            gearString = tostring(math.floor(currentGear))
        end
    else
        gearString = ""
        newGears = 0
    end
    
    -- Calculate RPM
    local rpm
    if self.vehType == 8 then -- Helicopters
        rpm = math.min(speed / 150, 1) * 100
    else
        rpm = convertRpmToPercentage(GetVehicleCurrentRpm(vehicle))
    end
    
    -- Get engine health and fuel
    local engineHealth = convertEngineHealthToPercentage(GetVehicleEngineHealth(vehicle))
    local fuel = 0
    if GetResourceState('cdn-fuel') == 'started' then
        fuel = math.floor(math.max(0, math.min(exports['cdn-fuel']:GetFuel(vehicle), 100)))
    end
    
    -- Check if state has changed significantly
    local stateChanged = false
    if self.lastSentState.speed ~= speed or 
       self.lastSentState.engineState ~= engineState or 
       self.lastSentState.currentGear ~= gearString or
       math.abs((self.lastSentState.rpm or 0) - rpm) > 1 or
       math.abs((self.lastSentState.engineHealth or 0) - engineHealth) > 2 or
       (self.lastSentState.fuel or 0) ~= fuel then
        stateChanged = true
    end
    
    if stateChanged then
        local newState = {
            speedUnit = config.speedUnit,
            speed = speed,
            rpm = rpm,
            engineHealth = engineHealth,
            engineState = engineState,
            gears = newGears,
            currentGear = gearString,
            fuel = fuel,
        }
        
        interface:message("state::vehicle::set", newState)
        
        -- Update last sent state
        self.lastSentState = newState
    end
end

return VehicleStatusThread
