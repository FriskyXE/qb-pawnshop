local QBCore = exports['qb-core']:GetCoreObject()

local function toggleNui(visible, shopData)
    SetNuiFocus(visible, visible)
    SendNUIMessage({
        action = 'setVisible',
        data = {
            visible = visible,
            shopData = shopData
        }
    })
end

RegisterNetEvent('qb-pawnshop:client:openMenu', function(data)
    local shopIndex = data and data.shopIndex or 1
    if Config.UseTimes then
        local hour = GetClockHours()
        if hour < Config.TimeOpen or hour >= Config.TimeClosed then
            lib.notify({ title = locale('menus.main_header'), description = locale('notifications.pawn_closed', Config.TimeOpen, Config.TimeClosed), type = 'error' })
            return
        end
    end

    local shop = Config.PawnLocation[shopIndex]
    local shopInventory = shop.inventory or {}
    local playerInventory = lib.callback.await('qb-pawnshop:server:getInv', false)
    local shopData = lib.callback.await('qb-pawnshop:server:getShopData', false, shopIndex, shopInventory)

    -- Filter player inventory to only show items accepted by this shop
    local filteredPlayerInv = {}
    if playerInventory then
        for _, v in pairs(playerInventory) do
            for _, itemData in pairs(shopInventory) do
                if v.name == itemData.name then
                    v.basePrice = itemData.price
                    filteredPlayerInv[#filteredPlayerInv + 1] = v
                end
            end
        end
    end

    toggleNui(true, {
        shopIndex = shopIndex,
        playerInventory = filteredPlayerInv,
        shopData = shopData
    })
end)

RegisterNUICallback('hideUI', function(_, cb)
    toggleNui(false)
    cb('ok')
end)

RegisterNUICallback('sellItem', function(data, cb)
    TriggerServerEvent('qb-pawnshop:server:sellPawnItems', SecurityToken, data.shopIndex, data.itemName, data.amount, data.basePrice)
    cb(true)
end)

RegisterNUICallback('buyItem', function(data, cb)
    TriggerServerEvent('qb-pawnshop:server:buyPawnItems', SecurityToken, data.shopIndex, data.itemName, data.amount, data.basePrice)
    cb(true)
end)
