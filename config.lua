Config = {}

Config.UseTimes = false -- Set to false if you want the pawnshop open 24/7
Config.TimeOpen = 7 -- Opening Time
Config.TimeClosed = 17 -- Closing Time

-- New Features Settings
Config.Webhook = "" -- Discord Webhook URL
Config.SellMargin = 1.3 -- 30% Profit (Price other players pay to buy items)
Config.DynamicPriceScale = 0.05 -- Decrease buy price by 5% for every item in stock
Config.MinPricePercent = 0.5 -- Buy price won't drop below 50% of original

Config.PawnLocation = {
    [1] = {
		blip = {
			id = 59, colour = 69, scale = 0.8
		}, inventory = {
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
		}, locations = {
			vec3(25.7, -1347.3, 29.49),
		}, doors = {
			-- 1, 2 -- Add door IDs from ox_doorlock here
		}, targets = {
			-- Example Zone
			-- { loc = vec3(25.06, -1347.32, 29.5), size = vec3(2, 2, 2), heading = 0.0, distance = 1.5 },
		
			-- Example Ped
			{ ped = 'a_f_o_ktown_01', scenario = 'WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT_FACILITY', loc = vec3(-706.039, -914.633, 18.215), heading = 90.458 },
		}
    },
}
