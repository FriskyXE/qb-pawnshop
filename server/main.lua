local QBCore = exports['qb-core']:GetCoreObject()

local function exploitBan(id, reason)
    MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {
            GetPlayerName(id),
            QBCore.Functions.GetIdentifier(id, 'license'),
            QBCore.Functions.GetIdentifier(id, 'discord'),
            QBCore.Functions.GetIdentifier(id, 'ip'),
            reason,
            2147483647,
            'qb-pawnshop'
        })
    TriggerEvent('qb-log:server:CreateLog', 'pawnshop', 'Player Banned', 'red',
        string.format('%s was banned by %s for %s', GetPlayerName(id), 'qb-pawnshop', reason), true)
    DropPlayer(id, 'You were permanently banned by the server for: Exploiting')
end

RegisterNetEvent('qb-pawnshop:server:sellPawnItems', function(itemName, itemAmount, itemPrice)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local totalPrice = (tonumber(itemAmount) * itemPrice)
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local dist
    for _, value in pairs(Config.PawnLocation) do
        dist = #(playerCoords - value.coords)
        if #(playerCoords - value.coords) < 2 then
            dist = #(playerCoords - value.coords)
            break
        end
    end
    if dist > 5 then
        exploitBan(src, 'sellPawnItems Exploiting')
        return
    end
    local itemLabel = exports.ox_inventory:GetItem(src, itemName).label
    if exports.ox_inventory:RemoveItem(src, itemName, tonumber(itemAmount)) then
        Player.Functions.AddMoney('cash', totalPrice, 'qb-pawnshop:server:sellPawnItems')
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('menus.main_header'),
            description = locale('notifications.sold', tonumber(itemAmount), itemLabel, totalPrice),
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('menus.main_header'),
            description = locale('notifications.no_items'),
            type = 'error'
        })
    end
    TriggerClientEvent('qb-pawnshop:client:openMenu', src)
end)

lib.callback.register('qb-pawnshop:server:getInv', function(source)
    local inventory = exports.ox_inventory:GetInventoryItems(source)
    return inventory
end)

if Config.UseTimes then
    CreateThread(function()
        while true do
            local hour = os.date('*t').hour
            local isClosed = hour < Config.TimeOpen or hour >= Config.TimeClosed
            local state = isClosed and 1 or 0 -- 1 = Locked, 0 = Unlocked

            for _, shop in pairs(Config.PawnLocation) do
                if shop.doors then
                    for _, doorId in pairs(shop.doors) do
                        exports.ox_doorlock:setDoorState(doorId, state)
                    end
                end
            end
            Wait(60000) -- Check every minute
        end
    end)
end
