local ShopStocks = {}
local HotDeals = {}

--- Picks random items from each shop's inventory to be "Hot Deals"
local function refreshHotDeals()
    if not Config.EnableHotDeals then return end
    HotDeals = {}
    for shopId, shop in pairs(Config.PawnLocation) do
        local inv = shop.inventory
        if inv and #inv > 0 then
            HotDeals[shopId] = {}
            local picked = {}
            local count = 0
            
            -- Pick unique random items
            while count < Config.HotDealCount and count < #inv do
                local randomIndex = math.random(1, #inv)
                local itemName = inv[randomIndex].name
                if not picked[itemName] then
                    picked[itemName] = true
                    HotDeals[shopId][itemName] = true
                    count = count + 1
                end
            end
        end
    end
    print("^2[qb-pawnshop] Daily Hot Deals have been refreshed!^7")
end

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
    
    -- Initialize hot deals on startup
    refreshHotDeals()
end)

-- [[ Stock Helpers ]]

function getStock(shopId, itemName)
    if not ShopStocks[shopId] then ShopStocks[shopId] = {} end
    return ShopStocks[shopId][itemName] or 0
end

function updateStock(shopId, itemName, amount)
    if not ShopStocks[shopId] then ShopStocks[shopId] = {} end
    ShopStocks[shopId][itemName] = (ShopStocks[shopId][itemName] or 0) + amount
    if ShopStocks[shopId][itemName] < 0 then ShopStocks[shopId][itemName] = 0 end

    MySQL.prepare('INSERT INTO pawnshop_stocks (shop_id, item_name, count) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE count = ?', {
        shopId, itemName, ShopStocks[shopId][itemName], ShopStocks[shopId][itemName]
    })
end

function calculatePrices(shopId, itemName, basePrice)
    local buyPrice = basePrice
    
    -- 1. Apply Dynamic Scaling
    if Config.EnableDynamicPrice then
        local stock = getStock(shopId, itemName)
        buyPrice = basePrice * (1.0 - (stock * Config.DynamicPriceScale))
        local minPrice = basePrice * Config.MinPricePercent
        if buyPrice < minPrice then buyPrice = minPrice end
    end

    -- 2. Apply Hot Deal Multiplier (Always applies to the current calculated buy price)
    local isHot = HotDeals[shopId] and HotDeals[shopId][itemName]
    if isHot then
        buyPrice = buyPrice * Config.HotDealMultiplier
    end
    
    local sellPrice = math.floor(buyPrice * Config.SellMargin)
    return math.floor(buyPrice), sellPrice, isHot
end

-- [[ Callbacks ]]

lib.callback.register('qb-pawnshop:server:getInv', function(source)
    return exports.ox_inventory:GetInventoryItems(source)
end)

lib.callback.register('qb-pawnshop:server:getShopData', function(source, shopIndex, inventory)
    local data = {}
    for _, item in pairs(inventory) do
        local buy, sell, isHot = calculatePrices(shopIndex, item.name, item.price)
        data[item.name] = { 
            buyPrice = buy, 
            sellPrice = sell, 
            stock = getStock(shopIndex, item.name),
            isHot = isHot
        }
    end
    return data
end)

-- Refresh deals every 24 hours (86400 seconds)
CreateThread(function()
    while true do
        Wait(86400000)
        refreshHotDeals()
    end
end)
