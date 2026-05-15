local QBCore = exports['qb-core']:GetCoreObject()
local Peds = {}
local Zones = {}

--- Spawns Peds, Blips, and sets up interactions
local function initInteractions()
    for shopIndex, shop in pairs(Config.PawnLocation) do
        -- 1. Create Blips
        if shop.locations and shop.blip then
            for _, loc in pairs(shop.locations) do
                local blip = AddBlipForCoord(loc.x, loc.y, loc.z)
                SetBlipSprite(blip, shop.blip.id or 431)
                SetBlipDisplay(blip, 4)
                SetBlipScale(blip, shop.blip.scale or 0.7)
                SetBlipAsShortRange(blip, true)
                SetBlipColour(blip, shop.blip.colour or 5)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName(locale('blips.pawnshop'))
                EndTextCommandSetBlipName(blip)
            end
        end

        -- 2. Setup Targets or Zones
        if shop.targets then
            for _, target in pairs(shop.targets) do
                if target.ped then
                    lib.requestModel(target.ped)
                    local ped = CreatePed(4, target.ped, target.loc.x, target.loc.y, target.loc.z - 1.0, target.heading or 0.0, false, false)
                    SetEntityAsMissionEntity(ped, true, true)
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    SetEntityInvincible(ped, true)
                    FreezeEntityPosition(ped, true)

                    if target.scenario then TaskStartScenarioInPlace(ped, target.scenario, 0, true) end

                    exports.ox_target:addLocalEntity(ped, {
                        {
                            name = 'pawnshop_open_' .. shopIndex,
                            event = 'qb-pawnshop:client:openMenu',
                            icon = 'fas fa-ring',
                            label = locale('menus.main_header'),
                            distance = target.distance or 2.0,
                            args = { shopIndex = shopIndex }
                        }
                    })
                    Peds[#Peds + 1] = ped
                elseif target.loc then
                    Zones[#Zones + 1] = lib.zones.box({
                        coords = target.loc,
                        size = target.size or vec3(1.5, 1.5, 2.0),
                        rotation = target.heading or 0.0,
                        onEnter = function()
                            lib.showTextUI(('[E] - %s'):format(locale('menus.open_pawn')), { position = "left-center", icon = 'hand' })
                        end,
                        onExit = function() lib.hideTextUI() end,
                        inside = function()
                            if IsControlJustReleased(0, 38) then TriggerEvent('qb-pawnshop:client:openMenu', { shopIndex = shopIndex }) end
                        end
                    })
                end
            end
        end
    end
end

CreateThread(initInteractions)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for i = 1, #Peds do DeletePed(Peds[i]) end
    for i = 1, #Zones do if Zones[i].remove then Zones[i]:remove() end end
end)
