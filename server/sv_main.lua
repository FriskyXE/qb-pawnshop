local QBCore = exports['qb-core']:GetCoreObject()

-- Handle item selling to shop
RegisterNetEvent('qb-pawnshop:server:sellPawnItems', function(shopIndex, itemName, itemAmount, basePrice)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Distance check (Security)
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
        
        TriggerClientEvent('ox_lib:notify', src, { title = locale('menus.main_header'), description = locale('notifications.sold', itemAmount, itemLabel, totalPrice), type = 'success' })
        discordLog("💰 ITEM SOLD", string.format("**%s** (ID: %s) sold **%sx %s** for **$%s** at Shop #%s", GetPlayerName(src), src, itemAmount, itemLabel, totalPrice, shopIndex), 3066993)
    else
        TriggerClientEvent('ox_lib:notify', src, { description = locale('notifications.no_items'), type = 'error' })
    end
    TriggerClientEvent('qb-pawnshop:client:openMenu', src, { shopIndex = shopIndex })
end)

-- Handle item buying from second-hand shop
RegisterNetEvent('qb-pawnshop:server:buyPawnItems', function(shopIndex, itemName, itemAmount, basePrice)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local currentStock = getStock(shopIndex, itemName)
    if currentStock < itemAmount then
        TriggerClientEvent('ox_lib:notify', src, { description = "Not enough stock in shop", type = 'error' })
        return
    end

    local _, sellPrice = calculatePrices(shopIndex, itemName, basePrice)
    local totalPrice = (itemAmount * sellPrice)

    if Player.PlayerData.money.cash >= totalPrice then
        if exports.ox_inventory:CanCarryItem(src, itemName, itemAmount) then
            Player.Functions.RemoveMoney('cash', totalPrice, 'pawnshop-buy')
            exports.ox_inventory:AddItem(src, itemName, itemAmount)
            updateStock(shopIndex, itemName, -itemAmount)
            
            TriggerClientEvent('ox_lib:notify', src, { title = locale('menus.main_header'), description = string.format("You bought %sx %s for $%s", itemAmount, QBCore.Shared.Items[itemName].label, totalPrice), type = 'success' })
            discordLog("🛒 ITEM BOUGHT", string.format("**%s** (ID: %s) bought **%sx %s** for **$%s** at Shop #%s", GetPlayerName(src), src, itemAmount, QBCore.Shared.Items[itemName].label, totalPrice, shopIndex), 3447003)
        else
            TriggerClientEvent('ox_lib:notify', src, { description = "Inventory full", type = 'error' })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, { description = "Not enough cash", type = 'error' })
    end
    TriggerClientEvent('qb-pawnshop:client:openMenu', src, { shopIndex = shopIndex })
end)

-- Synchronizes doors with ox_doorlock based on game-time state
RegisterNetEvent('qb-pawnshop:server:syncDoors', function(state)
    for _, shop in pairs(Config.PawnLocation) do
        if shop.doors then
            for _, doorId in pairs(shop.doors) do
                exports.ox_doorlock:setDoorState(doorId, state)
            end
        end
    end
end)
