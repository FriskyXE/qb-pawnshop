local QBCore = exports['qb-core']:GetCoreObject()
local Peds = {}
local Zones = {}

local function createPawnInteractions()
    for shopIndex, shop in pairs(Config.PawnLocation) do
        -- Create Blips
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

        -- Create Targets/Peds/Zones
        if shop.targets then
            for _, target in pairs(shop.targets) do
                if target.ped then
                    -- NPC Ped Interaction (Uses ox_target on the entity)
                    lib.requestModel(target.ped)
                    local ped = CreatePed(4, target.ped, target.loc.x, target.loc.y, target.loc.z - 1.0, target.heading or 0.0, false, false)
                    
                    SetEntityAsMissionEntity(ped, true, true)
                    SetPedAutoGiveScubaGearWhenEnteringWater(ped, false)
                    SetPedCanRagdollFromPlayerImpact(ped, false)
                    SetPedCanPlayAmbientAnims(ped, true)
                    SetPedCanPlayAmbientBaseAnims(ped, true)
                    SetPedCanPlayGestureAnims(ped, true)
                    SetPedCanPlayInjuredAnims(ped, true)
                    SetPedCanAttackFriendly(ped, false)
                    SetPedCanBeTargetted(ped, true)
                    SetPedCanBeTargettedByPlayer(ped, true)
                    SetPedCanBeTargettedByTeam(ped, ped, false)
                    SetPedCanUseAutoConversationLookat(ped, true)
                    SetPedCanBeKnockedOffBike(ped, false)
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    SetEntityInvincible(ped, true)
                    FreezeEntityPosition(ped, true)

                    if target.scenario then
                        TaskStartScenarioInPlace(ped, target.scenario, 0, true)
                    end

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
                    -- Coordinate Interaction (Uses ox_lib box zone + TextUI)
                    Zones[#Zones + 1] = lib.zones.box({
                        coords = target.loc,
                        size = target.size or vec3(1.5, 1.5, 2.0),
                        rotation = target.heading or 0.0,
                        debug = target.debug or false,
                        onEnter = function()
                            lib.showTextUI(('[E] - %s'):format(locale('menus.open_pawn')), {
                                position = "left-center",
                                icon = 'hand'
                            })
                        end,
                        onExit = function()
                            lib.hideTextUI()
                        end,
                        inside = function()
                            if IsControlJustReleased(0, 38) then
                                TriggerEvent('qb-pawnshop:client:openMenu', { shopIndex = shopIndex })
                            end
                        end
                    })
                end
            end
        end
    end
end

CreateThread(function()
    createPawnInteractions()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for i = 1, #Peds do
        DeletePed(Peds[i])
    end
    for i = 1, #Zones do
        if Zones[i].remove then
            Zones[i]:remove()
        end
    end
end)

local lastDoorState = nil
if Config.UseTimes then
    CreateThread(function()
        while true do
            local hour = GetClockHours()
            local isClosed = hour < Config.TimeOpen or hour >= Config.TimeClosed
            local newState = isClosed and 1 or 0 -- 1 = Locked, 0 = Unlocked

            if newState ~= lastDoorState then
                lastDoorState = newState
                TriggerServerEvent('qb-pawnshop:server:syncDoors', newState)
            end
            Wait(5000)
        end
    end)
end

RegisterNetEvent('qb-pawnshop:client:openMenu', function(data)
    local shopIndex = data and data.shopIndex or 1
    local shop = Config.PawnLocation[shopIndex]

    if Config.UseTimes then
        if GetClockHours() >= Config.TimeOpen and GetClockHours() <= Config.TimeClosed then
            lib.registerContext({
                id = 'pawn_main_menu',
                title = locale('menus.main_header'),
                options = {
                    {
                        title = locale('menus.sell_header'),
                        description = locale('menus.sell_txt'),
                        event = 'qb-pawnshop:client:openPawn',
                        args = { shopIndex = shopIndex }
                    }
                }
            })
            lib.showContext('pawn_main_menu')
        else
            lib.notify({
                title = locale('menus.main_header'),
                description = locale('notifications.pawn_closed', Config.TimeOpen, Config.TimeClosed),
                type = 'error'
            })
        end
    else
        lib.registerContext({
            id = 'pawn_main_menu',
            title = locale('menus.main_header'),
            options = {
                {
                    title = locale('menus.sell_header'),
                    description = locale('menus.sell_txt'),
                    event = 'qb-pawnshop:client:openPawn',
                    args = { shopIndex = shopIndex }
                }
            }
        })
        lib.showContext('pawn_main_menu')
    end
end)

RegisterNetEvent('qb-pawnshop:client:openPawn', function(data)
    local shopIndex = data and data.shopIndex or 1
    local shop = Config.PawnLocation[shopIndex]
    local shopInventory = shop.inventory or Config.PawnItems

    local inventory = lib.callback.await('qb-pawnshop:server:getInv', false)
    if not inventory then return end
    
    local options = {}
    for _, v in pairs(inventory) do
        for i = 1, #shopInventory do
            local itemData = shopInventory[i]
            if v.name == (itemData.item or itemData.name) then
                options[#options + 1] = {
                    title = v.label,
                    description = locale('menus.item_price', itemData.price),
                    event = 'qb-pawnshop:client:pawnitems',
                    args = {
                        label = v.label,
                        price = itemData.price,
                        name = v.name,
                        count = v.count
                    }
                }
            end
        end
    end

    if #options == 0 then
        lib.notify({
            title = locale('menus.main_header'),
            description = locale('notifications.no_items'),
            type = 'error'
        })
        return
    end

    lib.registerContext({
        id = 'pawn_sell_menu',
        title = locale('menus.sell_header'),
        menu = 'pawn_main_menu',
        options = options
    })
    lib.showContext('pawn_sell_menu')
end)

RegisterNetEvent('qb-pawnshop:client:pawnitems', function(item)
    local input = lib.inputDialog(locale('inputs.sell_header'), {
        {
            type = 'number',
            label = locale('inputs.amount', item.count),
            description = item.label,
            min = 1,
            max = item.count,
            default = 1
        }
    })

    if not input then return end
    local amount = tonumber(input[1])

    if amount and amount > 0 then
        if amount <= item.count then
            TriggerServerEvent('qb-pawnshop:server:sellPawnItems', item.name, amount, item.price)
        else
            lib.notify({
                description = locale('notifications.no_items'),
                type = 'error'
            })
        end
    else
        lib.notify({
            description = locale('notifications.negative'),
            type = 'error'
        })
    end
end)
