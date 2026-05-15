-- [[ QB-Pawnshop Rework - Server Side ]]
local QBCore = exports['qb-core']:GetCoreObject()

-- [[ Variables ]]
local ShopStocks = {}

-- [[ Initialization & Database ]]

--- Creates stocks table and loads existing data
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS pawnshop_stocks (
            shop_id INT NOT NULL,
            item_name VARCHAR(50) NOT NULL,
            count INT DEFAULT 0,
            PRIMARY KEY (shop_id, item_name)
        )
    ]])

    local results = MySQL.query.await('SELECT * FROM pawnshop_stocks')
    if results then
        for _, row in pairs(results) do
            if not ShopStocks[row.shop_id] then ShopStocks[row.shop_id] = {} end
            ShopStocks[row.shop_id][row.item_name] = row.count
        end
    end
end)

-- [[ Stock Helpers ]]

--- Gets current stock for an item in a specific shop
---@param shopId number
---@param itemName string
---@return number
local function getStock(shopId, itemName)
    if not ShopStocks[shopId] then ShopStocks[shopId] = {} end
    return ShopStocks[shopId][itemName] or 0
end

--- Updates stock for an item and persists to database
---@param shopId number
---@param itemName string
---@param amount number
local function updateStock(shopId, itemName, amount)
    if not ShopStocks[shopId] then ShopStocks[shopId] = {} end
    ShopStocks[shopId][itemName] = (ShopStocks[shopId][itemName] or 0) + amount
    if ShopStocks[shopId][itemName] < 0 then ShopStocks[shopId][itemName] = 0 end

    MySQL.prepare('INSERT INTO pawnshop_stocks (shop_id, item_name, count) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE count = ?', {
        shopId, itemName, ShopStocks[shopId][itemName], ShopStocks[shopId][itemName]
    })
end

-- [[ Calculation Helpers ]]

--- Calculates dynamic buy and sell prices based on stock
---@param shopId number
---@param itemName string
---@param basePrice number
---@return number, number
local function calculatePrices(shopId, itemName, basePrice)
    local stock = getStock(shopId, itemName)
    
    -- Buy Price (What shop pays player): decreases by Config.DynamicPriceScale for every item in stock
    local buyPrice = basePrice * (1.0 - (stock * Config.DynamicPriceScale))
    local minPrice = basePrice * Config.MinPricePercent
    
    if buyPrice < minPrice then buyPrice = minPrice end
    
    -- Sell Price (What player pays shop): higher than buy price based on margin
    local sellPrice = math.floor(buyPrice * Config.SellMargin)
    
    return math.floor(buyPrice), sellPrice
end

-- [[ Utility Helpers ]]

--- Sends a formatted log to Discord via Webhook
---@param title string
---@param message string
---@param color number
local function discordLog(title, message, color)
    if not Config.Webhook or Config.Webhook == "" then return end
    local embed = {
        {
            ["color"] = color,
            ["title"] = "**" .. title .. "**",
            ["description"] = message,
            ["footer"] = { ["text"] = os.date("%c") },
        }
    }
    PerformHttpRequest(Config.Webhook, function(err, text, headers) end, 'POST', json.encode({ username = "Pawn Shop Logs", embeds = embed }), { ['Content-Type'] = 'application/json' })
end

--- Permanently bans a player for exploiting
---@param id number
---@param reason string
local function exploitBan(id, reason)
    local Player = QBCore.Functions.GetPlayer(id)
    if not Player then return end

    MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        GetPlayerName(id),
        QBCore.Functions.GetIdentifier(id, 'license'),
        QBCore.Functions.GetIdentifier(id, 'discord'),
        QBCore.Functions.GetIdentifier(id, 'ip'),
        reason,
        2147483647,
        'qb-pawnshop'
    })

    TriggerEvent('qb-log:server:CreateLog', 'pawnshop', 'Player Banned', 'red', string.format('%s was banned for %s', GetPlayerName(id), reason), true)
    discordLog("🛑 CHEATER BANNED", string.format("**%s** (ID: %s) banned for: %s", GetPlayerName(id), id, reason), 15158332)
    DropPlayer(id, 'You were permanently banned: Exploiting')
end

-- [[ Main Events ]]

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
        
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('menus.main_header'),
            description = locale('notifications.sold', itemAmount, itemLabel, totalPrice),
            type = 'success'
        })
        
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
            
            TriggerClientEvent('ox_lib:notify', src, {
                title = locale('menus.main_header'),
                description = string.format("You bought %sx %s for $%s", itemAmount, QBCore.Shared.Items[itemName].label, totalPrice),
                type = 'success'
            })
            
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

-- [[ Callbacks ]]

--- Simple inventory check
lib.callback.register('qb-pawnshop:server:getInv', function(source)
    return exports.ox_inventory:GetInventoryItems(source)
end)

--- Returns dynamic prices and stock for a list of items
lib.callback.register('qb-pawnshop:server:getShopData', function(source, shopIndex, inventory)
    local data = {}
    for _, item in pairs(inventory) do
        local buy, sell = calculatePrices(shopIndex, item.name, item.price)
        data[item.name] = {
            buyPrice = buy,
            sellPrice = sell,
            stock = getStock(shopIndex, item.name)
        }
    end
    return data
end)
