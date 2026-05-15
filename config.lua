Config = {}

Config.UseTimes = false -- Set to false if you want the pawnshop open 24/7
Config.TimeOpen = 7 -- Opening Time
Config.TimeClosed = 17 -- Closing Time

Config.PawnLocation = {
    [1] = {
		blip = {
			id = 59, colour = 69, scale = 0.8
		}, inventory = {
			{ name = 'burger', price = 10 },
			{ name = 'water', price = 10 },
			{ name = 'cola', price = 10 },
			{ name = 'goldchain', price = math.random(50, 100) },
			{ name = 'diamond_ring', price = math.random(50, 100) },
			{ name = 'rolex', price = math.random(50, 100) },
			{ name = 'tenkgoldchain', price = math.random(50, 100) },
			{ name = 'tablet', price = math.random(50, 100) },
			{ name = 'iphone', price = math.random(50, 100) },
			{ name = 'samsungphone', price = math.random(50, 100) },
			{ name = 'laptop', price = math.random(50, 100) },
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