function myprogress.get_bar(skill, xp, level)
	local base = myprogress.xp_scaling[skill]
	local cur_xp = math.floor(base * (level ^ 1.5))
	local nxt_xp = math.floor(base * ((level + 1) ^ 1.5))
	local progress = math.max(0, math.min(1, (xp - cur_xp) / (nxt_xp - cur_xp)))
	local bar = "[" .. string.rep("|", math.floor(progress * 10)) .. string.rep(".", 10 - math.floor(progress * 10)) .. "]"
	return bar .. " " .. math.floor(progress * 100) .. "%"
end

function myprogress.update_hud(player)
	local name = player:get_player_name()
	local s = myprogress.players[name]
	if not s then return end

	local txt = 
		" Mining Lvl "..s.mlevel.." "..myprogress.get_bar("mining", s.mining, s.mlevel)..
		"\n Lumber Lvl "..s.llevel.." "..myprogress.get_bar("lumbering", s.lumbering, s.llevel)..
		"\n Build Lvl "..s.blevel.." "..myprogress.get_bar("building", s.building, s.blevel)..
		"\n Farm Lvl "..s.flevel.." "..myprogress.get_bar("farming", s.farming, s.flevel)..
		"\n Dig Lvl "..s.dlevel.." "..myprogress.get_bar("digging", s.digging, s.dlevel)

	if myprogress.player_huds[name] then 
		player:hud_change(myprogress.player_huds[name], "text", txt)
	else 
		myprogress.player_huds[name] = player:hud_add({
			hud_elem_type="text", 
			position={x=0.02, y=0.95}, 
			alignment={x=1,y=-1}, 
			number=0xFFFFFF, 
			text=txt
		}) 
	end
end

function myprogress.add_xp(player, skill, amount)
	local name = player:get_player_name()
	local s = myprogress.players[name]
	s[skill] = s[skill] + amount
	local l_key = skill:sub(1,1).."level"
	local new_l = math.floor((s[skill] / myprogress.xp_scaling[skill]) ^ (1/1.5))
	if new_l > s[l_key] then
		s[l_key] = new_l
		core.chat_send_player(name, "★ LEVEL UP: "..skill:upper().." IS NOW "..new_l.." ★")
	local rewards = {
    mining = "myprogress:master_smelter",
    lumbering = "myprogress:master_sawmill",
    digging = "myprogress:master_sifter",
    building = "myprogress:master_architect_table",
    farming = "myprogress:master_harvester"
}

	if new_l == 20 and rewards[skill] then
    	local inv = player:get_inventory()
    	inv:add_item("main", rewards[skill])
    	core.chat_send_player(name, "MASTERY REACHED! You have been awarded: " .. rewards[skill])
	end
	end
	myprogress.update_hud(player)
end
function award_for_digging(nname, playername)
	local ptable = myquests.players[playername]
	if not ptable or not ptable.awards then return end
	
	local atable = ptable.awards
	local player = core.get_player_by_name(playername)
	if not player then return end
	local inv = player:get_inventory()

	local function check_level(val, set_val, skill_name, machine_name)
		local levels = {1, 5, 15, 50, 100}
		local tier_names = {"wood", "stone", "bronze", "silver", "gold"}
		
		for i, mult in ipairs(levels) do
			if val == set_val * mult then
				local tier = tier_names[i]
				core.chat_send_player(playername, "Level "..i.." "..skill_name:upper().."!")
				
				inv:add_item("main", "myprogress:award_"..skill_name.."_"..tier)

		local pos = player:get_pos()
		pos.y = pos.y + 1.5
		
		core.sound_play("default_cool_item", {
    		pos = pos,
    		gain = 1.0,
    		max_hear_distance = 10,
})

core.add_particlespawner({
    amount = 40,
    time = 0.1,
    minpos = {x=pos.x-0.2, y=pos.y, z=pos.z-0.2},
    maxpos = {x=pos.x+0.2, y=pos.y+0.5, z=pos.z+0.2},
    minvel = {x=-3, y=1, z=-3},
    maxvel = {x=3, y=5, z=3},
    minacc = {x=0, y=-9.8, z=0},
    maxacc = {x=0, y=-9.8, z=0},
    minexptime = 1,
    maxexptime = 2,
    minsize = 1,
    maxsize = 3,
    texture = "default_item_smoke.png^[colorize:yellow:200",
})
				if i == 5 and machine_name then
					inv:add_item("main", machine_name)
					core.chat_send_player(playername, "MASTERY: You've earned a machine!")
				end
				return i
			end
		end
		return nil
	end

	if string.find(nname, "stone") then
		atable.miner = atable.miner + 1
		local lvl = check_level(atable.miner, myquests.settings.miner, "miner", "myprogress:master_smelter")
		if lvl then atable.miner_level = lvl end
	
	elseif string.find(nname, "sand") or string.find(nname, "dirt") then
		atable.digger = atable.digger + 1
		local lvl = check_level(atable.digger, myquests.settings.digger, "digger", "myprogress:master_sifter")
		if lvl then atable.digger_level = lvl end

	elseif string.find(nname, "tree") then
		atable.logger = atable.logger + 1
		local lvl = check_level(atable.logger, myquests.settings.logger, "logger", "myprogress:master_sawmill")
		if lvl then atable.logger_level = lvl end

	elseif string.find(nname, "farming:wheat") then
		atable.farmer = atable.farmer + 1
		local lvl = check_level(atable.farmer, myquests.settings.farmer, "farmer", "myprogress:master_harvester")
		if lvl then atable.farmer_level = lvl end
	end
end

function award_for_placing(nname, playername)
	if not myquests.players[playername] then return end
	local atable = myquests.players[playername].awards
	local player = core.get_player_by_name(playername)
	local inv = player:get_inventory()

	atable.builder = atable.builder + 1
	
	local levels = {1, 5, 15, 50, 100}
	local tiers = {"wood", "stone", "bronze", "silver", "gold"}
	local set = myquests.settings.builder

	for i, mult in ipairs(levels) do
		if atable.builder == set * mult then
			atable.builder_level = i
			core.chat_send_player(playername, "Builder Level "..i.."!")

local pos = player:get_pos()
pos.y = pos.y + 1.5

core.sound_play("default_cool_item", {
    pos = pos,
    gain = 1.0,
    max_hear_distance = 10,
})

core.add_particlespawner({
    amount = 40,
    time = 0.1,
    minpos = {x=pos.x-0.2, y=pos.y, z=pos.z-0.2},
    maxpos = {x=pos.x+0.2, y=pos.y+0.5, z=pos.z+0.2},
    minvel = {x=-3, y=1, z=-3},
    maxvel = {x=3, y=5, z=3},
    minacc = {x=0, y=-9.8, z=0},
    maxacc = {x=0, y=-9.8, z=0},
    minexptime = 1,
    maxexptime = 2,
    minsize = 1,
    maxsize = 3,
    texture = "default_item_smoke.png^[colorize:yellow:200",
})
			inv:add_item("main", "myprogress:award_builder_"..tiers[i])
			if i == 5 then inv:add_item("main", "myprogress:master_architect_table") end
		end
	end
end
