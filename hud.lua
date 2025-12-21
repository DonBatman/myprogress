-- hud.lua
local hud_data = {}

local function get_active_skill(player)
	local stack = player:get_wielded_item()
	local tool_name = stack:get_name()
	
	if tool_name:find("pick") then return "miner", "Mining"
	elseif tool_name:find("axe") then return "logger", "Lumbering"
	elseif tool_name:find("shovel") then return "digger", "Digging"
	elseif tool_name:find("hoe") then return "farmer", "Farming"
	else return "builder", "Building" end
end

function quests.update_hud(player)
	local name = player:get_player_name()
	
	if not quests.players or not quests.players[name] then return end
	local ptable = quests.players[name]
	if not ptable.awards then return end

	local skill, label = get_active_skill(player)
	local count = ptable.awards[skill] or 0
	local set = quests.settings[skill] or 10
	
	local levels = {1, 5, 15, 50, 100}
	local target = set * 100 
	for _, mult in ipairs(levels) do
		if count < set * mult then
			target = set * mult
			break
		end
	end

	local percent = math.min(math.floor((count / target) * 100), 100)
	local bar_text = label .. ": " .. count .. " / " .. target .. " (" .. percent .. "%)"

	local hud_color = 0xFFFFFF
	if percent >= 90 then hud_color = 0xFFD700
	elseif percent >= 50 then hud_color = 0x00FF00
	elseif percent >= 25 then hud_color = 0x00CCFF end

	if not hud_data[name] then
		hud_data[name] = player:hud_add({
			hud_elem_type = "text",
			-- POSITION: x=0.5 (center), y=0.05 (very top)
			position = {x = 0.5, y = 0.05},
			offset = {x = 0, y = 20},
			text = bar_text,
			alignment = {x = 0, y = 0},
			number = hud_color,
			scale = {x = 100, y = 100},
		})
	else
		player:hud_change(hud_data[name], "text", bar_text)
		player:hud_change(hud_data[name], "number", hud_color)
	end
end

local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer > 0.5 then
		for _, player in ipairs(minetest.get_connected_players()) do
			quests.update_hud(player)
		end
		timer = 0
	end
end)

minetest.register_on_leaveplayer(function(player)
	hud_data[player:get_player_name()] = nil
end)
