local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('qb-pawnshop:client:openMenu', function(data)
    local shopIndex = data and data.shopIndex or 1
    if Config.UseTimes then
        local hour = GetClockHours()
        if hour < Config.TimeOpen or hour >= Config.TimeClosed then
            lib.notify({ title = locale('menus.main_header'), description = locale('notifications.pawn_closed', Config.TimeOpen, Config.TimeClosed), type = 'error' })
            return
        end
    end

    local options = {
        {
            title = locale('menus.sell_header'),
            description = locale('menus.sell_txt'),
            icon = 'fas fa-hand-holding-usd',
            event = 'qb-pawnshop:client:openPawn',
            args = { shopIndex = shopIndex }
        }
    }

    if Config.Features.BuyItems then
        options[#options + 1] = {
            title = "Buy Items",
            description = "Purchase second-hand items from this shop",
            icon = 'fas fa-shopping-basket',
            event = 'qb-pawnshop:client:openBuyMenu',
            args = { shopIndex = shopIndex }
        }
    end

    lib.registerContext({
        id = 'pawn_main_menu',
        title = locale('menus.main_header'),
        options = options
    })
    lib.showContext('pawn_main_menu')
end)

RegisterNetEvent('qb-pawnshop:client:openPawn', function(data)
    local shopIndex = data and data.shopIndex or 1
    local shop = Config.PawnLocation[shopIndex]
    local shopInventory = shop.inventory or {}
    local inventory = lib.callback.await('qb-pawnshop:server:getInv', false)
    local shopData = lib.callback.await('qb-pawnshop:server:getShopData', false, shopIndex, shopInventory)
    
    if not inventory then return end
    
    local options = {}
    for _, v in pairs(inventory) do
        for i = 1, #shopInventory do
            local itemData = shopInventory[i]
            if v.name == itemData.name then
                local currentData = shopData[v.name]
                local currentBuyPrice = currentData.buyPrice
                local isHot = currentData.isHot

                options[#options + 1] = {
                    title = (isHot and "🔥 " or "") .. v.label,
                    description = string.format("%sPrice: **$%s**\nShop Stock: **%s**", (isHot and "**HOT DEAL!**\n" or ""), currentBuyPrice, currentData.stock),
                    icon = isHot and 'fas fa-fire' or 'fas fa-arrow-right',
                    event = 'qb-pawnshop:client:pawnitems',
                    args = { label = v.label, price = itemData.price, name = v.name, count = v.count, shopIndex = shopIndex }
                }
            end
        end
    end

    if #options == 0 then
        lib.notify({ title = locale('menus.main_header'), description = locale('notifications.no_items'), type = 'error' })
        return
    end

    lib.registerContext({ id = 'pawn_sell_menu', title = locale('menus.sell_header'), menu = 'pawn_main_menu', options = options })
    lib.showContext('pawn_sell_menu')
end)

RegisterNetEvent('qb-pawnshop:client:openBuyMenu', function(data)
    if not Config.Features.BuyItems then return end
    local shopIndex = data and data.shopIndex or 1
    local shop = Config.PawnLocation[shopIndex]
    local shopInventory = shop.inventory or {}
    local shopData = lib.callback.await('qb-pawnshop:server:getShopData', false, shopIndex, shopInventory)
    
    local options = {}
    for _, item in pairs(shopInventory) do
        local stockData = shopData[item.name]
        if stockData and stockData.stock > 0 then
            local isHot = stockData.isHot
            options[#options + 1] = {
                title = (isHot and "🔥 " or "") .. QBCore.Shared.Items[item.name].label,
                description = string.format("%sBuy for: **$%s**\nAvailable: **%s**", (isHot and "**HOT DEAL!**\n" or ""), stockData.sellPrice, stockData.stock),
                icon = isHot and 'fas fa-fire' or 'fas fa-tag',
                event = 'qb-pawnshop:client:buyItems',
                args = { name = item.name, label = QBCore.Shared.Items[item.name].label, price = item.price, stock = stockData.stock, shopIndex = shopIndex }
            }
        end
    end

    if #options == 0 then
        lib.notify({ description = "Shop has no stock right now", type = 'error' })
        return
    end

    lib.registerContext({ id = 'pawn_buy_menu', title = "Buy Second-hand Items", menu = 'pawn_main_menu', options = options })
    lib.showContext('pawn_buy_menu')
end)

RegisterNetEvent('qb-pawnshop:client:pawnitems', function(item)
    local input = lib.inputDialog(locale('inputs.sell_header'), {
        { type = 'number', label = locale('inputs.amount', item.count), description = ("Selling %s"):format(item.label), min = 1, max = item.count, default = 1 }
    })
    if not input or not input[1] then return end
    local amount = math.floor(tonumber(input[1]))
    if amount > 0 and amount <= item.count then
        TriggerServerEvent('qb-pawnshop:server:sellPawnItems', SecurityToken, item.shopIndex, item.name, amount, item.price)
    else
        lib.notify({ description = "Invalid amount", type = 'error' })
    end
end)

RegisterNetEvent('qb-pawnshop:client:buyItems', function(item)
    if not Config.Features.BuyItems then return end
    local input = lib.inputDialog("Purchase Item", {
        { type = 'number', label = "Amount to buy", description = ("Available stock: %s"):format(item.stock), min = 1, max = item.stock, default = 1 }
    })
    if not input or not input[1] then return end
    local amount = math.floor(tonumber(input[1]))
    if amount > 0 and amount <= item.stock then
        TriggerServerEvent('qb-pawnshop:server:buyPawnItems', SecurityToken, item.shopIndex, item.name, amount, item.price)
    else
        lib.notify({ description = "Invalid amount or not enough stock", type = 'error' })
    end
end)
