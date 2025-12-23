local function get_top_players(skill, limit)
	local list = {}
	
	for name, data in pairs(quests.players) do
		if data.awards and data.awards[skill] then
			table.insert(list, {name = name, score = data.awards[skill]})
		end
	end
	
	table.sort(list, function(a, b) return a.score > b.score end)
	
	return list
end

core.register_chatcommand("leaderboard", {
	params = "[skill]",
	description = "Show the top players (Usage: /leaderboard miner)",
	func = function(name, param)
		local skill = param:lower()
		local valid_skills = {miner=1, digger=1, logger=1, builder=1, farmer=1}
		
		if not valid_skills[skill] then
			return false, "Usage: /leaderboard <miner|digger|logger|builder|farmer>"
		end
		
		local top_list = get_top_players(skill, 5)
		
		if #top_list == 0 then
			return true, "No data found for " .. skill .. "."
		end
		
		local output = "\n--- " .. skill:upper() .. " LEADERBOARD ---"
		for i, entry in ipairs(top_list) do
			if i > 5 then break end
			output = output .. "\n" .. i .. ". " .. entry.name .. ": " .. entry.score
		end
		output = output .. "\n------------------------------"
		
		return true, output
	end,
})
