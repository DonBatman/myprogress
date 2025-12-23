local awards = {"Miner", "Logger", "Digger", "Builder", "Farmer"}
local award_levels = {
	{"Wood", "brown:150"},
	{"Stone", "gray:150"},
	{"Bronze", "red:100"},
	{"Silver", "white:75"},
	{"Gold", "yellow:120"},
}

for _, a in pairs(awards) do
	local al = string.lower(a)
	for _, level_data in ipairs(award_levels) do
		local b = level_data[1]
		local c = level_data[2]
		local bl = string.lower(b)

		core.register_node("myprogress:award_"..al.."_"..bl, {
			description = b.." "..a.." Trophy",
			drawtype = "mesh",
			mesh = "myprogress_award_"..al..".obj", 
			tiles = {"default_silver_sand.png^[colorize:"..c}, 
			paramtype = "light",
			paramtype2 = "facedir",
			groups = {cracky = 3}
		})
	end
end
