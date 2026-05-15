-- [[ QB-Pawnshop Rework - Client Side ]]
local QBCore = exports['qb-core']:GetCoreObject()

-- [[ Variables ]]
local Peds = {}
local Zones = {}
local lastDoorState = nil

-- [[ Initialization ]]

--- Spawns Peds, Blips, and sets up ox_target/ox_lib zones
local function initInteractions()
    for shopIndex, shop in pairs(Config.PawnLocation) do
        -- 1. Create Blips for locations
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
                    -- Interaction Mode: NPC
                    lib.requestModel(target.ped)
                    local ped = CreatePed(4, target.ped, target.loc.x, target.loc.y, target.loc.z - 1.0, target.heading or 0.0, false, false)
                    
                    SetEntityAsMissionEntity(ped, true, true)
                    SetPedAutoGiveScubaGearWhenEnteringWater(ped, false)
                    SetPedCanRagdollFromPlayerImpact(ped, false)
                    SetPedCanPlayAmbientAnims(ped, true)
                    SetPedCanPlayGestureAnims(ped, true)
                    SetPedCanAttackFriendly(ped, false)
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
                    -- Interaction Mode: ox_lib Zone (Fallback)
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

-- Start initialization
CreateThread(initInteractions)

--- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for i = 1, #Peds do DeletePed(Peds[i]) end
    for i = 1, #Zones do if Zones[i].remove then Zones[i]:remove() end end
end)

-- [[ Time & Door Management ]]

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
            Wait(10000) -- Check every 10 seconds (optimized for resmon)
        end
    end)
end

-- [[ UI & Menu Events ]]

RegisterNetEvent('qb-pawnshop:client:openMenu', function(data)
    local shopIndex = data and data.shopIndex or 1
    local shop = Config.PawnLocation[shopIndex]

    -- Time Check
    if Config.UseTimes then
        local hour = GetClockHours()
        if hour < Config.TimeOpen or hour >= Config.TimeClosed then
            lib.notify({
                title = locale('menus.main_header'),
                description = locale('notifications.pawn_closed', Config.TimeOpen, Config.TimeClosed),
                type = 'error'
            })
            return
        end
    end

    -- Main Context Menu
    lib.registerContext({
        id = 'pawn_main_menu',
        title = locale('menus.main_header'),
        options = {
            {
                title = locale('menus.sell_header'),
                description = locale('menus.sell_txt'),
                icon = 'fas fa-hand-holding-usd',
                event = 'qb-pawnshop:client:openPawn',
                args = { shopIndex = shopIndex }
            },
            {
                title = "Buy Items",
                description = "Purchase second-hand items from this shop",
                icon = 'fas fa-shopping-basket',
                event = 'qb-pawnshop:client:openBuyMenu',
                args = { shopIndex = shopIndex }
            }
        }
    })
    lib.showContext('pawn_main_menu')
end)

RegisterNetEvent('qb-pawnshop:client:openPawn', function(data)
    local shopIndex = data and data.shopIndex or 1
    local shop = Config.PawnLocation[shopIndex]
    local shopInventory = shop.inventory or {}

    -- Multi-callback await for performance
    local inventory = lib.callback.await('qb-pawnshop:server:getInv', false)
    local shopData = lib.callback.await('qb-pawnshop:server:getShopData', false, shopIndex, shopInventory)
    
    if not inventory then return end
    
    local options = {}
    for _, v in pairs(inventory) do
        for i = 1, #shopInventory do
            local itemData = shopInventory[i]
            if v.name == itemData.name then
                local currentBuyPrice = shopData[v.name].buyPrice
                options[#options + 1] = {
                    title = v.label,
                    description = string.format("Shop buys for: **$%s**\nShop Stock: **%s**", currentBuyPrice, shopData[v.name].stock),
                    icon = 'fas fa-arrow-right',
                    event = 'qb-pawnshop:client:pawnitems',
                    args = {
                        label = v.label,
                        price = itemData.price, -- Base price for server calculation
                        name = v.name,
                        count = v.count,
                        shopIndex = shopIndex
                    }
                }
            end
        end
    end

    if #options == 0 then
        lib.notify({ title = locale('menus.main_header'), description = locale('notifications.no_items'), type = 'error' })
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

RegisterNetEvent('qb-pawnshop:client:openBuyMenu', function(data)
    local shopIndex = data and data.shopIndex or 1
    local shop = Config.PawnLocation[shopIndex]
    local shopInventory = shop.inventory or {}

    local shopData = lib.callback.await('qb-pawnshop:server:getShopData', false, shopIndex, shopInventory)
    
    local options = {}
    for _, item in pairs(shopInventory) do
        local stockData = shopData[item.name]
        if stockData and stockData.stock > 0 then
            options[#options + 1] = {
                title = QBCore.Shared.Items[item.name].label,
                description = string.format("Buy for: **$%s**\nAvailable: **%s**", stockData.sellPrice, stockData.stock),
                icon = 'fas fa-tag',
                event = 'qb-pawnshop:client:buyItems',
                args = {
                    name = item.name,
                    label = QBCore.Shared.Items[item.name].label,
                    price = item.price, -- Base Price
                    stock = stockData.stock,
                    shopIndex = shopIndex
                }
            }
        end
    end

    if #options == 0 then
        lib.notify({ description = "Shop has no stock right now", type = 'error' })
        return
    end

    lib.registerContext({
        id = 'pawn_buy_menu',
        title = "Buy Second-hand Items",
        menu = 'pawn_main_menu',
        options = options
    })
    lib.showContext('pawn_buy_menu')
end)

RegisterNetEvent('qb-pawnshop:client:pawnitems', function(item)
    local input = lib.inputDialog(locale('inputs.sell_header'), {
        {
            type = 'number',
            label = locale('inputs.amount', item.count),
            description = ("Selling %s"):format(item.label),
            min = 1,
            max = item.count,
            default = 1
        }
    })

    if not input or not input[1] then return end
    local amount = math.floor(tonumber(input[1]))

    if amount > 0 and amount <= item.count then
        TriggerServerEvent('qb-pawnshop:server:sellPawnItems', item.shopIndex, item.name, amount, item.price)
    else
        lib.notify({ description = "Invalid amount", type = 'error' })
    end
end)

RegisterNetEvent('qb-pawnshop:client:buyItems', function(item)
    local input = lib.inputDialog("Purchase Item", {
        {
            type = 'number',
            label = "Amount to buy",
            description = ("Available stock: %s"):format(item.stock),
            min = 1,
            max = item.stock,
            default = 1
        }
    })

    if not input or not input[1] then return end
    local amount = math.floor(tonumber(input[1]))

    if amount > 0 and amount <= item.stock then
        TriggerServerEvent('qb-pawnshop:server:buyPawnItems', item.shopIndex, item.name, amount, item.price)
    else
        lib.notify({ description = "Invalid amount or not enough stock", type = 'error' })
    end
end)
