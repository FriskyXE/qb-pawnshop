local QBCore = exports['qb-core']:GetCoreObject()

-- Handle item selling to shop
RegisterNetEvent('qb-pawnshop:server:sellPawnItems', function(token, shopIndex, itemName, itemAmount, basePrice)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Token Security Check
    if token ~= SecurityToken then
        exploitBan(src, 'sellPawnItems Invalid Security Token')
        return
    end

    -- Distance check
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local shopCoords = Config.PawnLocation[shopIndex].locations[1]
    if #(playerCoords - shopCoords) > 10.0 then
        exploitBan(src, 'sellPawnItems Distance Exploit')
        return
    end

    local buyPrice, _ = calculatePrices(shopIndex, itemName, basePrice)
    local totalPrice = (tonumber(itemAmount) * buyPrice)
    local itemLabel = exports.ox_inventory:GetItem(src, itemName).label

    if exports.ox_inventory:RemoveItem(src, itemName, itemAmount) then
        Player.Functions.AddMoney('cash', totalPrice, 'pawnshop-sell')
        updateStock(shopIndex, itemName, itemAmount)
        
        -- Log sale for Provenance
        logSale(shopIndex, itemName, Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname, Player.PlayerData.citizenid, buyPrice)
        
        TriggerClientEvent('ox_lib:notify', src, { title = locale('menus.main_header'), description = locale('notifications.sold', itemAmount, itemLabel, totalPrice), type = 'success' })
        discordLog("sales", "💰 ITEM SOLD", string.format("**%s** (ID: %s) sold **%sx %s** for **$%s** at Shop #%s", GetPlayerName(src), src, itemAmount, itemLabel, totalPrice, shopIndex), 3066993)
    else
        TriggerClientEvent('ox_lib:notify', src, { description = locale('notifications.no_items'), type = 'error' })
    end
    TriggerClientEvent('qb-pawnshop:client:openMenu', src, { shopIndex = shopIndex })
end)

-- Handle item buying from second-hand shop
RegisterNetEvent('qb-pawnshop:server:buyPawnItems', function(token, shopIndex, itemName, itemAmount, basePrice)
    local src = source
    if not Config.EnableBuy then return end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Token Security Check
    if token ~= SecurityToken then
        exploitBan(src, 'buyPawnItems Invalid Security Token')
        return
    end

    -- Distance check
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local shopCoords = Config.PawnLocation[shopIndex].locations[1]
    if #(playerCoords - shopCoords) > 10.0 then
        exploitBan(src, 'buyPawnItems Distance Exploit')
        return
    end

    local currentStock = getStock(shopIndex, itemName)
    if currentStock < itemAmount then
        TriggerClientEvent('ox_lib:notify', src, { description = "Not enough stock in shop", type = 'error' })
        return
    end

    local _, sellPrice = calculatePrices(shopIndex, itemName, basePrice)
    local totalPrice = (itemAmount * sellPrice)

    if Player.PlayerData.money.cash >= totalPrice then
        if exports.ox_inventory:CanCarryItem(src, itemName, itemAmount) then
            -- Fetch Provenance Data
            local latestSeller = getLatestSeller(shopIndex, itemName)
            local metadata = {}
            if latestSeller then
                metadata.description = "Previously Owned By: " .. latestSeller
            end

            Player.Functions.RemoveMoney('cash', totalPrice, 'pawnshop-buy')
            exports.ox_inventory:AddItem(src, itemName, itemAmount, metadata)
            updateStock(shopIndex, itemName, -itemAmount)
            
            TriggerClientEvent('ox_lib:notify', src, { title = locale('menus.main_header'), description = string.format("You bought %sx %s for $%s", itemAmount, QBCore.Shared.Items[itemName].label, totalPrice), type = 'success' })
            discordLog("purchases", "🛒 ITEM BOUGHT", string.format("**%s** (ID: %s) bought **%sx %s** for **$%s** at Shop #%s", GetPlayerName(src), src, itemAmount, QBCore.Shared.Items[itemName].label, totalPrice, shopIndex), 3447003)
        else
            TriggerClientEvent('ox_lib:notify', src, { description = "Inventory full", type = 'error' })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, { description = "Not enough cash", type = 'error' })
    end
    TriggerClientEvent('qb-pawnshop:client:openMenu', src, { shopIndex = shopIndex })
end)

-- Synchronizes doors with ox_doorlock based on game-time state
RegisterNetEvent('qb-pawnshop:server:syncDoors', function(token, state)
    if not Config.EnableDoorLock then return end
    local src = source

    -- Token Security Check
    if token ~= SecurityToken then
        exploitBan(src, 'syncDoors Invalid Security Token')
        return
    end

    for _, shop in pairs(Config.PawnLocation) do
        if shop.doors then
            for _, doorId in pairs(shop.doors) do
                exports.ox_doorlock:setDoorState(doorId, state)
            end
        end
    end
end)

-- Token Generation
CreateThread(function()
    SecurityToken = "PawnShop_" .. math.random(100, 999) .. "_" .. math.random(1000, 9999)
end)

-- Provide token to client via callback
lib.callback.register('qb-pawnshop:server:getToken', function(source)
    return SecurityToken
end)
