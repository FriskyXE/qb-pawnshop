local ShopStocks = {}

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

local function getStock(shopId, itemName)
    if not ShopStocks[shopId] then ShopStocks[shopId] = {} end
    return ShopStocks[shopId][itemName] or 0
end

local function updateStock(shopId, itemName, amount)
    if not ShopStocks[shopId] then ShopStocks[shopId] = {} end
    ShopStocks[shopId][itemName] = (ShopStocks[shopId][itemName] or 0) + amount
    if ShopStocks[shopId][itemName] < 0 then ShopStocks[shopId][itemName] = 0 end

    MySQL.prepare('INSERT INTO pawnshop_stocks (shop_id, item_name, count) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE count = ?', {
        shopId, itemName, ShopStocks[shopId][itemName], ShopStocks[shopId][itemName]
    })
end

local function calculatePrices(shopId, itemName, basePrice)
    local stock = getStock(shopId, itemName)
    local buyPrice = basePrice * (1.0 - (stock * Config.DynamicPriceScale))
    local minPrice = basePrice * Config.MinPricePercent
    if buyPrice < minPrice then buyPrice = minPrice end
    local sellPrice = math.floor(buyPrice * Config.SellMargin)
    return math.floor(buyPrice), sellPrice
end

-- [[ Callbacks ]]

lib.callback.register('qb-pawnshop:server:getInv', function(source)
    return exports.ox_inventory:GetInventoryItems(source)
end)

lib.callback.register('qb-pawnshop:server:getShopData', function(source, shopIndex, inventory)
    local data = {}
    for _, item in pairs(inventory) do
        local buy, sell = calculatePrices(shopIndex, item.name, item.price)
        data[item.name] = { buyPrice = buy, sellPrice = sell, stock = getStock(shopIndex, item.name) }
    end
    return data
end)

-- [[ Exports ]]

exports('getStock', getStock)
exports('updateStock', updateStock)
exports('calculatePrices', calculatePrices)
