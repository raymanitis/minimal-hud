local logger = require("modules.utility.shared.logger")

local qbFramework = {}
qbFramework.__index = qbFramework

function qbFramework.new()
    local self = setmetatable({}, qbFramework)
    self.values = {
        hunger = 100,
        thirst = 100,
        stress = 0,
        oxygen = 100,
        stamina = 100
    }

    -- Initialize values from QBCore
    CreateThread(function()
        local QBCore = exports['qb-core']:GetCoreObject()
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData and PlayerData.metadata then
            self.values.hunger = PlayerData.metadata.hunger or 100
            self.values.thirst = PlayerData.metadata.thirst or 100
            self.values.stress = PlayerData.metadata.stress or 0
        end
    end)

    RegisterNetEvent("hud:client:UpdateNeeds", function(hunger, thirst)
        self.values.hunger = hunger or self.values.hunger
        self.values.thirst = thirst or self.values.thirst
        logger.verbose("(qbFramework) Updated needs - Hunger:", hunger, "Thirst:", thirst)
    end)

    RegisterNetEvent("hud:client:UpdateStress", function(stress)
        self.values.stress = stress or self.values.stress
        logger.verbose("(qbFramework) Updated stress:", stress)
    end)

    RegisterNetEvent("hud:client:UpdateOxygen", function(oxygen)
        self.values.oxygen = oxygen or self.values.oxygen
        logger.verbose("(qbFramework) Updated oxygen:", oxygen)
    end)

    RegisterNetEvent("hud:client:UpdateStamina", function(stamina)
        self.values.stamina = stamina or self.values.stamina
        logger.verbose("(qbFramework) Updated stamina:", stamina)
    end)

    -- Add metadata update event handler
    RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
        if data and data.metadata then
            self.values.hunger = data.metadata.hunger or self.values.hunger
            self.values.thirst = data.metadata.thirst or self.values.thirst
            self.values.stress = data.metadata.stress or self.values.stress
            logger.verbose("(qbFramework) Updated player metadata - Hunger:", self.values.hunger, "Thirst:", self.values.thirst)
        end
    end)

    return self
end

function qbFramework:getPlayerHunger()
    return self.values.hunger
end

function qbFramework:getPlayerThirst()
    return self.values.thirst
end

function qbFramework:getPlayerOxygen()
    return self.values.oxygen
end

function qbFramework:getPlayerStamina()
    return self.values.stamina
end

function qbFramework:getPlayerStress()
    return self.values.stress
end

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    logger.info("[qbFramework] Player loaded. Toggling HUD on.")
    interface:toggle(true)
end)

AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    logger.info("[qbFramework] Player logged out. Toggling HUD off.")
    interface:toggle(false)
end)

return qbFramework
