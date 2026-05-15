Config = {}

-- [[ General Settings ]] --
Config.UseTimes = false       -- Set to false if you want the pawnshop open 24/7
Config.TimeOpen = 7           -- Opening Time (GTA Hour)
Config.TimeClosed = 17        -- Closing Time (GTA Hour)

-- [[ Feature Settings ]] --
Config.Webhook = ""           -- Discord Webhook URL for logs
Config.SellMargin = 1.3       -- Profit Margin (1.3 = 30% profit) for players buying from shop
Config.DynamicPriceScale = 0.05 -- Price drop percentage (0.05 = 5%) for each item in shop stock
Config.MinPricePercent = 0.5  -- Minimum price floor (0.5 = 50% of base price)

-- [[ Shop Locations ]] --
Config.PawnLocation = {
    [1] = {
        -- Map Blip Configuration
		blip = {
			id = 59, 
            colour = 69, 
            scale = 0.8
		}, 
        -- Shop-Specific Inventory & Base Prices
        inventory = {
			{ name = 'burger', price = 10 },
			{ name = 'water', price = 10 },
			{ name = 'cola', price = 10 },
			{ name = 'goldchain', price = 100 },
			{ name = 'diamond_ring', price = 250 },
			{ name = 'rolex', price = 500 },
			{ name = 'tenkgoldchain', price = 150 },
			{ name = 'tablet', price = 200 },
			{ name = 'iphone', price = 600 },
			{ name = 'samsungphone', price = 400 },
			{ name = 'laptop', price = 800 },
		}, 
        -- Blip Appearance Locations
        locations = {
			vec3(25.7, -1347.3, 29.49),
		}, 
        -- Doors to manage with ox_doorlock (IDs from ox_doorlock config)
        doors = {
			-- 1, 2 
		}, 
        -- Interaction Targets (Add Ped for NPC, remove/comment Ped for Zone)
        targets = {
			-- NPC Ped Example
			{ 
                ped = 'a_f_o_ktown_01', 
                scenario = 'WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT_FACILITY', 
                loc = vec3(25.7, -1347.3, 29.49), 
                heading = 90.0,
                distance = 2.0
            },
            
			-- Box Zone Example (Uncomment to use instead of Ped)
			-- { loc = vec3(25.06, -1347.32, 29.5), size = vec3(2, 2, 2), heading = 0.0, distance = 1.5 },
		}
    },
}
